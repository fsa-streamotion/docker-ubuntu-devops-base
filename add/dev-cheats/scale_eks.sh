CLUSTER_NAME=$1
set -x;

echo "trying to lookup asg-group with clustername $1"
ASG_GROUP=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='eksctl.cluster.k8s.io/v1alpha1/cluster-name') && Value=='$CLUSTER_NAME']]".AutoScalingGroupName | jq -r '.[0]')
echo Scaling $ASG_GROUP to $2
aws autoscaling update-auto-scaling-group --auto-scaling-group-name=$ASG_GROUP --min-size=0 --max-size=20 --desired-capacity=$2

set +x;
