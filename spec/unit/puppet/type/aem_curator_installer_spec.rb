# frozen_string_literal: true

require 'spec_helper'

# Values are the ones aem_instance passes for install_aem62/63/64/65 with their
# defaults: title 'aem', home '/opt/aem/aem', snooze 10, timeout 600
describe Puppet::Type.type(:aem_curator_installer) do
  let(:resource) do
    described_class.new(name: 'aem', ensure: :present, home: '/opt/aem/aem', snooze: 10, timeout: 600)
  end

  it 'uses the default provider' do
    expect(resource.provider.class.name).to eq(:default)
  end

  it 'munges snooze and timeout to Integers' do
    expect(resource[:snooze]).to eq(10)
    expect(resource[:timeout]).to eq(600)
  end

  it 'keeps the home' do
    expect(resource[:home]).to eq('/opt/aem/aem')
  end

  it 'autorequires the home directory' do
    catalog = Puppet::Resource::Catalog.new
    home = Puppet::Type.type(:file).new(name: '/opt/aem/aem', ensure: :directory)
    catalog.add_resource(home)
    catalog.add_resource(resource)
    expect(resource.autorequire.map { |rel| rel.source.ref }).to include('File[/opt/aem/aem]')
  end

  it 'requires a home' do
    expect { described_class.new(name: 'aem') }.to raise_error(Puppet::ResourceError, %r{AEM Home must be specified})
  end
end
