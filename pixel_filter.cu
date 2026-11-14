#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include <iostream>
#include <vector>
#include <cuda_runtime.h>


__global__ void pixelFilter(
    const unsigned char* input, 
    unsigned char* output,
    int width, 
    int height
)
{   
    int x = blockIdx.x * blockDim.x + threadIdx.x;

    // 
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if(x >= width || y >= height){
        return;
    }

    int index = (y * width + x) * 3;

    output[index] = 255 - input[index];
    output[index + 1] = 255 - input[index + 1];
    output[index + 2] = 255 - input[index + 2];

}


int main(int argc, char* argv[]){

    if(argc != 2){
        std::cerr << "Usage: ./pixel_filter <image_path>" << std::endl;
        return 1;
    }

    int width, height, originalChannels;

 
    unsigned char* pixels = stbi_load(
        argv[1],
        &width, 
        &height, 
        &originalChannels, 
        3 
    );

    if(!pixels){
        std::cerr << "Failed to load image: " << stbi_failure_reason() << std::endl;
        return 1;
    }

    size_t bytes = static_cast<size_t> (width) * height * 3;

    std::vector<unsigned char> result(bytes);

    unsigned char* d_input = nullptr;
    unsigned char* d_output = nullptr;

    auto cleanup = [&]() {
        if (d_input) cudaFree(d_input);
        if(d_output) cudaFree(d_output);
        stbi_image_free(pixels);
    };

     auto checkCuda = [](cudaError_t error) {
        if (error != cudaSuccess) {
            std::cerr << "CUDA error: "
                      << cudaGetErrorString(error) << '\n';
            return false;
        }
        return true;
    };

    if(!checkCuda(cudaMalloc(
        reinterpret_cast<void**>(&d_input), bytes))){
            cleanup();
            return 1;
        }
    if (!checkCuda(cudaMalloc(
        reinterpret_cast<void**>(&d_output), bytes))) {
        cleanup();
        return 1;
    }

    if (!checkCuda(cudaMemcpy(
            d_input, pixels, bytes, cudaMemcpyHostToDevice))) {
        cleanup();
        return 1;
    }

    dim3 block(16, 16);

    dim3 grid(
        (width + block.x - 1) / block.x,
        (height + block.y - 1) / block.y
    );

    pixelFilter<<<grid, block>>>(
        d_input, d_output, width, height
    );

    if (!checkCuda(cudaGetLastError())) {
        cleanup();
        return 1;
    }

    if (!checkCuda(cudaDeviceSynchronize())) {
        cleanup();
        return 1;
    }

  
    if (!checkCuda(cudaMemcpy(
            result.data(), d_output, bytes,
            cudaMemcpyDeviceToHost))) {
        cleanup();
        return 1;
    }
   
    int saved = stbi_write_png(
        "output.png",
        width,
        height,
        3,
        result.data(),
        width * 3
    );

    cleanup();

    if (!saved) {
        std::cerr << "Failed to save output.png\n";
        return 1;
    }

    std::cout << "Saved inverted image to output.png\n";
    return 0;
}

