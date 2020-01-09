ci: clean deps lint package

clean:
	rm -rf Gemfile.lock bin/ pkg/ stage/ test/ vendor/ /tmp/shinesolutions/puppet-aem-curator/

deps:
	gem install bundler --version=1.17.3
	bundle install --binstubs -j4
	bundle exec r10k puppetfile install --verbose --moduledir modules
	mkdir -p vendor/inspec && cp inspec.yml vendor/inspec/
	bundle exec inspec vendor --overwrite vendor/inspec
	cd vendor/inspec/vendor && mv */inspec-aem-*.*.* inspec-aem
	rm -rf files/test/inspec/ && mkdir -p files/test/inspec/ && cp -R vendor/inspec/vendor/inspec-aem files/test/inspec/
	# only needed while using shinesolutions/puppet-aem fork
	# TODO: remove when switching back to bstopp/puppet-aem
	rm -rf modules/aem/.git

lint:
	bundle exec puppet-lint \
		--fail-on-warnings \
		--no-140chars-check \
		--no-autoloader_layout-check \
		--no-documentation-check \
		./manifests/*.pp
	puppet epp validate templates/*/*.epp
	bundle exec rubocop Gemfile
	mv Gemfile.lock Gemfile.lock.orig && PDK_DISABLE_ANALYTICS=true pdk validate metadata && mv Gemfile.lock.orig Gemfile.lock

package: deps
	PDK_DISABLE_ANALYTICS=true pdk build --force

release:
	rtk release

.PHONY: ci clean deps lint package release
