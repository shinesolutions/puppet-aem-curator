# frozen_string_literal: true

require 'spec_helper'

# Values are the ones install_aem62/63/64/65 pass through aem_instance with
# their defaults (aem_base '/opt', aem_id 'aem') and install_author's aem_port '4502'
describe 'aem_curator::aem_package' do
  let(:title) { 'aem' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with the install_aem6x values' do
        let(:params) do
          {
            ensure: 'present',
            group: 'aem-aem',
            home: '/opt/aem/aem',
            manage_home: true,
            source: '/opt/aem/aem/aem-aem-4502.jar',
            user: 'aem-aem',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/opt/aem/aem').with(
            ensure: 'directory',
            mode: '0775',
            owner: 'aem-aem',
            group: 'aem-aem',
          ).that_comes_before('Exec[aem unpack]')
        }
        it {
          is_expected.to contain_exec('aem unpack').with(
            command: 'java -jar /opt/aem/aem/aem-aem-4502.jar -b /opt/aem/aem -unpack',
            creates: '/opt/aem/aem/crx-quickstart',
            onlyif: ['which java', 'test -f /opt/aem/aem/aem-aem-4502.jar'],
            path: ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
            user: 'aem-aem',
            group: 'aem-aem',
          )
        }
      end
    end
  end
end
