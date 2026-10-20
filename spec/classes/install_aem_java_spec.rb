# frozen_string_literal: true

require 'spec_helper'

# Values: what packer-aem (the AMI bake) gives aem_curator::install_aem_java, i.e.
# ../packer-aem/templates/ansible/hieradata.j2 rendered with
# conf/ansible/inventory/group_vars/defaults.yaml (aem.jdk.filename jdk-8u221-linux-x64.rpm) plus
# conf/puppet/hieradata/common.yaml (tmp_dir, cert_base_url). aem.jdk.base_url is mandatory and
# ships as overwrite-me; it reuses the form of the aem.artifacts_base example in
# ../packer-aem/docs/configuration.md, s3://somebucket/artifacts.
describe 'aem_curator::install_aem_java' do
  let(:params) do
    {
      cert_base_url: 'file:///tmp/shinesolutions/packer-aem/certs',
      tmp_dir: '/tmp/shinesolutions/packer-aem',
      jdk_base_url: 's3://somebucket/artifacts',
      jdk_filename: 'jdk-8u221-linux-x64.rpm',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:java_home) { '/usr/java/jdk1.8.0_221-amd64/jre' }

      it { is_expected.to compile.with_all_deps }

      it 'downloads and installs the JDK RPM' do
        is_expected.to contain_java__download('8u221').with(
          ensure: 'present',
          java_se: 'jdk',
          url: 's3://somebucket/artifacts/jdk-8u221-linux-x64.rpm',
        )
        # TODO: java::download isn't given version_major/version_minor, so it names the download and
        # its creates guard after its default 8u201/b09, not the jdk_filename's 8u221 (see the TODO in
        # manifests/install_aem_java.pp)
        is_expected.to contain_archive('/tmp/jdk-8-8u201-b09-linux-x64.rpm')
          .with(source: 's3://somebucket/artifacts/jdk-8u221-linux-x64.rpm', creates: '/usr/java/jdk1.8.0_201')
      end

      it 'makes the 8u221 JDK the default java' do
        is_expected.to contain_exec("alternatives --set  java #{java_home}/bin/java").that_requires('Java::Download[8u221]')
        is_expected.to contain_file('/usr/java').with(ensure: 'directory', mode: '0775')
        is_expected.to contain_file('/usr/java/default').with(ensure: 'link', target: java_home)
        is_expected.to contain_file('/etc/ld.so.conf.d/99-libjvm.conf')
          .with(ensure: 'present', content: "#{java_home}/lib/amd64/server/\n")
          .that_notifies('Exec[/sbin/ldconfig]')
        is_expected.to contain_exec('/sbin/ldconfig').with_refreshonly(true)
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
        ).that_requires('Java::Download[8u221]')
      end
    end
  end
end
