IMAGE_TAG="1027603857/torch1.12.1_cuda11.3.1_cudnn8_devel:2024.5.19"
docker build -f ./Dockerfile --progress=auto -t ${IMAGE_TAG}
docker push 1027603857/${IMAGE_TAG}
