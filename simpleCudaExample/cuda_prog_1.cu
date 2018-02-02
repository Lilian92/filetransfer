#include <stdio.h>

__global__ void kernel_A( float *g_data, int dimx, int dimy )
{
    int ix  = blockIdx.x;
    int iy  = blockIdx.y*blockDim.y + threadIdx.y;
    int idx = iy*dimx + ix;

    float value = g_data[idx];

    if( ix % 2 )
    {
        value += sqrtf( logf(value) + 1.f );
    }
    else
    {
        value += sqrtf( cosf(value) + 1.f );
    }

    g_data[idx] = value;
}

__global__ void kernel_B( float *g_data, int dimx, int dimy )
{
    int id  = blockIdx.x*blockDim.x + threadIdx.x;

    float value = g_data[id];

    if( id % 2 )
    {
        value += sqrtf( logf(value) + 1.f );
    }
    else
    {
        value += sqrtf( cosf(value) + 1.f );
    }

    g_data[id] = value;
}

__global__ void kernel_C( float * _g_data, int dimx, int dimy )
{
    float2* g_data = reinterpret_cast<float2 *>(_g_data);

    int id  = blockIdx.x*blockDim.x + threadIdx.x;

    float2 value = g_data[id];

    value.x += sqrtf( cosf(value.x) + 1.f );
    value.y += sqrtf( logf(value.y) + 1.f );

    g_data[id] = value;
}

__global__ void kernel_D( float * _g_data, int dimx, int dimy )
{
    float4* g_data = reinterpret_cast<float4 *>(_g_data);

    int id  = blockIdx.x*blockDim.x + threadIdx.x;

    float4 value = g_data[id];

    value.x += sqrtf( cosf(value.x) + 1.f );
    value.y += sqrtf( logf(value.y) + 1.f );
    value.z += sqrtf( cosf(value.z) + 1.f );
    value.w += sqrtf( logf(value.w) + 1.f );

    g_data[id] = value;
}

float timing_experiment( void (*kernel)( float*, int,int), float *d_data, int dimx, int dimy, int nreps, int blockx, int blocky )
{
    float elapsed_time_ms=0.0f;
    cudaEvent_t start, stop;
    cudaEventCreate( &start );
    cudaEventCreate( &stop  );

    dim3 block( blockx, blocky );
    dim3 grid( dimx/block.x, dimy/block.y );

    cudaEventRecord( start, 0 );
    for(int i=0; i<nreps; i++)  // do not change this loop, it's not part of the algorithm - it's just to average time over several kernel launches
        kernel<<<grid,block>>>( d_data, dimx,dimy );
    cudaEventRecord( stop, 0 );
    cudaThreadSynchronize();
    cudaEventElapsedTime( &elapsed_time_ms, start, stop );
    elapsed_time_ms /= nreps;

    cudaEventDestroy( start );
    cudaEventDestroy( stop );

    return elapsed_time_ms;
}

int main(int argc, char *argv[])
{
    //begin choosing whether testing correctness, and code version
    size_t version = 1;
    bool testCorretness = 0;
    if(argc >= 2)
        version = atoi(argv[1]);
    if(argc >= 3)
        testCorretness = atoi(argv[2]);
    //end choosing whether testing correctness, and code version

    int dimx = 2*1024;
    int dimy = 2*1024;

    int nreps = 10;

    int nbytes = dimx*dimy*sizeof(float);

    float *d_data=0, *h_data=0;
    cudaMalloc( (void**)&d_data, nbytes );
    if( 0 == d_data )
    {
        printf("couldn't allocate GPU memory\n");
        return -1;
    }
    printf("allocated %.2f MB on GPU\n", nbytes/(1024.f*1024.f) );
    h_data = (float*)malloc( nbytes );
    if( 0 == h_data )
    {
        printf("couldn't allocate CPU memory\n");
        return -2;
    }
    printf("allocated %.2f MB on CPU\n", nbytes/(1024.f*1024.f) );
    for(int i=0; i<dimx*dimy; i++)
        h_data[i] = 10.f + rand() % 256;
    cudaMemcpy( d_data, h_data, nbytes, cudaMemcpyHostToDevice );

    float elapsed_time_ms=0.0f;

    //start choosing different versions and run
    if ( version == 1 ) {
        elapsed_time_ms = timing_experiment( kernel_A, d_data, dimx,dimy, nreps, 1, 512 );
    } else if ( version == 2 ) {
        elapsed_time_ms = timing_experiment( kernel_B, d_data, dimx*dimy, 1, nreps, 256, 1 );
    } else if ( version == 3 ) {
        elapsed_time_ms = timing_experiment( kernel_C, d_data, dimx*dimy/2, 1, nreps, 256, 1 );
    } else if ( version == 4 ) {
        elapsed_time_ms = timing_experiment( kernel_D, d_data, dimx*dimy/4, 1, nreps, 256, 1 );
    } else {
        printf( "code version does not exist.\n" );
        return -3;
    }
    printf("%c:  %8.6f ms\n", (char)(version-1+'A'), elapsed_time_ms );
    printf("CUDA: %s\n", cudaGetErrorString( cudaGetLastError() ) );
    //end choosing different versions and run

    //start test correctness
    if(testCorretness) {
        printf("\ncorrectness:\n");

        //read data from gpu to array "h_gpuRes"
        float *h_gpuRes=0;
        h_gpuRes = (float*)malloc( nbytes );
        if ( 0 == h_gpuRes )
        {
            printf("couldn't allocate CPU memory\n");
            return -2;
        }
        cudaMemcpy( h_gpuRes, d_data, nbytes, cudaMemcpyDeviceToHost);

        //execute the original version to test correctness
        cudaMemcpy( d_data, h_data, nbytes, cudaMemcpyHostToDevice );
        elapsed_time_ms = timing_experiment( kernel_A, d_data, dimx,dimy, nreps, 1, 512 );

        //read kernel A's data from gpu to array "h_gpuResA"
        float *h_gpuResA=0;
        h_gpuResA = (float*)malloc( nbytes );
        if ( 0 == h_gpuResA )
        {
            printf("couldn't allocate CPU memory\n");
            return -2;
        }
        cudaMemcpy( h_gpuResA, d_data, nbytes, cudaMemcpyDeviceToHost);

        //compare result
        int i;
        for(i=0; i<dimx*dimy; i++) {
            if( abs(h_gpuRes[i] - h_gpuResA[i]) > 1e-7 )  {
                printf( "calculation error in GPU results in %d\n", i );
                printf( "data: %f\nA's gpu result: %f\nOther version's gpu result: %f\n", h_data[i], h_gpuResA[i], h_gpuRes[i]);
                break;
            }
        }
        if( i >= dimx*dimy ) {
            printf( "calculation correct in GPU results! Congrats!\n" );
        }

        //release cpu memory
        if( h_gpuRes )
            free( h_gpuRes);
        if( h_gpuResA )
            free( h_gpuResA);
    }
    //end test correctness

    if( d_data )
        cudaFree( d_data );
    if( h_data )
        free( h_data );

    cudaThreadExit();

    return 0;
}
