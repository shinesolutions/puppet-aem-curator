aem_username = ENV['aem_username']
aem_password = ENV['aem_password']

describe http('http://localhost:4502/crx/server/crx.default/jcr:root/.1.json',
              auth: { user: aem_username, pass: aem_password }) do
  its('status') { should eq 404 }
end
