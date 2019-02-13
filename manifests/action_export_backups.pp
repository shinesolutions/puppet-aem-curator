File {
  backup => false,
}

class aem_curator::action_export_backups (
  $tmp_dir,
  $aem_id                     = undef,
  $aem_username               = $::aem_username,
  $aem_password               = $::aem_password,
  $descriptor_file            = $::descriptor_file,
  $component                  = $::component,
  $package_version            = $::package_version,
  $stack_prefix               = $::stack_prefix,
  $data_bucket_name           = $::data_bucket_name,
  $retries_max_tries          = 60,
  $retries_base_sleep_seconds = 5,
  $retries_max_sleep_seconds  = 5,
) {

  # load descriptor file
  $descriptor_hash = loadjson("${tmp_dir}/${descriptor_file}")
  notify { "The descriptor_hash is: ${descriptor_hash}": }

  # extract component hash
  $component_hash = $descriptor_hash[$component]
  notify { "The component_hash is: ${component_hash}": }

  if $component_hash {

    file { $tmp_dir:
      ensure => directory,
      mode   => '0775',
    }

    $packages = $component_hash['packages']
    notify { "The packages is: ${packages}": }

    if $packages {

      class { 'aem_curator::export_backup_packages':
        tmp_dir         => $tmp_dir,
        aem_id          => $aem_id,
        aem_username    => $aem_username,
        aem_password    => $aem_password,
        backup_path     => $::backup_path,
        packages        => $packages,
        package_version => $package_version,
      }

    } else {
      notify { "no 'packages' defined for component: ${component} in descriptor file: ${descriptor_file}. nothing to backup": }
    }


  } else {
    notify { "component: ${component} not found in descriptor file: ${descriptor_file}. nothing to backup": }
  }

}

class aem_curator::export_backup_packages (
  $tmp_dir,
  $aem_id,
  $aem_username,
  $aem_password,
  $backup_path,
  $packages,
  $package_version,
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

    aem_aem { "${aem_id}: Wait until CRX Package Manager is ready before creating backup file for package: ${package[name]}":
      ensure                     => aem_package_manager_is_ready,
      retries_max_tries          => $retries_max_tries,
      retries_base_sleep_seconds => $retries_base_sleep_seconds,
      retries_max_sleep_seconds  => $retries_max_sleep_seconds,
      aem_id                     => $_aem_id,
      aem_username               => $aem_username,
      aem_password               => $aem_password,
    } -> aem_package { "Create and download backup file for package: ${package[name]}":
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
    }

  }

}
