import numpy as np
import cv2
import os
import struct
import time

print(os.listdir(os.getcwd() + "\charset"))

bit_file = open("charset.bit", "wb")

f_num = len(os.listdir(os.getcwd() + "/charset"))
print(f_num)

for file in os.listdir(os.getcwd() + "/charset"):
    img = cv2.imread("charset/" + file)
    img = cv2.resize(img, (16, 8), interpolation=cv2.INTER_CUBIC)
    shape = np.shape(img)
    print(shape)
    for i in range(shape[1]):
        for j in range(shape[0]):
            if(img[j][i][0] > 128):
                bit_file.write(struct.pack("H", 0x0000))
            else:
                bit_file.write(struct.pack("H", 0xFFFF))
    
bit_file.close()
    #print(np.shape(img))