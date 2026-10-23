class aem_curator::action_disable_saml (
  # getvar('::name') reads the caller's top-scope variable (e.g. FACTER_name) and gives undef
  # when it is unset, like $::name on Puppet 7; OpenVox 9's strict_variables fails on it
  $aem_id       = getvar('::aem_id'),
  $aem_username = getvar('::aem_username'),
  $aem_password = getvar('::aem_password'),
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
