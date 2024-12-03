# Procedure for Analyzing Janus Particle Orientations

This document reviews the procedure for carrying out the analysis of Janus particle orientations, starting with the particle orientation tracking algorithm.

## Particle Orientation Detection and Tracking

To detect the particle orientation, a crucial property of Janus particles was exploited: their coated layer, typically made of carbon. This layer creates a zone of higher contrast observable in recorded videos. Using MATLAB's pattern detection tools, it is possible to assign an orientation vector to each particle.

The MATLAB script implements an algorithm for tracking Janus particles in video footage. These particles are characterized by a dark ring encircling a bright core, with one hemisphere darker than the other. The brightness distribution across the particle's area is used to estimate its orientation. Below, the main aspects of the code are explained systematically.

### 1. Initialization and Parameter Setup

The script begins by initializing various parameters critical for image processing:
- **Brightness Thresholds:** `maskLevel`
- **Particle Dimensions:** `particleRadius` and `thickness`
- **Morphological Settings:** `erodeRadius`, `dilateRadius`, and `dilateMask`

Structural elements are defined for ring detection, erosion, and dilation using MATLAB's `strel` function. Additionally, a custom ring-shaped structural element is constructed to match the geometry of Janus particles.

### 2. Video Preprocessing

Each video is processed frame-by-frame. Frames are converted to grayscale, and the pixel intensities are inverted to enhance the visibility of the particle features.

### 3. Morphological Operations and Particle Detection

Morphological operations are applied to isolate and identify the particles:
- **Opening:** The `imopen` function isolates ring-like structures corresponding to Janus particles.
- **Thresholding:** A histogram-based method generates a binary mask to identify bright regions above the background.
- **Refinement:** 
  - The binary mask is dilated (`imdilate`) to bridge gaps in partially detected particles.
  - Erosion (`imerode`) separates barely touching particles and removes noise.
  - The mask is inverted to isolate central bright spots.

The `bwlabel` function is used to label regions in processed frames, and `regionprops` extracts particle properties like centroids and area. Size filters are applied to exclude invalid objects.

### 4. Orientation Calculation

For each detected particle, its orientation is calculated based on the displacement between the centroid and weighted centroid. The orientation vector is normalized and scaled using the particle radius. Mathematically:

$$\text{Orientation} = \frac{(X_\text{centroid} - X_\text{weighted}, Y_\text{centroid} - Y_\text{weighted})}{\|\text{Displacement}\|}$$


### 5. Visualization and Output

The script generates annotated video frames showing:
- Detected particles with markers
- Orientation vectors for each particle

These visualizations use MATLAB's `insertMarker` and `insertShape` functions. Outputs include:
- A new video file with annotations
- A text file containing particle positions, orientations, and timestamps

### MATLAB Script of Orientational Tracking

The full example of the MATLAB code is available in this repository.
