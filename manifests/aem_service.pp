# == Define: aem_curator::aem_service
#
# Used to create the systemd service definition for an AEM instance.
#
# Based on Elastic Search service management.
#
# Ported from bstopp/aem 3.0.0 aem::service and aem::service::systemd
# (Apache-2.0, Copyright (C) 2015-2016 Bryan Stopp, see NOTICE) because that
# module is unmaintained and incompatible with OpenVox 9.
#
# Only the systemd variant is ported: the supported OSes, Rocky Linux 10 and
# Amazon Linux 2023, both use systemd. aem::service failed on Rocky (no service
# parameters for that OS) and picked the SysV init script on Amazon, which
# AL2023 doesn't support by default. The unit is still /lib/systemd/system/aem-<id>.service
# and the service is still named aem-<id>, so Service['aem-author'],
# `puppet resource service aem-author` and `systemctl ... aem-author` keep working.
#
define aem_curator::aem_service (
  $ensure           = 'present',
  $group            = 'aem',
  $home             = undef,
  $status           = 'enabled',
  $user             = 'aem',
  # TimeoutStopSec: systemd kills AEM when a graceful stop takes longer than
  # 4 minutes, e.g. while it finishes an offline compaction or a backup. The old
  # SysV init script on Amazon Linux waited without a limit. Pass service_options
  # to change it.
  $service_options  = { 'TimeoutStopSec' => '4min', 'KillSignal' => 'SIGCONT', 'PrivateTmp' => true }
) {
  if $home == undef {
    fail('Home directory must be specified.')
  }

  assert_type(Stdlib::Absolutepath, $home)

  # Setup the system state.
  if $ensure == 'present' {
    case $status {
      # Running now and on boot.
      'enabled': {
        $service_ensure   = 'running'
        $service_enabled  = true
      }
      # Not running now, nor on boot
      'disabled': {
        $service_ensure   = 'stopped'
        $service_enabled  = false
      }
      # Running now, but not on boot.
      'running': {
        $service_ensure   = 'running'
        $service_enabled  = false
      }
      # Basically, remove the service definition from catalog
      'unmanaged': {
        $service_ensure   = undef
        $service_enabled  = false
      }
      default: {
        fail("'${status}' is not a valid service status value")
      }
    }
  } else {
    # Shut it all down if 'absent'
    $service_ensure   = 'stopped'
    $service_enabled  = false
  }

  if ($status != 'unmanaged') {
    file { "/lib/systemd/system/aem-${name}.service":
      ensure  => $ensure,
      content => epp("${module_name}/systemd/aem.service.epp", {
          'name'            => $name,
          'home'            => $home,
          'user'            => $user,
          'group'           => $group,
          'service_options' => $service_options,
      }),
      owner   => 'root',
      group   => 'root',
    }

    service { "aem-${name}":
      ensure     => $service_ensure,
      enable     => $service_enabled,
      name       => "aem-${name}.service",
      hasstatus  => true,
      hasrestart => true,
      provider   => 'systemd',
    }

    if ($ensure == 'present') {
      File["/lib/systemd/system/aem-${name}.service"]
      -> Exec["reload_systemd_aem_${name}"]
      -> Service["aem-${name}"]

      File["/lib/systemd/system/aem-${name}.service"]
      ~> Exec["reload_systemd_aem_${name}"]
      ~> Service["aem-${name}"]
    } else {
      Service["aem-${name}"]
      -> File["/lib/systemd/system/aem-${name}.service"]

      Service["aem-${name}"]
      ~> File["/lib/systemd/system/aem-${name}.service"]
      ~> Exec["reload_systemd_aem_${name}"]
    }
  }

  exec { "reload_systemd_aem_${name}" :
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }
}
