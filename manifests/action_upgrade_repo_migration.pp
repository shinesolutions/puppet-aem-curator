class aem_curator::action_upgrade_repo_migration (
  # getvar('::name') reads the caller's top-scope variable (e.g. FACTER_name) and gives undef
  # when it is unset, like $::name on Puppet 7; OpenVox 9's strict_variables fails on it
  $tmp_dir,
  $aem_base,
  $aem_id                     = getvar('::aem_id'),
  $aem_port                   = getvar('::aem_port'),
  $retries_max_tries          = 60,
  $retries_base_sleep_seconds = 5,
  $retries_max_sleep_seconds  = 5,
  $source_crx2oak             = getvar('::source_crx2oak'),
) {

  if $source_crx2oak == '' {
    $_source_crx2oak = undef
  } else {
    $_source_crx2oak = $source_crx2oak
  }

  aem_curator::upgrade_repo_migration { "${aem_id}: Triggering AEM Repository migration":
    tmp_dir                    => $tmp_dir,
    aem_base                   => $aem_base,
    aem_id                     => $aem_id,
    aem_port                   => $aem_port,
    retries_max_tries          => $retries_max_tries,
    retries_base_sleep_seconds => $retries_base_sleep_seconds,
    retries_max_sleep_seconds  => $retries_max_sleep_seconds,
    source_crx2oak             => $_source_crx2oak,
  }
}
