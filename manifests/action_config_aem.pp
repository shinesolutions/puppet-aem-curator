
class aem_curator::action_config_aem (
  $aem_base                   = $facts['aem_base'],
  $aem_healthcheck_source     = $facts['aem_healthcheck_source'],
  $aem_healthcheck_version    = $facts['aem_healthcheck_version'],
  $aem_id                     = $facts['aem_id'],
  $aem_keystore_password      = $facts['aem_keystore_password'],
  $aem_keystore_path          = $facts['aem_keystore_path'],
  $aem_ssl_method             = $facts['aem_ssl_method'],
  $aem_ssl_port               = $facts['aem_ssl_port'],
  $cert_base_url              = $facts['cert_base_url'],
  $enable_create_system_users = true,
  $enable_truststore_removal  = true,
  $force                      = str2bool($facts['force']),
  $run_mode                   = $facts['run_mode'],
  $tmp_dir                    = $facts['tmp_dir']
) {

  assert_type(Boolean, $force)
  assert_type(Boolean, $enable_create_system_users)
  assert_type(Boolean, $enable_truststore_removal)

  # Action manifest currently does not support changing the existing
  # system user password
  aem_curator::reconfig_aem{"${aem_id}: Configure AEM":
    aem_base                   => $aem_base,
    aem_healthcheck_source     => $aem_healthcheck_source,
    aem_healthcheck_version    => $aem_healthcheck_version,
    aem_id                     => $aem_id,
    aem_keystore_password      => $aem_keystore_password,
    aem_keystore_path          => $aem_keystore_path,
    aem_ssl_method             => $aem_ssl_method,
    aem_ssl_port               => $aem_ssl_port,
    cert_base_url              => $cert_base_url,
    enable_create_system_users => $enable_create_system_users,
    enable_truststore_removal  => $enable_truststore_removal,
    force                      => $force,
    run_mode                   => $run_mode,
    tmp_dir                    => $tmp_dir,
  }
}
