# frozen_string_literal: true

# Shared catalog checks for aem_curator::install_author and install_publish with the values
# packer-aem gives them (see the header comment in each spec): AEM profile aem65_sp10 installed
# into /opt/aem/<aem_id> from aem.artifacts_base s3://somebucket/artifacts/, jetty SSL, and the
# repository moved onto the /dev/xvdb data volume mounted at /mnt/ebs1.
RSpec.shared_examples 'an AEM install from packer-aem' do |aem_id, port, ssl_port|
  home = "/opt/aem/#{aem_id}"
  tmp = '/tmp/shinesolutions/packer-aem'
  jvm_opts = '-XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -XX:+PrintTenuringDistribution ' \
             '-XX:+PrintGCApplicationStoppedTime -XX:+HeapDumpOnOutOfMemoryError'

  it { is_expected.to compile.with_all_deps }

  it 'downloads the license and the quickstart jar into the AEM home' do
    is_expected.to contain_file(home).with(ensure: 'directory', mode: '0775', owner: "aem-#{aem_id}", group: "aem-#{aem_id}")
    is_expected.to contain_archive("#{home}/license.properties")
      .with(source: "#{tmp}/license/license-6.5.properties", cleanup: false)
      .that_requires("File[#{home}]")
      .that_comes_before("File[#{home}/license.properties]")
    is_expected.to contain_file("#{home}/license.properties").with(ensure: 'file', mode: '0440', owner: "aem-#{aem_id}", group: "aem-#{aem_id}")
    # The trailing slash of the documented artifacts_base example gives a double slash
    is_expected.to contain_archive("#{home}/aem-#{aem_id}-#{port}.jar")
      .with(source: 's3://somebucket/artifacts//AEM_6.5_Quickstart.jar', cleanup: false)
      .that_comes_before("File[#{home}/aem-#{aem_id}-#{port}.jar]")
    is_expected.to contain_file("#{home}/aem-#{aem_id}-#{port}.jar").with(ensure: 'file', mode: '0775', owner: "aem-#{aem_id}", group: "aem-#{aem_id}")
  end

  it 'downloads the AEM Health Check package into the crx-quickstart install folder' do
    is_expected.to contain_archive("#{tmp}/#{aem_id}/aem-healthcheck-content-1.3.3.zip")
      .with_source('https://repo.maven.apache.org/maven2/com/shinesolutions/aem-healthcheck-content/1.3.3/aem-healthcheck-content-1.3.3.zip')
      .that_comes_before("Aem_resources::Crx_package_file[#{aem_id}: aem-healthcheck]")
    is_expected.to contain_aem_resources__crx_package_file("#{aem_id}: aem-healthcheck").with(
      ensure: 'present',
      home: home,
      source: "#{tmp}/#{aem_id}/aem-healthcheck-content-1.3.3.zip",
      user: "aem-#{aem_id}",
      group: "aem-#{aem_id}",
    )
    is_expected.to contain_file("#{home}/crx-quickstart/install/aem-healthcheck-content-1.3.3.zip").with(mode: '0664', owner: "aem-#{aem_id}")
  end

  it 'declares the AEM instance with the packer-aem JVM and run mode settings' do
    is_expected.to contain_aem_curator__aem_instance(aem_id).with(
      source: "#{home}/aem-#{aem_id}-#{port}.jar",
      home: home,
      user: "aem-#{aem_id}",
      group: "aem-#{aem_id}",
      type: aem_id,
      runmodes: [],
      port: port,
      sample_content: false,
      jvm_mem_opts: '-Xss4m -Xms4096m -Xmx8192m',
      jvm_opts: jvm_opts,
      status: 'running',
    ).that_comes_before("Exec[#{aem_id}: Manual delay to let AEM become ready]")
    is_expected.to contain_group("aem-#{aem_id}").that_comes_before("User[aem-#{aem_id}]")
    is_expected.to contain_user("aem-#{aem_id}").with_gid("aem-#{aem_id}").that_comes_before("Aem_curator::Aem_package[#{aem_id}]")
    is_expected.to contain_exec("#{aem_id} unpack").with(
      command: "java -jar #{home}/aem-#{aem_id}-#{port}.jar -b #{home} -unpack",
      creates: "#{home}/crx-quickstart",
      user: "aem-#{aem_id}",
    )
    is_expected.to contain_aem_curator__aem_package(aem_id).that_comes_before("Aem_resources::Instance_config[#{aem_id}]")
    is_expected.to contain_file("#{home}/crx-quickstart/bin/start-env")
      .with_content(%r{^TYPE='#{aem_id}'$})
      .with_content(%r{^PORT=#{port}$})
      .with_content(%r{^RUNMODES=''$})
      .with_content(%r{^SAMPLE_CONTENT='nosamplecontent'$})
      .with_content(%r{^JVM_MEM_OPTS='-Xss4m -Xms4096m -Xmx8192m'$})
      .with_content(%r{^JVM_OPTS='#{Regexp.escape(jvm_opts)}'$})
    is_expected.to contain_aem_resources__instance_config(aem_id).that_comes_before("Aem_curator_installer[#{aem_id}]")
    is_expected.to contain_aem_curator_installer(aem_id).with(ensure: 'present', home: home, snooze: 10, timeout: 600)
      .that_notifies("Aem_curator::Aem_service[#{aem_id}]")
  end

  it 'runs AEM as the systemd service aem-<aem_id>, not enabled at boot' do
    is_expected.to contain_aem_curator__aem_service(aem_id).with(status: 'running', home: home)
    is_expected.to contain_file("/lib/systemd/system/aem-#{aem_id}.service")
      .with_content(%r{^ExecStart=#{home}/crx-quickstart/bin/start$})
      .with_content(%r{^User=aem-#{aem_id}$})
      .with_content(%r{^TimeoutStopSec=4min$})
      .that_notifies("Exec[reload_systemd_aem_#{aem_id}]")
    is_expected.to contain_service("aem-#{aem_id}").with(ensure: 'running', enable: false, provider: 'systemd')
  end

  it 'waits for AEM and installs the aem65_sp10 service pack' do
    is_expected.to contain_aem_aem("#{aem_id}: Wait until login page is ready").with(ensure: 'login_page_is_ready', retries_max_tries: 120)
      .that_comes_before("Aem_aem[#{aem_id}: Wait until aem health check is ok]")
    is_expected.to contain_archive("#{tmp}/#{aem_id}/aem-service-pkg-6.5.10.zip").with_source('s3://somebucket/artifacts//aem-service-pkg-6.5.10.zip')
    is_expected.to contain_aem_package("#{aem_id}: Install aem-service-pkg").with(
      ensure: 'present',
      group: 'adobe/cq650/servicepack',
      version: '6.5.10',
      path: "#{tmp}/#{aem_id}",
    )
  end

  it 'writes the Puppet AEM Resources config for localhost' do
    is_expected.to contain_file("/etc/puppetlabs/puppet//#{aem_id}.yaml")
      .with_content(%r{^:host: 'localhost'$})
      .with_content(%r{^:port: #{port}$})
  end

  it 'enables jetty SSL with the AEM keystore' do
    is_expected.to contain_archive("#{tmp}/#{aem_id}/aem.key").with_source('file:///tmp/shinesolutions/packer-aem/certs/aem.key')
    is_expected.to contain_archive("#{tmp}/#{aem_id}/aem.cert").with_source('file:///tmp/shinesolutions/packer-aem/certs/aem.cert')
    is_expected.to contain_java_ks("cqse:/etc/ssl/aem-#{aem_id}/#{aem_id}.ks").with(ensure: 'latest', target: "/etc/ssl/aem-#{aem_id}/#{aem_id}.ks")
    is_expected.to contain_file("/etc/ssl/aem-#{aem_id}/#{aem_id}.ks").with(mode: '0640', owner: "aem-#{aem_id}")
    is_expected.to contain_aem_resources__author_publish_enable_ssl("#{aem_id}: Enable SSL").with(ssl_method: 'jetty', port: ssl_port)
  end

  it 'moves the repository onto the data volume after stopping AEM' do
    is_expected.to contain_exec("#{aem_id}: Prepare device for the AEM repository").with_command('mkfs -t ext4 /dev/xvdb')
      .that_comes_before('File[/mnt/ebs1]')
    is_expected.to contain_mount('/mnt/ebs1').with(ensure: 'mounted', device: '/dev/xvdb', fstype: 'ext4')
    is_expected.to contain_exec("#{aem_id}: Wait post AEM installation").with_command('sleep 300')
      .that_requires("Aem_curator::Config_aem[#{aem_id}: Configure AEM]")
      .that_comes_before("Exec[systemctl stop aem-#{aem_id}]")
    is_expected.to contain_exec("systemctl stop aem-#{aem_id}").that_requires('Mount[/mnt/ebs1]')
      .that_comes_before("Exec[#{aem_id}: Wait post AEM stop]")
    is_expected.to contain_exec("#{aem_id}: Ensure AEM resource is stopped")
      .with_command("/opt/puppetlabs/bin/puppet resource service aem-#{aem_id} ensure=stopped")
      .that_comes_before("Exec[mv #{home} /mnt/ebs1/#{aem_id}]")
    is_expected.to contain_exec("#{aem_id}: Set link from /mnt/ebs1/#{aem_id} to #{home}").with_command("ln -s /mnt/ebs1/#{aem_id} #{home}")
      .that_comes_before("Exec[#{aem_id}: Fix repository mount permissions]")
    is_expected.to contain_exec("#{aem_id}: Fix repository mount permissions").with_command("chown -R aem-#{aem_id}:aem-#{aem_id} /mnt/ebs1")
  end
end
