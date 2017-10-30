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
  $aem_port = '4502',
  $aem_ssl_port = '5432',
  $aem_id = 'aem',
) {
  class { 'aem_curator::install_aem':
    aem_role     => 'author',
    aem_port     => $aem_port,
    aem_ssl_port => $aem_ssl_port,
    aem_id       => $aem_id,
  }
}
