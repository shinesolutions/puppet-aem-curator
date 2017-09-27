ci: tools deps clean lint

deps:
	gem install bundler
	rm -rf .bundle
	bundle install
	cd test/integration/ && r10k puppetfile install --moduledir modules

clean:
	rm -rf pkg
	rm -rf test/integration/.tmp/
	rm -rf test/integration/modules/
	rm -rf /tmp/shinesolutions/puppet-aem-curator/

lint:
	puppet-lint \
		--fail-on-warnings \
		--no-140chars-check \
		--no-autoloader_layout-check \
		--no-documentation-check \
		test/integration/*/*.pp \
		manifests/*.pp
	rubocop

package:
	puppet module build .

tools:
	gem install puppet puppet-lint r10k

.PHONY: ci clean deps lint package tools
