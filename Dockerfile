FROM ubuntu:bionic

# Latest Kubectl release given by:
#   curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt
ARG KUBECTL_VERSION=v1.20.0

# Latest Eksctl release can be viewed here:
#   https://github.com/weaveworks/eksctl/releases
ARG EKSCTL_VERSION=0.34.0

ARG AWSCLI_VERSION=1.18.193
ARG JX_VERSION=v2.0.1263
ARG KUSTOMIZE_VERSION=2.0.3
ARG VELERO_VERSION=0.11.0
ARG ARGO_VERSION=v1.2.3
ARG KSONNET_VERSION=0.13.1

ENV DEBIAN_FRONTEND=noninteractive

ENV TZ='Australia/Sydney'
RUN echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get -y install software-properties-common && \
    apt-get -y upgrade git && \
    apt-get -y install \
        iputils-ping openjdk-8-jdk ca-certificates groff vim \
        less bash-completion make curl wget zip telnet \
        git tree openssl gcc jq tmux golang-cfssl gettext \
        python3 python3-pip bash-completion tzdata && \
    apt-get clean && \
    pip3 install --no-cache-dir --upgrade \
        awscli==${AWSCLI_VERSION} \
        aws-sam-cli==0.40.0 \
        sceptre==2.3.0 \
        troposphere==2.6.2 \
        cfn-flip==1.2.2 \
        colorama==0.3.9 \
        boto3==1.16.25 \
        botocore==1.16.25 \
        sceptre-aws-resolver==0.4 \
        sceptre-minify-file-contents-resolver==0.0.2 

# Sceptre custom hooks
RUN git clone \
      https://github.com/zaro0508/sceptre-stack-termination-protection-hook.git \
      /tmp/sceptre-stack-termination-protection-hook && \
    cd /tmp/sceptre-stack-termination-protection-hook && \
    python3 setup.py install

# Python tests
RUN pip3 install --no-cache-dir --upgrade \
        yq==2.10.0 && \
        yamllint==1.20.0 && \
        cfn_flip==1.2.2 && \
        ipdb==0.12.3 && \
        pathlib==1.0.1 && \
        pylint==2.5.3 && \
        autopep8==1.5.3 && \
        mypy==0.790 && \
        parliament==1.2.0

# Bashrc
RUN echo 'export LC_ALL=C.UTF-8' >> /root/.bashrc && \
    echo 'export LANG=C.UTF-8'   >> /root/.bashrc && \
    echo 'export PS1="\u@\h:\w \$ "' >> /root/.bashrc && \
    echo 'export PATH=/root/bin:$PATH' >> /root/.bashrc && \
    echo 'export PATH=$PATH:/root/dev-cheats/' >> /root/.bashrc && \
    echo "alias dep='kubectl get deploy'" >> /root/.bashrc && \
    echo "alias ing='kubectl get ing'" >> /root/.bashrc && \
    echo "alias svc='kubectl get svc'" >> /root/.bashrc && \
    echo "alias pods='kubectl get pods'" >> /root/.bashrc && \
    echo "alias k=kubectl" >> /root/.bashrc && \
    echo "alias ap='kubectl get pods --all-namespaces'" >> /root/.bashrc && \
    echo "alias po='kubectl get pods'" >> /root/.bashrc

# Git config
RUN git config --global alias.co checkout && \
    git config --global alias.br branch && \
    git config --global alias.st status

WORKDIR /src

ADD add/json2yaml /usr/local/bin/json2yaml
ADD add/dev-cheats /root/dev-cheats
ADD add/okta /tmp/okta

RUN mkdir /opt/okta-utils && \
    cd /tmp/okta && \
    mv oktashell.sh /usr/local/bin && \
    mv account-mapping.yml oktashell assumerole requirements.txt /opt/okta-utils && \
    chmod +x /usr/local/bin/json2yaml && \
    pip3 install --no-cache-dir -r /opt/okta-utils/requirements.txt

# Ruby
RUN apt-get install -y libssl-dev libreadline-dev zlib1g-dev
RUN git clone https://github.com/rbenv/ruby-build.git && \
    PREFIX=/usr/local ./ruby-build/install.sh && \
    ruby-build -v 2.4.1 /usr/local

# Shunit2 for Bash unit tests
RUN curl \
      https://raw.githubusercontent.com/kward/shunit2/c47d32d6af2998e94bbb96d58a77e519b2369d76/shunit2 \
      -o /tmp/shunit2 && \
    mv /tmp/shunit2 /usr/local/bin

RUN curl \
      https://raw.githubusercontent.com/alexharv074/scripts/master/DiffHighlight.pl \
      -o /tmp/DiffHighlight.pl && \
    mv /tmp/DiffHighlight.pl /usr/local/bin && \ 
    chmod +x /usr/local/bin/DiffHighlight.pl

# Other tools used in automated tests
RUN apt-get install -y \
      apt-utils colordiff shellcheck parallel dnsutils

# Gridsite tools used by sceptre-make to generate URLs
RUN apt-get install -y gridsite-clients

# Install Hub
RUN curl -L https://github.com/github/hub/releases/download/v2.12.1/hub-linux-amd64-2.12.1.tgz -o /tmp/hub.tar.gz && \
    tar -xvzf /tmp/hub.tar.gz -C /tmp && mv /tmp/hub-linux-* /usr/local/hub-linux && \
    echo 'export PATH=$PATH:/usr/local/hub-linux/bin' >> /root/.bashrc        

RUN rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# kubectl
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

# install kustomize
RUN curl -O -L https://github.com/kubernetes-sigs/kustomize/releases/download/v${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64 && \
     mv kustomize_${KUSTOMIZE_VERSION}_linux_amd64 /usr/local/bin/kustomize && chmod +x /usr/local/bin/kustomize

# ksonet
RUN wget https://github.com/ksonnet/ksonnet/releases/download/v${KSONNET_VERSION}/ks_${KSONNET_VERSION}_linux_amd64.tar.gz && \
    tar -xzf ks_${KSONNET_VERSION}_linux_amd64.tar.gz && chmod +x ks_${KSONNET_VERSION}_linux_amd64/ks && cp -v ks_${KSONNET_VERSION}_linux_amd64/ks /usr/local/bin/

# argo
RUN wget https://github.com/argoproj/argo-cd/releases/download/${ARGO_VERSION}/argocd-linux-amd64 && \
    chmod +x argocd-linux-amd64 && \mv argocd-linux-amd64 /usr/local/bin/argo

# velero
RUN curl -L https://github.com/heptio/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz -o /tmp/velero.tar.gz && \
    tar -xvzf /tmp/velero.tar.gz -C /tmp && \
    mv /tmp/velero /usr/local/bin/velero && \
    chmod +x /usr/local/bin/velero && \
    rm -rf /tmp/*

RUN cd /tmp/ && wget https://github.com/kubeflow/kfctl/releases/download/v1.2.0/kfctl_v1.2.0-0-gbc038f9_linux.tar.gz && \
    tar -xvzf kfctl_v1.2.0-0-gbc038f9_linux.tar.gz && chmod +x kfctl && mv kfctl /usr/local/bin/ && \
    rm -rf kfctl_v1.2.0-0-gbc038f9_linux.tar.gz

# Node.js
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g serverless

# kubeseal
ARG KUBESEAL_VERSION=v0.9.6
RUN wget https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBESEAL_VERSION}/kubeseal-linux-amd64 -O kubeseal && \
    install -m 755 kubeseal /usr/local/bin/kubeseal

RUN curl -Lo kubebox https://github.com/astefanutti/kubebox/releases/download/v0.8.0/kubebox-linux && chmod +x kubebox && mv kubebox /usr/local/bin/

# mkdocs to generate nicer doc from readme files
RUN pip3 install mkdocs
RUN pip3 install cfn_flip==1.2.2 ipdb

# AWLESS (tool for aws commandline)
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

RUN cd /tmp && \
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.6.0 sh - && \
    mv istio-1.6.0/bin/istioctl /usr/local/bin/ && chmod +x /usr/local/bin/istioctl && \
    rm -rf /tmp/*

RUN echo "complete -C '/usr/local/bin/aws_completer' aws" >> /root/.bashrc
RUN kubectl completion bash >/etc/bash_completion.d/kubectl
RUN echo 'complete -F __start_kubectl k' >>~/.bashrc

# https://github.com/sajid-moinuddin/kk.git
ADD add/kk-1.0.dev0.tar.gz /tmp/kk-1.0.dev0.tar.gz
RUN pip3 install /tmp/kk-1.0.dev0.tar.gz/kk-1.0.dev0

ADD add/kubectl-podnode-1.0.dev0.tar.gz /tmp/kubectl-podnode-1.0.dev0.tar.gz
RUN pip3 install /tmp/kubectl-podnode-1.0.dev0.tar.gz/kubectl-podnode-1.0.dev0
