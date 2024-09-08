#include <stdio.h>
#include <stdlib.h>

int main() {
    FILE *fptr = fopen("output.bin", "rb");
    const int BATCHSIZE = 4096;
    const int HEIGHT = 4096;
    const int WIDTH = 512;

    // allocate all the memory for the 3D array
    float ***image = (float ***) calloc(HEIGHT * WIDTH, sizeof(float **));

    // create each row...
    for (int i = 0; i < HEIGHT; ++i) {
        float **row = (float **) calloc(WIDTH, sizeof(float *));

        // create each column...
        for (int j = 0; j < WIDTH; ++j) {
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
            image[ctr / (WIDTH * 3)][ctr % (WIDTH * 3) / 3][ctr % 3] = buffer[i];
            ++ctr;
        }
        numRead = fread(buffer, sizeof(float), BATCHSIZE, fptr);
    }

    // Print final array
    int imageSize = HEIGHT * WIDTH * 3;
    for (int i = 0; i < imageSize; i += 3) {
        printf("[%d][%d]: {%f, %f, %f}\n",
            i / (WIDTH * 3),
            i % (WIDTH * 3) / 3,
            image[i / (WIDTH * 3)][i % (WIDTH * 3) / 3][0],
            image[i / (WIDTH * 3)][i % (WIDTH * 3) / 3][1],
            image[i / (WIDTH * 3)][i % (WIDTH * 3) / 3][2]
        );
    }

    for (int i = 0; i < HEIGHT; ++i) {
        for (int j = 0; j < WIDTH; ++j) {
            free(image[i][j]);
        }
        free(image[i]);
    }
    free(image);
    free(buffer);
    fclose(fptr);
}