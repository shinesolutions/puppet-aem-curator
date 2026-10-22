
class aem_curator::action_config_aem (
  # getvar('::name') reads the caller's top-scope variable (e.g. FACTER_name) and gives undef
  # when it is unset, like $::name on Puppet 7; OpenVox 9's strict_variables fails on it
  $aem_base                   = getvar('::aem_base'),
  $aem_healthcheck_source     = getvar('::aem_healthcheck_source'),
  $aem_healthcheck_version    = getvar('::aem_healthcheck_version'),
  $aem_id                     = getvar('::aem_id'),
  $aem_keystore_password      = getvar('::aem_keystore_password'),
  $aem_keystore_path          = getvar('::aem_keystore_path'),
  $aem_ssl_method             = getvar('::aem_ssl_method'),
  $aem_ssl_port               = getvar('::aem_ssl_port'),
  $cert_base_url              = getvar('::cert_base_url'),
  $enable_create_system_users = true,
  $enable_truststore_removal  = true,
  $force                      = str2bool(getvar('::force')),
  $run_mode                   = getvar('::run_mode'),
  $tmp_dir                    = getvar('::tmp_dir')
) {

  # validate_bool was removed in stdlib 9; assert_type(Boolean) is the same check
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
