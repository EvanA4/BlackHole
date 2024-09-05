#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>


// All photons are described in this manner
typedef struct Ray {
    float origin[3];
    float dir[3];
} Ray;


// Converts pixel row index to corresponding radius
float px2r(int px, const int MAXR, const int RESOLUTION) {
    float adjusted = MAXR * px / RESOLUTION;
    return (MAXR - sqrt(MAXR * MAXR - adjusted * adjusted));
}


// Converts pixel column index to corresponding psi
float px2psi(int px, const int RESOLUTION) {
    return (3.141592F * px / RESOLUTION);
}


// Creates ray in 3D cartesian coordinates using r and psi
Ray *create_ray(float r, float psi) {
    Ray *current = (Ray *) malloc(sizeof(Ray));

    current->origin[0] = r;
    current->origin[1] = 0.F;
    current->origin[2] = 0.F;

    current->dir[0] = cos(psi);
    current->dir[1] = sin(psi);
    current->dir[2] = 0.F;

    return current;
}


// Computes the length of the cross product between the position of the ray and its velocity
float get_L(Ray *current) {
    float lx, ly, lz;
    lx = current->origin[1] * current->dir[2] - current->origin[2] * current->dir[1];
    ly = current->origin[2] * current->dir[0] - current->origin[0] * current->dir[2];
    lz = current->origin[0] * current->dir[1] - current->origin[1] * current->dir[0];
    return sqrt(lx * lx + ly * ly + lz * lz);
}


// Computes the second derivative of position
float *get_ds2(const float L, float *s) {
    float *ds2 = (float *) calloc(3, sizeof(float));
    float slength = sqrt(s[0] * s[0] + s[1] * s[1] + s[2] * s[2]);
    float snorm[3] = {s[0] / slength, s[1] / slength, s[2] / slength};
    float combined = -1.5F * (L * L) / pow(slength, 4.F);
    ds2[0] *= combined;
    ds2[1] *= combined;
    ds2[2] *= combined;
    return ds2;
}


// Computes co-planar angle given co-planar cartesian coordinates
float get_phi(float *position) {
    float ratio = position[1] / position[0];
    if (position[0] < 0.F)
        ratio += 3.141592F;
    else if (position[0] == 0.F)
        return 1.570796 + (position[1] < 0.F ? 3.141592 : 0.F); // pi/2
    return atan(ratio);
}


// Follows path of photon around black hole
float *trace_ray(Ray *current) {
    float *output = (float *) calloc(3, sizeof(float));

    const float DISKRANGE[2] = {3.F, 6.F};
    const float DISKDEPTH = .025;
    const int N = 1500; // Number of steps
    const float L = get_L(current); // Angular momentum in range [0, 1]
    float t = 0.;
    float dt = .025;
    float *s = (float *) calloc(3, sizeof(float));
    float *ds = (float *) calloc(3, sizeof(float));

    memcpy(s, &(current->origin), 3 * sizeof(float));
    memcpy(ds, &(current->dir), 3 * sizeof(float));

    for (int i = 0; i < N; ++i) {
        // Casic Euler's method for second order ODE
        float *ds2 = get_ds2(L, s);

        float step_s[3] = {ds[0] * dt, ds[1] * dt, ds[2] * dt};
        float step_ds[3] = {ds2[0] * dt, ds2[1] * dt, ds2[2] * dt};
        free(ds2);

        // Update variables
        s[0] += step_s[0];
        s[1] += step_s[1];
        s[2] += step_s[2];
        ds[0] += step_ds[0];
        ds[1] += step_ds[1];
        ds[2] += step_ds[2];
        t += dt;

        // Check for escape conditions
        float slength2 = s[0] * s[0] + s[1] * s[1] + s[2] * s[2];
        if (slength2 < 1.) {
            // Photon crossed the event horizon
            output[0] = -1.F;
            output[1] = 0.F;
            return output;
        }
        // if (fabs(s[1]) < DISKDEPTH && slength2 < (DISKRANGE[0] * DISKRANGE[0]) && slength2 > (DISKRANGE[1] * DISKRANGE[1])) {
        //     // Photon hit accretion disk
        //     output[0] = get_phi(s);
        //     output[1] = sqrt(slength2);
        //     return output;
        // }
    }
  
    // Assume photon is far enough away from black hole to travel in straight line
    s[0] += 10000.F * ds[0];
    s[0] += 10000.F * ds[0];
    s[0] += 10000.F * ds[0];

    output[0] = get_phi(s);
    output[1] = sqrt(s[0] * s[0] + s[1] * s[1] + s[2] * s[2]);

    free(s);
    free(ds);
    return output;
}


int main() {
    FILE *fptr = fopen("output.bin", "wb");
    const int BATCHSIZE = 2048;
    const int RESOLUTION = 512;
    const int NUMBATCHES = ceil(RESOLUTION * RESOLUTION * 3 / (float) BATCHSIZE);
    const float MAXR = 10000.F;

    float *buffer = (float *) calloc(BATCHSIZE, sizeof(float));
    int bufferSize = 0;
    int buffersWritten = 0;

    // Print number of batches
    printf("Resolution: %d          Batch size: %d\n", RESOLUTION, BATCHSIZE);

    // EXR is created from bottom left to top right
    for (int i = 0; i < RESOLUTION; ++i) { // For each row
        for (int j = 0; j < RESOLUTION; ++j) { // For each pixel in row...

            // Get ray for a r0 and psi (and cartesian coordinates)
            float r0 = px2r(i, MAXR, RESOLUTION);
            float psi = px2psi(j, RESOLUTION);
            Ray *current = create_ray(r0, psi);

            // Compute r1 and phi for this input
            // float *output = trace_ray(current);
            float *output = (float *) calloc(3, sizeof(float));
            output[0] = (float) i;
            output[1] = (float) j;

            // Add phi and r1 and 0.F to buffer and write if necessary
            if (bufferSize + 3 < BATCHSIZE) { // Trivial case
                memcpy(buffer + bufferSize, output, 3 * sizeof(float));
                bufferSize += 3;

            } else if (bufferSize + 3 > BATCHSIZE) { // Adding to buffer would exceed BATCHSIZE
                int leftToAdd = bufferSize + 3 - BATCHSIZE;
                memcpy(buffer + bufferSize, output, (3 - leftToAdd) * sizeof(float));

                // Write buffer to file
                if (fwrite(buffer, sizeof(float), BATCHSIZE, fptr) != BATCHSIZE) {
                    printf("Error: failed to write batch number %d.\n", buffersWritten + 1);
                    exit(1);
                }
                bufferSize = leftToAdd;
                ++buffersWritten;
                printf("Completed batch %d of %d\n", buffersWritten, NUMBATCHES);

                // Add remainder of output to new buffer
                memcpy(buffer, output + 3 - leftToAdd, (leftToAdd) * sizeof(float));

            } else { // Perfectly filled the buffer!
                // Write buffer
                memcpy(buffer + bufferSize, output, 3 * sizeof(float));
                if (fwrite(buffer, sizeof(float), BATCHSIZE, fptr) != BATCHSIZE) {
                    printf("Error: failed to write batch number %d.\n", buffersWritten + 1);
                    exit(1);
                }
                ++buffersWritten;
                bufferSize = 0;
                printf("Completed batch %d of %d\n", buffersWritten, NUMBATCHES);
            }

            free(current);
            free(output);
        }
    }

    // Check for potential last write
    if (bufferSize) {
        // Write buffer
        if (fwrite(buffer, sizeof(float), bufferSize, fptr) != bufferSize) {
            printf("Error: failed to write batch number %d.\n", buffersWritten + 1);
            exit(1);
        }
        printf("Completed batch %d of %d with size %d instead of %d\n", buffersWritten + 1, NUMBATCHES, bufferSize, BATCHSIZE);
    }

    fflush(fptr);
    free(buffer);
    fclose(fptr);
}