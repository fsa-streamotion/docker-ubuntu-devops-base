echo "SCALING ASG $1 to $2"

set -x;

aws autoscaling update-auto-scaling-group --auto-scaling-group-name=$1 --min-size=0 --max-size=20 --desired-capacity=$2

set +x;
