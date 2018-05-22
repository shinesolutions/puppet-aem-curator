ci: clean deps lint package

deps:
	gem install bundler
	bundle install --binstubs
	bundle exec r10k puppetfile install --verbose --moduledir modules
	bundle exec inspec vendor --overwrite
	cd vendor && find . -name "*.tar.gz" -exec tar -xzvf '{}' \; -exec rm '{}' \;
	cd vendor && mv inspec-aem-?.?.? inspec-aem
	rm -rf files/test/inspec/ && mkdir -p files/test/inspec/ && cp -R vendor/* files/test/inspec/
	# only needed while using shinesolutions/puppet-aem fork
	# TODO: remove when switching back to bstopp/puppet-aem
	rm -rf modules/aem/.git

clean:
	rm -rf bin/ pkg/ stage/ test/ vendor/ *.lock
	rm -rf /tmp/shinesolutions/puppet-aem-curator/

lint:
	bundle exec puppet-lint \
		--fail-on-warnings \
		--no-140chars-check \
		--no-autoloader_layout-check \
		--no-documentation-check \
		./manifests/*.pp
	puppet epp validate templates/*/*.epp

package: deps
	puppet module build .

.PHONY: ci clean deps lint package
