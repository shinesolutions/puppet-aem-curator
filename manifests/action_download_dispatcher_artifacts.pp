
class aem_curator::action_download_dispatcher_artifacts (
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
