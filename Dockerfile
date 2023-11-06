ARG BASE_IMAGE=python:3.10.13-bullseye

FROM ${BASE_IMAGE}

ARG BASE_IMAGE

WORKDIR $HOME

# If this arg is not "autoscaler" then no autoscaler requirements will be included
ARG AUTOSCALER="autoscaler"
ENV TZ=Europe/Brussels
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata

SHELL ["/bin/bash", "-c"]
RUN sudo apt-get update -y && sudo apt-get upgrade -y \
    && sudo apt-get install -y \
        git \
        libjemalloc-dev \
        wget \
        cmake \
        g++ \ 
        zlib1g-dev \
        $(if [ "$AUTOSCALER" = "autoscaler" ]; then echo \
            tmux \
            screen \
            rsync \
            netbase \
            openssh-client \
            gnupg; fi)

RUN pip install --no-cache-dir \
        flatbuffers \
        cython==0.29.32 \
        # Necessary for Dataset to work properly.
        numpy\>=1.20 \
        psutil \
    # To avoid the following error on Jenkins:
    # AttributeError: 'numpy.ufunc' object has no attribute '__module__'
    && pip uninstall -y dask \
    && (if [ "$AUTOSCALER" = "autoscaler" ]; \
        then pip --no-cache-dir install \
        "redis>=3.5.0,<4.0.0" \
        "six==1.13.0" \
        "boto3==1.26.76" \
        "pyOpenSSL==22.1.0" \
        "cryptography==38.0.1" \
        "google-api-python-client==1.7.8" \
        "google-oauth" \
        "azure-cli-core==2.40.0" \
        "azure-identity==1.10.0" \
        "azure-mgmt-compute==23.1.0" \
        "azure-mgmt-network==19.0.0" \
        "azure-mgmt-resource==20.0.0" \
        "msrestazure==0.6.4"; \
    fi;)

RUN sudo rm -rf /var/lib/apt/lists/* \
    && sudo apt-get clean