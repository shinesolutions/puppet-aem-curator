# frozen_string_literal: true

require 'spec_helper'

describe 'aem_curator::config_aem_agents' do
  let(:title) { 'aem' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with defaults for all parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to have_aem_aem_resource_count(0) }
        it { is_expected.to have_aem_flush_agent_resource_count(0) }
        it { is_expected.to have_aem_outbox_replication_agent_resource_count(0) }
      end
    end
  end
end
