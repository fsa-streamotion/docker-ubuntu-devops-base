```
aws eks update-kubeconfig --name `jx get eks | grep -v NAME| cut -f 1`
```

```

aws iam list-roles \
    | jq -r ".Roles[] \
    | select(.RoleName \
    | startswith(\"$AWS_CLUSTER_NAME\") and contains(\"NodeInstanceRole\")) \
    .RoleName"
```


export KFAPP=kfapp
export REGION=ap-soutcheast-2
export AWS_CLUSTER_NAME=datalake-dev
export AWS_NODEGROUP_ROLE_NAMES=datalake-dev-node-role




aws iam list-roles \
    | jq -r ".Roles[].RoleName"


######## HELM ######
helm install stable/postgresql --name standalone --dry-run --debug
helm template [LOCAL-CHART-NAME] -x templates/file.yaml
helm upgrade --install

