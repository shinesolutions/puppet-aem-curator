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
# The agent configuration baked into the AMI is read, updated and written to
# a separate file, so the log files and metrics themselves are still defined
# in packer-aem. The agent's fetch-config deletes the file it was given when
# the AMI was baked and keeps only its own copy in amazon-cloudwatch-agent.d,
# and it deletes that copy when it applies this class's file, so the class
# reads the first of baked_config_paths and config_file_path that exists.
# Re-applying the class doesn't prefix a log group twice, and a log group
# whose name doesn't start with / is left as it is.
#
# The agent creates a log group and log stream only when it sends a file's
# first new line, and it resumes each file from the read position it saved
# under the baked configuration. So before applying the stack configuration,
# the class stops the agent and clears those positions: the agent then sends
# each file from the start, and a quiet log such as /var/log/secure still gets
# its prefixed log group and stream. A later change of the stack configuration
# sends the files again too.
#
# The class does nothing when none of those files exists, e.g. on an AMI
# without the unified CloudWatch agent.
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
#   Path to write the agent's stack JSON configuration file to.
#
# [*baked_config_paths*]
#   Paths of the agent configuration baked into the AMI, in order of
#   preference: the copy fetch-config keeps, then the file it was given.
#
# [*agent_ctl_path*]
#   Path to the amazon-cloudwatch-agent-ctl command.
#
# [*agent_state_dir*]
#   Directory where the agent saves the read position of each log file.
#
# === Copyright
#
# Copyright © 2026 Shine Solutions Group, unless otherwise noted.
#
class aem_curator::config_cloudwatch_agent (
  $stack_prefix,
  $component,
  $ec2_id,
  $metrics_prefix     = "${stack_prefix}-${component}",
  $config_file_path   = '/opt/aws/amazon-cloudwatch-agent/etc/aem-stack-cloudwatch-agent.json',
  $baked_config_paths = [
    '/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d/file_amazon-cloudwatch-agent.json',
    '/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json',
  ],
  $agent_ctl_path     = '/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl',
  $agent_state_dir    = '/opt/aws/amazon-cloudwatch-agent/logs/state',
) {

  $source_config_path = find_file($baked_config_paths + [$config_file_path])

  if $source_config_path {
    $baked_config = loadjson($source_config_path)

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

    # The agent is stopped before its saved read positions are cleared, so it
    # can't save them again, and fetch-config with -s starts it with the new
    # configuration.
    exec { 'Apply CloudWatch agent stack configuration':
      command     => join([
        "${agent_ctl_path} -a stop -m ec2",
        "rm -f ${agent_state_dir}/*",
        "${agent_ctl_path} -a fetch-config -m ec2 -s -c file:${config_file_path}",
      ], ' && '),
      provider    => shell,
      path        => ['/usr/bin', '/usr/sbin', '/bin'],
      subscribe   => File[$config_file_path],
      refreshonly => true,
    }
  }

}
