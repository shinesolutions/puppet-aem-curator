class aem_curator::action_enable_saml (
  $tmp_dir,
  $add_group_memberships          = $::add_group_memberships,
  $aem_id                         = $::aem_id,
  $aem_username                   = $::aem_username,
  $aem_password                   = $::aem_password,
  $assertion_consumer_service_url = $::assertion_consumer_service_url,
  $clock_tolerance                = $::clock_tolerance,
  $create_user                    = $::create_user,
  $default_groups                 = $::default_groups,
  $default_redirect_url           = $::default_redirect_url,
  $digest_method                  = $::digest_method,
  $file                           = $::file,
  $group_membership_attribute     = $::group_membership_attribute,
  $handle_logout                  = $::handle_logout,
  $idp_cert_alias                 = $::idp_cert_alias,
  $idp_http_redirect              = $::idp_http_redirect,
  $idp_url                        = $::idp_url,
  $key_store_password             = $::key_store_password,
  $logout_url                     = $::logout_url,
  $name_id_format                 = $::name_id_format,
  $path                           = $::path,
  $service_provider_entity_id     = $::service_provider_entity_id,
  $service_ranking                = $::service_ranking,
  $serial                         = $::serial,
  $signature_method               = $::signature_method,
  $sp_private_key_alias           = $::sp_private_key_alias,
  $synchronize_attributes         = $::synchronize_attributes,
  $use_encryption                 = $::use_encryption,
  $user_id_attribute              = $::user_id_attribute,
  $user_intermediate_path         = $::user_intermediate_path
) {

  $_add_group_memberships = if empty($add_group_memberships) {
    undef
  } else {
    $add_group_memberships
  }

  $_aem_id = if empty($aem_id) {
    undef
  } else {
    $aem_id
  }

  $_assertion_consumer_service_url = if empty($assertion_consumer_service_url) {
    undef
  } else {
    $assertion_consumer_service_url
  }

  $_clock_tolerance = if empty($clock_tolerance) {
    undef
  } else {
    $clock_tolerance
  }

  $_create_user = if empty($create_user) {
    undef
  } else {
    $create_user
  }

  $_default_groups = if empty($default_groups) {
    undef
  } else {
    $default_groups
  }

  $_default_redirect_url = if empty($default_redirect_url) {
    undef
  } else {
    $default_redirect_url
  }

  $_digest_method = if empty($digest_method) {
    undef
  } else {
    $digest_method
  }

  $_file =  if empty($file) {
    $enable_saml_certificate_upload = false
    undef
  } else {
    $enable_saml_certificate_upload = true
    $file
  }

  $_group_membership_attribute = if empty($group_membership_attribute) {
    undef
  } else {
    $group_membership_attribute
  }

  $_handle_logout = if empty($handle_logout) {
    undef
  } else {
    $handle_logout
  }

  $_idp_cert_alias = if empty($idp_cert_alias) {
    undef
  } else {
    $idp_cert_alias
  }

  $_idp_http_redirect = if empty($idp_http_redirect) {
    undef
  } else {
    $idp_http_redirect
  }

  $_idp_url = if empty($idp_url) {
    undef
  } else {
    $idp_url
  }

  $_key_store_password = if empty($key_store_password) {
    undef
  } else {
    $key_store_password
  }

  $_logout_url = if empty($logout_url) {
    undef
  } else {
    $logout_url
  }

  $_name_id_format = if empty($name_id_format) {
    undef
  } else {
    $name_id_format
  }

  $_path = if empty($path) {
    undef
  } else {
    $path
  }

  $_serial = if empty($serial) {
    undef
  } else {
    $serial
  }

  $_service_provider_entity_id = if empty($service_provider_entity_id) {
    undef
  } else {
    $service_provider_entity_id
  }

  $_service_ranking = if empty($service_ranking) {
    undef
  } else {
    $service_ranking
  }

  $_signature_method = if empty($signature_method) {
    undef
  } else {
    $signature_method
  }

  $_sp_private_key_alias = if empty($sp_private_key_alias) {
    undef
  } else {
    $sp_private_key_alias
  }

  $_synchronize_attributes = if empty($synchronize_attributes) {
    undef
  } else {
    $synchronize_attributes
  }

  $_use_encryption = if empty($use_encryption) {
    undef
  } else {
    $use_encryption
  }

  $_user_id_attribute = if empty($user_id_attribute) {
    undef
  } else {
    $user_id_attribute
  }

  $_user_intermediate_path = if empty($user_intermediate_path) {
    undef
  } else {
    $user_intermediate_path
  }

  $saml_configuration = {
    add_group_memberships          => $_add_group_memberships,
    assertion_consumer_service_url => $_assertion_consumer_service_url,
    clock_tolerance                => $_clock_tolerance,
    create_user                    => $_create_user,
    default_groups                 => $_default_groups,
    default_redirect_url           => $_default_redirect_url,
    digest_method                  => $_digest_method,
    file                           => $_file,
    group_membership_attribute     => $_group_membership_attribute,
    handle_logout                  => $_handle_logout,
    idp_cert_alias                 => $_idp_cert_alias,
    idp_http_redirect              => $_idp_http_redirect,
    idp_url                        => $_idp_url,
    key_store_password             => $_key_store_password,
    logout_url                     => $_logout_url,
    name_id_format                 => $_name_id_format,
    path                           => $_path,
    serial                         => $_serial,
    service_provider_entity_id     => $_service_provider_entity_id,
    service_ranking                => $_service_ranking,
    signature_method               => $_signature_method,
    sp_private_key_alias           => $_sp_private_key_alias,
    synchronize_attributes         => $_synchronize_attributes,
    use_encryption                 => $_use_encryption,
    user_id_attribute              => $_user_id_attribute,
    user_intermediate_path         => $_user_intermediate_path,
  }

  Exec {
    cwd     => $tmp_dir,
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    timeout => 0,
  }

  if !defined(File[$tmp_dir]) {
      file { $tmp_dir:
        ensure => directory,
      }
    }

  aem_curator::config_saml { "${_aem_id}: Enable SAML":
    aem_id                                                => $_aem_id,
    aem_username                                          => $aem_username,
    aem_password                                          => $aem_password,
    enable_saml                                           => true,
    enable_authorizable_keystore_creation                 => false,
    saml_configuration                                    => $saml_configuration,
    enable_saml_certificate_upload                        => $enable_saml_certificate_upload,
    enable_authorizable_keystore_certificate_chain_upload => false,
    tmp_dir                                               => $tmp_dir,
  }
}
