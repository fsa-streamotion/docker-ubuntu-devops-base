FROM kayosportsau/ubuntu-okta:1.0.1

ARG JX_VERSION=v2.0.420
ARG EKSCTL_VERSION=latest_release

ADD add/dev-cheats /root/dev-cheats

RUN curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mkdir -p /root/bin && cp ./kubectl /root/bin/kubectl && export PATH=/root/bin:$PATH && \
    curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x ./aws-iam-authenticator && \
    mkdir -p /root/bin && cp ./aws-iam-authenticator /root/bin/aws-iam-authenticator && export PATH=/root/bin:$PATH && \
    echo 'export PATH=/root/bin:$PATH' >> /root/.bashrc && \
    curl -LO https://git.io/get_helm.sh && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    helm init --client-only && \
    helm plugin install https://github.com/rimusz/helm-tiller && \
    helm plugin install https://github.com/databus23/helm-diff --version master && \
    wget -O helmfile https://github.com/roboll/helmfile/releases/download/v0.80.0/helmfile_linux_amd64 && \
    chmod +x ./helmfile && \
    cp ./helmfile /root/bin/helmfile && \
    mkdir -p ~/.jx/bin && \
    curl -L https://github.com/jenkins-x/jx/releases/download/$JX_VERSION/jx-linux-amd64.tar.gz | tar xzv -C ~/.jx/bin && \
    export PATH=$PATH:/root/.jx/bin && \
    echo 'export PATH=$PATH:/root/.jx/bin' >> /root/.bashrc && \
    echo "source <(kubectl completion bash)" >> /root/.bashrc && \
    echo "source <(jx completion bash)" >> /root/.bashrc && \
    wget https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail && chmod +x kubetail && mv kubetail /usr/local/bin && \
    curl --location "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin && \
    echo 'export PATH=$PATH:/root/dev-cheats/' >> /root/.bashrc