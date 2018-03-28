class aem_curator::action_disable_crxde (
  $aem_instances,
  $aem_username     = $::aem_username,
  $aem_password     = $::aem_password,
) {

  $aem_instances.each | Integer $index, Hash $aem_instance | {
    aem_resources::disable_crxde { "${aem_instance['aem_id']}: Disable CRXDE":
      run_mode     => $aem_instance['run_mode'],
      aem_id       => $aem_instance['aem_id'],
      aem_username => $::aem_username,
      aem_password => $::aem_password,
    }
  }

}
