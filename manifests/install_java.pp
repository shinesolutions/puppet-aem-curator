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
# [*jdk_base_url*]
#   Base URL (supported by the puppet-archive module) to download the JDK RPM from
#
# [*jdk_filename*]
#   Oracle JDK 21 RPM file name with the full version, e.g. jdk-21.0.13_linux-x64_bin.rpm
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
  # Oracle JDK 21 only (Java 8 and 11 are no longer supported)
  $jdk_filename   = 'jdk-21.0.13_linux-x64_bin.rpm',
) {
  # Oracle JDK 21 RPMs are named jdk-21.0.N_linux-x64_bin.rpm and install into the
  # version-specific /usr/lib/jvm/jdk-21.0.N-oracle-x64 (the full version is needed to find it)
  $jdk_filename_splitted = split($jdk_filename, '-')
  $jdk_version = split($jdk_filename_splitted[1], '_')[0]
  if $jdk_version !~ /^21\.\d+\.\d+$/ {
    fail("Error: Unsupported JDK file name ${jdk_filename}. Supported is Oracle JDK 21 with its full version, e.g. jdk-21.0.13_linux-x64_bin.rpm")
  }
  $java_home_path = "/usr/lib/jvm/jdk-${jdk_version}-oracle-x64"
  $libjvm_content_path = "${java_home_path}/lib/server/\n"
  # JDK 9+ has no jre/ directory; cacerts is a regular file (password-less PKCS12 since JDK 18)
  $cacert_path = "${java_home_path}/lib/security/cacerts"

  # version_major/version_minor make java::download's creates guard the RPM's install directory
  # (${basedir}/jdk${version_major}${version_minor}); without them it uses its 8u201/b09 defaults,
  # so the guard never matched and the RPM was downloaded and installed on every run
  java::download { $jdk_version :
    ensure        => 'present',
    java_se       => 'jdk',
    version       => '21',
    version_major => "-${jdk_version}",
    version_minor => '-oracle-x64',
    basedir       => '/usr/lib/jvm',
    url           => "${jdk_base_url}/${jdk_filename}",
  } -> exec { "alternatives --set  java ${java_home_path}/bin/java":
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    require => Java::Download[$jdk_version],
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
      password    => 'changeit',
      path        => ['/bin','/usr/bin'],
      require     => Java::Download[$jdk_version],
    }
  }
}
