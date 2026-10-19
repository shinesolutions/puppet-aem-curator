# frozen_string_literal: true

require 'spec_helper'

# Values are the ones install_aem62/63/64/65 pass through aem_instance with
# their defaults (aem_base '/opt', aem_id 'aem', status 'running')
describe 'aem_curator::aem_service' do
  let(:title) { 'aem' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with the install_aem6x values' do
        let(:params) do
          {
            ensure: 'present',
            status: 'running',
            home: '/opt/aem/aem',
            user: 'aem-aem',
            group: 'aem-aem',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/lib/systemd/system/aem-aem.service').with(
            ensure: 'present',
            owner: 'root',
            group: 'root',
            content: <<~UNIT,
              # ************************************
              # Managed by Puppet AEM Module
              # ************************************

              [Unit]
              Description=Adobe Experience Manager (aem)
              After=network.target remote-fs.target nss-lookup.target

              [Service]
              Type=forking
              PIDFile=/opt/aem/aem/crx-quickstart/conf/cq.pid
              User=aem-aem
              Group=aem-aem
              ExecStart=/opt/aem/aem/crx-quickstart/bin/start
              ExecStop=/opt/aem/aem/crx-quickstart/bin/stop
              # We want systemd to give aem some time to finish gracefully, but still want
              # it to kill aem after TimeoutStopSec if something went wrong during the
              # graceful stop. Normally, Systemd sends SIGTERM signal right after the
              # ExecStop, which would kill aem. We are sending useless SIGCONT here to give
              # aem time to finish.

              TimeoutStopSec=4min
              KillSignal=SIGCONT
              PrivateTmp=true


              [Install]
              WantedBy=multi-user.target
            UNIT
          ).that_notifies('Exec[reload_systemd_aem_aem]')
        }
        it {
          is_expected.to contain_exec('reload_systemd_aem_aem').with(
            command: '/bin/systemctl daemon-reload',
            refreshonly: true,
          ).that_notifies('Service[aem-aem]')
        }
        it {
          is_expected.to contain_service('aem-aem').with(
            ensure: 'running',
            enable: false,
            name: 'aem-aem.service',
            hasstatus: true,
            hasrestart: true,
            provider: 'systemd',
          )
        }
      end

      context 'with defaults for all parameters' do
        it { is_expected.to compile.and_raise_error(%r{Home directory must be specified}) }
      end
    end
  end
end
