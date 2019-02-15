File {
  backup => false,
}

class aem_curator::action_deploy_artifact (
  $aem_id                     = $::aem_id,
  $aem_username               = $::aem_username,
  $aem_password               = $::aem_password,
  $package_source             = $::package_source,
  $package_group              = $::package_group,
  $package_name               = $::package_name,
  $package_version            = $::package_version,
  $package_replicate          = $::package_replicate,
  $package_activate           = $::package_activate,
  $package_force              = $::package_force,
  $path                       = '/tmp/shinesolutions/aem-aws-stack-provisioner',
  $retries_max_tries          = 60,
  $retries_base_sleep_seconds = 5,
  $retries_max_sleep_seconds  = 5,
) {

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
