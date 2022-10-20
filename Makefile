ci: clean deps lint package

clean:
	rm -rf Gemfile.lock bin/ pkg/ stage/ test/ vendor/ /tmp/shinesolutions/puppet-aem-curator/

deps:
	gem install bundler --version=2.3.24
	gem install hiera -version=3.10.0
	bundle install --binstubs -j4
	bundle exec r10k puppetfile install --verbose --moduledir modules
	mkdir -p vendor/inspec && cp inspec.yml vendor/inspec/
	bundle exec inspec vendor --overwrite vendor/inspec
	cd vendor/inspec/vendor && mv */inspec-aem-*.*.* inspec-aem
	rm -rf files/test/inspec/ && mkdir -p files/test/inspec/ && cp -R vendor/inspec/vendor/inspec-aem files/test/inspec/

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

release-major:
	rtk release --release-increment-type major

release-minor:
	rtk release --release-increment-type minor

release-patch:
	rtk release --release-increment-type patch

release: release-minor

publish:
	pdk release publish --force --forge-token=$(forge_token)

.PHONY: ci clean deps lint package release release-major release-minor release-patch publish
