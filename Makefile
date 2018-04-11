ci: clean deps lint package

deps:
	gem install bundler
	bundle install --binstubs
	bundle exec r10k puppetfile install --verbose --moduledir modules
	bundle exec inspec vendor --overwrite
	mkdir -p files/test/inspec &&	mv vendor/*.tar.gz files/test/inspec/ && cd files/test/inspec && gunzip *.tar.gz && tar -xvf *.tar && rm -f *.tar

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
