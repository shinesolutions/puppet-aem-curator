# == Define: aem_curator::aem_instance
#
# This define manages AEM instances.
#
# Ported from bstopp/aem 3.0.0 aem::instance (Apache-2.0, Copyright (C) 2015-2016
# Bryan Stopp, see NOTICE) because that module is unmaintained and incompatible
# with OpenVox 9. Behaviour, parameters and resource ordering are unchanged; the
# stdlib validate_* and is_* functions removed in stdlib 9 are replaced with the
# equivalent assert_type checks, and aem::config with aem_resources::instance_config.
#
define aem_curator::aem_instance (
  $ensure           = 'present',
  $context_root     = undef,
  $debug_port       = undef,
  $group            = 'aem',
  $home             = undef,
  $jvm_mem_opts     = '-Xmx1024m',
  $jvm_opts         = undef,
  $manage_group     = true,
  $manage_home      = true,
  $manage_user      = true,
  $osgi_configs     = undef,
  $crx_packages     = undef,
  $port             = 4502,
  $runmodes         = [],
  $sample_content   = true,
  $service_options  = undef,
  $snooze           = 10,
  $source           = undef,
  $status           = 'enabled',
  $timeout          = 600,
  $type             = author,
  $user             = 'aem',
  $version          = undef) {
  # validate_integer accepted Integers and integer Strings
  $integer = Variant[Integer, Pattern[/^[-+]?\d+$/]]

  # Kept 1:1 with aem::instance (the ordering below starts from it); the stdlib
  # anchor type is deprecated but still in stdlib 9 and 10
  anchor { "aem::${name}::begin": } # lint:ignore:anchor_resource

  assert_type(Pattern[/^(present|absent)$/], $ensure) |$expected, $actual| {
    fail("${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'.")
  }

  if $debug_port {
    assert_type($integer, $debug_port)
  }

  if !$home {
    case $facts['kernel'] {
      'Linux' : { $_home = '/opt/aem' }
      default : { fail("'${module_name}' has no default 'home' value for '${facts['kernel']}'") }
    }
  } else {
    $_home = $home
  }

  assert_type(Stdlib::Absolutepath, $_home)

  assert_type(Boolean, $manage_group)

  if $manage_group {
    group { $group: ensure => $ensure, }
  }

  assert_type(Boolean, $manage_user)

  if $manage_user {
    user { $user:
      ensure => $ensure,
      gid    => $group,
    }
  }

  assert_type(Boolean, $manage_home)

  if $osgi_configs {
    if !($osgi_configs =~ Hash) and !($osgi_configs =~ Array and $osgi_configs[0] =~ Hash) {
      fail("Aem_curator::Aem_instance[${name}]: 'osgi_configs' must be either a Hash or an Array of Hashes")
    }
  }

  if $crx_packages {
    assert_type(Array, $crx_packages)
  }

  assert_type($integer, $port)
  assert_type(Array, $runmodes)

  assert_type(Boolean, $sample_content)

  assert_type(Pattern[/^(enabled|disabled|running|unmanaged)$/], $status) |$expected, $actual| {
    fail("${status} is not supported for status. Allowed values are 'enabled', 'disabled', 'running' and 'unmanaged'.")
  }

  assert_type($integer, $snooze)
  if ($ensure == 'present') {
    assert_type(Stdlib::Absolutepath, $source)
  }

  assert_type($integer, $timeout)

  assert_type(Pattern[/^(author|publish|standby)$/], $type) |$expected, $actual| {
    fail("${type} is not supported for type. Allowed values are 'author', 'publish' and 'standby'.")
  }

  if $version {
    assert_type(Pattern[/^\d+\.\d+(\.\d+)?$/], $version) |$expected, $actual| {
      fail("${version} is not a valid version.")
    }
  }

  # ### Manage actions

  # package(s)
  aem_curator::aem_package { $name :
    ensure      => $ensure,
    group       => $group,
    home        => $_home,
    manage_home => $manage_home,
    source      => $source,
    user        => $user,
  }

  if $status != 'unmanaged' {
    aem_curator::aem_service { $name :
      ensure          => $ensure,
      status          => $status,
      home            => $_home,
      user            => $user,
      group           => $group,
      service_options => $service_options,
    }
  }

  if ($ensure == 'present') {
    # configuration
    aem_resources::instance_config { $name:
      context_root   => $context_root,
      debug_port     => $debug_port,
      group          => $group,
      home           => $_home,
      jvm_mem_opts   => $jvm_mem_opts,
      jvm_opts       => $jvm_opts,
      osgi_configs   => $osgi_configs,
      crx_packages   => $crx_packages,
      port           => $port,
      runmodes       => $runmodes,
      sample_content => $sample_content,
      type           => $type,
      user           => $user,
    }

    aem_curator_installer { $name:
      ensure  => $ensure,
      home    => $_home,
      snooze  => $snooze,
      timeout => $timeout,
    }

    # Is there no way to do this better?
    if $manage_group {
      Anchor["aem::${name}::begin"]
      -> Group[$group]
      -> Aem_curator::Aem_package[$name]
    }

    if $manage_user {
      Anchor["aem::${name}::begin"]
      -> User[$user]
      -> Aem_curator::Aem_package[$name]

      if $manage_group {
        Anchor["aem::${name}::begin"]
        -> Group[$group]
        -> User[$user]
      }
    }

    Anchor["aem::${name}::begin"]
    -> Aem_curator::Aem_package[$name]
    -> Aem_resources::Instance_config[$name]
    -> Aem_curator_installer[$name]

    if $status != 'unmanaged' {
      Aem_curator_installer[$name]
      ~> Aem_curator::Aem_service[$name]

      Aem_resources::Instance_config[$name]
      ~> Aem_curator::Aem_service[$name]
    }
  } else {
    Anchor["aem::${name}::begin"]
    -> Aem_curator::Aem_service[$name]
    -> Aem_curator::Aem_package[$name]

    # I mean seriously.
    if $manage_user {
      Anchor["aem::${name}::begin"]
      -> User[$user]
    }

    if $manage_group {
      Anchor["aem::${name}::begin"]
      -> Group[$group]

      if $manage_user {
        Anchor["aem::${name}::begin"]
        -> User[$user]
        -> Group[$group]
      }
    }
  }
}
