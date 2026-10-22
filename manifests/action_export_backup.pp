
class aem_curator::action_export_backup (
  # getvar('::name') reads the caller's top-scope variable (e.g. FACTER_name) and gives undef
  # when it is unset, like $::name on Puppet 7; OpenVox 9's strict_variables fails on it
  $tmp_dir,
  $aem_id                     = getvar('::aem_id'),
  $aem_username               = getvar('::aem_username'),
  $aem_password               = getvar('::aem_password'),
  $backup_path                = getvar('::backup_path'),
  $package_group              = getvar('::package_group'),
  $package_name               = getvar('::package_name'),
  $package_version            = getvar('::package_version'),
  $package_filter             = getvar('::package_filter'),
  $stack_prefix               = getvar('::stack_prefix'),
  $data_bucket_name           = getvar('::data_bucket_name'),
  $retries_max_tries          = 60,
  $retries_base_sleep_seconds = 5,
  $retries_max_sleep_seconds  = 5,
) {

  $_aem_id = pick(
    $aem_id,
    'author'
    )

    file { $tmp_dir:
      ensure => directory,
      mode   => '0775',
      owner  => 'root',
      group  => 'root',
    } -> file { "${tmp_dir}/${_aem_id}":
      ensure => directory,
      mode   => '0775',
      owner  => 'root',
      group  => 'root',
    } -> file { "${tmp_dir}/${_aem_id}/${package_group}":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> aem_aem { "${_aem_id}: Wait until CRX Package Manager is ready before creating backup file":
    ensure                     => aem_package_manager_is_ready,
    retries_max_tries          => $retries_max_tries,
    retries_base_sleep_seconds => $retries_base_sleep_seconds,
    retries_max_sleep_seconds  => $retries_max_sleep_seconds,
    aem_id                     => $_aem_id,
    aem_username               => $aem_username,
    aem_password               => $aem_password,
  } -> aem_package { 'Create and download backup file':
    ensure       => archived,
    aem_id       => $_aem_id,
    aem_username => $aem_username,
    aem_password => $aem_password,
    name         => $package_name,
    version      => $package_version,
    group        => $package_group,
    path         => "${tmp_dir}/${_aem_id}/${package_group}",
    filter       => $package_filter,
  } -> exec { "aws s3 cp ${tmp_dir}/${_aem_id}/${package_group}/${package_name}-${package_version}.zip s3://${data_bucket_name}/backup/${stack_prefix}/${package_group}/${backup_path}/${package_name}-${package_version}.zip":
    cwd  => $tmp_dir,
    path => ['/bin', '/usr/local/bin', '/usr/bin'],
  } -> file { "${tmp_dir}/${_aem_id}/${package_group}/${package_name}-${package_version}.zip":
    ensure => absent,
    backup => false,
  }

}
