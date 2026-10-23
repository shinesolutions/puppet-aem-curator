# frozen_string_literal: true

require 'spec_helper'

describe 'aem_curator::config_aem_jmx' do
  let(:title) { 'aem' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with defaults for all parameters' do
        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/etc/jmx.properties').with(
            mode: '0400',
            owner: 'aem-aem',
            group: 'aem-aem',
            content: "\ncom.sun.management.jmxremote=true\ncom.sun.management.jmxremote.port=5982\n" \
                     "com.sun.management.jmxremote.local.only=true\njava.rmi.server.hostname=localhost\n" \
                     "\ncom.sun.management.jmxremote.authenticate=false\n" \
                     "\ncom.sun.management.jmxremote.ssl=false\n",
          )
        }
        it { is_expected.not_to contain_file('/etc/jmx-aem.password') }
        it { is_expected.not_to contain_file('/etc/jmx-aem.access') }
      end
    end
  end
end
