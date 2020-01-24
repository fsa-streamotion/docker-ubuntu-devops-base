kubectl version -o json | jq

kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2

kubectl get psp eks.privileged

kubectl describe deployment coredns --namespace kube-system | grep Image