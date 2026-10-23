# frozen_string_literal: true

require 'spec_helper_acceptance'

# Only the classes and defined types that apply with their default parameters
# are tested here: the others install, configure and run AEM, which needs AEM
# artifacts, a license and the parameters the AEM OpenCloud provisioner sets.
describe 'aem_curator' do
  context 'aem_curator class with default parameters' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) { 'include aem_curator' }
    end
  end

  context 'aem_curator::config_logrotate class with default parameters' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) { 'include aem_curator::config_logrotate' }
    end
  end

  context 'defined types with default parameters' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<~PUPPET
          aem_curator::config_aem_agents { 'aem': }
          aem_curator::config_authorizable_keystore { 'aem': }
          aem_curator::config_saml { 'aem': }
          aem_curator::config_truststore { 'aem': }
          aem_curator::config_truststore_certificate { 'aem': }
          aem_curator::reconfig_aem { 'aem': }
        PUPPET
      end
    end
  end
end
