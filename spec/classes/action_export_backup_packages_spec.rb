# frozen_string_literal: true

require 'spec_helper'

# Packages follow the export-backups descriptor format (aem-helloworld-config's
# export-backups-descriptor.json), where filter is an array of hashes. aem_package
# hands filter to ruby_aem, which sends it to AEM as is, so it must be a JSON string.
describe 'aem_curator::action_export_backup_packages' do
  let(:params) do
    {
      tmp_dir: '/tmp/shinesolutions/aem-aws-stack-provisioner',
      aem_id: 'author',
      aem_username: 'exporter',
      aem_password: 'password',
      backup_path: '2026/11',
      package_version: '20261109-author-primary',
      stack_prefix: 'test-stack',
      data_bucket_name: 'test-bucket',
      retries_max_tries: 60,
      retries_base_sleep_seconds: 5,
      retries_max_sleep_seconds: 5,
      packages: [
        {
          'group' => 'shinesolutions',
          'name' => 'aem-helloworld',
          'filter' => [
            { 'root' => '/apps/helloworld', 'rules' => [] },
            { 'root' => '/content/helloworld', 'rules' => [{ 'modifier' => 'exclude', 'pattern' => '.*.\d*\.\d*\.(png|jpeg|gif)' }] },
          ],
        },
        {
          'group' => 'shinesolutions',
          'name' => 'aem-string-filter',
          'aem_id' => 'publish',
          'filter' => '[{"root":"/etc/designs/helloworld","rules":[]}]',
        },
      ],
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it 'converts an array filter to JSON' do
        is_expected.to contain_aem_package('author: Create and download backup file for package: aem-helloworld').with(
          ensure: 'archived',
          group: 'shinesolutions',
          filter: '[{"root":"/apps/helloworld","rules":[]},{"root":"/content/helloworld","rules":[{"modifier":"exclude","pattern":".*.\\\\d*\\\\.\\\\d*\\\\.(png|jpeg|gif)"}]}]',
        )
      end

      it 'passes a JSON string filter through unchanged' do
        is_expected.to contain_aem_package('publish: Create and download backup file for package: aem-string-filter').with(
          filter: '[{"root":"/etc/designs/helloworld","rules":[]}]',
        )
      end
    end
  end
end
