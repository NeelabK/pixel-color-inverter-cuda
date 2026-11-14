# CUDA Image Filter

A small C++/CUDA project that applies color inversion to JPEG and PNG images on an NVIDIA GPU.

Each GPU thread processes one pixel, inverting its red, green, and blue channels:

```cpp
output = 255 - input;
```

For example, RGB `(255, 100, 0)` becomes `(0, 155, 255)`.

## Requirements

- An NVIDIA GPU with a compatible driver
- CUDA Toolkit with the `nvcc` compiler
- A compatible C++ compiler
- These image-loading and writing headers from [stb](https://github.com/nothings/stb):
  - `stb_image.h`
  - `stb_image_write.h`

Place both headers in the same directory as `pixel_filter.cu`.

You can run the project on a local NVIDIA GPU or a rented GPU machine.

## Build

```bash
nvcc -std=c++17 pixel_filter.cu -o pixel_filter
```

## Run

Pass the path to an input image:

```bash
./pixel_filter photo.jpg
```

For paths containing spaces:

```bash
./pixel_filter "my photo.png"
```

The program saves the inverted image as `output.png` in the current working directory. Running it again overwrites that output.

## How It Works

1. Decode the input image into RGB pixels using `stb_image`.
2. Allocate input and output buffers in GPU memory.
3. Copy the input pixels from CPU to GPU.
4. Launch the inversion kernel using 16×16 thread blocks.
5. Each thread checks its coordinates and inverts one pixel.
6. Copy the result back to CPU memory.
7. Save the result using `stb_image_write` and release allocated memory.

Input images are converted to three-channel RGB, so transparency is not preserved.

## Planned Improvements

- Pixelation
- Color quantization
- Dithering
- Configurable output filename

## Acknowledgments

Uses [stb](https://github.com/nothings/stb) for image decoding and writing. 
