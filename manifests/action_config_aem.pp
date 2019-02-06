File {
  backup => false,
}

class aem_curator::action_config_aem (
  $aem_base                   = $::aem_base,
  $aem_healthcheck_source     = $::aem_healthcheck_source,
  $aem_healthcheck_version    = $::aem_healthcheck_version,
  $aem_id                     = $::aem_id,
  $aem_keystore_password      = $::aem_keystore_password,
  $aem_keystore_path          = $::aem_keystore_path,
  $aem_ssl_port               = $::aem_ssl_port,
  $cert_base_url              = $::cert_base_url,
  $enable_create_system_users = true,
  $enable_truststore_removal  = true,
  $force                      = $::force,
  $run_mode                   = $::run_mode,
  $tmp_dir                    = $::tmp_dir
) {

  # Action manifest currently does not support changing the existing
  # system user password
  aem_curator::reconfig_aem{"${aem_id}: Configure AEM":
    aem_base                   => $aem_base,
    aem_healthcheck_source     => $aem_healthcheck_source,
    aem_healthcheck_version    => $aem_healthcheck_version,
    aem_id                     => $aem_id,
    aem_keystore_password      => $aem_keystore_password,
    aem_keystore_path          => $aem_keystore_path,
    aem_ssl_port               => $aem_ssl_port,
    cert_base_url              => $cert_base_url,
    enable_create_system_users => $enable_create_system_users,
    enable_truststore_removal  => $enable_truststore_removal,
    force                      => $force,
    run_mode                   => $run_mode,
    tmp_dir                    => $tmp_dir,
  }
}
