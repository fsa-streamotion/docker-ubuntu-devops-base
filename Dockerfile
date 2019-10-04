FROM kayosportsau/ubuntu-base:1.0.4

ARG KUBECTL_VERSION=v1.13.10
ARG JX_VERSION=v2.0.800
ARG EKSCTL_VERSION=latest_release

ADD add/dev-cheats /root/dev-cheats

ADD add/okta /tmp/okta

RUN mkdir /opt/okta-utils && \
    cd /tmp/okta && \
    mv oktashell.sh /usr/local/bin && \
    mv oktashell assumerole requirements.txt /opt/okta-utils && \
    pip3 install --no-cache-dir -r /opt/okta-utils/requirements.txt

#Install Hub
RUN curl -L https://github.com/github/hub/releases/download/v2.12.1/hub-linux-amd64-2.12.1.tgz  -o /tmp/hub.tar.gz && \
    tar -xvzf /tmp/hub.tar.gz -C /tmp && mv /tmp/hub-linux-* /usr/local/hub-linux && \
    echo 'export PATH=$PATH:/usr/local/hub-linux/bin' >> /root/.bashrc    

ENV TZ='Australia/Sydney'
ENV DEBIAN_FRONTEND=noninteractive
#install tzdata package
RUN echo $TZ > /etc/timezone && \
        apt-get update && apt-get install -y tzdata && \
        rm /etc/localtime && \
        ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
        dpkg-reconfigure -f noninteractive tzdata && \
        apt-get clean

#kubectl
RUN curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    curl -L https://amazon-eks.s3-us-west-2.amazonaws.com/${IAM_AUTHENTICATOR_VERSION}/bin/linux/amd64/aws-iam-authenticator -o /usr/local/bin/aws-iam-authenticator && \
    chmod +x /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/aws-iam-authenticator

RUN mkdir -p ~/.jx/bin && \
    curl -L https://github.com/jenkins-x/jx/releases/download/$JX_VERSION/jx-linux-amd64.tar.gz | tar xzv -C /tmp/ \
    && mv /tmp/jx /usr/bin/jx && chmod +x /usr/bin/jx && \
    export PATH=$PATH:/root/.jx/bin && \
    echo 'export PATH=$PATH:/root/.jx/bin' >> /root/.bashrc && \

RUN curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator && \
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
    echo "source <(kubectl completion bash)" >> /root/.bashrc && \
    echo "source <(jx completion bash)" >> /root/.bashrc && \
    wget https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail && chmod +x kubetail && mv kubetail /usr/local/bin && \
    curl --location "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin && \
    echo 'export PATH=$PATH:/root/dev-cheats/' >> /root/.bashrc

# Node.js
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g serverless
