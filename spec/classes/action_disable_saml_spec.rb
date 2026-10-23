# frozen_string_literal: true

require 'spec_helper'

# The action_* classes default their parameters to getvar('::name'): the top-scope
# variable the caller sets (e.g. FACTER_aem_id), or undef when it is unset, as $::name
# was on Puppet 7. Facts are top-scope variables, so they stand in for FACTER_ values.
describe 'aem_curator::action_disable_saml' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      context 'without the top-scope variables' do
        let(:facts) { os_facts }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('aem_curator::action_disable_saml').with(aem_id: nil, aem_username: nil, aem_password: nil) }
        # aem_id is undef, so aem_resources::disable_saml uses its own default 'aem'
        it { is_expected.to contain_aem_resources__disable_saml('Disable SAML Authentication').with_aem_id('aem') }
        it { is_expected.to contain_aem_saml('[aem] Disable SAML authentication').with_ensure('absent') }
      end

      context 'with the top-scope aem_id set' do
        # 'author' is install_author's default aem_id
        let(:facts) { os_facts.merge(aem_id: 'author') }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('aem_curator::action_disable_saml').with_aem_id('author') }
        it { is_expected.to contain_aem_resources__disable_saml('Disable SAML Authentication').with_aem_id('author') }
        it { is_expected.to contain_aem_saml('[author] Disable SAML authentication').with_ensure('absent') }
      end
    end
  end
end
