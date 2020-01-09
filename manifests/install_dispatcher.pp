# == Class: config::author
#
# Install AEM and configure for the `publisher` role.
#
# === Parameters
#
# [*cert_base_url*]
#   Base URL (supported by the puppet-archive module) to download the X.509
#   certificate and private key to be used with Apache.
#
# [*cert_filename*]
#   The local path and filename to save the X.509 certificate and private key
#   to be used with Apache.
#
# [*tmp_dir*]
#   A temporary directory used to store the X.509 certificate and private key
#   while building the PEM file for Apache.
#
# [*apache_module_base_url*]
#   Base URL (supported by the puppet-archive module) to download the archive
#   containing the AEM Dispatcher Apache module.
#
# [*apache_module_tarball*]
#   The name of the archive containing the AEM Dispatcher Apache module.
#
# [*apache_module_filename*]
#   The name of the AEM Dispatcher Apache module shared object file stored
#   inside the archive.
#
# [*apache_module_temp_dir*]
#   A temporary directory used to store the AEM Dispatcher Apache module while
#   installing it.
#
# [*apache_additional_modules*]
#   List of additional modules that will be installed with apache
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
class aem_curator::install_dispatcher (
  $apache_module_base_url,
  $apache_module_filename,
  $apache_module_tarball,
  $apache_module_temp_dir,
  $cert_base_url,
  $cert_filename,
  $tmp_dir,
  $apache_http_port  = '80',
  $apache_https_port = '443',
  $default_vhost     = true,
  $aem_id            = 'dispatcher',
  $apache_additional_modules = [],
) {

  # Prepare AEM certificate
  concat { $cert_filename:
    mode  => '0600',
    order => 'numeric',
  }

  file { "${tmp_dir}/${aem_id}":
    ensure => directory,
    mode   => '0700',
  }

  [ 'key', 'cert' ].each |$idx, $part| {
    archive { "${tmp_dir}/${aem_id}/aem.${part}":
      ensure  => present,
      source  => "${cert_base_url}/aem.${part}",
      require => File["${tmp_dir}/${aem_id}"],
    } -> concat::fragment { "${cert_filename}:${part}":
      target => $cert_filename,
      source => "${tmp_dir}/${aem_id}/aem.${part}",
      order  => $idx,
    }
  }

  apache::listen { $apache_http_port: }
  apache::listen { $apache_https_port: }

  class { '::apache':
    default_vhost => $default_vhost
  }
  $apache_base_module_classes = [
    '::apache::mod::ssl',
    '::apache::mod::headers',
    '::apache::mod::proxy',
    '::apache::mod::proxy_http',
    '::apache::mod::proxy_connect',
  ]

  $apache_module_classes = unique($apache_base_module_classes + $apache_additional_modules)

  class { $apache_module_classes: }

  archive { $apache_module_tarball:
    source       => "${apache_module_base_url}/${apache_module_tarball}",
    path         => "${apache_module_temp_dir}/${apache_module_tarball}",
    extract      => true,
    extract_path => $apache_module_temp_dir,
  }

  class { '::aem::dispatcher' :
    module_file => "${apache_module_temp_dir}/${apache_module_filename}",
  } -> file { '/var/www/html':
    # Set the Docroot owner and group to apache
    # https://docs.adobe.com/docs/en/dispatcher/disp-install.html#Apache Web Server - Configure Apache Web Server for Dispatcher
    ensure => directory,
    owner  => 'apache',
    group  => 'apache',
  } -> tcp_conn_validator { "Ensure dispatcher is listening on http port ${apache_http_port}" :
    host      => 'localhost',
    port      => $apache_http_port,
    try_sleep => 5,
    timeout   => 60,
  } -> tcp_conn_validator { "Ensure dispatcher is listening on https port ${apache_https_port}" :
    host      => 'localhost',
    port      => $apache_https_port,
    try_sleep => 5,
    timeout   => 60,
  }
}
