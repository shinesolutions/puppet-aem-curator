#== Define: aem_curator::config_aem_agents
# This manifest helps you to configure AEM agents on AEM.
#
# Via a control flag you can enable the removal of all agents on AEM
# or the creation of certain agents.
#
# === Parameters
# [*aem_id*]
#   String to define the aem id.
#   Supported values are aem, author or publish.
#
# [*dispatcher_host_url*]
#   String to define the dispatcher url.
#   Per default we are assuming that the dispatcher is using HTTPS via port 443.
#
# [*dispatcher_id*]
#   String to define the dispatcher id for creating the flush agent or outbox agents on AEM.
#
# [*enable_create_flush_agents*]
#   Boolean to run the process of creating the flush agents on AEM.
#
# [*enable_create_outbox_replication_agents*]
#   Boolean to run the process of creating the outbox replication agents on AEM.
#
# [*enable_remove_all_agents*]
#   Boolean to run the process of removing all existing agents on AEM.
#
# [*log_level*]
# Sring tp define th log level for the agents.
# Default is info.
# Allowed values are info, error, debug.
#
# [*run_mode*]
#  String to define the run mode for creating the AEM Agents.
#   Supported values are author or publish.
#
# [*replication_agent_user_id*]
#  String to define user id of the replication agent.
#  Default value is `replicator.`
#
# === Copyright
#
# Copyright © 2021 Shine Solutions Group Group, unless otherwise noted.
#

define aem_curator::config_aem_agents (
  $aem_id                                  = undef,
  $dispatcher_id                           = undef,
  $dispatcher_host_url                     = undef,
  $enable_create_flush_agents              = false,
  $enable_create_outbox_replication_agents = false,
  $enable_remove_all_agents                = false,
  $log_level                               = 'info',
  $replication_agent_user_id               = 'replicator',
  $run_mode                                = undef,
) {
  # Validate booleans
  validate_bool($enable_create_flush_agents)
  validate_bool($enable_create_outbox_replication_agents)
  validate_bool($enable_remove_all_agents)

  # Validate aem_id
  validate_string($aem_id)
  # Validate run mode
  validate_string($run_mode)

  if $enable_remove_all_agents {
    aem_aem { "${aem_id}: Remove all agents":
        ensure   => all_agents_removed,
        run_mode => $run_mode,
        aem_id   => $aem_id,
      }
  }

  if $enable_create_flush_agents {

    # Validate Strings
    validate_string($dispatcher_id)
    validate_string($dispatcher_host_url)
    validate_string($log_level)

    aem_flush_agent { "${aem_id}: Create flush agent for ${run_mode}-dispatcher ${dispatcher_id}":
      ensure        => present,
      name          => "flushAgent-${dispatcher_id}",
      run_mode      => $run_mode,
      title         => "Flush agent for ${run_mode}-dispatcher ${dispatcher_id}",
      description   => "Flush agent for ${run_mode}-dispatcher ${dispatcher_id}",
      dest_base_url => "https://${dispatcher_host_url}:443",
      log_level     => $log_level,
      retry_delay   => 60000,
      force         => true,
      aem_id        => $aem_id,
    }
  }

  if $enable_create_outbox_replication_agents {

    # Validate Strings
    validate_string($dispatcher_id)
    validate_string($log_level)
    validate_string($replication_agent_user_id)

    aem_outbox_replication_agent { "${aem_id}: Create outbox replication agent for ${run_mode}-dispatcher ${dispatcher_id}":
      ensure      => present,
      name        => 'outbox',
      run_mode    => $run_mode,
      title       => "Outbox replication agent ${run_mode}-dispatcher ${dispatcher_id}",
      description => "Outbox replication agent for ${run_mode}-dispatcher ${dispatcher_id}",
      user_id     => $replication_agent_user_id,
      log_level   => $log_level,
      force       => true,
      aem_id      => $aem_id,
    }
  }
}
