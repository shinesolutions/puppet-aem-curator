define aem_curator::config_aem_crxde (
  $aem_id,
  $run_mode,
  $enable_crxde = false,
) {

  assert_type(Boolean, $enable_crxde)

  if $enable_crxde == true {
    aem_resources::enable_crxde { "${aem_id}: Enable CRXDE":
      aem_id   => $aem_id,
      run_mode => $run_mode,
    }
  }

}
