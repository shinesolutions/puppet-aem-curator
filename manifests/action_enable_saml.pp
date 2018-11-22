class aem_curator::action_enable_saml (
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
  $tmp_dir                        = $::tmp_dir,
  $use_encryption                 = $::use_encryption,
  $user_id_attribute              = $::user_id_attribute,
  $user_intermediate_path         = $::user_intermediate_path
) {

  if !defined(File["${tmp_dir}/SAML"]) {
      file { "${tmp_dir}/SAML":
        ensure => directory,
    }
  }

  if $file {
    archive { "${tmp_dir}/SAML/saml_certificate.crt":
      ensure => present,
      source => $file,
    }
  }

  aem_resources::enable_saml { "${aem_id}: Action Enable SAML authentication":
    add_group_memberships          => $add_group_memberships,
    aem_id                         => $aem_id,
    aem_username                   => $aem_username,
    aem_password                   => $aem_password,
    assertion_consumer_service_url => $assertion_consumer_service_url,
    clock_tolerance                => $clock_tolerance,
    create_user                    => $create_user,
    default_groups                 => $default_groups,
    default_redirect_url           => $default_redirect_url,
    digest_method                  => $digest_method,
    file                           => "${tmp_dir}/SAML/saml_certificate.crt",
    group_membership_attribute     => $group_membership_attribute,
    handle_logout                  => $handle_logout,
    idp_cert_alias                 => $idp_cert_alias,
    idp_http_redirect              => $idp_http_redirect,
    idp_url                        => $idp_url,
    key_store_password             => $key_store_password,
    logout_url                     => $logout_url,
    name_id_format                 => $name_id_format,
    path                           => $path,
    service_provider_entity_id     => $service_provider_entity_id,
    service_ranking                => $service_ranking,
    sp_private_key_alias           => $sp_private_key_alias,
    synchronize_attributes         => $synchronize_attributes,
    use_encryption                 => $use_encryption,
    user_id_attribute              => $user_id_attribute,
    serial                         => $serial,
    signature_method               => $signature_method,
    tmp_dir                        => $tmp_dir,
    user_intermediate_path         => $user_intermediate_path
  }

  if $file {
    file { "${tmp_dir}/SAML/saml_certificate.crt":
      ensure => absent
    }
  }
}
