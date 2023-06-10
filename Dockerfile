
FROM ubuntu:20.04

ARG HOST_GROUP_ID
ARG HOST_USER_ID
ARG HOST_USER_NAME
ENV HOST_GROUP_ID=${HOST_GROUP_ID}
ENV HOST_USER_ID=${HOST_USER_ID}

# Install kubectl 1.21.0
RUN apt-get update && \
    apt-get install -y apt-utils && \
    apt-get install -y gnupg2 && \
    apt-get install -y curl && \
    apt-get install -y apt-transport-https && \
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y kubectl=1.21.0-00

# Install go version 1.61
ENV GO_VERSION=1.16

RUN apt-get update && apt-get install -y wget jq && \
    wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"


# Install cfssl 1.4.1
RUN curl https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssl -o /usr/local/bin/cfssl && \
    chmod +x /usr/local/bin/cfssl

# Install cfssljson 1.4.1
RUN curl https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssljson -o /usr/local/bin/cfssljson && \
    chmod +x /usr/local/bin/cfssljson

# Install AWS CLI
RUN  apt-get update && apt-get install -y unzip && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -fr ./aws awscliv2.zip

# Install tmux 2.8-3
RUN apt-get update && \
    apt-get install -y tmux

# Install shunit2 for testing bash scrips
RUN curl -o shunit2 https://raw.githubusercontent.com/kward/shunit2/master/shunit2 && \
    chmod +x shunit2 && \
    mv shunit2 /usr/local/bin/

# Set default AWS region
ENV AWS_DEFAULT_REGION=us-east-1

# Install terraform
ENV TF_VERSION=1.3.9
RUN apt-get update && \
    apt-get install -y unzip wget less openssh-client && \
    wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
    unzip terraform_${TF_VERSION}_linux_amd64.zip -d /usr/local/bin/ && \
    rm terraform_${TF_VERSION}_linux_amd64.zip

# Handle local user:
RUN groupadd --gid=${HOST_GROUP_ID} ${HOST_USER_NAME}
RUN useradd \
    -d /home/${HOST_USER_NAME} \
    --uid=${HOST_USER_ID} \
    --gid=${HOST_GROUP_ID} \
    ${HOST_USER_NAME}
USER ${HOST_USER_NAME}
