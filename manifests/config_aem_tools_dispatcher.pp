class aem_curator::config_aem_tools_dispatcher (
  $base_dir,
  $aem_tools_env_path = '$PATH',
) {

  file {"${base_dir}/aem-tools/flush-dispatcher-cache.sh":
    ensure  => present,
    content => epp('aem_curator/aem-tools/flush-dispatcher-cache.sh.epp', {
      'base_dir'           => $base_dir,
      'aem_tools_env_path' => $aem_tools_env_path
      }
    ),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

}
