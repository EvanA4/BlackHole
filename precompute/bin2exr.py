import numpy as np
from openexr_numpy import imwrite
import struct

RESOLUTION = 100

def read_bin(fileName: str) -> list[list[float]]:
    '''
    Reads file and returns list of floats.
    '''
    fileContent: bytes
    with open(fileName, mode='rb') as file: # b is important -> binary
        fileContent = file.read()

    floatArr: list[list[float]] = []
    for rowNum in range(RESOLUTION):
        floatArr.append([])

    ctr = 0
    for rowNum in range(RESOLUTION):
        for colNum in range(RESOLUTION):
            pixel = []
            for i in range(3):
                pixel.append(struct.unpack("f", fileContent[ctr : ctr + 4])[0])
                ctr += 4
            floatArr[RESOLUTION - rowNum - 1].append(pixel)

    return floatArr


if __name__ == '__main__':
    rawList = read_bin('output.bin')
    # print(rawList[0])
    nparr = np.asarray(rawList, dtype=np.float32)
    print(nparr)
    # imwrite('final.exr', nparr)