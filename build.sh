IMAGE_TAG="torch2.3.0_cuda12.1_cudnn8_devel_2024.7.17"
docker build -f ./Dockerfile --progress=auto -t "1027603857/pytorch:${IMAGE_TAG}" .
docker push "1027603857/pytorch:${IMAGE_TAG}"
