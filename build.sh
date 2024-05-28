IMAGE_TAG="torch1.12.1_cuda11.3.1_cudnn8_devel_2024.5.28"
docker build -f ./Dockerfile --progress=auto -t "1027603857/pytorch:${IMAGE_TAG}" .
docker push "1027603857/pytorch:${IMAGE_TAG}"
