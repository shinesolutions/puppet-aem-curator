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
  $aem_quickstart_source,
  $aem_license_source,
  $aem_artifacts_base,
  $aem_healthcheck_version,
  $aem_base,
  $aem_sample_content,
  $aem_jvm_mem_opts,
  $setup_repository_volume,
  $repository_volume_device,
  $repository_volume_mount_point,
  $aem_keystore_password,
  $cert_base_url,
  $jvm_opts = [
    '-XX:+PrintGCDetails',
    '-XX:+PrintGCTimeStamps',
    '-XX:+PrintGCDateStamps',
    '-XX:+PrintTenuringDistribution',
    '-XX:+PrintGCApplicationStoppedTime',
    '-XX:+HeapDumpOnOutOfMemoryError',
  ],
  $sleep_secs        = 120,
  $aem_keystore_path = undef,
  $aem_debug         = false,
  $puppet_conf_dir   = '/etc/puppetlabs/puppet/',
  $aem_port          = '4502',
  $aem_ssl_port      = '5432',
  $run_mode          = 'author',
  $aem_id            = 'author',
) {
  aem_curator::install_aem { "${aem_id}: Install AEM Author":
    tmp_dir                       => $tmp_dir,
    aem_host                      => $aem_host,
    aem_quickstart_source         => $aem_quickstart_source,
    aem_license_source            => $aem_license_source,
    aem_artifacts_base            => $aem_artifacts_base,
    aem_healthcheck_version       => $aem_healthcheck_version,
    aem_base                      => $aem_base,
    aem_sample_content            => $aem_sample_content,
    aem_jvm_mem_opts              => $aem_jvm_mem_opts,
    setup_repository_volume       => $setup_repository_volume,
    repository_volume_device      => $repository_volume_device,
    repository_volume_mount_point => $repository_volume_mount_point,
    aem_keystore_path             => $aem_keystore_path,
    aem_keystore_password         => $aem_keystore_password,
    cert_base_url                 => $cert_base_url,
    sleep_secs                    => $sleep_secs,
    jvm_opts                      => $jvm_opts,
    aem_debug                     => false,
    puppet_conf_dir               => '/etc/puppetlabs/puppet/',
    run_mode                      => $run_mode,
    aem_port                      => $aem_port,
    aem_ssl_port                  => $aem_ssl_port,
    aem_id                        => $aem_id,
  }
}
