# frozen_string_literal: true

require 'spec_helper'

describe 'aem_curator::upgrade_repo_migration' do
  let(:title) { 'aem' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with defaults for all parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/tmp').with_ensure('directory').that_comes_before('Service[aem-aem]') }
        it { is_expected.to contain_file('/tmp/aem').with(ensure: 'directory', mode: '0700') }
        it { is_expected.to contain_service('aem-aem').with_ensure('stopped') }
        it { is_expected.to contain_exec('aem: Ensure AEM resource is stopped').with_command('/opt/puppetlabs/bin/puppet resource service aem-aem ensure=stopped') }
        it { is_expected.not_to contain_archive('/opt/aem/aem/crx-quickstart/opt/extensions/crx2oak.jar') }
        it {
          is_expected.to contain_exec('aem: Executing repository migration').with(
            command: 'java -Xmx4096m -jar /opt/aem/aem/aem-aem-4502.jar -v -x crx2oak -xargs -- --load-profile segment-no-ds',
            cwd: '/opt/aem/aem',
          ).that_requires('Exec[aem: Ensure AEM resource is stopped]')
        }
        it { is_expected.to contain_exec('aem: Fix /opt/aem/aem/crx-quickstart/repository/ permissions').with_command('chown -R aem-aem:aem-aem /opt/aem/aem/crx-quickstart/repository/') }
        it { is_expected.to contain_exec('aem: Delete temp directory /tmp/aem').with_command('rm -fr /tmp/aem') }
      end
    end
  end
end
