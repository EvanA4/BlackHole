import numpy as np
from openexr_numpy import imwrite
import struct

RESOLUTION = 512

if __name__ == '__main__':
    with open('output.bin', 'rb') as f:
        rawList = np.fromfile(f, dtype=np.float32)
    image = np.reshape(rawList, [RESOLUTION, RESOLUTION, 3])
    print(image)
    imwrite('final.exr', image)