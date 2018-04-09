ci: clean tools deps lint

deps:
	r10k puppetfile install --verbose --moduledir modules
	inspec vendor --overwrite
	mkdir -p files/test/inspec &&	mv vendor/*.tar.gz files/test/inspec/ && cd files/test/inspec && gunzip *.tar.gz && tar -xvf *.tar

clean:
	rm -rf pkg
	rm -rf stage/
	rm -rf test/
	rm -rf /tmp/shinesolutions/puppet-aem-curator/
	rm -rf vendor/
	rm -f inspec.lock

lint:
	puppet-lint \
		--fail-on-warnings \
		--no-140chars-check \
		--no-autoloader_layout-check \
		--no-documentation-check \
		./manifests/*.pp
	puppet epp validate templates/*/*.epp

package: deps
	puppet module build .

tools:
	gem install puppet puppet-lint r10k

.PHONY: ci clean deps lint package tools
