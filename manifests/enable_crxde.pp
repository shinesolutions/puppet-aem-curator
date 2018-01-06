class aem_curator::enable_crxde (
  $aem_instances,
) {

  $aem_instances.each | Integer $index, Hash $aem_instance | {
    aem_resources::enable_crxde { "${aem_instance['aem_id']}: Enable CRXDE":
      run_mode => $aem_instance['run_mode'],
      aem_id   => $aem_instance['aem_id'],
    }
  }

}
