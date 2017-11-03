define aem_curator::install_aem62_sp1_cfp5(
  $tmp_dir,
  $aem_artifacts_base,
  $aem_id = 'aem',
) {

  aem_curator::install_aem_package { "${aem_id}: Install hotfix 11490":
    tmp_dir        => $tmp_dir,
    group          => 'adobe/cq620/hotfix',
    name           => 'cq-6.2.0-hotfix-11490',
    version        => '1.2',
    artifacts_base => $aem_artifacts_base,
    aem_id         => $aem_id,
  } -> aem_curator::install_aem_package { "${aem_id}: Install hotfix 12785":
    tmp_dir                     => $tmp_dir,
    group                       => 'adobe/cq620/hotfix',
    name                        => 'cq-6.2.0-hotfix-12785',
    version                     => '7.0',
    restart                     => true,
    post_install_sleep_secs     => 150,
    post_login_page_ready_sleep => 30,
    artifacts_base              => $aem_artifacts_base,
    aem_id                      => $aem_id,
  } -> aem_curator::install_aem_package { "${aem_id}: Install service pack 1":
    tmp_dir        => $tmp_dir,
    file_name      => 'AEM-6.2-Service-Pack-1-6.2.SP1.zip',
    name           => 'aem-service-pkg',
    group          => 'adobe/cq620/servicepack',
    version        => '6.2.SP1',
    artifacts_base => $aem_artifacts_base,
    aem_id         => $aem_id,
  } -> aem_curator::install_aem_package { "${aem_id}: Install cumulative fix pack 5":
    tmp_dir                 => $tmp_dir,
    file_name               => 'AEM-6.2-SP1-CFP3-5.0.zip',
    name                    => 'cq-6.2.0-sp1-cfp',
    group                   => 'adobe/cq620/cumulativefixpack',
    post_install_sleep_secs => 900,
    version                 => '5.0',
    artifacts_base          => $aem_artifacts_base,
    aem_id                  => $aem_id,
  } -> aem_curator::install_aem_package { "${aem_id}: Install hotfix 15607":
    tmp_dir        => $tmp_dir,
    group          => 'adobe/cq620/hotfix',
    name           => 'cq-6.2.0-hotfix-15607',
    version        => '1.0',
    artifacts_base => $aem_artifacts_base,
    aem_id         => $aem_id,
  }

}
