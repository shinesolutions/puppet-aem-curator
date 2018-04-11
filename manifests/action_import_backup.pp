File {
  backup => false,
}

class aem_curator::action_import_backup (
  $tmp_dir,
  $aem_id              = $::aem_id,
  $aem_username        = $::aem_username,
  $aem_password        = $::aem_password,
  $source_stack_prefix = $::source_stack_prefix,
  $backup_path         = $::backup_path,
  $package_group       = $::package_group,
  $package_name        = $::package_name,
  $package_version     = $::package_version,
  $data_bucket_name    = $::data_bucket_name,
) {

  $_aem_id = pick(
    $aem_id,
    'author'
    )

  archive { "${tmp_dir}/${package_group}/${package_name}-${package_version}.zip":
    ensure => present,
    source => "s3://${data_bucket_name}/backup/${source_stack_prefix}/${package_group}/${backup_path}/${package_name}-${package_version}.zip",
  } -> aem_package { 'Upload and install backup file':
    ensure       => present,
    aem_id       => $_aem_id,
    aem_username => $aem_username,
    aem_password => $aem_password,
    name         => $package_name,
    version      => $package_version,
    group        => $package_group,
    path         => "${tmp_dir}/${package_group}",
    force        => true,
  } -> file { "${tmp_dir}/${package_group}/${package_name}-${package_version}.zip":
    ensure => absent,
  }

}
