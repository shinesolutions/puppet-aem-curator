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
# [*corretto_version*]
#   Amazon Corretto 21 version to install and lock, e.g. 21.0.13.1.2
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
  # Amazon Corretto rather than Oracle JDK 21, as Oracle JDK 21 updates from 21.0.13 need a commercial
  # license; 21.0.13.1.2 is the first Corretto 21 with the Java4Shell fix (CVE-2026-114938)
  $corretto_version = '21.0.13.1.2',
) {
  if $corretto_version !~ /^21(\.\d+)+$/ {
    fail("Error: Unsupported Corretto version ${corretto_version}. Supported is Amazon Corretto 21 with its full version, e.g. 21.0.13.1.2")
  }

  $corretto_package = 'java-21-amazon-corretto-devel'

  # Amazon Linux packages Corretto in its own repo, installed into an architecture-specific directory
  # (/usr/lib/jvm/java-21-amazon-corretto is a link to it, which alternatives --set doesn't take). Other
  # OSes don't package it, so Amazon's Corretto repo is added, whose RPM installs into the plain directory
  if $facts['os']['name'] == 'Amazon' {
    $java_home_path = "/usr/lib/jvm/java-21-amazon-corretto.${facts['os']['architecture']}"
    $corretto_repo = []
  } else {
    $java_home_path = '/usr/lib/jvm/java-21-amazon-corretto'
    yumrepo { 'AmazonCorretto':
      descr    => 'Amazon Corretto',
      baseurl  => 'https://yum.corretto.aws/$basearch',
      gpgkey   => 'https://yum.corretto.aws/corretto.key',
      gpgcheck => '1',
      enabled  => '1',
    }
    $corretto_repo = [Yumrepo['AmazonCorretto']]
  }
  $libjvm_content_path = "${java_home_path}/lib/server/\n"
  # On Amazon Linux this is a link to the system truststore /etc/pki/java/cacerts, which update-ca-trust
  # regenerates; Amazon's Corretto repo RPM ships its own file
  $cacert_path = "${java_home_path}/lib/security/cacerts"

  # Lock the Corretto packages (on Amazon Linux the JDK is split into -devel and -headless) with dnf
  # versionlock, so a later dnf upgrade on the host can't change the pinned version, as it couldn't
  # with the Oracle RPM, which was installed from a file rather than a repo. Locks are listed as
  # <name>-<epoch>:<version>-<release>.*
  package { 'python3-dnf-plugin-versionlock':
    ensure => 'present',
  } -> exec { 'Unlock other Amazon Corretto 21 versions':
    # A lock on another version would stop the pinned version from installing
    command  => "dnf versionlock delete 'java-21-amazon-corretto*'",
    onlyif   => "dnf -q versionlock list | grep '^java-21-amazon-corretto-' | grep -qvF ':${corretto_version}-'",
    path     => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    provider => 'shell',
  } -> package { $corretto_package:
    ensure  => $corretto_version,
    require => $corretto_repo,
  } -> exec { "Lock Amazon Corretto ${corretto_version}":
    command  => "dnf versionlock add 'java-21-amazon-corretto*'",
    unless   => "dnf -q versionlock list | grep '^java-21-amazon-corretto-devel-' | grep -qF ':${corretto_version}-'",
    path     => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    provider => 'shell',
  }

  exec { "alternatives --set  java ${java_home_path}/bin/java":
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    require => Package[$corretto_package],
  }

  file { '/usr/java':
    ensure => directory,
    mode   => '0775',
  }

  # Set "default" symlink as this is used in checks and is not created by all Java installations
  file { '/usr/java/default':
    ensure => 'link',
    target => $java_home_path,
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
    # Downloaded into ${tmp_dir}/java like install_aem_java: it used to require File[$tmp_dir],
    # which nothing declares, so the catalog failed
    archive { "${tmp_dir}/java/aem.${part}":
      ensure  => present,
      source  => "${cert_base_url}/aem.${part}",
      require => File["${tmp_dir}/java"],
    } -> java_ks { "cqse-${idx}:${cacert_path}":
      ensure      => latest,
      certificate => "${tmp_dir}/java/aem.${part}",
      # keytool takes changeit for Amazon Linux's JKS system truststore and the Corretto repo RPM's
      # own cacerts (acceptance)
      password    => 'changeit',
      path        => ['/bin','/usr/bin'],
      require     => Package[$corretto_package],
    }
  }
}
