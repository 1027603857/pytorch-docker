ARG BASE_IMAGE=nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04
ARG PYTHON_VERSION=3.10
ARG CUDA_VERSION=11.3
ARG PYTORCH_VERSION=1.12.1

FROM ${BASE_IMAGE} as dev-base
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        ccache \
        cmake \
        curl \
        git \
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
RUN curl -fsSL -v -o ~/miniconda.sh -O  "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
RUN chmod +x ~/miniconda.sh && \
    bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda install -y python=${PYTHON_VERSION} cmake conda-build pyyaml numpy ipython && \
    /opt/conda/bin/python -mpip install astunparse expecttest future numpy psutil pyyaml requests \
        setuptools six types-dataclasses typing_extensions sympy && \
    /opt/conda/bin/conda clean -ya

FROM conda as conda-installs
ARG CUDA_CHANNEL=nvidia
ARG INSTALL_CHANNEL=pytorch
ENV CONDA_OVERRIDE_CUDA=${CUDA_VERSION}
# Automatically set by buildx
RUN /opt/conda/bin/conda install -c "${INSTALL_CHANNEL}" -y python=${PYTHON_VERSION}
ARG TARGETPLATFORM
# On arm64 we can only install wheel packages
RUN /opt/conda/bin/conda install -c "${INSTALL_CHANNEL}" -c "${CUDA_CHANNEL}" -y "python=${PYTHON_VERSION}" pytorch==1.12.1 torchvision==0.13.1 torchaudio==0.12.1 cudatoolkit=11.3
RUN /opt/conda/bin/conda clean -ya
RUN /opt/conda/bin/pip install torchelastic tensorflow==2.11.0

FROM ${BASE_IMAGE} as official
LABEL com.nvidia.volumes.needed="nvidia_driver"
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	openssh-server \
        ca-certificates \
	libgl1-mesa-glx \
        libjpeg-dev \
        libpng-dev && \
    rm -rf /var/lib/apt/lists/*
# Config ssh
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
        echo "service ssh start" >> /root/.bashrc && \
        echo "export \$(cat /proc/1/environ |tr '\0' '\n' | xargs)" >> /etc/profile
COPY --from=conda-installs /opt/conda /opt/conda
# Optimize access speed in mainland
RUN /opt/conda/bin/conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
RUN /opt/conda/bin/conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
RUN /opt/conda/bin/conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
RUN /opt/conda/bin/conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/
RUN /opt/conda/bin/conda config --set show_channel_urls yes
RUN /opt/conda/bin/conda update conda
RUN /opt/conda/bin/pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

ENV PATH /opt/conda/bin:$PATH
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV PYTORCH_VERSION ${PYTORCH_VERSION}
WORKDIR /workspace