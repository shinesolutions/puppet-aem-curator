File {
  backup => false,
}

class aem_curator::action_config_aem (
  $aem_base                = $::aem_base,
  $aem_healthcheck_source  = $::aem_healthcheck_source,
  $aem_healthcheck_version = $::aem_healthcheck_version,
  $aem_id                  = $::aem_id,
  $aem_keystore_password   = $::aem_keystore_password,
  $aem_keystore_path       = $::aem_keystore_path,
  $aem_ssl_port            = $::aem_ssl_port,
  $cert_base_url           = $::cert_base_url,
  $force                   = $::force,
  $run_mode                = $::run_mode,
  $tmp_dir                 = $::tmp_dir
) {
  aem_curator::reconfig_aem{"${aem_id}: Configure AEM":
    aem_base                => $aem_base,
    aem_healthcheck_source  => $aem_healthcheck_source,
    aem_healthcheck_version => $aem_healthcheck_version,
    aem_id                  => $aem_id,
    aem_keystore_password   => $aem_keystore_password,
    aem_keystore_path       => $aem_keystore_path,
    aem_ssl_port            => $aem_ssl_port,
    cert_base_url           => $cert_base_url
    force                   => $force,
    run_mode                => $run_mode,
    tmp_dir                 => $tmp_dir,
  }
}
