#== Class: aem_curator::config_publish
# Configuration AEM Publisher
#
# === Parameters
# [*jvm_mem_opts*]
#   User defined JVM Memory options to be passed to AEM Publisher
#
# [*jmxremote_port*]
#   User defined Port on which JMXRemote is listening
#
# === Copyright
#
# Copyright © 2017 Shine Solutions Group, unless otherwise noted.
#


File {
  backup => false,
}

class aem_curator::config_publish (
  $aem_password_reset_source,
  $aem_password_reset_version,
  $credentials_file,
  $crx_quickstart_dir,
  $enable_crxde,
  $enable_daily_export_cron,
  $enable_default_passwords,
  $enable_hourly_live_snapshot_cron,
  $enable_offline_compaction_cron,
  $exec_path,
  $login_ready_base_sleep_seconds,
  $login_ready_max_sleep_seconds,
  $login_ready_max_tries,
  $publish_port,
  $publish_protocol,
  $publish_dispatcher_id,
  $publish_dispatcher_host,
  $puppet_conf_dir,
  $tmp_dir,
  $vol_type,
  $aem_id                  = 'publish',
  $delete_repository_index = false,
  $jmxremote_port          = '59183',
  $jvm_mem_opts            = undef,
  $run_mode                = 'publish',
  $snapshotid              = $::snapshotid,
) {

  $credentials_hash = loadjson("${tmp_dir}/${credentials_file}")

  if $snapshotid != undef and $snapshotid != '' {
    if $delete_repository_index {
      $attach_volume_before = File["${crx_quickstart_dir}/repository/index/"]
    } else {
      $attach_volume_before = Service['aem-publish']
    }
    exec { "Attach volume from snapshot ID ${snapshotid}":
      command => "/opt/shinesolutions/aws-tools/snapshot_attach.py --device /dev/sdb --device-alias /dev/xvdb --volume-type ${vol_type} --snapshot-id ${snapshotid} -vvvv",
      path    => $exec_path,
      before  => $attach_volume_before,
    }
  }

  if $delete_repository_index {
    file { "${crx_quickstart_dir}/repository/index/":
      ensure  => absent,
      recurse => true,
      purge   => true,
      force   => true,
      before  => Service['aem-publish'],
    }
  }

  if $jvm_mem_opts {
    file_line { "${aem_id}: Set JVM memory opts":
      ensure => present,
      path   => "${crx_quickstart_dir}/bin/start-env",
      line   => "JVM_MEM_OPTS='${jvm_mem_opts}'",
      match  => '^JVM_MEM_OPTS',
    }
  }

  if $jmxremote_port {
    file_line { "${aem_id}: enable JMXRemote":
      ensure => present,
      path   => "${crx_quickstart_dir}/bin/start-env",
      line   => "JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=${jmxremote_port} -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=true -Djava.rmi.server.hostname=localhost\"",
      after  => '^JVM_OPTS',
      notify => Service['aem-publish'],
    }
  }

  file { "${crx_quickstart_dir}/install/":
    ensure => directory,
    mode   => '0775',
    owner  => "aem-${aem_id}",
    group  => "aem-${aem_id}",
  } -> archive { "${crx_quickstart_dir}/install/aem-password-reset-content-${aem_password_reset_version}.zip":
    ensure => present,
    source => $aem_password_reset_source,
  } -> aem_resources::puppet_aem_resources_set_config { 'Set puppet-aem-resources config file for publish':
    conf_dir => $puppet_conf_dir,
    protocol => $publish_protocol,
    host     => 'localhost',
    port     => $publish_port,
    debug    => false,
    aem_id   => $aem_id,
  } -> service { 'aem-publish':
    ensure => 'running',
    enable => true,
  } -> aem_aem { "${aem_id}: Wait until login page is ready":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_bundle { "${aem_id}: Stop webdav bundle":
    ensure => stopped,
    name   => 'org.apache.sling.jcr.webdav',
    aem_id => $aem_id,
  } -> aem_bundle { "${aem_id}: Stop davex bundle":
    ensure => stopped,
    name   => 'org.apache.sling.jcr.davex',
    aem_id => $aem_id,
  } -> aem_curator::config_aem_crxde { "${aem_id}: Configure CRXDE":
    aem_id       => $aem_id,
    enable_crxde => $enable_crxde,
    run_mode     => $run_mode,
  } -> aem_aem { "${aem_id}: Remove all agents":
    ensure   => all_agents_removed,
    run_mode => 'publish',
    aem_id   => $aem_id,
  } -> aem_package { "${aem_id}: Remove password reset package":
    ensure  => absent,
    name    => 'aem-password-reset-content',
    group   => 'shinesolutions',
    version => $aem_password_reset_version,
    aem_id  => $aem_id,
  } -> aem_flush_agent { "${aem_id}: Create flush agent":
    ensure        => present,
    name          => "flushAgent-${publish_dispatcher_id}",
    run_mode      => 'publish',
    title         => "Flush agent for publish-dispatcher ${publish_dispatcher_id}",
    description   => "Flush agent for publish-dispatcher ${publish_dispatcher_id}",
    dest_base_url => "https://${publish_dispatcher_host}:443",
    log_level     => 'info',
    retry_delay   => 60000,
    force         => true,
    aem_id        => $aem_id,
  } -> aem_outbox_replication_agent { "${aem_id}: Create outbox replication agent":
    ensure      => present,
    name        => 'outbox',
    run_mode    => 'publish',
    title       => "Outbox replication agent for publish-dispatcher ${publish_dispatcher_id}",
    description => "Outbox replication agent for publish-dispatcher ${publish_dispatcher_id}",
    user_id     => 'replicator',
    log_level   => 'info',
    force       => true,
    aem_id      => $aem_id,
  } -> aem_curator::config_aem_system_users { "${aem_id}: Configure system users":
    aem_id                   => $aem_id,
    credentials_hash         => $credentials_hash,
    enable_default_passwords => $enable_default_passwords,
  } -> file { "${crx_quickstart_dir}/install/aem-password-reset-content-${aem_password_reset_version}.zip":
    ensure => absent,
  }

}
