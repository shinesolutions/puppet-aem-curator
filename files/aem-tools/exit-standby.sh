#!/usr/bin/env bash
set -o nounset
set -o errexit

instance_id=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id)

lifecycle_state=$(aws autoscaling describe-auto-scaling-instances --instance-ids "${instance_id}" --query AutoScalingInstances[].LifecycleState --output text)

if [ "$lifecycle_state" = "Standby" ]
then

    group_name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${instance_id}" "Name=key,Values=aws:autoscaling:groupName" --output=text --query Tags[0].Value)

    aws autoscaling exit-standby --instance-ids "${instance_id}" --auto-scaling-group-name "${group_name}"

else

    echo "Instance is in ${lifecycle_state} State. Can not Exit Standby."

fi
