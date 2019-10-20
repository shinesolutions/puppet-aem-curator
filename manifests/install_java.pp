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
class aem_curator::install_java (
  $cert_base_url,
  $tmp_dir,
  $jdk_base_url,
  $jdk_filename       = 'jdk-8u221-linux-x64.rpm',
  $jdk_version        = '8',
  $jdk_version_update = '221',
  $jdk_version_build  = '',
  $jdk_format         = 'rpm',
) {

  class { 'oracle_java':
    download_url   => $jdk_base_url,
    filename       => $jdk_filename,
    version        => "${jdk_version}u${jdk_version_update}",
    build          => $jdk_version_build,
    type           => 'jdk',
    format         => $jdk_format,
    check_checksum => false,
  }

  file { '/etc/ld.so.conf.d/99-libjvm.conf':
    ensure  => present,
    content => "/usr/java/latest/jre/lib/amd64/server\n",
    notify  => Exec['/sbin/ldconfig'],
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
      require => File[$tmp_dir],
    } -> java_ks { "cqse-${idx}:/usr/java/default/jre/lib/security/cacerts":
      ensure      => latest,
      certificate => "${tmp_dir}/aem.${part}",
      password    => 'changeit',
    }
  }
}
