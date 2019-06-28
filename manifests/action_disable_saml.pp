class aem_curator::action_disable_saml (
  $aem_id       = $::aem_id,
  $aem_username = $::aem_username,
  $aem_password = $::aem_password,
) {

  $_aem_id = if empty($aem_id) {
    undef
  } else {
    $aem_id
  }

  aem_resources::disable_saml { 'Disable SAML Authentication':
    aem_id       => $aem_id,
    aem_username => $aem_username,
    aem_password => $aem_password
  }

}
