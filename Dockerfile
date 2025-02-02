# FROM python:3.10.5-slim

# ARG KUBESPRAY_BRANCH=release-2.17
# ARG TZ=Etc/UTC

# WORKDIR /kubespray

# RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
#     && apt-get update \
#     && apt-get install -y --no-install-recommends git sshpass build-essential libssl-dev \
#     && apt-get purge -y --auto-remove \
#     && rm -rf /var/lib/apt/lists/* \
#     && git clone --branch $KUBESPRAY_BRANCH https://github.com/kubernetes-sigs/kubespray.git /kubespray \
#     && /usr/local/bin/python3 -m pip install --no-cache-dir -r requirements.txt

##################################################################################################################

# Use imutable image tags rather than mutable tags (like ubuntu:20.04)
FROM ubuntu:focal-20220531

ARG TZ=Etc/UTC
ARG KUBESPRAY_BRANCH=release-2.19
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && apt update -y \
    && apt install -y \
    libssl-dev python3-dev python3-pip sshpass rsync curl \
    && rm -rf /var/lib/apt/lists/*

# Some tools like yamllint need this
# Pip needs this as well at the moment to install ansible
# (and potentially other packages)
# See: https://github.com/pypa/pip/issues/10219
ENV LANG=C.UTF-8

WORKDIR /kubespray

COPY ./kubespray .

RUN /usr/bin/python3 -m pip install --no-cache-dir pip -U \
    && python3 -m pip install --no-cache-dir -r requirements.txt

RUN ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" \
    && KUBE_VERSION=$(sed -n 's/^kube_version: //p' roles/kubespray-defaults/defaults/main.yaml) \
    && curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/$ARCH/kubectl \
    && chmod a+x kubectl \
    && mv kubectl /usr/local/bin/kubectl \
    && curl -LO https://github.com/mikefarah/yq/releases/download/v4.25.2/yq_linux_$ARCH \
    && chmod a+x yq_linux_$ARCH \
    && mv yq_linux_$ARCH /usr/local/bin/yq
