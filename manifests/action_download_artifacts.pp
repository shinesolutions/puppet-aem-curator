
class aem_curator::action_download_artifacts (
  $tmp_dir,
  $base_dir,
  $aem_id          = undef,
  $descriptor_file = $::descriptor_file,
  $component       = $::component
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

    # extract the artifacts hash
    $artifacts = $component_hash['artifacts']
    notify { "The artifacts is: ${artifacts}": }

    if $artifacts {

      class { 'aem_curator::action_download_dispatcher_artifacts':
        base_dir  => $base_dir,
        artifacts => $artifacts,
        path      => "${tmp_dir}/artifacts",
      }


    } else {

      notify { "no 'artifacts' defined for component: ${component} in descriptor file: ${descriptor_file}. nothing to download": }

    }

    # extract the packages hash
    $packages = $component_hash['packages']
    notify { "The packages is: ${packages}": }

    if $packages {

      class { 'aem_curator::action_download_packages':
        aem_id   => $aem_id,
        packages => $packages,
        path     => "${tmp_dir}/packages",
      }

    } else {

      notify { "no 'packages' defined for component: ${component} in descriptor file: ${descriptor_file}. nothing to download": }

    }


  } else {

    notify { "component: ${component} not found in descriptor file: ${descriptor_file}. nothing to download": }

  }

}
