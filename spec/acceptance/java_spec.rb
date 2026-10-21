# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'openssl'

# The manifests that depend on the JDK, applied with the real Oracle JDK RPMs:
# install_java (JDK 21), install_aem_java (JDK 11, the one AEM runs on), then the keystore part of
# config_aem_ssl and the JMX properties of config_aem_jmx against JDK 11.
#
# The RPMs need an Oracle account and are too big to commit, so set JDK_RPM_DIR to a directory with an
# Oracle JDK 11 and a JDK 21 RPM, any update (make acceptance-java), e.g. jdk-11.0.33.0.1_linux-x64_bin.rpm
# and jdk-21.0.13_linux-x64_bin.rpm. The newest of each is used, and its package name, version and install
# directory are read from the RPM itself (rpm -qp on the machine running the tests), so the tests check
# that the directory the manifests derive from the file name is the one the RPM really installs into.
# They are copied to the host and installed from file://. They are x86_64 RPMs, so the hosts must be x86_64.
#
# Paths are the ones packer-aem gives the classes (../packer-aem/conf/puppet/hieradata/common.yaml:
# tmp_dir /tmp/shinesolutions/packer-aem, cert_base_url file://<tmp_dir>/certs, aem_keystore_path
# /etc/ssl/aem-author/author.ks). The key and certificate stand in for the ones packer-aem's
# config::certs fetches from ACM, and are generated here.
describe 'JDK dependent manifests' do
  rpm_dir = '/tmp/shinesolutions/jdk-rpms'
  tmp_dir = '/tmp/shinesolutions/packer-aem'

  # The newest jdk-<major>*_linux-x64_bin.rpm in JDK_RPM_DIR, with what the RPM says about itself:
  # file name, package name (e.g. jdk-11), version (e.g. 11.0.33.0.1) and the directory its bin/java is
  # in (e.g. /usr/lib/jvm/jdk-11.0.33.0.1-oracle-x64). Empty without JDK_RPM_DIR or a matching RPM.
  def self.oracle_jdk(major)
    rpms = Dir.glob(File.join(ENV.fetch('JDK_RPM_DIR', ''), "jdk-#{major}.*_linux-x64_bin.rpm"))
    rpms = rpms.map { |rpm| [rpm, `rpm -qp --qf '%{NAME} %{VERSION}' '#{rpm}' 2>/dev/null`.split] }
               .select { |_rpm, (name, version)| name && version }
    return {} if rpms.empty?

    rpm, (package, version) = rpms.max_by { |_rpm, (_name, v)| Gem::Version.new(v) }
    java = `rpm -qlp '#{rpm}' 2>/dev/null`.lines.map(&:strip).find { |file| file.match?(%r{^/usr/lib/jvm/[^/]+/bin/java$}) }
    { rpm: File.basename(rpm), package: package, version: version, java_home: java && File.dirname(java, 2) }
  end

  jdk21 = oracle_jdk(21)
  jdk11 = oracle_jdk(11)

  def self.java_class_manifest(klass, rpm, tmp_dir, rpm_dir)
    <<~PUPPET
      class { 'aem_curator::#{klass}':
        cert_base_url => 'file://#{tmp_dir}/certs',
        tmp_dir       => '#{tmp_dir}',
        jdk_base_url  => 'file://#{rpm_dir}',
        jdk_filename  => '#{rpm}',
      }
    PUPPET
  end

  before(:all) do
    skip 'Set JDK_RPM_DIR to a directory with an Oracle JDK 11 and a JDK 21 RPM to run these' unless jdk11[:java_home] && jdk21[:java_home]
    skip 'The Oracle JDK RPMs are x86_64 only' unless fact('os.architecture') == 'x86_64'

    key = OpenSSL::PKey::RSA.new(2048)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse('/CN=localhost')
    cert.public_key = key.public_key
    cert.not_before = Time.now
    cert.not_after = Time.now + (24 * 60 * 60)
    cert.sign(key, OpenSSL::Digest.new('SHA256'))
    # packer-aem's config::certs creates <tmp_dir>/certs with aem.key and aem.cert before these classes
    on(default, "mkdir -p #{tmp_dir}/certs #{rpm_dir}")
    create_remote_file(default, "#{tmp_dir}/certs/aem.cert", cert.to_pem)
    create_remote_file(default, "#{tmp_dir}/certs/aem.key", key.to_pem)
    [jdk21[:rpm], jdk11[:rpm]].each do |rpm|
      scp_to(default, File.join(ENV.fetch('JDK_RPM_DIR'), rpm), "#{rpm_dir}/#{rpm}")
    end
  end

  shared_examples 'an Oracle JDK install' do |package, version, java_home|
    it 'installs the RPM into its version-specific directory' do
      expect(on(default, "rpm -q #{package}").stdout).to start_with("#{package}-#{version}")
      expect(on(default, "test -f #{java_home}/lib/security/cacerts").exit_code).to eq(0)
    end

    it 'makes it the java alternative, /usr/java/default and the java on the PATH' do
      expect(on(default, 'alternatives --display java').stdout).to match(%r{link currently points to #{java_home}/bin/java})
      expect(on(default, 'readlink /usr/java/default').stdout.strip).to eq(java_home)
      # what aem_package's java -jar ... -unpack and the oak-run scripts run
      expect(on(default, 'readlink -f "$(command -v java)"').stdout.strip).to eq("#{java_home}/bin/java")
      expect(on(default, 'java -version 2>&1').stdout).to match(%r{version "#{Regexp.escape(version)}"})
    end

    it 'adds libjvm to the dynamic linker path (used by collectd GenericJMX)' do
      expect(on(default, 'cat /etc/ld.so.conf.d/99-libjvm.conf').stdout).to eq("#{java_home}/lib/server/\n")
      expect(on(default, 'ldconfig -p').stdout).to include("#{java_home}/lib/server/libjvm.so")
    end

    it 'imports the AEM certificate into the JDK cacerts' do
      result = on(default, "keytool -list -keystore #{java_home}/lib/security/cacerts -storepass changeit -alias cqse-0")
      expect(result.stdout).to include('trustedCertEntry')
    end
  end

  context 'aem_curator::install_java with Oracle JDK 21' do
    manifest = java_class_manifest('install_java', jdk21[:rpm], tmp_dir, rpm_dir)

    before(:all) do
      apply_manifest(manifest, catch_failures: true)
      @second_run = apply_manifest(manifest, catch_failures: true).stdout
    end

    it_behaves_like 'an Oracle JDK install', jdk21[:package], jdk21[:version], jdk21[:java_home]

    # The alternatives --set exec has no guard and runs on every apply, as before
    it 'downloads and installs the RPM and imports the certificate only on the first run' do
      expect(@second_run).not_to match(%r{Java::Download\[#{Regexp.escape(jdk21[:version].to_s)}\]/(Archive|Exec)}) # rubocop:disable RSpec/InstanceVariable
      expect(@second_run).not_to match(%r{Java_ks}) # rubocop:disable RSpec/InstanceVariable
    end
  end

  context 'aem_curator::install_aem_java with Oracle JDK 11' do
    manifest = java_class_manifest('install_aem_java', jdk11[:rpm], tmp_dir, rpm_dir)

    before(:all) do
      apply_manifest(manifest, catch_failures: true)
      @second_run = apply_manifest(manifest, catch_failures: true).stdout
    end

    it_behaves_like 'an Oracle JDK install', jdk11[:package], jdk11[:version], jdk11[:java_home]

    it 'downloads and installs the RPM and imports the certificate only on the first run' do
      expect(@second_run).not_to match(%r{Java::Download\[#{Regexp.escape(jdk11[:version].to_s)}\]/(Archive|Exec)}) # rubocop:disable RSpec/InstanceVariable
      expect(@second_run).not_to match(%r{Java_ks}) # rubocop:disable RSpec/InstanceVariable
    end
  end

  context 'aem_curator::config_aem_ssl jetty keystore with JDK 11' do
    before(:all) do
      # aem_curator::aem_instance creates the AEM user. The aem_resources providers are loaded, but only
      # the file, archive and java_ks resources are applied, as enabling SSL in AEM needs a running AEM
      on(default, 'id aem-author || useradd aem-author')
      install_aem_resources_dependencies(default)
      create_remote_file(default, '/tmp/config_aem_ssl.pp', <<~PUPPET)
        aem_curator::config_aem_ssl { 'author':
          tmp_dir               => '#{tmp_dir}',
          run_mode              => 'author',
          aem_ssl_port          => '5432',
          aem_id                => 'author',
          aem_ssl_method        => 'jetty',
          aem_keystore_password => 'overwrite-me',
          aem_keystore_path     => '/etc/ssl/aem-author/author.ks',
          cert_base_url         => 'file://#{tmp_dir}/certs',
        }
      PUPPET
      on(default, '/opt/puppetlabs/bin/puppet apply --detailed-exitcodes --tags file,archive,java_ks /tmp/config_aem_ssl.pp', acceptable_exit_codes: [0, 2])
    end

    it 'builds the AEM keystore with the cqse key and certificate' do
      result = on(default, 'keytool -list -keystore /etc/ssl/aem-author/author.ks -storepass overwrite-me -alias cqse')
      expect(result.stdout).to include('PrivateKeyEntry')
      expect(on(default, 'stat -c "%a %U %G" /etc/ssl/aem-author/author.ks').stdout.strip).to eq('640 aem-author aem-author')
    end

    it 'hands AEM a truststore that exists in the JDK' do
      expect(on(default, 'test -f /usr/java/default/lib/security/cacerts').exit_code).to eq(0)
      expect(on(default, 'keytool -list -keystore /usr/java/default/lib/security/cacerts -storepass changeit -alias cqse-0').stdout)
        .to include('trustedCertEntry')
    end
  end

  context 'aem_curator::config_aem_jmx with JDK 11' do
    before(:all) do
      on(default, 'id aem-aem || useradd aem-aem')
      apply_manifest("aem_curator::config_aem_jmx { 'aem': }", catch_failures: true)
    end

    it 'writes JMX properties that the JDK accepts' do
      expect(on(default, 'java -Dcom.sun.management.config.file=/etc/jmx.properties -version 2>&1').stdout).to match(%r{version "#{Regexp.escape(jdk11[:version].to_s)}"})
    end
  end
end
