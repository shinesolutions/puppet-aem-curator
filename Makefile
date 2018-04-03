ci: clean tools deps lint

deps:
	r10k puppetfile install --verbose --moduledir modules
	mkdir -p inspec/profiles/inspec-aem
	mkdir -p inspec/profiles/inspec-aem-aws
	mkdir stage
	cd stage
	wget https://github.com/shinesolutions/inspec-aem/archive/master.tar.gz
	tar -xzf master.tar.gz ../inspec/profiles/inspec-aem/
	wget https://github.com/shinesolutions/inspec-aem-aws/archive/master.tar.gz
	tar -xzf master.tar.gz ../inspec/profiles/inspec-aem-aws/

clean:
	rm -rf pkg
	rm -rf inspec/
	rm -fr stage/
	rm -rf test/integration/.tmp/
	rm -rf test/integration/modules/
	rm -rf /tmp/shinesolutions/puppet-aem-curator/

lint:
	puppet-lint \
		--fail-on-warnings \
		--no-140chars-check \
		--no-autoloader_layout-check \
		--no-documentation-check \
		./manifests/*.pp

package: deps
	puppet module build .

tools:
	gem install puppet puppet-lint r10k

.PHONY: ci clean deps lint package tools
