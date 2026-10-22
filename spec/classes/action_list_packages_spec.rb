# frozen_string_literal: true

require 'spec_helper'

# Values: aem_instances from ../aem-aws-stack-provisioner/data/author-publish-dispatcher.yaml
# (aem_curator::action_list_packages::aem_instances). aem_username and aem_password are the
# FACTER_ values the list-packages.sh aem-tools script sets at run time, so they are left unset.
describe 'aem_curator::action_list_packages' do
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
          is_expected.to contain_aem_aem("#{aem_id}: Wait until CRX Package Manager is ready before listing packages by groups").with(
            ensure: 'aem_package_manager_is_ready',
            aem_id: aem_id,
            retries_max_tries: 60,
            retries_base_sleep_seconds: 5,
            retries_max_sleep_seconds: 5,
          ).that_comes_before("Aem_aem[#{aem_id}: List packages by groups]")
        }
        it {
          is_expected.to contain_aem_aem("#{aem_id}: List packages by groups").with(
            ensure: 'packages_listed',
            package_groups: [],
            run_mode: aem_id,
            aem_id: aem_id,
          )
        }
      end
    end
  end
end
