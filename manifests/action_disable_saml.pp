class aem_curator::action_disable_saml (
  $aem_id       = $::aem_id,
  $aem_username = $::aem_username,
  $aem_password = $::aem_password,
) {

  aem_resources::disable_saml { 'Disable SAML Authentication':
    aem_id       => $aem_id,
    aem_username => $aem_username,
    aem_password => $aem_password
  }

}
