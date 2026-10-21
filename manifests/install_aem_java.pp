# == Class: aem_curator::install_aem_java
#
# Install Java for AEM Component
#
# === Parameters

# [*cert_base_url*]
#   Base URL (supported by the puppet-archive module) to download the X.509
#   certificate and private key to be used with Apache.
#
# [*jdk_base_url*]
#   Base URL (supported by the puppet-archive module) to download the Java JDK from
#
# [*jdk_filename*]
#   Oracle JDK 11 RPM file name with the full version, e.g. jdk-11.0.33.0.1_linux-x64_bin.rpm
#
# [*tmp_dir*]
#   A temporary directory used to store the X.509 certificate and private key
#   while building the PEM file for Apache.
#
# === Copyright
#
# Copyright © 2021 Shine Solutions Group Group, unless otherwise noted.
#
class aem_curator::install_aem_java (
  $cert_base_url,
  $tmp_dir,
  $jdk_base_url,
  # The latest Oracle JDK 11 only (Java 8 and older JDK 11 layouts are no longer supported)
  $jdk_filename = 'jdk-11.0.33.0.1_linux-x64_bin.rpm',
) {
  # Oracle JDK 11 RPMs since 11.0.24 install into the version-specific
  # /usr/lib/jvm/jdk-<version>-oracle-x64, so the full version (which can have four parts,
  # e.g. 11.0.33.0.1) is taken from the file name jdk-<version>_linux-x64_bin.rpm
  $jdk_filename_splitted = split($jdk_filename, '-')
  $jdk_version = split($jdk_filename_splitted[1], '_')[0]
  if $jdk_version !~ /^11\.\d+\.\d+(\.\d+)*$/ {
    fail("Error: Unsupported JDK file name ${jdk_filename}. Supported is Oracle JDK 11 with its full version, e.g. jdk-11.0.33.0.1_linux-x64_bin.rpm")
  }
  $java_home_path = "/usr/lib/jvm/jdk-${jdk_version}-oracle-x64"
  # JDK 9+ has no jre/ directory: libjvm and cacerts (a regular JKS file in JDK 11) are under lib/
  $libjvm_content_path = "${java_home_path}/lib/server/\n"
  $cacert_path = "${java_home_path}/lib/security/cacerts"

  # version_major/version_minor make java::download's creates guard the RPM's install directory
  # (${basedir}/jdk${version_major}${version_minor}); without them it uses its 8u201/b09 defaults,
  # so the guard never matched and the RPM was downloaded and installed on every run
  java::download { $jdk_version :
    ensure        => 'present',
    java_se       => 'jdk',
    version       => '11',
    version_major => "-${jdk_version}",
    version_minor => '-oracle-x64',
    basedir       => '/usr/lib/jvm',
    url           => "${jdk_base_url}/${jdk_filename}",
  }

  # Need to set alternative for java here due to oracle_java module's add alternative feature is broken in version 2.9.4
  exec { "alternatives --set  java ${java_home_path}/bin/java":
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    require => Java::Download[$jdk_version],
  }

  file { '/usr/java':
    ensure => directory,
    mode   => '0775',
  }

  # Set "default" symlink as this is referenced by keystore settings and is not created by all Java installations
  file { '/usr/java/default':
    ensure => 'link',
    target => $java_home_path,
  }

  file { '/etc/ld.so.conf.d/99-libjvm.conf':
    ensure  => present,
    content => $libjvm_content_path,
    notify  => Exec['/sbin/ldconfig'],
    require => Java::Download[$jdk_version],
  }

  exec { '/sbin/ldconfig':
    refreshonly => true,
    require     => File['/etc/ld.so.conf.d/99-libjvm.conf']
  }

  file { "${tmp_dir}/java":
    ensure => directory,
    mode   => '0700',
  }

  [ 'cert' ].each |$idx, $part| {
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
