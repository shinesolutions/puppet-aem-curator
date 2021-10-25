define aem_curator::config_aem_development_bundles (
  $aem_id,
  $run_mode,
  $enable_development_bundles = false,
) {

  validate_bool($enable_development_bundles)

  if $enable_development_bundles == true {
    aem_resources::enable_development_bundles { "${aem_id}: Enable Development bundles":
      aem_id   => $aem_id,
      run_mode => $run_mode,
    }
  }

}
