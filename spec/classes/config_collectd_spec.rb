# frozen_string_literal: true

require 'spec_helper'

describe 'aem_curator::config_collectd' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          proxy_protocol: 'http',
          proxy_enabled: false,
          proxy_host: 'proxy.example.com',
          proxy_port: '3128',
          component: 'author-standby',
          aem_instances: [
            {
              'aem_id' => 'author',
              'jmxremote_port' => '5982',
              'instance_prefixes' => ['standby-status'],
            },
          ],
          collectd_prefix: 'stack-author-standby',
          ec2_id: 'i-0123456789abcdef0',
        }
      end

      context 'with collectd-cloudwatch' do
        let(:params) { super().merge(collectd_cloudwatch: true) }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_collectd__plugin__genericjmx__mbean('standby-status') }
        it { is_expected.to contain_file_line('seconds_since_last_success standby status') }
        it { is_expected.to contain_file_line('Set Hostname for CW').with_line('host = "i-0123456789abcdef0"') }
        it { is_expected.to contain_file_line('Push constant dimension value').with_line('constant_dimension_value = "stack-author-standby"') }
        it { is_expected.not_to contain_collectd__plugin__filter__chain('PostChain') }
      end

      context 'without collectd-cloudwatch, when collectd sends to the CloudWatch agent' do
        let(:params) { super().merge(collectd_cloudwatch: false) }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_collectd__plugin__genericjmx__mbean('standby-status') }
        it { is_expected.not_to contain_file_line('seconds_since_last_success standby status') }
        it { is_expected.not_to contain_file_line('Set Hostname for CW') }
        it { is_expected.not_to contain_file_line('Push constant value to CW as a metric') }
        it { is_expected.not_to contain_file_line('Push constant dimension value') }
        it { is_expected.to contain_collectd__plugin__filter__chain('PostChain').with_target('stop') }
        it {
          is_expected.to contain_collectd__plugin__filter__match('standby-status').with(
            chain: 'PostChain',
            rule: 'standby-status',
            plugin: 'regex',
            options: { 'Plugin' => '^GenericJMX$', 'PluginInstance' => '^standby-status$' },
          )
        }
        it {
          is_expected.to contain_collectd__plugin__filter__target('standby-status-network').with(
            chain: 'PostChain',
            rule: 'standby-status',
            plugin: 'write',
            options: { 'Plugin' => 'network' },
          )
        }
      end

      context 'with a JMX trust store' do
        let(:params) do
          super().merge(
            collectd_cloudwatch: false,
            jmx_truststore_path: '/etc/ssl/aem-author/jmx.ks',
          )
        end

        it {
          is_expected.to contain_class('collectd::plugin::genericjmx').with_jvmarg(
            [
              '-Djdk.rmi.ssl.client.enableEndpointIdentification=false',
              '-Djavax.net.ssl.trustStore=/etc/ssl/aem-author/jmx.ks',
              '-Djavax.net.ssl.trustStorePassword=changeit',
            ],
          )
        }
      end

      context 'without a JMX trust store' do
        let(:params) { super().merge(collectd_cloudwatch: false) }

        it {
          is_expected.to contain_class('collectd::plugin::genericjmx').with_jvmarg(
            ['-Djdk.rmi.ssl.client.enableEndpointIdentification=false'],
          )
        }
      end
    end
  end
end
