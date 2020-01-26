# == Class: config::author
#
# Install AEM and configure for the `author` role.
#
# === Parameters
#
# [*aem_port*]
#   TCP port AEM will listen on.
#
# [*aem_ssl_port*]
#   SSL port AEM will listen on.
#
# === Authors
#
# Andy Wang <andy.wang@shinesolutions.com>
# James Sinclair <james.sinclair@shinesolutions.com>
#
# === Copyright
#
# Copyright © 2017 Shine Solutions Group, unless otherwise noted.
#
class aem_curator::install_author (
  $tmp_dir,
  $aem_host,
  $aem_profile,
  $aem_artifacts_base,
  $aem_license_base,
  $aem_healthcheck_version,
  $aem_base,
  $aem_sample_content,
  $aem_jvm_mem_opts,
  $setup_repository_volume,
  $data_volume_device,
  $data_volume_mount_point,
  $aem_keystore_password,
  $cert_base_url,
  $aem_debug_port          = undef,
  $aem_debug               = false,
  $aem_healthcheck_source  = undef,
  $aem_id                  = 'author',
  $aem_keystore_path       = undef,
  $aem_port                = '4502',
  $aem_ssl_port            = '5432',
  $aem_jvm_opts            = [
    '-XX:+PrintGCDetails',
    '-XX:+PrintGCTimeStamps',
    '-XX:+PrintGCDateStamps',
    '-XX:+PrintTenuringDistribution',
    '-XX:+PrintGCApplicationStoppedTime',
    '-XX:+HeapDumpOnOutOfMemoryError',
  ],
  $aem_osgi_configs        = undef,
  $post_install_sleep_secs = 120,
  $post_stop_sleep_secs    = 120,
  $puppet_conf_dir         = '/etc/puppetlabs/puppet/',
  $run_modes               = [],
) {
  aem_curator::install_aem { "${aem_id}: Install AEM Author":
    aem_artifacts_base      => $aem_artifacts_base,
    aem_license_base        => $aem_license_base,
    aem_base                => $aem_base,
    aem_debug               => false,
    aem_healthcheck_version => $aem_healthcheck_version,
    aem_healthcheck_source  => $aem_healthcheck_source,
    aem_host                => $aem_host,
    aem_id                  => $aem_id,
    aem_type                => 'author',
    aem_jvm_mem_opts        => $aem_jvm_mem_opts,
    aem_keystore_password   => $aem_keystore_password,
    aem_keystore_path       => $aem_keystore_path,
    aem_port                => $aem_port,
    aem_debug_port          => $aem_debug_port,
    aem_profile             => $aem_profile,
    aem_sample_content      => $aem_sample_content,
    aem_ssl_port            => $aem_ssl_port,
    cert_base_url           => $cert_base_url,
    aem_jvm_opts            => $aem_jvm_opts,
    aem_osgi_configs        => $aem_osgi_configs,
    post_install_sleep_secs => $post_install_sleep_secs,
    post_stop_sleep_secs    => $post_stop_sleep_secs,
    puppet_conf_dir         => '/etc/puppetlabs/puppet/',
    data_volume_device      => $data_volume_device,
    data_volume_mount_point => $data_volume_mount_point,
    run_modes               => $run_modes,
    setup_repository_volume => $setup_repository_volume,
    tmp_dir                 => $tmp_dir,
  }
}
