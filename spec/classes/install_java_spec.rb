# frozen_string_literal: true

require 'spec_helper'

# Values: what packer-aem (the AMI bake) gives aem_curator::install_java, i.e.
# ../packer-aem/templates/ansible/hieradata.j2 rendered with conf/ansible/inventory/group_vars/defaults.yaml
# plus conf/puppet/hieradata/common.yaml (tmp_dir, cert_base_url). java.base_url is mandatory and ships
# as overwrite-me; it reuses the form of the aem.artifacts_base example in ../packer-aem/docs/configuration.md,
# s3://somebucket/artifacts. install_java supports Oracle JDK 21 only: packer-aem's java.filename
# default is still jdk-8u221-linux-x64.rpm, so the JDK 21 file name is the class default.
describe 'aem_curator::install_java' do
  let(:packer_aem_params) do
    {
      cert_base_url: 'file:///tmp/shinesolutions/packer-aem/certs',
      tmp_dir: '/tmp/shinesolutions/packer-aem',
      jdk_base_url: 's3://somebucket/artifacts',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:java_home) { '/usr/lib/jvm/jdk-21.0.13-oracle-x64' }

      context 'with the default JDK 21 file name' do
        let(:params) { packer_aem_params }

        it { is_expected.to compile.with_all_deps }

        it 'downloads and installs the JDK RPM once' do
          is_expected.to contain_java__download('21.0.13').with(
            ensure: 'present',
            java_se: 'jdk',
            url: 's3://somebucket/artifacts/jdk-21.0.13_linux-x64_bin.rpm',
          )
          # The creates guard is the RPM's install directory, so a later run doesn't reinstall it
          is_expected.to contain_archive('/tmp/jdk-21--21.0.13--oracle-x64-linux-x64.rpm')
            .with(source: 's3://somebucket/artifacts/jdk-21.0.13_linux-x64_bin.rpm', creates: java_home)
          is_expected.to contain_exec('Install Oracle java_se jdk 21 -21.0.13 -oracle-x64').with_creates(java_home)
        end

        it 'makes the JDK the default java' do
          is_expected.to contain_exec("alternatives --set  java #{java_home}/bin/java").that_requires('Java::Download[21.0.13]')
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
          ).that_requires('Java::Download[21.0.13]')
        end
      end

      context "with packer-aem's java.filename default" do
        let(:params) { packer_aem_params.merge(jdk_filename: 'jdk-8u221-linux-x64.rpm') }

        it { is_expected.to compile.and_raise_error(%r{Unsupported JDK file name jdk-8u221-linux-x64.rpm}) }
      end
    end
  end
end
