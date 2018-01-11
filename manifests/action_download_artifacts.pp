File {
  backup => false,
}

class aem_curator::action_download_artifacts (
  $tmp_dir,
  $base_dir,
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

      class { 'download_dispatcher_artifacts':
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

      class { 'download_packages':
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


class download_dispatcher_artifacts (
  $base_dir,
  $artifacts,
  $path
) {

  file { $path:
    ensure => directory,
    mode   => '0775',
  }

  $artifacts.each | Integer $index, Hash $artifact| {

    file { "${path}/${artifact[name]}":
      ensure  => directory,
      mode    => '0775',
      require => File[$path],
    }

    archive { "${path}/${artifact[name]}.zip":
      ensure       => present,
      extract      => true,
      extract_path => "${path}/${artifact[name]}",
      source       => $artifact[source],
      require      => File["${path}/${artifact[name]}"],
      before       => Exec["/usr/bin/python ${base_dir}/aem-tools/generate-artifacts-descriptor.py"],
    }

  }

  #Execute Python script to generate artifacts content json file for deployment.
  exec { "/usr/bin/python ${base_dir}/aem-tools/generate-artifacts-descriptor.py":
    path => '/usr/bin',
  }

}

class download_packages (
  $packages,
  $path
) {
  # prepare the packages
  file { $path:
    ensure => directory,
    mode   => '0775',
  }

  $packages.each | Integer $index, Hash $package| {
    # TODO: validate the package values exist and populated
    if !defined(File["${path}/${package['group']}"]) {
      exec { "Create ${path}/${package['group']}":
        creates => "${path}/${package['group']}",
        command => "mkdir -p ${path}/${package['group']}",
        cwd     => $path,
        path    => ['/usr/bin', '/usr/sbin', '/bin/'],
        require => File[$path],
      } -> file { "${path}/${package['group']}":
        ensure => directory,
        mode   => '0775',
      }
    }

    if $package['force'] {
      # This is not _guaranteed_ to never match, but
      # the chance of matching is very, very low.
      $checksum = '00000000000000000000000000000000'
      $checksum_type = 'md5'
      $checksum_verify = false
    } elsif $package['checksum'] {
      $checksum      = $package['checksum']
      $checksum_type = pick(
        $package['checksum_type'],
        'md5',
      )
      $checksum_verify = true
    } else {
      $checksum        = undef
      $checksum_type   = undef
      $checksum_verify = true
    }

    archive { "${path}/${package['aem_id']}/${package['group']}/${package['name']}-${package['version']}.zip":
      ensure          => present,
      source          => $package[source],
      checksum        => $checksum,
      checksum_type   => $checksum_type,
      checksum_verify => $checksum_verify,
      require         => File["${path}/${package['group']}"],
    }
  }
}
