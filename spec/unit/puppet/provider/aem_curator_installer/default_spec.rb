# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

# Checks the provider's instance discovery on Ruby 4 against an unpacked AEM 6.5
# layout (crx-quickstart/app/cq-quickstart-6.5.0-standalone-quickstart.jar and the
# start-env PORT that aem_resources::instance_config writes for install_author's '4502')
describe Puppet::Type.type(:aem_curator_installer).provider(:default) do
  let(:home) { Dir.mktmpdir }
  let(:resource) do
    Puppet::Type.type(:aem_curator_installer).new(name: 'aem', ensure: :present, home: home, snooze: 10, timeout: 600)
  end
  let(:provider) { resource.provider }

  after(:each) { FileUtils.remove_entry(home) }

  context 'with an unpacked AEM 6.5 instance' do
    before(:each) do
      FileUtils.mkdir_p(File.join(home, 'crx-quickstart', 'app'))
      FileUtils.mkdir_p(File.join(home, 'crx-quickstart', 'bin'))
      FileUtils.touch(File.join(home, 'crx-quickstart', 'app', 'cq-quickstart-6.5.0-standalone-quickstart.jar'))
      File.write(File.join(home, 'crx-quickstart', 'bin', 'start-env'), "PORT=4502\n")
    end

    it 'is absent until the repository exists' do
      expect(provider.exists?).to be(false)
    end

    it 'reads the version from the quickstart jar and the port from start-env' do
      found = provider.send(:find_instance)
      expect(found[:version]).to eq('6.5.0')
      expect(found[:port]).to eq('4502')
    end

    it 'is present once the repository exists' do
      FileUtils.mkdir_p(File.join(home, 'crx-quickstart', 'repository'))
      expect(provider.exists?).to be(true)
    end

    it 'removes the repository on destroy' do
      FileUtils.mkdir_p(File.join(home, 'crx-quickstart', 'repository'))
      provider.destroy
      expect(File.exist?(File.join(home, 'crx-quickstart', 'repository'))).to be(false)
    end
  end
end
