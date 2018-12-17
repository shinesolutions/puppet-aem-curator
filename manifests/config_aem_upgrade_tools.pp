class aem_curator::config_aem_upgrade_tools (
  $base_dir,
  $tmp_dir,
  $enable_upgrade_tools     = undef,
  $aem_instances      = undef,
  $aem_tools_env_path = '$PATH',
  $confdir            = $settings::confdir,
) {
  if $enable_upgrade_tools {

    $_aem_instances = pick(
      $aem_instances,
      [{'aem_id' => 'author'}]
    )

    file {"${base_dir}/aem-tools/upgrade":
      ensure => directory,
    }

    file { "${base_dir}/aem-tools/upgrade/unpack-aem-jar.sh":
      ensure  => present,
      content => epp(
        'aem_curator/aem-tools/upgrade-aem-unpack-jar.sh.epp', {
          'base_dir'           => $base_dir,
          'confdir'            => $confdir,
          'aem_instances'      => $aem_instances,
          'aem_tools_env_path' => $aem_tools_env_path,
        }
      ),
      mode    => '0775',
      owner   => 'root',
      group   => 'root',
    } -> file { "${base_dir}/aem-tools/upgrade/repo-migration.sh":
      ensure  => present,
      content => epp(
        'aem_curator/aem-tools/upgrade-aem-repo-migration.sh.epp', {
          'base_dir'           => $base_dir,
          'confdir'            => $confdir,
          'aem_instances'      => $aem_instances,
          'aem_tools_env_path' => $aem_tools_env_path,
        }
      ),
      mode    => '0775',
      owner   => 'root',
      group   => 'root',
    } -> file { "${base_dir}/aem-tools/upgrade/upgrade-aem.sh":
      ensure  => present,
      content => epp(
        'aem_curator/aem-tools/upgrade-aem.sh.epp', {
          'base_dir'           => $base_dir,
          'confdir'            => $confdir,
          'aem_instances'      => $aem_instances,
          'aem_tools_env_path' => $aem_tools_env_path,
        }
      ),
      mode    => '0775',
      owner   => 'root',
      group   => 'root',
    } -> file { "${base_dir}/aem-tools/upgrade/upgrade-aem-script.sh":
      ensure  => present,
      content => epp(
        'aem_curator/aem-tools/upgrade-aem-script.sh.epp', {
          'base_dir'           => $base_dir,
          'aem_tools_env_path' => $aem_tools_env_path,
        }
      ),
      mode    => '0775',
      owner   => 'root',
      group   => 'root',
    }
  }
}
