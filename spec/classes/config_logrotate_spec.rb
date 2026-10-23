# frozen_string_literal: true

require 'spec_helper'

describe 'aem_curator::config_logrotate' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with defaults for all parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('aem_curator::config_logrotate') }
        it { is_expected.to have_logrotate__conf_resource_count(0) }
        it { is_expected.to have_logrotate__rule_resource_count(0) }
      end
    end
  end
end
