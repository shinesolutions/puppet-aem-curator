class aem_curator::config_aem_tools_dispatcher (
  $base_dir,
) {

  file {"${base_dir}/aem-tools/flush-dispatcher-cache.sh":
    ensure  => present,
    content => epp('aem_curator/aem-tools/flush-dispatcher-cache.sh.epp', {
      'base_dir'    => $base_dir,
      }
    ),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

}
