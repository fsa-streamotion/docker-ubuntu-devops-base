aws autoscaling describe-auto-scaling-groups | jq '.[] | .[]| { name: .AutoScalingGroupName , size: .DesiredCapacity }'

