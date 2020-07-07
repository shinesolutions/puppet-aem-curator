# == Class: config::java
#
# Configuration AEM Java AMIs
#
# === Parameters
#
# [*cert_base_url*]
#   Base URL (supported by the puppet-archive module) to download the X.509
#   certificate and private key to be used with Apache.
#
# [*tmp_dir*]
#   A temporary directory used to store the X.509 certificate and private key
#   while building the PEM file for Apache.
#
# === Authors
#
# James Sinclair <james.sinclair@shinesolutions.com>
#
# === Copyright
#
# Copyright © 2017 Shine Solutions Group, unless otherwise noted.
#
class aem_curator::install_aem_java (
  $cert_base_url,
  $tmp_dir,
  $jdk_base_url,
  $jdk_filename       = 'jdk-11.0.7_linux-x64_bin.rpm',
  $jdk_version        = '11.0.7',
) {

    java::download { $jdk_version :
      ensure  => 'present',
      java_se => 'jdk',
      url     => "${jdk_base_url}/${jdk_filename}",
    }

  file { '/etc/ld.so.conf.d/99-libjvm.conf':
    ensure  => present,
    content => "/usr/java/latest/lib/server\n",
    notify  => Exec['/sbin/ldconfig'],
    require => Java::Download[$jdk_version],
    }

  exec { '/sbin/ldconfig':
    refreshonly => true,
  }

  file { "${tmp_dir}/java":
    ensure => directory,
    mode   => '0700',
  }

  [ 'cert' ].each |$idx, $part| {
    archive { "${tmp_dir}/aem.${part}":
      ensure  => present,
      source  => "${cert_base_url}/aem.${part}",
      require => [
        File["${tmp_dir}/java"],
        Java::Download[$jdk_version],
        ],
        } ->  java_ks { "cqse-${idx}:/usr/java/latest/lib/security/cacerts":
          ensure      => latest,
          certificate => "${tmp_dir}/aem.${part}",
          password    => 'changeit',
          path        => ['/bin','/usr/bin'],
      }
    }
  }
