# == Define: aem_curator::aem_package
#
# Used to unpack the AEM instance prior to configuration.
#
# Do not use this defines directly.
#
# Ported from bstopp/aem 3.0.0 aem::package (Apache-2.0, Copyright (C) 2015-2016
# Bryan Stopp, see NOTICE) because that module is unmaintained and incompatible
# with OpenVox 9. Behaviour is unchanged.
#
define aem_curator::aem_package (
  $ensure,
  $group,
  $home,
  $manage_home,
  $source,
  $user,
) {
  File {
    group => $group,
    owner => $user,
  }

  Exec {
    group => $group,
    path  => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
    user  => $user,
  }

  if $ensure == 'present' {
    # Manage home directory.
    if !defined(File[$home]) and $manage_home {
      file { $home:
        ensure => directory,
        mode   => '0775',
      }
    }

    if defined(File[$home]) {
      File[$home]
      -> Exec["${name} unpack"]
    }

    # Unpack the Jar
    exec { "${name} unpack":
      command => "java -jar ${source} -b ${home} -unpack",
      creates => "${home}/crx-quickstart",
      onlyif  => ['which java', "test -f ${source}"],
    }
  } else {
    # Remove installation
    file { "${home}/crx-quickstart": ensure => absent, force => true }

    # Remove managed home directory
    if !defined(File[$home]) and $manage_home {
      file { $home:
        ensure => absent,
        force  => true,
      }
    }

    if defined(File[$home]) {
      File["${home}/crx-quickstart"]
      -> File[$home]
    }
  }
}
