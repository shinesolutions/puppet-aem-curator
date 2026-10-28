require 'voxpupuli/acceptance/spec_helper_acceptance'

# configure_beaker installs the fixture modules from spec/fixtures/modules (this
# module and the dependency versions pinned in .fixtures.yml) on each host in
# before(:suite), so the hosts get exactly the dependency versions the unit tests use.
# The agent comes from the nodesets' images (BEAKER_PUPPET_COLLECTION=preinstalled in the Makefile)
configure_beaker(modules: :fixtures)

# The aem_resources providers load ruby_aem, whose HTTP client (ethon) loads libcurl through FFI.
# OpenVox 9's bundled Ruby has its own OpenSSL in /opt/puppetlabs/puppet/lib and no libcurl, and the
# system libcurl then binds to that OpenSSL and fails ("undefined symbol: EVP_camellia_256_cbc"), so
# build curl against OpenVox's OpenSSL into /opt/puppetlabs/puppet once per host, as
# the-works-buildenv's provisioners/shell/init.sh does ("Fix missing libcurl for OpenVox Puppet 9
# bundled Ruby"), and install ruby_aem into the agent's Ruby (the AEM AMIs provide both). ruby_aem is
# the version in Gemfile.lock (the test gem the aem_resources fixture's providers need), not a pinned one.
def install_aem_resources_dependencies(host, curl_version: '8.12.1')
  unless host.file_exist?('/opt/puppetlabs/puppet/lib/libcurl.so')
    on(host, 'dnf -y install gcc make perl tar gzip')
    on(host, <<~SHELL)
      set -e
      cd /tmp
      curl -fsSLO https://curl.se/download/curl-#{curl_version}.tar.gz
      tar xzf curl-#{curl_version}.tar.gz
      cd curl-#{curl_version}
      ./configure --prefix=/opt/puppetlabs/puppet --with-openssl=/opt/puppetlabs/puppet \
        --without-gssapi --without-libpsl --disable-ldap --disable-ntlm \
        LDFLAGS="-Wl,-rpath,/opt/puppetlabs/puppet/lib"
      make && make install
      cd /tmp && rm -rf curl-#{curl_version} curl-#{curl_version}.tar.gz
    SHELL
  end
  ruby_aem_version = Gem.loaded_specs.fetch('ruby_aem').version
  on(host, "/opt/puppetlabs/puppet/bin/gem list -i ruby_aem -v #{ruby_aem_version} || " \
           "/opt/puppetlabs/puppet/bin/gem install ruby_aem -v #{ruby_aem_version} --no-document")
end
