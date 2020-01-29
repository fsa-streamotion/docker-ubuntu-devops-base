FROM kayosportsau/ubuntu-base:1.0.15

ARG KUBECTL_VERSION=v1.14.9
ARG JX_VERSION=v2.0.800
ARG EKSCTL_VERSION=latest_release
ARG KUSTOMIZE_VERSION=2.0.3
ARG VELERO_VERSION="0.11.0"
ARG ARGO_VERSION=v1.2.3

ADD add/dev-cheats /root/dev-cheats

ADD add/okta /tmp/okta

RUN mkdir /opt/okta-utils && \
    cd /tmp/okta && \
    mv oktashell.sh /usr/local/bin && \
    mv oktashell assumerole requirements.txt /opt/okta-utils && \
    pip3 install --no-cache-dir -r /opt/okta-utils/requirements.txt && \
    pip3 install sceptre-aws-resolver

#Sceptre custom hooks
RUN git clone \
      https://github.com/zaro0508/sceptre-stack-termination-protection-hook.git \
      /tmp/sceptre-stack-termination-protection-hook && \
    cd /tmp/sceptre-stack-termination-protection-hook && \
    python3 setup.py install

#Install Hub
RUN curl -L https://github.com/github/hub/releases/download/v2.12.1/hub-linux-amd64-2.12.1.tgz  -o /tmp/hub.tar.gz && \
    tar -xvzf /tmp/hub.tar.gz -C /tmp && mv /tmp/hub-linux-* /usr/local/hub-linux && \
    echo 'export PATH=$PATH:/usr/local/hub-linux/bin' >> /root/.bashrc        


RUN     rm /etc/localtime && \
        ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
        dpkg-reconfigure -f noninteractive tzdata

#kubectl
RUN curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    curl -L https://amazon-eks.s3-us-west-2.amazonaws.com/${IAM_AUTHENTICATOR_VERSION}/bin/linux/amd64/aws-iam-authenticator -o /usr/local/bin/aws-iam-authenticator && \
    chmod +x /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/aws-iam-authenticator

RUN mkdir -p ~/.jx && \
    curl -L https://github.com/jenkins-x/jx/releases/download/$JX_VERSION/jx-linux-amd64.tar.gz | tar xzv -C /tmp/ \
    && mv /tmp/jx /usr/bin/jx && chmod +x /usr/bin/jx
    
# helm stuff
RUN mkdir -p /root/bin && \
    export PATH=/root/bin:$PATH && echo 'export PATH=/root/bin:$PATH' >> /root/.bashrc && \
    curl -LO https://git.io/get_helm.sh && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    helm init --client-only && \
    helm plugin install https://github.com/rimusz/helm-tiller && \
    helm plugin install https://github.com/databus23/helm-diff --version master && \
    wget -O helmfile https://github.com/roboll/helmfile/releases/download/v0.80.0/helmfile_linux_amd64 && \
    chmod +x ./helmfile && \
    cp ./helmfile /root/bin/helmfile && \
    echo "source /usr/share/bash-completion/bash_completion" >> /root/.bashrc && \
    echo "source <(kubectl completion bash)" >> /root/.bashrc && \
    echo "source <(jx completion bash)" >> /root/.bashrc

RUN wget https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail && chmod +x kubetail && mv kubetail /usr/local/bin

RUN curl --location "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin && \
    echo 'export PATH=$PATH:/root/dev-cheats/' >> /root/.bashrc


#install kustomize
RUN curl -O -L https://github.com/kubernetes-sigs/kustomize/releases/download/v${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64 && \
     mv kustomize_${KUSTOMIZE_VERSION}_linux_amd64 /usr/local/bin/kustomize && chmod +x /usr/local/bin/kustomize

# ksonet
ARG KSONNET_VERSION=0.13.1
RUN wget https://github.com/ksonnet/ksonnet/releases/download/v${KSONNET_VERSION}/ks_${KSONNET_VERSION}_linux_amd64.tar.gz && \
    tar -xzf ks_${KSONNET_VERSION}_linux_amd64.tar.gz && chmod +x ks_${KSONNET_VERSION}_linux_amd64/ks && cp -v ks_${KSONNET_VERSION}_linux_amd64/ks /usr/local/bin/

#argo
RUN wget https://github.com/argoproj/argo-cd/releases/download/${ARGO_VERSION}/argocd-linux-amd64 && \
    chmod +x argocd-linux-amd64 && \mv argocd-linux-amd64 /usr/local/bin/argo

#velero
RUN curl -L https://github.com/heptio/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz -o /tmp/velero.tar.gz && \
    tar -xvzf /tmp/velero.tar.gz -C /tmp && \
    mv /tmp/velero /usr/local/bin/velero && \
    chmod +x /usr/local/bin/velero && \
    rm -rf /tmp/*

ARG KFCTL_VERSION=v0.6.2
RUN cd /tmp/ && wget https://github.com/kubeflow/kubeflow/releases/download/v0.6.2/kfctl_${KFCTL_VERSION}_linux.tar.gz && \
    tar -xvzf kfctl_${KFCTL_VERSION}_linux.tar.gz && chmod +x kfctl && mv kfctl /usr/local/bin/ && rm -rf kfctl_${KFCTL_VERSION}_linux.tar.gz

# Node.js
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g serverless

# kubeseal
ARG KUBESEAL_VERSION=v0.9.6
RUN wget https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBESEAL_VERSION}/kubeseal-linux-amd64 -O kubeseal && \
    install -m 755 kubeseal /usr/local/bin/kubeseal

# mkdocs to generate nicer doc from readme files
RUN pip3 install mkdocs

RUN pip3 install cfn_flip==1.2.2 ipdb

#AWLESS (tool for aws commandline)
RUN wget https://github.com/wallix/awless/releases/download/v0.1.11/awless-linux-amd64.tar.gz && \
    tar -xvzf awless-linux-amd64.tar.gz && \
    rm -rf awless-linux-amd64.tar.gz && \
    chmod +x awless && \
    mv awless /usr/local/bin/ && \
    echo 'source <(awless completion bash)' >> /root/.bashrc

RUN cd /tmp && \
    wget https://github.com/jenkins-x/jx-release-version/releases/download/v1.0.24/jx-release-version_1.0.24_linux_amd64.tar.gz && \
    tar -xvzf jx-release-version_1.0.24_linux_amd64.tar.gz && chmod +x jx-release-version && mv jx-release-version /usr/local/bin && \
    rm -rf /tmp/* 


RUN echo "complete -C '/usr/local/bin/aws_completer' aws" >> /root/.bashrc
RUN kubectl completion bash >/etc/bash_completion.d/kubectl
RUN echo 'complete -F __start_kubectl k' >>~/.bashrc



RUN echo export LC_ALL=C.UTF-8 >> /root/.bashrc
RUN echo export LANG=C.UTF-8   >> /root/.bashrc
