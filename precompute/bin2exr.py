import numpy as np
from openexr_numpy import imwrite

HEIGHT = 4096
WIDTH = 512

if __name__ == '__main__':
    with open('output.bin', 'rb') as f:
        rawList = np.fromfile(f, dtype=np.float32)
    image = np.reshape(rawList, [HEIGHT, WIDTH, 3])
    image = np.flip(image, 0)
    # print(image)
    imwrite('final.exr', image)