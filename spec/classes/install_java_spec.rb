# frozen_string_literal: true

require 'spec_helper'

# Values: what packer-aem (the AMI bake) gives aem_curator::install_java, i.e.
# ../packer-aem/templates/ansible/hieradata.j2 rendered with conf/ansible/inventory/group_vars/defaults.yaml
# plus conf/puppet/hieradata/common.yaml (tmp_dir, cert_base_url). install_java installs Amazon Corretto 21;
# packer-aem's java.corretto_version default is the class default.
describe 'aem_curator::install_java' do
  let(:packer_aem_params) do
    {
      cert_base_url: 'file:///tmp/shinesolutions/packer-aem/certs',
      tmp_dir: '/tmp/shinesolutions/packer-aem',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      # Amazon Linux's own Corretto package installs into an architecture-specific directory,
      # the RPM from Amazon's Corretto repo into the plain one
      let(:java_home) do
        if os_facts[:os]['name'] == 'Amazon'
          "/usr/lib/jvm/java-21-amazon-corretto.#{os_facts[:os]['architecture']}"
        else
          '/usr/lib/jvm/java-21-amazon-corretto'
        end
      end

      context 'with the default Corretto version' do
        let(:params) { packer_aem_params }

        it { is_expected.to compile.with_all_deps }

        it 'installs the pinned Corretto version' do
          is_expected.to contain_package('java-21-amazon-corretto-devel').with_ensure('21.0.13.1.2')
        end

        if os_facts[:os]['name'] == 'Amazon'
          it "installs Corretto from Amazon Linux's own repo" do
            is_expected.not_to contain_yumrepo('AmazonCorretto')
          end
        else
          it "adds Amazon's Corretto repo before installing Corretto" do
            is_expected.to contain_yumrepo('AmazonCorretto').with(
              baseurl: 'https://yum.corretto.aws/$basearch',
              gpgkey: 'https://yum.corretto.aws/corretto.key',
              gpgcheck: '1',
              enabled: '1',
            ).that_comes_before('Package[java-21-amazon-corretto-devel]')
          end
        end

        it 'locks the pinned Corretto version with dnf versionlock' do
          is_expected.to contain_package('python3-dnf-plugin-versionlock')
            .with_ensure('present')
            .that_comes_before('Exec[Unlock other Amazon Corretto 21 versions]')
          # Only when a lock is on another version, which would stop the pinned version from installing
          is_expected.to contain_exec('Unlock other Amazon Corretto 21 versions').with(
            command: "dnf versionlock delete 'java-21-amazon-corretto*'",
            onlyif: "dnf -q versionlock list | grep '^java-21-amazon-corretto-' | grep -qvF ':21.0.13.1.2-'",
            provider: 'shell',
          ).that_comes_before('Package[java-21-amazon-corretto-devel]')
          is_expected.to contain_exec('Lock Amazon Corretto 21.0.13.1.2').with(
            command: "dnf versionlock add 'java-21-amazon-corretto*'",
            unless: "dnf -q versionlock list | grep '^java-21-amazon-corretto-devel-' | grep -qF ':21.0.13.1.2-'",
            provider: 'shell',
          ).that_requires('Package[java-21-amazon-corretto-devel]')
        end

        it 'makes Corretto the default java' do
          is_expected.to contain_exec("alternatives --set  java #{java_home}/bin/java").that_requires('Package[java-21-amazon-corretto-devel]')
          is_expected.to contain_file('/usr/java').with(ensure: 'directory', mode: '0775')
          is_expected.to contain_file('/usr/java/default').with(ensure: 'link', target: java_home)
          is_expected.to contain_file('/etc/ld.so.conf.d/99-libjvm.conf')
            .with(ensure: 'present', content: "#{java_home}/lib/server/\n")
            .that_notifies('Exec[/sbin/ldconfig]')
        end

        it 'adds the AEM certificate to the JDK cacerts' do
          is_expected.to contain_file('/tmp/shinesolutions/packer-aem/java').with(ensure: 'directory', mode: '0700')
          is_expected.to contain_archive('/tmp/shinesolutions/packer-aem/java/aem.cert')
            .with_source('file:///tmp/shinesolutions/packer-aem/certs/aem.cert')
            .that_requires('File[/tmp/shinesolutions/packer-aem/java]')
            .that_comes_before("Java_ks[cqse-0:#{java_home}/lib/security/cacerts]")
          is_expected.to contain_java_ks("cqse-0:#{java_home}/lib/security/cacerts").with(
            ensure: 'latest',
            certificate: '/tmp/shinesolutions/packer-aem/java/aem.cert',
            password: 'changeit',
          ).that_requires('Package[java-21-amazon-corretto-devel]')
        end
      end

      context 'with an Oracle JDK file name as the version' do
        let(:params) { packer_aem_params.merge(corretto_version: 'jdk-21.0.12_linux-x64_bin.rpm') }

        it { is_expected.to compile.and_raise_error(%r{Unsupported Corretto version jdk-21.0.12_linux-x64_bin.rpm}) }
      end
    end
  end
end
