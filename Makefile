# Every hand-written Markdown file (docs/ also gets generated HTML, which isn't linted)
# and every YAML file, for markdownlint and yamllint
MARKDOWN_FILES := README.md CHANGELOG.md docs/*.md .github/ISSUE_TEMPLATE/*.md
YAML_FILES := .fixtures.yml .markdownlint.yaml .rubocop.yml inspec.yml \
	.github/workflows/*.yaml spec/acceptance/nodesets/*.yml spec/default_facts.yml

# Everything CI checks, cheapest first so a failure shows up early: lint-extra (RuboCop,
# YAML, Markdown and JSON lint), then rake test (Puppet lint, syntax, metadata_lint, unit
# specs), acceptance tests and the package. lint-extra rather than lint, as rake test
# already runs the rake lint checks. deps comes first because RuboCop needs the gems
ci: clean deps lint-extra test acceptance package

# Install the Ruby gems, and vendor the InSpec AEM profile declared in inspec.yml
# into files/test/inspec/inspec-aem, which the aem-tools scripts run with `inspec exec`.
# The profile is downloaded with curl instead of `inspec vendor`, as the InSpec gem
# doesn't support Ruby 4 (--no-same-owner: root in the buildenv container can't chown
# on a macOS bind mount). It is downloaded to a file rather than piped into tar, so a
# failed download fails the build. r10k is no longer run: the unit tests use .fixtures.yml
deps:
	gem install bundler --version=4.0.22
	bundle install
	rm -rf vendor/inspec/ && mkdir -p vendor/inspec/
	url="$$(ruby -ryaml -e "puts YAML.load_file('inspec.yml')['depends'][0]['url']")" && \
		curl -fsSL -o vendor/inspec/inspec-aem.tar.gz "$$url"
	tar --no-same-owner -xzf vendor/inspec/inspec-aem.tar.gz -C vendor/inspec/
	rm -rf files/test/inspec/ && mkdir -p files/test/inspec/
	mv vendor/inspec/inspec-aem-* files/test/inspec/inspec-aem

clean:
	rm -rf bin/ pkg/ stage/ test/ vendor/

# lint, validate (syntax, metadata_lint), unit specs and static checks.
# safe.directory lets the git-based checks run as root in the buildenv container
test:
	GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0=$(CURDIR) \
		bundle exec rake test

# All static checks, without the unit specs
lint: lint-extra
	bundle exec rake lint syntax metadata_lint

# The static checks rake test doesn't run (rake test has no RuboCop), so ci runs them
# without repeating rake test's lint/syntax/metadata_lint
lint-extra:
	bundle exec rake rubocop
	yamllint $(YAML_FILES)
	markdownlint-cli2 $(MARKDOWN_FILES)
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

.PHONY: ci deps clean test lint lint-extra acceptance docs package release release-major release-minor release-patch publish-check publish
