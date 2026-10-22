# frozen_string_literal: true

require 'spec_helper'

# Values are the ones install_aem62/63/64/65 pass with their defaults
# (aem_base '/opt', aem_id 'aem') and install_author's aem_port '4502' and run_modes []
describe 'aem_curator::aem_instance' do
  let(:title) { 'aem' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with the install_aem6x values' do
        let(:params) do
          {
            source: '/opt/aem/aem/aem-aem-4502.jar',
            home: '/opt/aem/aem',
            user: 'aem-aem',
            group: 'aem-aem',
            type: :undef,
            runmodes: [],
            port: '4502',
            debug_port: :undef,
            sample_content: false,
            jvm_mem_opts: '-Xss4m -Xmx8192m',
            jvm_opts: '-XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps ' \
                      '-XX:+PrintTenuringDistribution -XX:+PrintGCApplicationStoppedTime -XX:+HeapDumpOnOutOfMemoryError',
            osgi_configs: :undef,
            status: 'running',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_anchor('aem::aem::begin').that_comes_before('Aem_curator::Aem_package[aem]') }
        it { is_expected.to contain_group('aem-aem').with_ensure('present').that_comes_before('User[aem-aem]') }
        it { is_expected.to contain_user('aem-aem').with(ensure: 'present', gid: 'aem-aem').that_comes_before('Aem_curator::Aem_package[aem]') }
        it {
          is_expected.to contain_aem_curator__aem_package('aem').with(
            ensure: 'present',
            group: 'aem-aem',
            home: '/opt/aem/aem',
            manage_home: true,
            source: '/opt/aem/aem/aem-aem-4502.jar',
            user: 'aem-aem',
          ).that_comes_before('Aem_resources::Instance_config[aem]')
        }
        it {
          is_expected.to contain_aem_resources__instance_config('aem').with(
            context_root: nil,
            debug_port: nil,
            group: 'aem-aem',
            home: '/opt/aem/aem',
            jvm_mem_opts: '-Xss4m -Xmx8192m',
            jvm_opts: '-XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps ' \
                      '-XX:+PrintTenuringDistribution -XX:+PrintGCApplicationStoppedTime -XX:+HeapDumpOnOutOfMemoryError',
            osgi_configs: nil,
            crx_packages: nil,
            port: '4502',
            runmodes: [],
            sample_content: false,
            type: 'author',
            user: 'aem-aem',
          ).that_comes_before('Aem_curator_installer[aem]').that_notifies('Aem_curator::Aem_service[aem]')
        }
        it {
          is_expected.to contain_aem_curator_installer('aem').with(
            ensure: 'present',
            home: '/opt/aem/aem',
            snooze: 10,
            timeout: 600,
          ).that_notifies('Aem_curator::Aem_service[aem]')
        }
        it {
          is_expected.to contain_aem_curator__aem_service('aem').with(
            ensure: 'present',
            status: 'running',
            home: '/opt/aem/aem',
            user: 'aem-aem',
            group: 'aem-aem',
          )
        }
        it { is_expected.to contain_service('aem-aem').with(ensure: 'running', enable: false) }
        it { is_expected.to contain_file('/lib/systemd/system/aem-aem.service').with_content(%r{^TimeoutStopSec=4min$}) }
        it { is_expected.to contain_file('/opt/aem/aem/crx-quickstart/bin/start-env') }
      end
    end
  end
end
