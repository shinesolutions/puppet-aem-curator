# frozen_string_literal: true

require 'spec_helper'

describe 'aem_curator::config_authorizable_keystore' do
  let(:title) { 'aem' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with defaults for all parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to have_aem_resources__create_authorizable_keystore_resource_count(0) }
      end
    end
  end
end
