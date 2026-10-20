# frozen_string_literal: true

require 'spec_helper'

# Values: what packer-aem (the AMI bake) gives aem_curator::install_java, i.e.
# ../packer-aem/templates/ansible/hieradata.j2 rendered with
# conf/ansible/inventory/group_vars/defaults.yaml (java.base_url and java.filename) plus
# conf/puppet/hieradata/common.yaml (tmp_dir, cert_base_url). java.base_url ships as the
# placeholder overwrite-me.
describe 'aem_curator::install_java' do
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

        # TODO: install_java requires File[<tmp_dir>], which neither it nor packer-aem declares,
        # so the catalog fails before java.base_url (overwrite-me) is even used; see the TODO in
        # manifests/install_java.pp and Needs decision
        it { is_expected.to compile.and_raise_error(%r{Could not find resource 'File\[/tmp/shinesolutions/packer-aem\]' in parameter 'require'}) }
      end
    end
  end
end
