# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'openssl'

# The manifests that depend on the JDK: install_java (Amazon Corretto 21, from its repo), then, with the
# real Oracle JDK 11 RPM, install_aem_java (JDK 11, the one AEM runs on), the keystore part of
# config_aem_ssl and the JMX properties of config_aem_jmx against JDK 11.
#
# The Oracle RPM needs an Oracle account and is too big to commit, so set JDK_11_RPM to the Oracle JDK 11 RPM
# file to test, any update (make acceptance-java), e.g. JDK_11_RPM=/path/to/jdk-11.0.33.0.1_linux-x64_bin.rpm;
# without it, only install_java is tested. The RPM's package name, version and install directory are read
# from the RPM itself (rpm -qp on the machine running the tests), so the tests check that the directory the
# manifest derives from the file name is the one the RPM really installs into. It's copied to the host and
# installed from file://. It's an x86_64 RPM, so the host must be x86_64.
#
# Paths are the ones packer-aem gives the classes (../packer-aem/conf/puppet/hieradata/common.yaml:
# tmp_dir /tmp/shinesolutions/packer-aem, cert_base_url file://<tmp_dir>/certs, aem_keystore_path
# /etc/ssl/aem-author/author.ks). The key and certificate stand in for the ones packer-aem's
# config::certs fetches from ACM, and are generated here.
describe 'JDK dependent manifests' do
  rpm_dir = '/tmp/shinesolutions/jdk-rpms'
  tmp_dir = '/tmp/shinesolutions/packer-aem'
  # install_java's default; the older version is the latest Corretto 21 before it, to test changing version
  corretto_version = '21.0.13.1.2'
  older_corretto_version = '21.0.13.0.11'

  # The RPM file in JDK_<major>_RPM, with what the RPM says about itself: path, file name, package name
  # (e.g. jdk-11), version (e.g. 11.0.33.0.1) and the directory its bin/java is in
  # (e.g. /usr/lib/jvm/jdk-11.0.33.0.1-oracle-x64). Empty when the variable isn't set; it fails when the
  # file isn't an Oracle JDK <major> RPM, so a wrong file can't silently test the wrong JDK.
  def self.oracle_jdk(major)
    path = ENV.fetch("JDK_#{major}_RPM", '')
    return {} if path.empty?

    package, version = `rpm -qp --qf '%{NAME} %{VERSION}' '#{path}' 2>/dev/null`.split
    raise "JDK_#{major}_RPM=#{path} isn't an Oracle JDK #{major} RPM (#{package} #{version})" unless package == "jdk-#{major}" && version&.start_with?("#{major}.")

    java = `rpm -qlp '#{path}' 2>/dev/null`.lines.map(&:strip).find { |file| file.match?(%r{^/usr/lib/jvm/[^/]+/bin/java$}) }
    { path: path, rpm: File.basename(path), package: package, version: version, java_home: java && File.dirname(java, 2) }
  end

  jdk11 = oracle_jdk(11)

  def self.java_class_manifest(klass, tmp_dir, params = {})
    params_puppet = params.map { |name, value| "#{name} => '#{value}'," }.join("\n  ")
    <<~PUPPET
      class { 'aem_curator::#{klass}':
        cert_base_url => 'file://#{tmp_dir}/certs',
        tmp_dir       => '#{tmp_dir}',
        #{params_puppet}
      }
    PUPPET
  end

  before(:all) do
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
    on(default, "mkdir -p #{tmp_dir}/certs")
    create_remote_file(default, "#{tmp_dir}/certs/aem.cert", cert.to_pem)
    create_remote_file(default, "#{tmp_dir}/certs/aem.key", key.to_pem)
  end

  # package: the JDK's package; package_version: the version rpm -q shows it with; java_home: the JDK's
  # directory; java_version: what java -version prints for it
  shared_examples 'a JDK install' do
    it 'installs the JDK package' do
      expect(on(default, "rpm -q #{package}").stdout).to start_with("#{package}-#{package_version}")
      expect(on(default, "test -f #{java_home}/lib/security/cacerts").exit_code).to eq(0)
    end

    it 'makes it the java alternative, /usr/java/default and the java on the PATH' do
      expect(on(default, 'alternatives --display java').stdout).to match(%r{link currently points to #{java_home}/bin/java})
      expect(on(default, 'readlink /usr/java/default').stdout.strip).to eq(java_home)
      # what aem_package's java -jar ... -unpack and the oak-run scripts run
      expect(on(default, 'readlink -f "$(command -v java)"').stdout.strip).to eq("#{java_home}/bin/java")
      expect(on(default, 'java -version 2>&1').stdout).to include(java_version)
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

  context 'aem_curator::install_java with Amazon Corretto 21' do
    older_manifest = java_class_manifest('install_java', tmp_dir, corretto_version: older_corretto_version)
    manifest = java_class_manifest('install_java', tmp_dir)

    before(:all) do
      # Amazon Linux 2023 locks the image to its release's repo, and the image can be older than the
      # Corretto version: move it to the latest release, like baking from an AMI that has the version
      on(default, 'dnf -y --releasever=latest upgrade system-release') if fact('os.name') == 'Amazon'

      # Install and lock an older version first, to test that dnf upgrade can't change the locked version
      # and that changing corretto_version installs the new version in its place
      apply_manifest(older_manifest, catch_failures: true)
      on(default, "dnf -y upgrade 'java-21-amazon-corretto*'")
      @locked_version = on(default, "rpm -q --qf '%{VERSION}' java-21-amazon-corretto-devel").stdout

      apply_manifest(manifest, catch_failures: true)
      @second_run = apply_manifest(manifest, catch_failures: true).stdout
    end

    let(:package) { 'java-21-amazon-corretto-devel' }
    let(:package_version) { corretto_version }
    # Amazon Linux's own package installs into an architecture-specific directory, the RPM from
    # Amazon's Corretto repo into the plain one
    let(:java_home) do
      (fact('os.name') == 'Amazon') ? "/usr/lib/jvm/java-21-amazon-corretto.#{fact('os.architecture')}" : '/usr/lib/jvm/java-21-amazon-corretto'
    end
    let(:java_version) { "Corretto-#{corretto_version}" }

    it_behaves_like 'a JDK install'

    it 'keeps the locked version through dnf upgrade' do
      expect(@locked_version).to eq(older_corretto_version) # rubocop:disable RSpec/InstanceVariable
    end

    it 'locks only the pinned version' do
      locks = on(default, 'dnf -q versionlock list').stdout.lines.map(&:strip).grep(%r{^java-21-amazon-corretto-})
      expect(locks).to include(match(%r{^java-21-amazon-corretto-devel-\d+:#{Regexp.escape(corretto_version)}-}))
      expect(locks).to all(match(%r{:#{Regexp.escape(corretto_version)}-}))
    end

    # The alternatives --set exec has no guard and runs on every apply, as before
    it 'installs, unlocks, locks and imports the certificate only when needed' do
      expect(@second_run).not_to match(%r{Package\[java-21-amazon-corretto-devel\]|Corretto|Java_ks}) # rubocop:disable RSpec/InstanceVariable
    end
  end

  context 'with the Oracle JDK 11 RPM' do
    before(:all) do
      skip 'Set JDK_11_RPM to the Oracle JDK 11 RPM file to run these' unless jdk11[:java_home]
      skip 'The Oracle JDK RPMs are x86_64 only' unless fact('os.architecture') == 'x86_64'

      on(default, "mkdir -p #{rpm_dir}")
      scp_to(default, jdk11[:path], "#{rpm_dir}/#{jdk11[:rpm]}")
    end

    context 'aem_curator::install_aem_java with Oracle JDK 11' do
      manifest = java_class_manifest('install_aem_java', tmp_dir, jdk_base_url: "file://#{rpm_dir}", jdk_filename: jdk11[:rpm])

      before(:all) do
        apply_manifest(manifest, catch_failures: true)
        @second_run = apply_manifest(manifest, catch_failures: true).stdout
      end

      let(:package) { jdk11[:package] }
      let(:package_version) { jdk11[:version] }
      let(:java_home) { jdk11[:java_home] }
      let(:java_version) { "version \"#{jdk11[:version]}\"" }

      it_behaves_like 'a JDK install'

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
end
