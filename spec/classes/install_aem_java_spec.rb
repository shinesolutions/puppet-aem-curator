# frozen_string_literal: true

require 'spec_helper'

# Values: what packer-aem (the AMI bake) gives aem_curator::install_aem_java, i.e.
# ../packer-aem/templates/ansible/hieradata.j2 rendered with
# conf/ansible/inventory/group_vars/defaults.yaml (aem.jdk.base_url and aem.jdk.filename) plus
# conf/puppet/hieradata/common.yaml (tmp_dir, cert_base_url). aem.jdk.base_url ships as the
# placeholder overwrite-me.
describe 'aem_curator::install_aem_java' do
  let(:packer_aem_params) do
    {
      cert_base_url: 'file:///tmp/shinesolutions/packer-aem/certs',
      tmp_dir: '/tmp/shinesolutions/packer-aem',
      jdk_base_url: 'overwrite-me',
      jdk_filename: 'jdk-8u221-linux-x64.rpm',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with packer-aem as shipped' do
        let(:params) { packer_aem_params }

        # TODO: aem.jdk.base_url is mandatory in packer-aem and ships as overwrite-me, which
        # puppet/archive (used by java::download) rejects as a source URL; see Needs decision
        it { is_expected.to compile.and_raise_error(%r{invalid source url: overwrite-me/jdk-8u221-linux-x64.rpm}) }
      end
    end
  end
end
