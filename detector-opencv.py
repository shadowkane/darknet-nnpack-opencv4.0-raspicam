# Stupid python path shit.
# Instead just add darknet.py to somewhere in your python path
# OK actually that might not be a great idea, idk, work in progress
# Use at your own risk. or don't, i don't care
import sys, os
from ctypes import *
import time
import numpy as np

pathToDarknet = "/home/pi/Libraries/yolo/3/darknet-nnpack/darknet-nnpack_global/test builds/darknet-nnpack/"
pathToDarknetPythonLib = os.path.join(pathToDarknet, "python/");
sys.path.append(pathToDarknetPythonLib)
import darknet as dn

from scipy.misc import imread, imshow
import cv2

def array_to_image(arr):
    arr = arr.transpose(2,0,1)
    c = arr.shape[0]
    h = arr.shape[1]
    w = arr.shape[2]
    arr = (arr/255.0).flatten()
    data = dn.c_array(dn.c_float, arr)
    im = dn.IMAGE(w,h,c,data)
    return im

# use this function if you have used opencv and then the rgbgr_image function from darknet library (this will change the color order so RGB => BGR)
def image_to_array_opencv(im):
    data = np.zeros((im.h, im.w, im.c), np.uint8)
    h = 0
    w = 0
    c = 2
    for index in range(im.h*im.w*im.c):
        data[h][w][c]=(int(im.data[index]*255))
        w+=1
        if(w == im.w):
            w = 0
            h+=1
            if(h == im.h):
                h = 0
                c+=1
                if(c == 3):
                    c = 1
                if(c == 2):
                    c = 0
    return data

# this function we return an array from image without changing the color order.
def image_to_array(im):
    # this use reshape and transpose
    data = np.zeros((im.h * im.w * im.c), np.uint8)
    for index in range(im.h*im.w*im.c):
        data[index] = (int(im.data[index]*255))
    data = data.reshape(im.c, im.h, im.w).transpose(1,2,0)
    return data

# using opencv to draw detected objects.
# set the relative argument to 0 so the box will not be relative the the image itself, and will return the actuel position
def drawDetectedObjects(detectedObjects, image):
    for detectedObject in detectedObjects:
        objectName = detectedObject[0]
        predection = detectedObject[1]
        center_x = detectedObject[2][0]
        center_y = detectedObject[2][1]
        w = detectedObject[2][2]
        h = detectedObject[2][3]
        x = int(center_x - w/2)
        y = int(center_y - h/2)
        w = int(w)
        h = int(h)
        cv2.rectangle(image,(x,y),(x+w,y+h), (0, 255, 0), 2)
        cv2.putText(image, str(objectName.decode('utf-8')), (x, y), cv2.FONT_HERSHEY_SIMPLEX, 0.75, (0,255,0), 2)
    return image

# if you want to draw the boxes inside the image just set drawBoxes to True and set the alphabet
def detect2(net, meta, image, thresh=.5, hier_thresh=.5, nms=.45, drawBoxes = False, alphabet=None):
    num = c_int(0)
    pnum = pointer(num)
    dets = dn.get_network_boxes(net, image.w, image.h, thresh, hier_thresh, None, 1, pnum)
    num = pnum[0]
    if (nms): dn.do_nms_obj(dets, num, meta.classes, nms);   
    res = []
    for j in range(num):
        for i in range(meta.classes):
            if dets[j].prob[i] > 0:
                b = dets[j].bbox
                res.append((meta.names[i], dets[j].prob[i], (b.x, b.y, b.w, b.h)))
    res = sorted(res, key=lambda x: -x[1])
    if drawBoxes == True:
        dn.draw_detections(image, dets, num, thresh, meta.names, alphabet, meta.classes)
    #dn.free_image(image)
    #dn.free_detections(dets, num)
    return res

if __name__ == "__main__":
    dn.srand(222222)
    dn.nnp_initialize()

    # Darknet
    print("load network and meta(classes and names)")
    net = dn.load_net(b"cfg/yolov3-tiny.cfg", b"/home/pi/Libraries/yolo/3/trained_weight/yolov3-tiny.weights", 0)
    meta = dn.load_meta(b"cfg/coco.data")
    alphabet = dn.load_alphabet()
    
    print("using darknet function")
    t = time.time()
    r = dn.detect(net, meta, b"data/dog.jpg")
    print('reading image + detection time: {}'.format(time.time() - t))
    print (r)
    
    # scipy
    print("using scipy to pass image to darknet")
    t = time.time()
    arr= imread(b"data/dog.jpg")
    im = array_to_image(arr)
    print('reading and converting image time: {}'.format(time.time() - t))
    t = time.time()
    r = detect2(net, meta, im, drawBoxes=True, alphabet=alphabet)
    print('detection time: {}'.format(time.time() - t))
    arr = image_to_array(im)
    print (r)
    imshow(arr)
    
    # OpenCV
    print("using opencv to pass image to darknet")
    t = time.time()
    arr = cv2.imread("data/dog.jpg")
    im = array_to_image(arr)
    dn.rgbgr_image(im)
    print('reading and converting image time: {}'.format(time.time() - t))
    t = time.time()
    r = detect2(net, meta, im, drawBoxes=True, alphabet=alphabet)
    print('detection time: {}'.format(time.time() - t))
    arr = image_to_array_opencv(im)
    #drawDetectedObjects(r, arr)
    cv2.imshow("detected image", arr)
    print (r)
    cv2.waitKey()
   


