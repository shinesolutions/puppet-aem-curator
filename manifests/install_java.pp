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
# Copyright © 2021 Shine Solutions Group Group, unless otherwise noted.
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
  # Split JDK filename to determine JDK Major Version
  $jdk_filename_splitted = split($jdk_filename, '-')
  # Case to Setup variables per JDK Version
  case $jdk_filename_splitted[1] {
    /^8/: {
      # Automation to determine JDK Version via default filename
      # Splitting JDK File Name jdk-8u221-linux-x64.rpm to [8, 221]
      $jdk_version = $jdk_filename_splitted[1]
      $jdk_version_splitted = split($jdk_version, 'u')
      $jdk_version_major = $jdk_version_splitted[0]
      $jdk_version_update = $jdk_version_splitted[1]
      # Support of different JDK8 versions with different binary pathes
      if Integer($jdk_version_update) >= 261 {
        $java_home_path = "/usr/java/jdk1.${jdk_version_major}.0_${jdk_version_update}-amd64"
        $libjvm_content_path = "${java_home_path}/jre/lib/amd64/server/\n"
        $cacert_path = "${java_home_path}/jre/lib/security/cacerts"
      } elsif Integer($jdk_version_update) <= 162 {
        $java_home_path = "/usr/java/jdk1.${jdk_version_major}.0_${jdk_version_update}/jre"
        $libjvm_content_path = "${java_home_path}/lib/amd64/server/\n"
        $cacert_path = "${java_home_path}/lib/security/cacerts"
      } else {
        $java_home_path = "/usr/java/jdk1.${jdk_version_major}.0_${jdk_version_update}-amd64/jre"
        $libjvm_content_path = "${java_home_path}/lib/amd64/server/\n"
        $cacert_path = "${java_home_path}/lib/security/cacerts"
      }
    }
    /^11/:
    {
      # Automation to determine JDK Version via default filename
      # Splitting JDK File Name jdk-11.0.7_linux-x64_bin.rpm
      # to receive JDK version 11.0.7
      $jdk_version_raw = split($jdk_filename_splitted[1], '_')
      $jdk_version = $jdk_version_raw[0]
      $java_home_path = "/usr/java/jdk-${jdk_version}"
      $libjvm_content_path = "${java_home_path}/lib/server/\n"
      $cacert_path = "${java_home_path}/lib/security/cacerts"
    }
    default: {
      fail('Error: Unknown Java Version. Supported java versions are : ( 8 | 11 )')
    }
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
    content => $libjvm_content_path,
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
    } -> java_ks { "cqse-${idx}:${cacert_path}":
      ensure      => latest,
      certificate => "${tmp_dir}/aem.${part}",
      password    => 'changeit',
      path        => ['/bin','/usr/bin'],
      require     => Java::Download[$jdk_version],
    }
  }
}
