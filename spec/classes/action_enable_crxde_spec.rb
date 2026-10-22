# frozen_string_literal: true

require 'spec_helper'

# Values: aem_instances from ../aem-aws-stack-provisioner/data/author-publish-dispatcher.yaml
# (aem_curator::action_enable_crxde::aem_instances). aem_username and aem_password are the
# FACTER_ values the enable-crxde.sh aem-tools script sets at run time, so they are left unset (undef).
describe 'aem_curator::action_enable_crxde' do
  let(:params) do
    {
      aem_instances: [
        { 'run_mode' => 'author', 'aem_id' => 'author' },
        { 'run_mode' => 'publish', 'aem_id' => 'publish' },
      ],
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      ['author', 'publish'].each do |aem_id|
        it {
          is_expected.to contain_aem_resources__enable_crxde("#{aem_id}: Enable CRXDE").with(
            run_mode: aem_id,
            aem_id: aem_id,
            aem_username: nil,
            aem_password: nil,
          )
        }
      end
    end
  end
end
