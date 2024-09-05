#include <stdio.h>
#include <stdlib.h>

int main() {
    FILE *fptr = fopen("output.bin", "rb");
    const int BATCHSIZE = 2048;
    const int RESOLUTION = 1024;

    // allocate all the memory for the 3D array
    float ***image = (float ***) calloc(RESOLUTION, sizeof(float **));

    // create each row...
    for (int i = 0; i < RESOLUTION; ++i) {
        float **row = (float **) calloc(RESOLUTION, sizeof(float *));

        // create each column...
        for (int j = 0; j < RESOLUTION; ++j) {
            float *col = (float *) calloc(3, sizeof(float)); // a column is three zeros
            row[j] = col;
        }

        image[i] = row;
    }

    int ctr = 0;
    float *buffer = (float *) calloc(BATCHSIZE, sizeof(float));

    // Handle all buffer reads
    int numRead = fread(buffer, sizeof(float), BATCHSIZE, fptr);
    int numItr = 0;
    while (numRead) {
        for (int i = 0; i < numRead; ++i) {
            image[ctr / (RESOLUTION * 3)][ctr % (RESOLUTION * 3) / 3][ctr % 3] = buffer[i];
            ++ctr;
        }
        numRead = fread(buffer, sizeof(float), BATCHSIZE, fptr);
    }

    // Print final array
    int imageSize = RESOLUTION * RESOLUTION * 3;
    for (int i = 0; i < imageSize; i += 3) {
        printf("[%d][%d]: {%f, %f, %f}\n",
            i / (RESOLUTION * 3),
            i % (RESOLUTION * 3) / 3,
            image[i / (RESOLUTION * 3)][i % (RESOLUTION * 3) / 3][0],
            image[i / (RESOLUTION * 3)][i % (RESOLUTION * 3) / 3][1],
            image[i / (RESOLUTION * 3)][i % (RESOLUTION * 3) / 3][2]
        );
    }

    for (int i = 0; i < RESOLUTION; ++i) {
        for (int j = 0; j < RESOLUTION; ++j) {
            free(image[i][j]);
        }
        free(image[i]);
    }
    free(image);
    free(buffer);
    fclose(fptr);
}