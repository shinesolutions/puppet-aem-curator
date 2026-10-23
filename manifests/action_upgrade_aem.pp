class aem_curator::action_upgrade_aem (
  # getvar('::name') reads the caller's top-scope variable (e.g. FACTER_name) and gives undef
  # when it is unset, like $::name on Puppet 7; OpenVox 9's strict_variables fails on it
  $aem_base,
  $base_dir,
  $tmp_dir,
  $aem_id                  = getvar('::aem_id'),
  $aem_port                = getvar('::aem_port'),
  $aem_upgrade_version     = getvar('::aem_upgrade_version'),
  $post_upgrade_sleep_secs = getvar('::post_upgrade_sleep_secs'),
) {
  aem_curator::upgrade_aem { "${aem_id}: Upgrading AEM to version ${aem_upgrade_version}":
    aem_base                => $aem_base,
    aem_id                  => $aem_id,
    aem_port                => $aem_port,
    base_dir                => $base_dir,
    post_upgrade_sleep_secs => $post_upgrade_sleep_secs,
    tmp_dir                 => $tmp_dir,
    aem_upgrade_version     => $aem_upgrade_version,
  }
}
