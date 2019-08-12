#delete all pods that are not running so deployments can restart them
kubectl get pods | grep -v Running  | grep -v NAME | awk '{print $1}' | xargs kubectl delete pods