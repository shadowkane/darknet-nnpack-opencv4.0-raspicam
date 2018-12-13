#ifdef OPENCV

#include "stdio.h"
#include "stdlib.h"
#include "opencv2/opencv.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/core/version.hpp"
#include "opencv2/videoio/videoio.hpp"
#include "opencv2/imgcodecs/imgcodecs.hpp"

#include "image.h"

using namespace cv;

#ifdef RASPICAM
#include "raspicam/raspicam_cv.h"
using namespace raspicam;
#endif // RASPICAM

extern "C" {
/*
IplImage *image_to_ipl(image im)
{
    int x,y,c;
    IplImage *disp = cvCreateImage(cvSize(im.w,im.h), IPL_DEPTH_8U, im.c);
    int step = disp->widthStep;
    for(y = 0; y < im.h; ++y){
        for(x = 0; x < im.w; ++x){
            for(c= 0; c < im.c; ++c){
                float val = im.data[c*im.h*im.w + y*im.w + x];
                disp->imageData[y*step + x*im.c + c] = (unsigned char)(val*255);
            }
        }
    }
    return disp;
}

image ipl_to_image(IplImage* src)
{
    int h = src->height;
    int w = src->width;
    int c = src->nChannels;
    image im = make_image(w, h, c);
    unsigned char *data = (unsigned char *)src->imageData;
    int step = src->widthStep;
    int i, j, k;

    for(i = 0; i < h; ++i){
        for(k= 0; k < c; ++k){
            for(j = 0; j < w; ++j){
                im.data[k*w*h + i*w + j] = data[i*step + j*c + k]/255.;
            }
        }
    }
    return im;
}
*/
Mat image_to_mat(image im)
{
    //printf("image change to mat");
    image copy = copy_image(im);
    constrain_image(copy);
    if(im.c == 3) rgbgr_image(copy);
    /*
    IplImage *ipl = image_to_ipl(copy);
    Mat m = cvarrToMat(ipl, true);
    cvReleaseImage(&ipl);
    */
    Mat m;
    if(copy.c==3)
        m = Mat(copy.h, copy.w, CV_8UC3);
    else
        m = Mat(copy.h, copy.w, CV_8UC1);
    int x,y,c;
    int step = copy.c * copy.w;
    for(y = 0; y < copy.h; ++y){
        for(x = 0; x < copy.w; ++x){
            for(c= 0; c < copy.c; ++c){
                float val = copy.data[c*copy.h*copy.w + y*copy.w + x];
                m.data[y*step + x*copy.c + c] = (unsigned char)(val*255);
                //printf("%d, ",c*copy.h*copy.w + y*copy.w + x);
                //printf("%u, ", val);
            }
        }
    }
    if(im.c == 3)
    free_image(copy);
    return m;
}

image mat_to_image(Mat m)
{
    /*IplImage ipl = m;
    image im = ipl_to_image(&ipl);*/
    //printf("mat change to image");
    int h = m.rows;
    int w = m.cols;
    int c = m.channels();
    image im = make_image(w, h, c);

    int step = w*c;
    int i, j, k;

    /*for(i = 0; i < h; ++i){
        for(k= 0; k < c; ++k){
            for(j = 0; j < w; ++j){
                im.data[k*w*h + i*w + j] = (unsigned char)(m.data[i*step + j*c + k])/255.;
                //printf("%d, ",k*w*h + i*w + j);
                //printf("%f, ",im.data[k*w*h + i*w + j]);
            }
        }
    }*/
    for(i = 0; i < h; ++i){
        for(j = 0; j < w; ++j){
            for(k= 0; k < c; ++k){
                im.data[k*h*w + i*w + j] = (unsigned char)(m.data[i*step + j*c + k])/255.0;
            }
        }
    }
    rgbgr_image(im);
    return im;
}

void *open_video_stream(const char *f, int c, int w, int h, int fps, bool *isWebcam)
{
    /*
    VideoCapture *cap;
    if(f) cap = new VideoCapture(f);
    else cap = new VideoCapture(c);
    if(!cap->isOpened()) return 0;
    if(w) cap->set(CV_CAP_PROP_FRAME_WIDTH, w);
    if(h) cap->set(CV_CAP_PROP_FRAME_HEIGHT, h);
    if(fps) cap->set(CV_CAP_PROP_FPS, w);
    return (void *) cap;
    */
    *isWebcam = false;

#ifdef RASPICAM
    RaspiCam_Cv *webcam;
#endif // RASPICAM
    VideoCapture *cap;
    if(f){
        *isWebcam = false;
        cap = new VideoCapture(f);
    }else{
        if(c==9999){
#ifdef RASPICAM
            *isWebcam = true;
            webcam = new RaspiCam_Cv();
#else
            printf("this magic number is for raspicam, be real, do you have 9999 camera?!!");
            return 0;
#endif // RASPICAM
        }
        else{
            *isWebcam = false;
            cap = new VideoCapture(c);
        }
    }
    if(*isWebcam==false){
        if(!cap->isOpened()) return 0;
        if(w) cap->set(CAP_PROP_FRAME_WIDTH, w);
        if(h) cap->set(CAP_PROP_FRAME_HEIGHT, h);
        if(fps) cap->set(CAP_PROP_FPS, fps);
        if(c==0) cap->set(CAP_PROP_FORMAT, -1);
        else if(c==1) cap->set(CAP_PROP_FORMAT, CV_8UC1);
        else if(c==3) cap->set(CAP_PROP_FORMAT, CV_8UC3);
        else fprintf(stderr, "OpenCV can't force opencv cam with %d channels\n", c);
        return (void *) cap;
    }else{
#ifdef RASPICAM
        if(w) webcam->set(CAP_PROP_FRAME_WIDTH, w);
        if(h) webcam->set(CAP_PROP_FRAME_HEIGHT, h);
        if(fps) webcam->set(CAP_PROP_FPS, fps);
        if(c==0) webcam->set(CAP_PROP_FORMAT, -1);
        else if(c==1) webcam->set(CAP_PROP_FORMAT, CV_8UC1);
        else if(c==3) webcam->set(CAP_PROP_FORMAT, CV_8UC3);
        else fprintf(stderr, "OpenCV can't force opencv cam with %d channels\n", c);
        printf(" it's webca => w=%d, h=%d \n",w,h);
        if(!webcam->open()) return 0;
        return (void *) webcam;
#else
        return 0;
#endif // RASPICAM
    }

}

image get_image_from_stream(void *p, bool isWebcam)
{
    if(isWebcam == false){
        VideoCapture *cap = (VideoCapture *)p;
        Mat m;
        *cap >> m;
        if(m.empty()) return make_empty_image(0,0,0);
        return mat_to_image(m);
    }
    else{
#ifdef RASPICAM
        RaspiCam_Cv *webcam = (RaspiCam_Cv *)p;
        webcam->grab();
        Mat m;
        webcam->retrieve(m);
        if(m.empty()) return make_empty_image(0,0,0);
        return mat_to_image(m);
#else
        return make_empty_image(0,0,0);
#endif // RASPICAM
    }
}

image load_image_cv(char *filename, int channels)
{
    printf("load image from image opencv! \n");
    int flag = -1;
    if (channels == 0) flag = -1;
    else if (channels == 1) flag = 0;
    else if (channels == 3) flag = 1;
    else {
        fprintf(stderr, "OpenCV can't force load with %d channels\n", channels);
    }
    Mat m;
    m = imread(filename, flag);
    if(!m.data){
        fprintf(stderr, "Cannot load image \"%s\"\n", filename);
        char buff[256];
        sprintf(buff, "echo %s >> bad.list", filename);
        system(buff);
        return make_image(10,10,3);
        //exit(0);
    }
    image im = mat_to_image(m);
    return im;
}

int show_image_cv(image im, const char* name, int ms)
{
    Mat m = image_to_mat(im);
    imshow(name, m);
    int c = waitKey(ms);
    if (c != -1) c = c%256;
    return c;
}

void make_window(char *name, int w, int h, int fullscreen)
{
    namedWindow(name, WINDOW_NORMAL);
    if (fullscreen) {
        setWindowProperty(name, WND_PROP_FULLSCREEN, WINDOW_FULLSCREEN);
    } else {
        resizeWindow(name, w, h);
        if(strcmp(name, "Demo") == 0) moveWindow(name, 0, 0);
    }
}

}

#endif
