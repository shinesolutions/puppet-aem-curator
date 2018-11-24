define aem_curator::config_authorizable_keystore (
  $aem_id                                = 'aem',
  $aem_username                          = undef,
  $aem_password                          = undef,
  $authorizable_id                       = undef,
  $enable_authorizable_keystore_creation = false,
  $intermediate_path                     = undef,
  $authorizable_keystore_password        = undef,
) {
  if $enable_authorizable_keystore_creation {
    aem_resources::create_authorizable_keystore { "${aem_id}: Create a new AEM Keystore for user ${$authorizable_id}":
      aem_id                         => $aem_id,
      aem_username                   => $aem_username,
      aem_password                   => $aem_password,
      authorizable_id                => $authorizable_id,
      intermediate_path              => $intermediate_path,
      authorizable_keystore_password => $authorizable_keystore_password,
    }
  }
}
