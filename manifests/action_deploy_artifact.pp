
class aem_curator::action_deploy_artifact (
  # getvar('::name') reads the caller's top-scope variable (e.g. FACTER_name) and gives undef
  # when it is unset, like $::name on Puppet 7; OpenVox 9's strict_variables fails on it
  $aem_id                     = getvar('::aem_id'),
  $aem_username               = getvar('::aem_username'),
  $aem_password               = getvar('::aem_password'),
  $package_source             = getvar('::package_source'),
  $package_group              = getvar('::package_group'),
  $package_name               = getvar('::package_name'),
  $package_version            = getvar('::package_version'),
  $package_replicate          = str2bool(getvar('::package_replicate')),
  $package_activate           = str2bool(getvar('::package_activate')),
  $package_force              = str2bool(getvar('::package_force')),
  $path                       = '/tmp/shinesolutions/aem-aws-stack-provisioner',
  $retries_max_tries          = 60,
  $retries_base_sleep_seconds = 5,
  $retries_max_sleep_seconds  = 5,
) {

  # validate_bool was removed in stdlib 9; assert_type(Boolean) is the same check
  assert_type(Boolean, $package_replicate)
  assert_type(Boolean, $package_activate)
  assert_type(Boolean, $package_force)

  Aem_aem {
    retries_max_tries          => $retries_max_tries,
    retries_base_sleep_seconds => $retries_base_sleep_seconds,
    retries_max_sleep_seconds  => $retries_max_sleep_seconds,
  }

  Aem_package {
    retries_max_tries          => $retries_max_tries,
    retries_base_sleep_seconds => $retries_base_sleep_seconds,
    retries_max_sleep_seconds  => $retries_max_sleep_seconds,
  }

  $_aem_id = pick(
    $aem_id,
    'author'
    )

  file { "${path}/${package_group}/${package_name}-${package_version}.zip":
    ensure => absent,
  } -> archive { "${path}/${package_group}/${package_name}-${package_version}.zip":
    ensure => present,
    source => $package_source,
  } -> aem_aem { "Wait until CRX Package Manager is ready before deploying package ${package_group}/${package_name}-${package_version}":
    ensure       => aem_package_manager_is_ready,
    aem_id       => $_aem_id,
    aem_username => $aem_username,
    aem_password => $aem_password,
  } -> aem_package { "Deploy package ${package_group}/${package_name}-${package_version}":
    ensure       => present,
    aem_id       => $_aem_id,
    aem_username => $aem_username,
    aem_password => $aem_password,
    name         => $package_name,
    group        => $package_group,
    version      => $package_version,
    path         => "${path}/${package_group}",
    replicate    => $package_replicate,
    activate     => $package_activate,
    force        => $package_force,
  }

}
