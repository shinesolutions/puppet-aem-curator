# == Class: aem_curator::install_dispatcher
#
# Install AEM and configure for the `dispatcher` role.
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
# [*apache_user*]
#   The apache user for updating the permissions to the docroot dir
#
# [*apache_group*]
#   The apache group for updating the permissions to the docroot dir
#
# === Authors
#
# Andy Wang <andy.wang@shinesolutions.com>
# James Sinclair <james.sinclair@shinesolutions.com>
#
# === Copyright
#
# Copyright © 2019 Shine Solutions Group, unless otherwise noted.
#
class aem_curator::install_dispatcher (
  $apache_module_base_url,
  $apache_module_filename,
  $apache_module_tarball,
  $apache_module_temp_dir,
  $cert_base_url,
  $cert_filename,
  $tmp_dir,
  $post_stop_sleep_secs      = 120,
  $aem_base                  = '/var',
  $setup_data_volume         = false,
  $apache_http_port          = '80',
  $apache_https_port         = '443',
  $data_volume_device        = undef,
  $data_volume_mount_point   = undef,
  $default_vhost             = true,
  $aem_id                    = 'dispatcher',
  $dispatcher_service_name   = 'httpd',
  $docroot_dir               = '/var/www/html',
  $apache_additional_modules = [],
  $apache_user               = 'apache',
  $apache_group              = 'apache'
) {

    Exec {
      cwd     => $tmp_dir,
      path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
      timeout => 0,
    }

    if $setup_data_volume {
      # Dependencies to Class 'Apache::Service' is resolved by the puppet module apache
      exec { "${aem_id}: Prepare device for the AEM Data Volume":
        command => "mkfs -t ext4 ${data_volume_device}",
      } -> file { $data_volume_mount_point:
        ensure => directory,
        mode   => '0755',
      } -> mount { $data_volume_mount_point:
        ensure   => mounted,
        device   => $data_volume_device,
        fstype   => 'ext4',
        options  => 'nofail,defaults,noatime',
        remounts => false,
        atboot   => false,
        before   => [
                      Exec["mv ${docroot_dir} ${data_volume_mount_point}/${aem_id}"],
                      Class['Apache::Service']
                    ]
      }

      # Dependencies to Package['httpd'] is resolved by the puppet module apache
      exec { "mv ${docroot_dir} ${data_volume_mount_point}/${aem_id}":
        require => [
                    Package['httpd'],
                    Mount[$data_volume_mount_point]
                  ]
      }

      exec { "${aem_id}: Fix data volume mount permissions":
        command => "chown -R ${apache_user}:${apache_group} ${data_volume_mount_point}",
        require => [
          Exec["mv ${docroot_dir} ${data_volume_mount_point}/${aem_id}"]
        ]
      }

      # Dependencies to Class 'Apache::Service' is resolved by the puppet module apache
      file { $docroot_dir:
        # Set the Docroot owner and group to apache
        # https://docs.adobe.com/docs/en/dispatcher/disp-install.html#Apache Web Server - Configure Apache Web Server for Dispatcher
        ensure  => link,
        owner   => $apache_user,
        group   => $apache_group,
        target  =>  "${data_volume_mount_point}/${aem_id}",
        replace => true,
        require => [
          Exec["${aem_id}: Fix data volume mount permissions"],
          Class['Apache']
        ],
        notify  => Class['Apache::Service']
      }
    } else {
      # Dependencies to Class 'Apache::Service' is resolved by the puppet module apache
      file { $docroot_dir:
        # Set the Docroot owner and group to apache
        # https://docs.adobe.com/docs/en/dispatcher/disp-install.html#Apache Web Server - Configure Apache Web Server for Dispatcher
        ensure  => directory,
        owner   => $apache_user,
        group   => $apache_group,
        require => Class['Apache'],
        notify  => Class['Apache::Service'],
      }
    }

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

  class { 'apache':
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
    before       => Class['aem::dispatcher']
  }

  class { '::aem::dispatcher' :
    module_file => "${apache_module_temp_dir}/${apache_module_filename}",
    require     => Archive[$apache_module_tarball]
  }

  # Dependencies to Class 'Apache::Service' is resolved by the puppet module apache
  # Dependencies to Class 'dispatcher' is resolved by the puppet module dispatcher
  tcp_conn_validator { "Ensure dispatcher is listening on http port ${apache_http_port}" :
    host      => 'localhost',
    port      => $apache_http_port,
    try_sleep => 5,
    timeout   => 60,
    require   => [
                  Class['Apache::Service'],
                  Class['::aem::dispatcher']
                  ]
  } -> tcp_conn_validator { "Ensure dispatcher is listening on https port ${apache_https_port}" :
    host      => 'localhost',
    port      => $apache_https_port,
    try_sleep => 5,
    timeout   => 60,
    require   => [
                  Class['Apache::Service'],
                  Class['::aem::dispatcher']
                  ]
    }
}
