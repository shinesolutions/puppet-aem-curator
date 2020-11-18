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
  # Support of different JDK8 versions with different binary pathes
  if Integer($jdk_version_update) >= 261 {
    $java_home_path = "/usr/java/jdk1.${jdk_version}.0_${jdk_version_update}-amd64"
  } elsif Integer($jdk_version_update) <= 162 {
    $java_home_path = "/usr/java/jdk1.${jdk_version}.0_${jdk_version_update}/jre"
  } else {
    $java_home_path = "/usr/java/jdk1.${jdk_version}.0_${jdk_version_update}-amd64/jre"
  }
  java::download { $jdk_version :
    ensure  => 'present',
    java_se => 'jdk',
    url     => "${jdk_base_url}/${jdk_filename}",
  } -> exec { "alternatives --set  java ${java_home_path}/bin/java":
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    require => Java::Download[$jdk_version],
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
      path        => ['/bin','/usr/bin'],
      require     => Java::Download[$jdk_version],
    }
  }
}
