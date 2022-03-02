
class aem_curator::action_download_packages (
  $packages,
  $aem_id,
  $path
) {
  # prepare the packages
  file { $path:
    ensure => directory,
    mode   => '0775',
  }

  $packages.each | Integer $index, Hash $package| {

    $_aem_id = pick(
      $package[aem_id],
      $aem_id,
      'author'
      )

    $_ensure = pick(
      $package['ensure'],
      'present',
    )

    if $_ensure == 'present' {
      # TODO: validate the package values exist and populated
      if !defined(File["${path}/${_aem_id}/${package['group']}"]) {
        exec { "Create ${path}/${_aem_id}/${package['group']}":
          creates => "${path}/${_aem_id}/${package['group']}",
          command => "mkdir -p ${path}/${_aem_id}/${package['group']}",
          cwd     => $path,
          path    => ['/usr/bin', '/usr/sbin', '/bin/'],
          require => File[$path],
        } -> file { "${path}/${_aem_id}/${package['group']}":
          ensure => directory,
          mode   => '0775',
        }
      }

      if $package['force'] {
        # This is not _guaranteed_ to never match, but
        # the chance of matching is very, very low.
        $checksum = '00000000000000000000000000000000'
        $checksum_type = 'md5'
        $checksum_verify = false
      } elsif $package['checksum'] {
        $checksum      = $package['checksum']
        $checksum_type = pick(
          $package['checksum_type'],
          'md5',
        )
        $checksum_verify = true
      } else {
        $checksum        = undef
        $checksum_type   = undef
        $checksum_verify = true
      }

      archive { "${path}/${_aem_id}/${package['group']}/${package['name']}-${package['version']}.zip":
        ensure          => present,
        source          => $package[source],
        checksum        => $checksum,
        checksum_type   => $checksum_type,
        checksum_verify => $checksum_verify,
        require         => File["${path}/${_aem_id}/${package['group']}"],
      }
    }
  }
}
