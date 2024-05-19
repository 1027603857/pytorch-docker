docker build \
	-f ./Dockerfile \
	--progress=auto \
	-t zjl/torch1.12.1_cuda11.3.1_cudnn8:2024.5.18 \
	--build-arg BASE_IMAGE=nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04 \
	--build-arg PYTHON_VERSION=3.10 \
	--build-arg CUDA_VERSION=11.3 \
	--build-arg CUDA_CHANNEL=nvidia \
	--build-arg PYTORCH_VERSION=1.12.1 \
	--build-arg INSTALL_CHANNEL=pytorch .