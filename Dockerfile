ARG BASE_IMAGE=nvidia/cuda:12.1.0-cudnn8-devel-ubuntu20.04
ARG PYTHON_VERSION=3.8
ARG CUDA_VERSION=12.1
ARG PYTORCH_VERSION=2.3

FROM ${BASE_IMAGE} as dev-base
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        ccache cmake \
        curl git vim \
        openssh-server \
        libgl1-mesa-glx \
        libjpeg-dev \
        libpng-dev && \
    rm -rf /var/lib/apt/lists/*
RUN /usr/sbin/update-ccache-symlinks
RUN mkdir /opt/ccache && ccache --set-config=cache_dir=/opt/ccache
ENV PATH /opt/conda/bin:$PATH

FROM dev-base as conda
# Automatically set by buildx
ARG TARGETPLATFORM
# translating Docker's TARGETPLATFORM into miniconda arches
RUN curl -fsSL -v -o ~/miniconda.sh -O "https://repo.anaconda.com/miniconda/Miniconda3-py38_23.11.0-2-Linux-x86_64.sh"
RUN chmod +x ~/miniconda.sh && \
    bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda install -y python=${PYTHON_VERSION} cmake conda-build pyyaml numpy ipython && \
    /opt/conda/bin/python -mpip install astunparse expecttest future numpy psutil pyyaml requests \
        setuptools six types-dataclasses typing_extensions sympy && \
    /opt/conda/bin/conda clean -ya && \
    ccache -C

FROM conda as conda-installs
ARG CUDA_CHANNEL=nvidia
ARG INSTALL_CHANNEL=pytorch
ENV CONDA_OVERRIDE_CUDA=${CUDA_VERSION}
# Automatically set by buildx
RUN /opt/conda/bin/conda install -c "${INSTALL_CHANNEL}" -y python=${PYTHON_VERSION}
ARG TARGETPLATFORM
# On arm64 we can only install wheel packages
RUN /opt/conda/bin/conda install -c "${INSTALL_CHANNEL}" -c "${CUDA_CHANNEL}" -y "python=${PYTHON_VERSION}" \
    pytorch==2.3.0 torchvision==0.18.0 torchaudio==2.3.0 pytorch-cuda=12.1 && \
    /opt/conda/bin/conda install -y jupyter notebook && \
    /opt/conda/bin/conda clean -ya && \
    /opt/conda/bin/pip install torchelastic

FROM conda-installs as official
LABEL com.nvidia.volumes.needed="nvidia_driver"

# Config ssh
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'cd /workspace' >> /root/.bashrc && \
    echo 'service ssh start' >> /root/.bashrc && \
    echo 'export $(cat /proc/1/environ |tr "\\0" "\\n" | xargs)' >> /etc/profile

# Optimize access speed in Chinese mainland
RUN /opt/conda/bin/conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/ && \
    /opt/conda/bin/conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/ && \
    /opt/conda/bin/conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/ && \
    /opt/conda/bin/conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/ && \
    /opt/conda/bin/conda config --set show_channel_urls yes && \
    /opt/conda/bin/conda update conda && \
    /opt/conda/bin/pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64:/usr/local/tensorrt/lib

# Install tensorflow in conda env
# pip install tensorflow==2.13.0 tensorrt==8.6
# conda env config vars set LD_LIBRARY_PATH=$CONDA_PREFIX/lib/python3.10/site-packages/tensorrt:$LD_LIBRARY_PATH -n env_name

ENV PYTORCH_VERSION ${PYTORCH_VERSION}
WORKDIR /workspace
