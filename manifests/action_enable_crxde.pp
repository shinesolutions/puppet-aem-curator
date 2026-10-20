class aem_curator::action_enable_crxde (
  # getvar('::name') reads the caller's top-scope variable (e.g. FACTER_name) and gives undef
  # when it is unset, like $::name on Puppet 7; OpenVox 9's strict_variables fails on it
  $aem_instances,
  $aem_username     = getvar('::aem_username'),
  $aem_password     = getvar('::aem_password'),
) {

  $aem_instances.each | Integer $index, Hash $aem_instance | {
    aem_resources::enable_crxde { "${aem_instance['aem_id']}: Enable CRXDE":
      run_mode     => $aem_instance['run_mode'],
      aem_id       => $aem_instance['aem_id'],
      aem_username => getvar('::aem_username'),
      aem_password => getvar('::aem_password'),
    }
  }

}
