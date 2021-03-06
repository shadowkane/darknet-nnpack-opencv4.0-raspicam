GPU=0
CUDNN=0
OPENCV=1
RASPICAM=1
NNPACK=1
ARM_NEON=1
OPENMP=0
DEBUG=0

ARCH= -gencode arch=compute_30,code=sm_30 \
      -gencode arch=compute_35,code=sm_35 \
      -gencode arch=compute_50,code=[sm_50,compute_50] \
      -gencode arch=compute_52,code=[sm_52,compute_52]
#      -gencode arch=compute_20,code=[sm_20,sm_21] \ This one is deprecated?

# This is what I use, uncomment if you know your arch and want to specify
# ARCH= -gencode arch=compute_52,code=compute_52

VPATH=./src/:./examples
SLIB=libdarknet.so
ALIB=libdarknet.a
EXEC=darknet
OBJDIR=./obj/

#the path of your NNPACK
NNPACKDIR=/home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/

# function to scan directory tree
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

CC= gcc
CPP= g++ -std=c++11
NVCC= nvcc 
AR= ar
ARFLAGS= rcs
OPTS= -Ofast
LDFLAGS= -lm -pthread -lrt
COMMON= -Iinclude/ -Isrc/
CFLAGS= -Wall -Wno-unused-result -Wno-unknown-pragmas -Wfatal-errors -fPIC

ifeq ($(OPENMP), 1) 
CFLAGS+= -fopenmp
endif

ifeq ($(DEBUG), 1) 
OPTS= -O0 -g
endif

CFLAGS+=$(OPTS)

ifeq ($(OPENCV), 1) 
COMMON+= -DOPENCV `pkg-config --cflags opencv` -lstdc++
CFLAGS+= -DOPENCV `pkg-config --cflags opencv` -lstdc++
LDFLAGS+= `pkg-config --libs opencv` -lstdc++
#COMMON+= `pkg-config --cflags opencv`
endif

ifeq ($(RASPICAM), 1) 
COMMON+= -DRASPICAM
CFLAGS+= -DRASPICAM
LDFLAGS+= `pkg-config --libs raspicam` 
COMMON+= `pkg-config --cflags raspicam` 
endif

ifeq ($(GPU), 1) 
COMMON+= -DGPU -I/usr/local/cuda/include/
CFLAGS+= -DGPU
LDFLAGS+= -L/usr/local/cuda/lib64 -lcuda -lcudart -lcublas -lcurand
endif

ifeq ($(CUDNN), 1) 
COMMON+= -DCUDNN 
CFLAGS+= -DCUDNN
LDFLAGS+= -lcudnn
endif

ifeq ($(NNPACK), 1)
#NNPACKOBJS = /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/init.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/convolution-inference.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/convolution-input-gradient.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/convolution-kernel-gradient.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/convolution-output.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/fully-connected-inference.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/fully-connected-output.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/pooling-output.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/relu-input-gradient.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/relu-output.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/softmax-output.c.o
#NNPACKOBJS+= /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/psimd/blas/shdotxf.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/psimd/2d-fourier-8x8.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/psimd/2d-fourier-16x16.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/psimd/2d-winograd-8x8-3x3.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/psimd/fft-block-mac.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/psimd/relu.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/psimd/softmax.c.o
#NNPACKOBJS+= /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/neon/blas/c4gemm.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/neon/blas/c4gemm-conjb.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/neon/blas/c4gemm-conjb-transc.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/neon/blas/conv1x1.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/neon/blas/s4c2gemm.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/neon/blas/s4c2gemm-conjb.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/neon/blas/s4c2gemm-conjb-transc.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/neon/blas/s4gemm.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/neon/blas/sdotxf.c.o /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/src/neon/blas/sgemm.c.o
#NNPACKOBJS+= /home/pi/Programs/NNPACK/NNPACK-darknet/NNPACK-darknet/build/deps/pthreadpool/src/threadpool-pthreads.c.o

NNPACKOBJS := $(call rwildcard,$(NNPACKDIR)build/src/,*.o)
NNPACKOBJS += $(call rwildcard,$(NNPACKDIR)build/deps/,*.o)
COMMON+= -DNNPACK -L$(NNPACKDIR)lib -I$(NNPACKDIR)include # this was only -DNNPACK 
CFLAGS+= -DNNPACK -I/src/include -I/src/local/include -I$(NNPACKDIR)include # this was only -DNNPACK and i added -lnnpack -lpthreadpool but i deleted and added -I/src/include -I/src/lib -I/src/local/include -I/src/local/lib and it shows me a pthread_pool problem
LDFLAGS+= -L/src/lib -L/src/local/lib -L$(NNPACKDIR)lib -lnnpack -lpthreadpool -lgoogletest-core
endif

ifeq ($(ARM_NEON), 1)
COMMON+= -DARM_NEON
CFLAGS+= -DARM_NEON  -march=armv7-a -mfloat-abi=hard -mfpu=neon-vfpv4 -funsafe-math-optimizations -ftree-vectorize
endif

OBJ=gemm.o utils.o cuda.o deconvolutional_layer.o convolutional_layer.o list.o image.o activations.o im2col.o col2im.o blas.o crop_layer.o dropout_layer.o maxpool_layer.o softmax_layer.o data.o matrix.o network.o connected_layer.o cost_layer.o parser.o option_list.o detection_layer.o route_layer.o upsample_layer.o box.o normalization_layer.o avgpool_layer.o layer.o local_layer.o shortcut_layer.o logistic_layer.o activation_layer.o rnn_layer.o gru_layer.o crnn_layer.o demo.o batchnorm_layer.o region_layer.o reorg_layer.o tree.o  lstm_layer.o l2norm_layer.o yolo_layer.o iseg_layer.o image_opencv.o
EXECOBJA=captcha.o lsd.o super.o art.o tag.o cifar.o go.o rnn.o segmenter.o regressor.o classifier.o coco.o yolo.o detector.o nightmare.o instance-segmenter.o darknet.o

ifeq ($(GPU), 1) 
LDFLAGS+= -lstdc++ 
OBJ+=convolutional_kernels.o deconvolutional_kernels.o activation_kernels.o im2col_kernels.o col2im_kernels.o blas_kernels.o crop_layer_kernels.o dropout_layer_kernels.o maxpool_layer_kernels.o avgpool_layer_kernels.o
endif

EXECOBJ = $(addprefix $(OBJDIR), $(EXECOBJA))
OBJS = $(addprefix $(OBJDIR), $(OBJ))
DEPS = $(wildcard src/*.h) Makefile include/darknet.h

all: obj backup results $(SLIB) $(ALIB) $(EXEC)
#all: obj  results $(SLIB) $(ALIB) $(EXEC)


$(EXEC): $(EXECOBJ) $(ALIB)
	$(CC) $(COMMON) $(CFLAGS) $^ -o $@ $(LDFLAGS) $(ALIB)

$(ALIB): $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

$(SLIB): $(OBJS) $(NNPACKOBJS)
	$(CC) $(COMMON) $(CFLAGS) $(LDFLAGS) -shared $^ -o $@ # this was CC not CPP

$(OBJDIR)%.o: %.cpp $(DEPS)
	$(CPP) $(COMMON) $(CFLAGS) $(LDFLAGS) -c $< -o $@

$(OBJDIR)%.o: %.c $(DEPS)
	$(CC) $(COMMON) $(CFLAGS) -c $< -o $@

$(OBJDIR)%.o: %.cu $(DEPS)
	$(NVCC) $(ARCH) $(COMMON) --compiler-options "$(CFLAGS)" -c $< -o $@

obj:
	mkdir -p obj
backup:
	mkdir -p backup
results:
	mkdir -p results

.PHONY: clean

clean:
	rm -rf $(OBJS) $(SLIB) $(ALIB) $(EXEC) $(EXECOBJ) $(OBJDIR)/*

