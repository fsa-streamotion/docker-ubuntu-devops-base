cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: gitops
  namespace: jx
spec:
  serviceAccountName: jenkins
  containers:
  - name: gitops
    image: sajid2045/gitops-toolkit
    args:
    - sleep
    - "1000000"
EOF