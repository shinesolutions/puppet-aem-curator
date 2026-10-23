# frozen_string_literal: true

require 'spec_helper'

# Values: what packer-aem (the AMI bake) gives aem_curator::install_dispatcher, i.e.
# ../packer-aem/templates/ansible/hieradata.j2 rendered with
# conf/ansible/inventory/group_vars/defaults.yaml (aem.dispatcher.*, aws.rhel7.devicemap_data_b),
# plus conf/puppet/hieradata/common.yaml and aws.yaml (tmp_dir /tmp/shinesolutions/packer-aem).
describe 'aem_curator::install_dispatcher' do
  let(:params) do
    {
      apache_module_base_url: 'http://download.macromedia.com/dispatcher/download',
      apache_module_tarball: 'dispatcher-apache2.4-linux-x86_64-ssl1.0-4.3.3.tar.gz',
      apache_module_filename: 'dispatcher-apache2.4-4.3.3.so',
      data_volume_device: '/dev/xvdb',
      tmp_dir: '/tmp/shinesolutions/packer-aem',
      cert_base_url: 'file:///tmp/shinesolutions/packer-aem/certs',
      cert_filename: '/etc/ssl/aem.unified-dispatcher.cert',
      data_volume_mount_point: '/mnt/ebs1',
      setup_data_volume: true,
      docroot_dir: '/var/www/html',
      post_stop_sleep_secs: 300,
      apache_user: 'apache',
      apache_group: 'apache',
      apache_module_temp_dir: '/tmp/shinesolutions/packer-aem',
      apache_http_port: '80',
      apache_https_port: '443',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      # adobeinc/dispatcher 1.0.0 reads the legacy fact $::osfamily, which OpenVox 9 only
      # provides with include_legacy_facts = true; the bake has to run puppet with it
      let(:facts) { os_facts.merge(osfamily: os_facts[:os]['family']) }

      it { is_expected.to compile.with_all_deps }

      it 'prepares the data volume and moves the docroot onto it' do
        is_expected.to contain_exec('dispatcher: Prepare device for the AEM Data Volume').with_command('mkfs -t ext4 /dev/xvdb')
        is_expected.to contain_mount('/mnt/ebs1').with(ensure: 'mounted', device: '/dev/xvdb', fstype: 'ext4', options: 'nofail,defaults,noatime')
        is_expected.to contain_exec('mv /var/www/html /mnt/ebs1/dispatcher').that_requires(['Package[httpd]', 'Mount[/mnt/ebs1]'])
        is_expected.to contain_exec('dispatcher: Fix data volume mount permissions').with_command('chown -R apache:apache /mnt/ebs1')
        is_expected.to contain_file('/var/www/html').with(ensure: 'link', target: '/mnt/ebs1/dispatcher', owner: 'apache', group: 'apache')
      end

      it 'builds the unified certificate from the key and the cert' do
        is_expected.to contain_concat('/etc/ssl/aem.unified-dispatcher.cert').with(mode: '0600', order: 'numeric')
        is_expected.to contain_archive('/tmp/shinesolutions/packer-aem/dispatcher/aem.key').with_source('file:///tmp/shinesolutions/packer-aem/certs/aem.key')
        is_expected.to contain_archive('/tmp/shinesolutions/packer-aem/dispatcher/aem.cert').with_source('file:///tmp/shinesolutions/packer-aem/certs/aem.cert')
        is_expected.to contain_exec('Convert /tmp/shinesolutions/packer-aem/dispatcher/aem.key to PEM')
          .with_creates('/tmp/shinesolutions/packer-aem/dispatcher/aem.key.pem')
          .that_requires('Archive[/tmp/shinesolutions/packer-aem/dispatcher/aem.key]')
        is_expected.to contain_concat__fragment('/etc/ssl/aem.unified-dispatcher.cert:key')
          .with(source: '/tmp/shinesolutions/packer-aem/dispatcher/aem.key.pem', order: 0)
          .that_requires('Exec[Convert /tmp/shinesolutions/packer-aem/dispatcher/aem.key to PEM]')
        is_expected.to contain_concat__fragment('/etc/ssl/aem.unified-dispatcher.cert:cert').with(source: '/tmp/shinesolutions/packer-aem/dispatcher/aem.cert', order: 1)
      end

      it 'installs Apache with the SSL and proxy modules and the Dispatcher module' do
        is_expected.to contain_class('apache').with_default_vhost(true)
        is_expected.to contain_apache__listen('80')
        is_expected.to contain_apache__listen('443')
        ['ssl', 'headers', 'proxy', 'proxy_http', 'proxy_connect'].each { |mod| is_expected.to contain_class("apache::mod::#{mod}") }
        is_expected.to contain_archive('dispatcher-apache2.4-linux-x86_64-ssl1.0-4.3.3.tar.gz').with(
          source: 'http://download.macromedia.com/dispatcher/download/dispatcher-apache2.4-linux-x86_64-ssl1.0-4.3.3.tar.gz',
          path: '/tmp/shinesolutions/packer-aem/dispatcher-apache2.4-linux-x86_64-ssl1.0-4.3.3.tar.gz',
          extract: true,
          extract_path: '/tmp/shinesolutions/packer-aem',
        ).that_comes_before('Class[dispatcher]')
        is_expected.to contain_class('dispatcher').with_module_file('/tmp/shinesolutions/packer-aem/dispatcher-apache2.4-4.3.3.so')
      end

      it 'waits until the Dispatcher listens on the http and https ports' do
        is_expected.to contain_tcp_conn_validator('Ensure dispatcher is listening on http port 80').with(host: 'localhost', port: '80')
                                                                                                   .that_requires(['Class[Apache::Service]', 'Class[dispatcher]'])
        is_expected.to contain_tcp_conn_validator('Ensure dispatcher is listening on https port 443').with(host: 'localhost', port: '443')
                                                                                                     .that_requires('Tcp_conn_validator[Ensure dispatcher is listening on http port 80]')
      end
    end
  end
end
