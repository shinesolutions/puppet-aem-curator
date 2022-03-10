
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

      class { 'aem_curator::action_export_backup_packages':
        tmp_dir                    => $tmp_dir,
        aem_id                     => $aem_id,
        aem_username               => $aem_username,
        aem_password               => $aem_password,
        backup_path                => $::backup_path,
        packages                   => $packages,
        package_version            => $package_version,
        stack_prefix               => $stack_prefix,
        data_bucket_name           => $data_bucket_name,
        retries_max_tries          => $retries_max_tries,
        retries_base_sleep_seconds => $retries_base_sleep_seconds,
        retries_max_sleep_seconds  => $retries_max_sleep_seconds,
      }

    } else {
      notify { "no 'packages' defined for component: ${component} in descriptor file: ${descriptor_file}. nothing to backup": }
    }


  } else {
    notify { "component: ${component} not found in descriptor file: ${descriptor_file}. nothing to backup": }
  }

}
