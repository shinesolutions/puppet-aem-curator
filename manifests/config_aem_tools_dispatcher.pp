class aem_curator::config_aem_tools_dispatcher (
  $base_dir,
  $docroot_dir,
) {

  file { "${base_dir}/aem-tools/":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file {"${base_dir}/aem-tools/flush-dispatcher-cache.sh":
    ensure  => present,
    content => epp('aem_curator/aem-tools/flush-dispatcher-cache.sh.epp', {
      'base_dir'    => $base_dir,
      'docroot_dir' => $docroot_dir
      }
    ),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

}
