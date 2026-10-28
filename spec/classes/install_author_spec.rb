# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/install_aem_role'

# Values: what packer-aem (the AMI bake) gives aem_curator::install_author, i.e.
# ../packer-aem/templates/ansible/hieradata.j2 rendered with
# conf/ansible/inventory/group_vars/defaults.yaml (aem.profile aem65_sp10, aem.ssl_method jetty,
# aem.author.*, library.aem_healthcheck_*, aws.rhel7.devicemap_data_b) plus
# conf/puppet/hieradata/common.yaml and aws.yaml (tmp_dir /tmp/shinesolutions/packer-aem).
# aem.artifacts_base is mandatory and ships as overwrite-me, so it is the example from
# ../packer-aem/docs/configuration.md, s3://somebucket/artifacts/. The keystore and truststore
# passwords are SSM lookups of the overwrite-me parameter, so the placeholder stands in.
describe 'aem_curator::install_author' do
  let(:params) do
    {
      aem_profile: 'aem65_sp10',
      aem_keystore_password: 'overwrite-me',
      aem_truststore_password: 'overwrite-me',
      aem_ssl_method: 'jetty',
      aem_artifacts_base: 's3://somebucket/artifacts/',
      aem_jvm_mem_opts: '-Xss4m -Xms4096m -Xmx8192m',
      aem_jvm_opts: [
        '-XX:+PrintGCDetails',
        '-XX:+PrintGCTimeStamps',
        '-XX:+PrintGCDateStamps',
        '-XX:+PrintTenuringDistribution',
        '-XX:+PrintGCApplicationStoppedTime',
        '-XX:+HeapDumpOnOutOfMemoryError',
      ],
      run_modes: [],
      data_volume_device: '/dev/xvdb',
      aem_healthcheck_version: '2.0.0',
      aem_healthcheck_source: 'https://repo.maven.apache.org/maven2/com/shinesolutions/aem-healthcheck-content/2.0.0/aem-healthcheck-content-2.0.0.zip',
      tmp_dir: '/tmp/shinesolutions/packer-aem',
      aem_host: 'localhost',
      cert_base_url: 'file:///tmp/shinesolutions/packer-aem/certs',
      aem_base: '/opt',
      aem_sample_content: false,
      setup_repository_volume: true,
      data_volume_mount_point: '/mnt/ebs1',
      post_stop_sleep_secs: 300,
      aem_license_base: '/tmp/shinesolutions/packer-aem/license',
      aem_keystore_path: '/etc/ssl/aem-author/author.ks',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      # aem_id, aem_port and aem_ssl_port are install_author's defaults
      it_behaves_like 'an AEM install from packer-aem', 'author', '4502', '5432'
    end
  end
end
