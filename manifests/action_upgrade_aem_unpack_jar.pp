class aem_curator::action_upgrade_aem_unpack_jar (
  $tmp_dir,
  $aem_base,
  $aem_artifacts_base         = $::aem_artifacts_base,
  $aem_id                     = $::aem_id,
  $aem_port                   = $::aem_port,
  $enable_backup              = str2bool($::enable_backup),
  $upgrade_version            = $::upgrade_version,
  $post_stop_sleep_secs       = 120,
  $retries_max_tries          = 60,
  $retries_base_sleep_seconds = 5,
  $retries_max_sleep_seconds  = 5,
  $puppet_binary              = '/opt/puppetlabs/bin/puppet',
) {

  validate_bool($enable_backup)

  aem_curator::upgrade_aem_unpack_jar { "${aem_id}: Unpacking AEM ${upgrade_version}":
    aem_artifacts_base         => $aem_artifacts_base,
    aem_port                   => $aem_port,
    aem_base                   => $aem_base,
    aem_id                     => $aem_id,
    enable_backup              => $enable_backup,
    post_stop_sleep_secs       => $post_stop_sleep_secs,
    retries_base_sleep_seconds => $retries_base_sleep_seconds,
    retries_max_sleep_seconds  => $retries_max_sleep_seconds,
    retries_max_tries          => $retries_max_tries,
    tmp_dir                    => $tmp_dir,
    upgrade_version            => $upgrade_version,
    puppet_binary              => $puppet_binary,
  }
}
