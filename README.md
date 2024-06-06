# pytorch镜像
配置在conda下的pytorch镜像，自己做了一些调整。

启动命令
```
docker run -it -d -p 1234:22 -v /home/workspack:/workspace --gpus all --shm-size=8g --name pytorch 1027603857/pytorch bash
```
安装tensorflow
```
# tensorflow==2.13.0 tensorrt==8.6
docker run -it -d -p 1234:22 -v /YOUR_WORKSPACE:/workspace -v /TENSORRT:/TENSORRT --gpus all --shm-size=8g --name pytorch 1027603857/pytorch bash
```
