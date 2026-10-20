# frozen_string_literal: true

require 'spec_helper'

# Values: docroot_dir from ../aem-aws-stack-provisioner/data/common.yaml
# (aem_curator::action_flush_dispatcher_cache::docroot_dir -> common::docroot_dir).
describe 'aem_curator::action_flush_dispatcher_cache' do
  let(:params) { { docroot_dir: '/var/www/html/' } }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      ['apps', 'bin', 'conf', 'content', 'etc', 'etc.clientlibs', 'home', 'libs', 'system', 'tmp', 'var'].each do |dir|
        it {
          is_expected.to contain_file("/var/www/html//#{dir}").with(
            ensure: 'directory',
            purge: true,
            force: true,
            recurse: true,
            owner: 'apache',
            group: 'apache',
          )
        }
      end
    end
  end
end
