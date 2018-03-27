File {
  backup => false,
}

class aem_curator::action_deploy_artifact (
  $aem_id            = undef,
  $package_source    = $::package_source,
  $package_group     = $::package_group,
  $package_name      = $::package_name,
  $package_version   = $::package_version,
  $package_replicate = $::package_replicate,
  $package_activate  = $::package_activate,
  $package_force     = $::package_force,
  $path              = '/tmp/shinesolutions/aem-aws-stack-provisioner',
) {

  $_aem_id = $aem_id ? {
      'author'  => 'author',
      'publish' => 'publish',
      default   => 'author',
  }

  file { "${path}/${package_group}/${package_name}-${package_version}.zip":
    ensure => absent,
  } -> archive { "${path}/${package_group}/${package_name}-${package_version}.zip":
    ensure => present,
    source => $package_source,
  } -> aem_package { "Deploy package ${package_group}/${package_name}-${package_version}":
    ensure    => present,
    aem_id    => $_aem_id,
    name      => $package_name,
    group     => $package_group,
    version   => $package_version,
    path      => "${path}/${package_group}",
    replicate => $package_replicate,
    activate  => $package_activate,
    force     => $package_force,
  }

}
