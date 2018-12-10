class aem_curator::action_upgrade_aem (
  $aem_base,
  $base_dir,
  $login_ready_max_tries,
  $login_ready_base_sleep_seconds,
  $login_ready_max_sleep_seconds,
  $tmp_dir,
  $aem_id                  = $::aem_id,
  $aem_port                = $::aem_port,
  $aem_upgrade_version     = $::aem_upgrade_version,
  $post_upgrade_sleep_secs = $::post_upgrade_sleep_secs,
) {
  aem_curator::upgrade_aem { "${aem_id}: Upgrading AEM to version ${aem_upgrade_version}":
    aem_base                       => $aem_base,
    aem_id                         => $aem_id,
    aem_port                       => $aem_port,
    base_dir                       => $base_dir,
    post_upgrade_sleep_secs        => $post_upgrade_sleep_secs,
    tmp_dir                        => $tmp_dir,
    aem_upgrade_version            => $aem_upgrade_version,
    login_ready_max_tries          => $login_ready_max_tries,
    login_ready_base_sleep_seconds => $login_ready_base_sleep_seconds,
    login_ready_max_sleep_seconds  => $login_ready_max_sleep_seconds,
  }
}
