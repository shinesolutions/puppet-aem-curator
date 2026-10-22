# frozen_string_literal: true

require 'spec_helper'

# Values: what aem-aws-stack-provisioner gives aem_curator::config_aem_tools_dispatcher on a
# Dispatcher: base_dir from ../aem-aws-stack-provisioner/data/common.yaml (common::base_dir) and
# aem_tools_env_path from manifests/publish-dispatcher.pp and author-dispatcher.pp.
describe 'aem_curator::config_aem_tools_dispatcher' do
  let(:params) do
    {
      base_dir: '/opt/shinesolutions',
      aem_tools_env_path: '$PATH:/opt/puppetlabs/puppet/bin',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }
      it {
        is_expected.to contain_file('/opt/shinesolutions/aem-tools/flush-dispatcher-cache.sh').with(
          ensure: 'present',
          mode: '0775',
          owner: 'root',
          group: 'root',
        ).with_content(%r{^PATH=\$PATH:/opt/puppetlabs/puppet/bin$})
                                                                                              .with_content(%r{^cd /opt/shinesolutions/aem-aws-stack-provisioner/$})
                                                                                              .with_content(%r{--execute "include aem_curator::action_flush_dispatcher_cache"})
      }
    end
  end
end
