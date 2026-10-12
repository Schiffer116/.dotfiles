#!/bin/bash
# Start, stop or show the aws-dev box (infra/aws-dev). The instance is found by its
# Name tag, so this needs AWS credentials but not the Terraform state.
#   devbox.sh start   start it and wait until it answers over Tailscale
#   devbox.sh stop    stop it now (the box also stops itself once idle)
#   devbox.sh status  EC2 state and Tailscale reachability
set -euo pipefail

region=${DEVBOX_REGION:-ap-southeast-1}
name=${DEVBOX_NAME:-aws-dev}
host=${DEVBOX_HOST:-aws-dev} # Tailscale (MagicDNS) name

ec2() { aws ec2 --region "$region" --output text "$@"; }

instance_id() {
    local id
    id=$(ec2 describe-instances \
        --filters "Name=tag:Name,Values=$name" \
                  "Name=instance-state-name,Values=pending,running,stopping,stopped" \
        --query 'Reservations[].Instances[].InstanceId')
    if [[ -z $id || $id == None ]]; then
        echo "devbox: no instance tagged Name=$name in $region" >&2
        exit 1
    fi
    if [[ $id == *[[:space:]]* ]]; then
        echo "devbox: more than one instance tagged Name=$name: $id" >&2
        exit 1
    fi
    echo "$id"
}

wait_for_tailscale() {
    command -v tailscale >/dev/null || return 0
    echo "waiting for $host on Tailscale..."
    for _ in $(seq 36); do
        if tailscale ping -c 1 --timeout 5s "$host" >/dev/null 2>&1; then
            echo "$host is up: ssh $host"
            return 0
        fi
        sleep 5
    done
    echo "devbox: $host is running but not answering on Tailscale yet" >&2
    return 1
}

case "${1:-}" in
    start)
        id=$(instance_id)
        ec2 start-instances --instance-ids "$id" >/dev/null
        ec2 wait instance-running --instance-ids "$id"
        echo "$id running"
        wait_for_tailscale
        ;;
    stop)
        id=$(instance_id)
        ec2 stop-instances --instance-ids "$id" >/dev/null
        ec2 wait instance-stopped --instance-ids "$id"
        echo "$id stopped"
        ;;
    status)
        id=$(instance_id)
        ec2 describe-instances --instance-ids "$id" \
            --query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType,Placement.AvailabilityZone,PublicIpAddress]'
        if command -v tailscale >/dev/null; then
            if tailscale ping -c 1 --timeout 3s "$host" >/dev/null 2>&1; then
                echo "tailscale: $host reachable"
            else
                echo "tailscale: $host not reachable"
            fi
        fi
        ;;
    *)
        echo "usage: ${0##*/} start|stop|status" >&2
        exit 2
        ;;
esac
