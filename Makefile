# Everything CI checks, cheapest first so a failure shows up early: the YAML, Markdown
# and JSON lint (lint-extra), then rake test (Puppet lint, syntax, metadata_lint, unit
# specs, RuboCop), acceptance tests and the package. lint-extra rather than lint, as
# rake test already runs the rake lint checks
ci: clean lint-extra deps test acceptance package

# Install the Ruby gems, and vendor the InSpec AEM profile declared in inspec.yml
# into files/test/inspec/inspec-aem, which the aem-tools scripts run with `inspec exec`.
# The profile is downloaded with curl instead of `inspec vendor`, as the InSpec gem
# doesn't support Ruby 4 (--no-same-owner: root in the buildenv container can't chown
# on a macOS bind mount). r10k is no longer run: the unit tests use .fixtures.yml
deps:
	gem install bundler --version=4.0.22
	bundle install
	rm -rf vendor/inspec/ && mkdir -p vendor/inspec/
	curl -sfL "$$(ruby -ryaml -e "puts YAML.load_file('inspec.yml')['depends'][0]['url']")" | tar --no-same-owner -xz -C vendor/inspec/
	rm -rf files/test/inspec/ && mkdir -p files/test/inspec/
	mv vendor/inspec/inspec-aem-* files/test/inspec/inspec-aem

clean:
	rm -rf bin/ pkg/ stage/ test/ vendor/ /tmp/shinesolutions/puppet-aem-curator/

# lint, validate (syntax, metadata_lint), unit specs and static checks.
# safe.directory lets the git-based checks run as root in the buildenv container
test:
	GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0=$(CURDIR) \
		bundle exec rake test

# Puppet lint, syntax, metadata.json lint and RuboCop, plus lint-extra
lint: lint-extra
	bundle exec rake lint syntax metadata_lint rubocop

# The lint checks rake test doesn't run: yamllint, markdownlint and the .rtk.json check.
# They need no gems, so ci runs them before deps
lint-extra:
	yamllint .markdownlint.yaml .github/workflows/*.yaml
	markdownlint-cli2 README.md
	python3 -m json.tool .rtk.json

# Run acceptance tests against every nodeset; beaker only runs one per invocation.
# The fixture modules are installed on the hosts, see spec/spec_helper_acceptance.rb
acceptance:
	bundle exec rake fixtures:prep
	set -e; for nodeset in spec/acceptance/nodesets/*.yml; do \
		echo "== $$nodeset"; \
		BEAKER_SETFILE=$$nodeset bundle exec rake beaker; \
	done

# Generate the HTML reference into docs/
docs:
	bundle exec rake "strings:generate[,,,,,,--output-dir docs]"

# Move the Unreleased CHANGELOG.md entries to a release section, e.g. make changelog VERSION=4.1.10
# (VERSION defaults to metadata.json's version without its pre-release suffix)
changelog:
	bundle exec rake "changelog:release[$(VERSION)]"

package: deps
	bundle exec rake module:build

release-major:
	rtk release --release-increment-type major

release-minor:
	rtk release --release-increment-type minor

release-patch:
	rtk release --release-increment-type patch

release: release-minor

# Check the module is ready to publish to the Puppet Forge; reports what is missing.
# safe.directory lets the git-based checks run as root in the buildenv container
publish-check: package
	GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0=$(CURDIR) \
		tools/publish-check

# Publish the built package to the Puppet Forge, run by the publish workflow on a pushed tag.
# Requires BLACKSMITH_FORGE_API_KEY (a Forge API key) and a passing publish-check
publish: publish-check
	bundle exec rake module:push

.PHONY: ci deps clean test lint lint-extra acceptance docs changelog package release release-major release-minor release-patch publish-check publish
