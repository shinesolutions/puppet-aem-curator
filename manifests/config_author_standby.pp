#== Class: aem_curator::config_author_standby
# Configuration AEM Author
#
# === Parameters
# [*jvm_mem_opts*]
#   User defined JVM Memory options to be passed to the AEM Author
#
# [*jmxremote_port*]
#   User defined Port on which JMXRemote is listening
#
# [*jvm_opts*]
#   User defined additional JVM options
#
# [*aem_home_dir*]
#  Path to the AEM Application home directory
#  default: /opt/aem/author
#
# [*author_standby_osgi_config*]
#  Author Standby OSGI configuration as hashmap.
#  default: undef
#
# [*aem_context_root*]
#  Set CONTEXT_ROOT in AEM start-env binary
#  default: undef
#
# [*aem_debug_port*]
#  Enable AEM Debug port
#  default: undef
#
# [*aem_osgi_configs*]
#  A Hashmap of OSGI to configure on AEM.
#  A list of examples can be found here https://github.com/bstopp/puppet-aem/blob/1441ee00f4669b56e43476273bba5073f0985fbc/docs/aem-instance/OSGi-Configurations.md
#  default: {}
#
# [*aem_runmodes*]
#  A list of additional runmodes for AEM
#  default: []
#
# [*aem_crx_packages*]
#   A list of CRX packages.
#   Allowed values are  s3: | http: | https: | file:
#  default: undef
#
# === Copyright
#
# Copyright © 2017 Shine Solutions Group, unless otherwise noted.
#

File {
  backup => false,
}

class aem_curator::config_author_standby (
  $author_port,
  $author_protocol,
  $author_primary_host,
  $credentials_file,
  $crx_quickstart_dir,
  $enable_crxde,
  $enable_default_passwords,
  $puppet_conf_dir,
  $tmp_dir,
  $aem_context_root             = undef,
  $aem_crx_packages             = undef,
  $aem_debug_port               = undef,
  $aem_osgi_configs             = {},
  $aem_home_dir                 = '/opt/aem/author',
  $aem_id                       = 'author',
  $aem_runmodes                 = [],
  $aem_version                  = '6.2',
  $author_standby_osgi_config   = undef,
  $enable_aem_clean_directories = false,
  $data_volume_mount_point      = undef,
  $delete_repository_index      = false,
  $jmxremote_port               = '5982',
  $jvm_mem_opts                 = undef,
  $jvm_opts                     = undef,
  $run_mode                     = 'author',
) {

  if !defined(File[$tmp_dir]) {
    file { $tmp_dir:
      ensure => directory,
    }
  }

  $credentials_hash = loadjson("${tmp_dir}/${credentials_file}")

  Exec {
    cwd     => $tmp_dir,
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    timeout => 0,
  }

  exec { "${aem_id}: Set repository ownership":
    command => "chown -R aem-${aem_id}:aem-${aem_id} ${data_volume_mount_point}",
    before  => Service['aem-author'],
  }

  if $delete_repository_index {

    file { "${crx_quickstart_dir}/repository/index/":
      ensure  => absent,
      recurse => true,
      purge   => true,
      force   => true,
      before  => Service['aem-author'],
    }
  }

  if $jmxremote_port {
    $jmxremote_options = [
      '-Dcom.sun.management.jmxremote',
      "-Dcom.sun.management.jmxremote.port=${jmxremote_port}",
      '-Dcom.sun.management.jmxremote.authenticate=false',
      '-Dcom.sun.management.jmxremote.ssl=false',
      '-Dcom.sun.management.jmxremote.local.only=true',
      '-Djava.rmi.server.hostname=localhost'
    ]
    $_jvm_opts_list = concat([$jvm_opts], $jmxremote_options)
    $_jvm_opts = $_jvm_opts_list.join(' ')
  } else {
    $_jvm_opts = $jvm_opts
  }

  if $enable_aem_clean_directories {
    $list_clean_directories = [
      'logs',
      'threaddumps'
    ]

    $list_clean_directories.each | Integer $index, String $clean_directory| {
      exec { "${aem_id}: Cleaning directory ${crx_quickstart_dir}/${clean_directory}/":
        command => "rm -fr ${crx_quickstart_dir}/${clean_directory}/*",
        before  => Service['aem-author'],
      }
    }
  }

  aem_resources::puppet_aem_resources_set_config { 'Set puppet-aem-resources config file for author-standby':
    conf_dir => $puppet_conf_dir,
    protocol => $author_protocol,
    host     => 'localhost',
    port     => $author_port,
    debug    => false,
    aem_id   => $aem_id,
  } -> aem_resources::author_standby_set_config { 'Set author-standby config':
    aem_context_root => $aem_context_root,
    aem_crx_packages => $aem_crx_packages,
    aem_debug_port   => $aem_debug_port,
    aem_home_dir     => $aem_home_dir,
    aem_id           => $aem_id,
    aem_port         => $author_port,
    aem_runmodes     => $aem_runmodes,
    aem_user         => "aem-${aem_id}",
    aem_user_group   => "aem-${aem_id}",
    aem_version      => $aem_version,
    jvm_mem_opts     => $jvm_mem_opts,
    jvm_opts         => $_jvm_opts,
    osgi_configs     => $author_standby_osgi_config,
    primary_host     => $author_primary_host,
  } -> aem_resources::set_osgi_config { "${aem_id}: Set AEM OSGI config":
    aem_home_dir   => $aem_home_dir,
    aem_id         => $aem_id,
    aem_user       => "aem-${aem_id}",
    aem_user_group => "aem-${aem_id}",
    osgi_configs   => $aem_osgi_configs
  } -> service { 'aem-author':
    ensure => 'running',
    enable => true,
  } -> tcp_conn_validator { "${aem_id}: Wait until AEM Author Standby is listening on port ${author_port}":
    host      => '127.0.0.1',
    port      => $author_port,
    try_sleep => 5,
    timeout   => 300,
  }
}
