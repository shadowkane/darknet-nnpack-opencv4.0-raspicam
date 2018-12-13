# darknet-nnpack-opencv4.0-raspicam
this library was test with raspberry pi 3, using opencv 4.0 and raspicam.
darknet nnpack uses nnapck to optimize it without using GPU.

originally this library created by pjreddie, (link for darknet website: https://pjreddie.com)
and optimized by digitalbrain79 by adding nnpack, (link for github: https://github.com/digitalbrain79/darknet-nnpack)
and i just ipdate it to work with opencv 4.0, and uses raspicam for raspberry pi users.

i will clone the same steps as digitalbrain79 mentions:

# Darknet with NNPACK
NNPACK was used to optimize [Darknet](https://github.com/pjreddie/darknet) without using a GPU. It is useful for embedded devices using ARM CPUs.

## Build from Raspberry Pi 3
Log in to Raspberry Pi using SSH.<br/>
Install [PeachPy](https://github.com/Maratyszcza/PeachPy) and [confu](https://github.com/Maratyszcza/confu)
```
sudo pip install --upgrade git+https://github.com/Maratyszcza/PeachPy
sudo pip install --upgrade git+https://github.com/Maratyszcza/confu
```
Install [Ninja](https://ninja-build.org/)
```
git clone https://github.com/ninja-build/ninja.git
cd ninja
git checkout release
./configure.py --bootstrap
export NINJA_PATH=$PWD
```
Install clang
```
sudo apt-get install clang
```
Install [NNPACK-darknet](https://github.com/digitalbrain79/NNPACK-darknet.git)
```
git clone https://github.com/digitalbrain79/NNPACK-darknet.git
cd NNPACK-darknet
confu setup
python ./configure.py --backend auto
$NINJA_PATH/ninja
sudo cp -a lib/* /usr/lib/
sudo cp include/nnpack.h /usr/include/
sudo cp deps/pthreadpool/include/pthreadpool.h /usr/include/
```
Build darknet-nnpack
(note: you can change the makefile to enable or disable any dependency, by default RASPICAM=1, OPENCV=1)
```
git clone https://github.com/digitalbrain79/darknet-nnpack.git
cd darknet-nnpack
make
```

## Test (digitalbrain79 test)
The weight files can be downloaded from the [YOLO homepage](https://pjreddie.com/darknet/yolo/).
```
YOLOv2-tiny
./darknet detector test cfg/coco.data cfg/yolov2-tiny.cfg yolov2-tiny.weights data/person.jpg
YOLOv3-tiny
./darknet detector test cfg/coco.data cfg/yolov3-tiny.cfg yolov3-tiny.weights data/person.jpg
```
## other test
i had to create a new command to run the camera because i didn't manage to make the command "demo" works.
```
opencv uses camera, the default index is 0:
 ./darknet detector demotest cfg/coco.data cfg/yolov3-tiny.cfg yolov3-tiny.weights
to change the thresh
 ./darknet detector demotest cfg/coco.data cfg/yolov3-tiny.cfg yolov3-tiny.weights -thresh 0.2
to change camera index (don't use 9999, unless you have 9999 camera pluged in your system using 9999 usb port :/ !!)
 ./darknet detector demotest cfg/coco.data cfg/yolov3-tiny.cfg yolov3-tiny.weights -c 1
if you use raspicam, yeah,now use that magic number 9999 (-thresh it's an option)
 ./darknet detector demotest cfg/coco.data cfg/yolov3-tiny.cfg yolov3-tiny.weights -thresh 0.2 -c 9999
```

## Result (digitalbrain79 results)
Model | Build Options | Prediction Time (seconds)
:-:|:-:|:-:
YOLOv2-tiny | NNPACK=1,ARM_NEON=1 | 1.8
YOLOv2-tiny | NNPACK=0,ARM_NEON=0 | 31
YOLOv3-tiny | NNPACK=1,ARM_NEON=1 | 2.0
YOLOv3-tiny | NNPACK=0,ARM_NEON=0 | 32

# My result
Model | Build Options | Prediction Time (seconds)
:-:|:-:|:-:
YOLOv3-tiny | NNPACK=1,ARM_NEON=1, OPENCV=1,RASPICAM=1 | 1.5 (i was able to get around 1.2 sec)

Note: i'm still working on this library. at least i need to figure out the problem with "demo". feel free to test this library by yourself, change it and try to get more speed and share with us your work.
as i said, i'm working with raspberry pi. my goal is to get less then 1 sec for prediction time, using a resolution nothing less then 640x480(3 channels) in case you asking.

