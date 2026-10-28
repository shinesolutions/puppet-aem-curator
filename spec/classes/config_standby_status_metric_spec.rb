# frozen_string_literal: true

require 'spec_helper'

describe 'aem_curator::config_standby_status_metric' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          stack_prefix: 'stack',
          component: 'author-standby',
          ec2_id: 'i-0123456789abcdef0',
          aws_region: 'ap-southeast-2',
        }
      end
      let(:script) { '/opt/shinesolutions/standby-status/publish-standby-status-metric.sh' }

      context 'with defaults for the optional parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/opt/shinesolutions/standby-status/StandbyStatus.java') }

        it {
          is_expected.to contain_file(script)
            .with_mode('0700')
            .with_content(%r{rmi://localhost:5982/jmxrmi})
            .with_content(%r{--namespace 'collectd'})
            .with_content(%r{--metric-name 'GenericJMX\.delay\.seconds_since_last_success'})
            .with_content(%r{--dimensions 'FixedDimension=stack-author-standby,Host=i-0123456789abcdef0,PluginInstance=standby-status'})
            .without_content(%r{trustStore|https_proxy|JMX_USER})
        }

        it {
          is_expected.to contain_systemd__timer('publish-standby-status-metric.timer')
            .with_enable(true)
            .with_active(true)
            .with_service_content(%r{ExecStart=#{script}})
            .with_timer_content(%r{OnCalendar=minutely})
        }
      end

      context 'with SSL, JMX authentication and a proxy' do
        let(:params) do
          super().merge(
            jmxremote_port: '5983',
            jmxremote_keystore_path: '/etc/ssl/aem-author/jmx.ks',
            jmx_user: 'monitorOnly',
            jmx_user_password: 'secret',
            proxy_enabled: true,
            proxy_host: 'proxy.example.com',
            proxy_port: '3128',
            proxy_noproxy: ['localhost', '169.254.169.254'],
          )
        end

        it {
          is_expected.to contain_file(script)
            .with_content(%r{rmi://localhost:5983/jmxrmi})
            .with_content(%r{-Djavax\.net\.ssl\.trustStore='/etc/ssl/aem-author/jmx\.ks' -Djavax\.net\.ssl\.trustStorePassword='changeit'})
            .with_content(%r{export JMX_USER='monitorOnly'})
            .with_content(%r{export https_proxy='http://proxy\.example\.com:3128'})
            .with_content(%r{export no_proxy='localhost,169\.254\.169\.254'})
        }
      end
    end
  end
end
