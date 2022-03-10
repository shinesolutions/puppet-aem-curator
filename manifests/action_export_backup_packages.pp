
class aem_curator::action_export_backup_packages (
  $tmp_dir,
  $aem_id,
  $aem_username,
  $aem_password,
  $backup_path,
  $packages,
  $package_version,
  $stack_prefix,
  $data_bucket_name,
  $retries_max_tries,
  $retries_base_sleep_seconds,
  $retries_max_sleep_seconds,
) {

  $packages.each | Integer $index, Hash $package| {

    $_aem_id = pick(
      $package[aem_id],
      $aem_id,
      'author'
      )

    if !defined(File["${tmp_dir}/${_aem_id}/${package[group]}"]) {

      exec { "Create ${tmp_dir}/${_aem_id}/${package[group]}":
        creates => "${tmp_dir}/${_aem_id}/${package[group]}",
        command => "mkdir -p ${tmp_dir}/${_aem_id}/${package[group]}",
        cwd     => $tmp_dir,
        path    => ['/usr/bin', '/usr/sbin'],
      } -> file { "${tmp_dir}/${_aem_id}/${package['group']}":
        ensure => directory,
        mode   => '0775',
      }

    }

    aem_aem { "${_aem_id}: Wait until CRX Package Manager is ready before creating backup file for package: ${package[name]}":
      ensure                     => aem_package_manager_is_ready,
      retries_max_tries          => $retries_max_tries,
      retries_base_sleep_seconds => $retries_base_sleep_seconds,
      retries_max_sleep_seconds  => $retries_max_sleep_seconds,
      aem_id                     => $_aem_id,
      aem_username               => $aem_username,
      aem_password               => $aem_password,
    } -> aem_package { "${_aem_id}: Create and download backup file for package: ${package[name]}":
      ensure       => archived,
      name         => $package[name],
      version      => $package_version,
      group        => $package[group],
      path         => "${tmp_dir}/${_aem_id}/${package['group']}",
      filter       => $package[filter],
      aem_id       => $_aem_id,
      aem_username => $aem_username,
      aem_password => $aem_password,
      require      => File["${tmp_dir}/${_aem_id}/${package['group']}"],
    } -> exec { "aws s3 cp ${tmp_dir}/${_aem_id}/${package[group]}/${package[name]}-${package_version}.zip s3://${data_bucket_name}/backup/${stack_prefix}/${package[group]}/${backup_path}/${package[name]}-${package_version}.zip":
      cwd  => $tmp_dir,
      path => ['/bin'],
    } -> file { "${tmp_dir}/${_aem_id}/${package[group]}/${package[name]}-${package_version}.zip":
      ensure => absent,
      backup => false,
    }

  }

}
