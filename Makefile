ci: clean deps lint package

deps:
	gem install bundler
	bundle install --binstubs
	bundle exec r10k puppetfile install --verbose --moduledir modules
	bundle exec inspec vendor --overwrite
	mkdir -p files/test/inspec &&	mv vendor/*.tar.gz files/test/inspec/ && cd files/test/inspec && gunzip *.tar.gz && tar -xvf *.tar

clean:
	rm -rf pkg
	rm -rf stage/
	rm -rf test/
	rm -rf /tmp/shinesolutions/puppet-aem-curator/
	rm -rf vendor/
	rm -f inspec.lock

lint:
	bundle exec puppet-lint \
		--fail-on-warnings \
		--no-140chars-check \
		--no-autoloader_layout-check \
		--no-documentation-check \
		./manifests/*.pp
	bundle exec puppet epp validate templates/*/*.epp

package: deps
	bundle exec puppet module build .

.PHONY: ci clean deps lint package
