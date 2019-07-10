File {
  backup => false,
}

class aem_curator::action_export_backup (
  $tmp_dir,
  $aem_id                     = $::aem_id,
  $aem_username               = $::aem_username,
  $aem_password               = $::aem_password,
  $backup_path                = $::backup_path,
  $package_group              = $::package_group,
  $package_name               = $::package_name,
  $package_version            = $::package_version,
  $package_filter             = $::package_filter,
  $stack_prefix               = $::stack_prefix,
  $data_bucket_name           = $::data_bucket_name,
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
