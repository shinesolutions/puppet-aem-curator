aem_username = ENV['aem_username']
aem_password = ENV['aem_password']

describe aem do
  it { should have_crxde_enabled }
end
