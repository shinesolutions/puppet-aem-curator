define aem_curator::config_saml (
  $aem_id                                                = 'aem',
  $aem_username                                          = undef,
  $aem_password                                          = undef,
  $aem_system_users                                      = {},
  $enable_saml                                           = false,
  $enable_authorizable_keystore_creation                 = false,
  $saml_configuration                                    = {},
  $enable_saml_certificate_upload                        = false,
  $enable_authorizable_keystore_certificate_chain_upload = false,
  $tmp_dir                                               = '/tmp',
) {
  if $enable_saml {
    # Create temp directory
    if !defined(File["${tmp_dir}/SAML"]) {
        file { "${tmp_dir}/SAML":
          ensure => directory,
        }
      }

    # Add certificate to AEM Truststore
    if $enable_saml_certificate_upload {
      aem_curator::config_truststore_certificate { "${aem_id}: Add SAML certificate to AEM Truststore":
        add_certificate => $enable_saml_certificate_upload,
        aem_id          => $aem_id,
        aem_username    => $aem_username,
        aem_password    => $aem_password,
        file            => $saml_configuration['file']
        force           => true
        tmp_dir         => $tmp_dir
      }
    }

    # Add certificate chain to AEM Keystore for user authentication-service
    if $enable_authorizable_keystore_certificate_chain_upload {
      # Create AEM Keystore for user authentication-service
      if $enable_authorizable_keystore_creation{
        aem_curator::config_authorizable_keystore { "${aem_id}: Create Keystore for user authentication-service":
          aem_id                                => $aem_id,
          aem_username                          => $aem_username,
          aem_password                          => $aem_password,
          enable_authorizable_keystore_creation => $enable_authorizable_keystore_creation,
          authorizable_id                       => $aem_system_users[authentication-service][name],
          intermediate_path                     => $aem_system_users[authentication-service][path],
          authorizable_keystore_password        => $aem_system_users[authentication-service][authorizable_keystore][password],
        }
      }

      # Add certificate chain to AEM Keystore for user authentication-service
      aem_curator::config_authorizable_keystore_certificate_chain { "${aem_id}: Add certificate chain to Keystore for user authentication-service":
        aem_id                                                => $aem_id,
        aem_username                                          => $aem_username,
        aem_password                                          => $aem_password,
        enable_authorizable_keystore_certificate_chain_upload => $enable_authorizable_keystore_certificate_chain_upload,
        authorizable_id                                       => $aem_system_users[authentication-service][name],
        intermediate_path                                     => $aem_system_users[authentication-service][path],
        authorizable_keystore_password                        => $aem_system_users[authentication-service][authorizable_keystore][password],
        private_key_alias                                     => $aem_system_users[authentication-service][authorizable_keystore][private_key_alias]
        private_key_file_path                                 => $aem_system_users[authentication-service][authorizable_keystore][private_key],
        certificate_chain_file_path                           => $aem_system_users[authentication-service][authorizable_keystore][certificate],
        tmp_dir                                               => $tmp_dir
      }
    }

    $params_enable_saml = {
      'aem_resources::enable_saml' =>
        $saml_configuration
    }

    $default_params_enable_saml = {
      aem_id       => $aem_id,
      aem_username => $aem_username,
      aem_password => $aem_password,
      tmp_dir      => $tmp_dir
    }

    create_resources(
      'aem_resources::enable_saml',
      $params_enable_saml,
      $default_params_enable_saml
    )

    # Remove created temp directory
    exec { "${aem_id}: Clean SAML temp directory":
      command => "rm -fr ${tmp_dir}/SAML"
    }
  }
}
