class aem_curator::action_enable_crxde (
  $aem_instances,
  $aem_username     = $facts['aem_username'],
  $aem_password     = $facts['aem_password'],
) {

  $aem_instances.each | Integer $index, Hash $aem_instance | {
    aem_resources::enable_crxde { "${aem_instance['aem_id']}: Enable CRXDE":
      run_mode     => $aem_instance['run_mode'],
      aem_id       => $aem_instance['aem_id'],
      aem_username => $facts['aem_username'],
      aem_password => $facts['aem_password'],
    }
  }

}
