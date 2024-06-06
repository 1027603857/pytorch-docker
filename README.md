# pytorch镜像
配置在conda下的pytorch镜像，自己做了一些调整。

启动命令

docker run -it -d -p 1234:22 -v /home/workspack:/workspace --gpus all --name pytorch -e NVIDIA_VISIBLE_DEVICES=YOUR_GPU_LABELS 1027603857/pytorch bash

安装tensorflow

conda容器内执行

pip install tensorflow==2.13.0 tensorrt==8.6
conda env config vars set LD_LIBRARY_PATH=$CONDA_PREFIX/lib/python3.10/site-packages/tensorrt:$LD_LIBRARY_PATH -n env_name
