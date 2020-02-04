kubectl run -it --requests=cpu=100m,memory=256Mi --limits=cpu=100m,memory=256Mi  --rm test --image=busybox:1.28 --restart=Never --command -- sh

