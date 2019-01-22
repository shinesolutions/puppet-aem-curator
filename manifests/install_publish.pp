# == Class: config::author
#
# Install AEM and configure for the `publish` role.
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
class aem_curator::install_publish (
  $aem_artifacts_base,
  $aem_license_base,
  $aem_base,
  $aem_healthcheck_version,
  $aem_host,
  $aem_jvm_mem_opts,
  $aem_keystore_password,
  $aem_profile,
  $aem_sample_content,
  $cert_base_url,
  $repository_volume_device,
  $repository_volume_mount_point,
  $setup_repository_volume,
  $tmp_dir,
  $aem_debug               = false,
  $aem_id                  = 'publish',
  $aem_keystore_path       = undef,
  $aem_port                = '4503',
  $aem_ssl_port            = '5433',
  $aem_jvm_opts            = [
    '-XX:+PrintGCDetails',
    '-XX:+PrintGCTimeStamps',
    '-XX:+PrintGCDateStamps',
    '-XX:+PrintTenuringDistribution',
    '-XX:+PrintGCApplicationStoppedTime',
    '-XX:+HeapDumpOnOutOfMemoryError',
  ],
  $aem_start_opts          = '',
  $post_install_sleep_secs = 120,
  $post_stop_sleep_secs    = 120,
  $puppet_conf_dir         = '/etc/puppetlabs/puppet/',
  $run_mode                = 'publish',
) {
  aem_curator::install_aem { "${aem_id}: Install AEM Publish":
    aem_artifacts_base            => $aem_artifacts_base,
    aem_license_base              => $aem_license_base,
    aem_base                      => $aem_base,
    aem_debug                     => false,
    aem_healthcheck_version       => $aem_healthcheck_version,
    aem_host                      => $aem_host,
    aem_id                        => $aem_id,
    aem_jvm_mem_opts              => $aem_jvm_mem_opts,
    aem_keystore_password         => $aem_keystore_password,
    aem_keystore_path             => $aem_keystore_path,
    aem_port                      => $aem_port,
    aem_profile                   => $aem_profile,
    aem_sample_content            => $aem_sample_content,
    aem_ssl_port                  => $aem_ssl_port,
    cert_base_url                 => $cert_base_url,
    aem_jvm_opts                  => $aem_jvm_opts,
    aem_start_opts                => $aem_start_opts,
    post_install_sleep_secs       => $post_install_sleep_secs,
    post_stop_sleep_secs          => $post_stop_sleep_secs,
    puppet_conf_dir               => '/etc/puppetlabs/puppet/',
    repository_volume_device      => $repository_volume_device,
    repository_volume_mount_point => $repository_volume_mount_point,
    run_mode                      => $run_mode,
    setup_repository_volume       => $setup_repository_volume,
    tmp_dir                       => $tmp_dir,
  }
}
