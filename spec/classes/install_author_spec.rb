# frozen_string_literal: true

require 'spec_helper'

# Values: what packer-aem (the AMI bake) gives aem_curator::install_author, i.e.
# ../packer-aem/templates/ansible/hieradata.j2 rendered with
# conf/ansible/inventory/group_vars/defaults.yaml (aem.profile aem65_sp10, aem.ssl_method jetty,
# aem.author.*, library.aem_healthcheck_*, aws.rhel7.devicemap_data_b) plus
# conf/puppet/hieradata/common.yaml and aws.yaml (tmp_dir /tmp/shinesolutions/packer-aem).
# aem.artifacts_base and the keystore/truststore password parameters ship as the placeholder
# overwrite-me; the passwords are SSM lookups of that parameter, so the placeholder stands in.
describe 'aem_curator::install_author' do
  let(:packer_aem_params) do
    {
      aem_profile: 'aem65_sp10',
      aem_keystore_password: 'overwrite-me',
      aem_truststore_password: 'overwrite-me',
      aem_ssl_method: 'jetty',
      aem_artifacts_base: 'overwrite-me',
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
      aem_healthcheck_version: '1.3.3',
      aem_healthcheck_source: 'https://repo.maven.apache.org/maven2/com/shinesolutions/aem-healthcheck-content/1.3.3/aem-healthcheck-content-1.3.3.zip',
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

      context 'with packer-aem as shipped' do
        let(:params) { packer_aem_params }

        # TODO: aem.artifacts_base is mandatory in packer-aem and ships as overwrite-me, which
        # puppet/archive rejects as a source URL; see Needs decision on the value to test with
        it { is_expected.to compile.and_raise_error(%r{invalid source url: overwrite-me/AEM_6.5_Quickstart.jar}) }
      end
    end
  end
end
