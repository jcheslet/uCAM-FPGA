# uCAM-III Image Acquisition Module for FPGA

## Overview

This project aims to develop an acquisition module to retrieve images from the uCAM-III camera and make them accessible within an FPGA design.
The module is designed to enhance the range of accessible projects and their attractiveness by integrating image sources into VHDL modules.

## Key Features

- **Image Retrieval**: Captures images from the uCAM-III camera with selectable formats and resolutions.
- **FPGA Integration**: Makes images accessible to the rest of the FPGA design, e.g. for image processing.
- **UART Communication**: FPGA design handle the communication to maximise camera throughput.
- **Multiple Output Formats**: Supports raw stream, pixel, and RAM storage formats.

## Images Formats

- **Resolution**: Supports lower resolutions for uncompressed operation.
- **Future Work**: Provides a basis for JPEG stream production for advanced projects.

### Main Entity generics


| **Parameter**    | **Type**          | **Default Value** | **Description**                                  |
|------------------|-------------------|------------------|---------------------------------------------------|
| `CLK_FREQU`      | integer           | 100,000,000      | Clock frequency, default is 100 MHz.              |
| `MODE`           | integer (0 to 2)  | 0                | **RAW RGB**: 0 \| **RAW Grey**: 1 \| **JPEG**: 2. |
| `RESOLUTION`     | integer (0 to 3)  | 0                | Select the resolution, depends on the MODE.       |
| `BYTES_PER_PIXEL`| integer (1 to 2)  | 2                | Number of bytes per pixel (has to match MODE).    |

#### Resolution Generic in pixels

| **Resolution Index** | **0** | **1** | **2** | **3** |
|----------------------|-------|-------|-------|-------|
| **Raw**              | 80x60 | 160x120 | 128x128 | 128x96 |
| **JPEG**             | 160x128 | 320x240 | 640x480 | N/A |


### Performances

The table below presents the maximum frame rates achieved with the uCAM-III.

_Note: The primary limitation comes from the ~200ms shutter time._

| **Format**       | **Resolution** | **Frame Rate** |
|------------------|----------------|----------------|
| 8-bit            | 80x60 px       | ~7.0 fps       |
| 8-bit            | 160x120 px     | ~2.8 fps       |
| 16-bit           | 80x60 px       | ~4.7 fps       |
| 16-bit           | 160x120 px     | ~1.8 fps       |
| JPEG             | 160x128 px     | ~7.2 fps       |
| JPEG             | 640x480 px     | ~4.8 fps       |

## Available Output Formats

1. **Raw Stream**: Sequential transmission of image bytes without interpretation.
2. **Pixel**: Outputs color values with pixel coordinates.
3. **RAM**: Stores images in dual-port memory with read-only access for user.

## Resource Utilization (for AMD Xilinx Nexys-A7)

 | Resource | Utilization |
 |----------|-------------|
 | LUTs     | 340 ~ 377   |
 | FFs      | 290 ~ 308   |
 | BRAMs    | 0 ~ 16      |

## Resources

### Datasheets

- [uCAM-III Datasheet](https://resources.4dsystems.com.au/datasheets/accessories/uCAM-III/)

### Packet Structure of uCAM-III

This table outlines the structure of an image packet:

| **Byte Range** | **Field**       | **Size (bytes)** | **Description**                      |
|----------------|-----------------|------------------|--------------------------------------|
| 0 - 1          | ID              | 2                | Identifier                           |
| 2 - 3          | Data Size       | 2                | Size of the image data               |
| 4 - (N-2)      | Image Data      | Package Size - 6 | The actual image data                |
| N-2 - N-1      | Verify Code     | 2                | Code used for verification           |

## Disclaimer

This project was done during my engineering school time. Please note that codes, comments and documentation quality might be low and/or outdated.

While efforts were made to ensure functionality and clarity, there may be areas that require improvement or further optimization.

I intend to update and clean the project when I have the opportunity.

Feel free to explore, learn, and contribute! Your feedback and suggestions are welcome.
