import numpy as np
from openexr_numpy import imwrite
import struct

RESOLUTION = 139

def read_bin(fileName: str) -> list[list[float]]:
    '''
    Reads file and returns list of floats.
    '''
    fileContent: bytes
    with open(fileName, mode='rb') as file: # b is important -> binary
        fileContent = file.read()

    floatArr: list[float] = []

    ctr = 0
    imageSize = RESOLUTION * RESOLUTION * 3
    while ctr < imageSize:
        floatArr.append(struct.unpack("f", fileContent[ctr : ctr + 4])[0])
        ctr += 4

    return floatArr


if __name__ == '__main__':
    rawList = read_bin('output.bin')
    print(rawList)
    # nparr = np.asarray(rawList, dtype=np.float32)
    # print(nparr)
    # imwrite('final.exr', nparr)