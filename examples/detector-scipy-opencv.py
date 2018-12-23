# Stupid python path shit.
# Instead just add darknet.py to somewhere in your python path
# OK actually that might not be a great idea, idk, work in progress
# Use at your own risk. or don't, i don't care
import sys, os
from ctypes import *

pathToDarknet = "/home/pi/Libraries/yolo/3/darknet-nnpack/darknet-nnpack_global/test builds/darknet-nnpack/"
pathToDarknetPythonLib = os.path.join(pathToDarknet, "python/");
sys.path.append(pathToDarknetPythonLib)
import darknet as dn

from scipy.misc import imread
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
'''
def detect2(net, meta, image, thresh=.5, hier_thresh=.5, nms=.45):
    boxes = dn.make_boxes(net)
    probs = dn.make_probs(net)
    num =   dn.num_boxes(net)
    dn.network_detect(net, image, thresh, hier_thresh, nms, boxes, probs)
    res = []
    for j in range(num):
        for i in range(meta.classes):
            if probs[j][i] > 0:
                res.append((meta.names[i], probs[j][i], (boxes[j].x, boxes[j].y, boxes[j].w, boxes[j].h)))
    res = sorted(res, key=lambda x: -x[1])
    dn.free_ptrs(dn.cast(probs, dn.POINTER(dn.c_void_p)), num)
    return res
'''

def detect2(net, meta, image, thresh=.5, hier_thresh=.5, nms=.45):
    num = c_int(0)
    pnum = pointer(num)
    dets = dn.get_network_boxes(net, image.w, image.h, thresh, hier_thresh, None, 0, pnum)
    num = pnum[0]
    if (nms): dn.do_nms_obj(dets, num, meta.classes, nms);
    res = []
    for j in range(num):
        for i in range(meta.classes):
            if dets[j].prob[i] > 0:
                b = dets[j].bbox
                res.append((meta.names[i], dets[j].prob[i], (b.x, b.y, b.w, b.h)))
    res = sorted(res, key=lambda x: -x[1])
    #dn.free_image(im)
    #dn.free_detections(dets, num)
    return res

if __name__ == "__main__":
    dn.srand(2222222)
    dn.nnp_initialize()

    # Darknet
    print("load network and meta(classes and names)")
    net = dn.load_net(b"../cfg/yolov3-tiny.cfg", b"/home/pi/Libraries/yolo/3/trained_weight/yolov3-tiny.weights", 0)
    meta = dn.load_meta(b"../cfg/coco4examples.data")
    print("using darknet function")
    r = dn.detect(net, meta, b"../data/dog.jpg")
    print (r)

    # scipy
    print("using scipy to pass image to darknet")
    arr= imread(b"../data/dog.jpg")
    im = array_to_image(arr)
    r = detect2(net, meta, im)
    print (r)
    
    # OpenCV
    print("using opencv to pass image to darknet")
    arr = cv2.imread("../data/dog.jpg")
    im = array_to_image(arr)
    dn.rgbgr_image(im)
    r = detect2(net, meta, im)
    print (r)

