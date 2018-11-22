define aem_curator::config_authorizable_keystore_certificate_chain (
  $certificate_chain_file_path,
  $private_key_file_path,
  $private_key_alias,
  $aem_id                                                = 'aem',
  $aem_username                                          = undef,
  $aem_password                                          = undef,
  $authorizable_id                                       = undef,
  $enable_authorizable_keystore_certificate_chain_upload = false,
  $intermediate_path                                     = undef,
  $authorizable_keystore_password                        = undef,
  $tmp_dir                                               = '/tmp',
) {
  if $enable_authorizable_keystore_certificate_chain_upload {
    archive { "${tmp_dir}/SAML/private_key.der":
      ensure => present,
      source => $private_key_file_path,
    }

    archive { "${tmp_dir}/SAML/certificate_chain.crt":
      ensure => present,
      source => $certificate_chain_file_path,
    }

    $params_add_keystore_certificate = {
      'aem_resources::add_authorizable_keystore_certificate' => {
        certificate_chain_file_path => "${tmp_dir}/SAML/certificate_chain.crt"
      }
    }

    $default_params_add_keystore_certificate = {
      aem_id                => $aem_id,
      aem_username          => $aem_username,
      aem_password          => $aem_password,
      authorizable_id       => $authorizable_id,
      intermediate_path     => $intermediate_path,
      private_key_file_path => "${tmp_dir}/SAML/private_key.der",
      private_key_alias     => $private_key_alias,
    }

    create_resources(
      'aem_resources::add_authorizable_keystore_certificate',
      $params_add_keystore_certificate,
      $default_params_add_keystore_certificate
    )
  }
}
