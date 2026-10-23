# == Class: aem_curator::config_cloudwatch_agent
#
# Stack-time configuration of the unified amazon-cloudwatch-agent, which
# packer-aem installs instead of the legacy awslogs agent and collectd on
# Amazon Linux 2023. It gives the agent's logs and metrics the same stack and
# component names awslogs and collectd use on other OSes:
#
# - each log group is prefixed with the stack prefix, e.g.
#   `<stack_prefix>/var/log/messages`
# - each log stream is named `<component>/<instance id>`
# - each metric gets `FixedDimension=<metrics_prefix>` and `Host=<instance id>`
#   dimensions, the same as aem_curator::config_collectd's constant dimension
#
# The agent configuration baked into the AMI is read, updated and written
# back, so the log files and metrics themselves are still defined in
# packer-aem. Re-applying the class doesn't prefix a log group twice, and a
# log group whose name doesn't start with / is left as it is.
#
# === Parameters
#
# [*stack_prefix*]
#   Stack prefix to add to each log group name.
#
# [*component*]
#   Component name used in each log stream name, e.g. author-primary.
#
# [*ec2_id*]
#   EC2 instance ID, used as the Host metric dimension.
#
# [*metrics_prefix*]
#   Value of the FixedDimension metric dimension.
#   default: "${stack_prefix}-${component}"
#
# [*config_file_path*]
#   Path to the agent's JSON configuration file.
#
# [*agent_ctl_path*]
#   Path to the amazon-cloudwatch-agent-ctl command.
#
# === Copyright
#
# Copyright © 2026 Shine Solutions Group, unless otherwise noted.
#
class aem_curator::config_cloudwatch_agent (
  $stack_prefix,
  $component,
  $ec2_id,
  $metrics_prefix   = "${stack_prefix}-${component}",
  $config_file_path = '/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json',
  $agent_ctl_path   = '/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl',
) {

  $baked_config = loadjson($config_file_path)

  # Log groups baked into the AMI are named after the log file path, so only a
  # name starting with / still needs the prefix.
  $collect_list = $baked_config.dig('logs', 'logs_collected', 'files', 'collect_list').lest || { [] }
  $logs_config = {
    'logs' => {
      'logs_collected' => {
        'files' => {
          'collect_list' => $collect_list.map |$entry| {
            $entry + {
              'log_group_name'  => $entry['log_group_name'] ? {
                /^\// => "${stack_prefix}${entry['log_group_name']}",
                default => $entry['log_group_name'],
              },
              # {instance_id} is a placeholder the agent fills in, not a Puppet variable.
              'log_stream_name' => "${component}/{instance_id}",
            }
          },
        },
      },
    },
  }

  $metrics_collected = $baked_config.dig('metrics', 'metrics_collected').lest || { {} }
  $metrics_config = {
    'metrics' => {
      'metrics_collected' => Hash($metrics_collected.map |$plugin, $plugin_config| {
        [$plugin, {
          'append_dimensions' => {
            'FixedDimension' => $metrics_prefix,
            'Host'           => $ec2_id,
          },
        }]
      }),
    },
  }

  $stack_config = deep_merge(
    $baked_config,
    empty($collect_list) ? { true => {}, default => $logs_config },
    empty($metrics_collected) ? { true => {}, default => $metrics_config },
  )

  file { $config_file_path:
    ensure  => file,
    content => to_json_pretty($stack_config),
  }

  # fetch-config with -s restarts the agent so it picks up the new configuration.
  exec { 'Apply CloudWatch agent stack configuration':
    command     => "${agent_ctl_path} -a fetch-config -m ec2 -s -c file:${config_file_path}",
    path        => ['/usr/bin', '/usr/sbin', '/bin'],
    subscribe   => File[$config_file_path],
    refreshonly => true,
  }

}
