//
//  ImageCropperView.swift
//  Z-Tix
//
//  Created by Harnish Patel on 29/10/2025.
//

import SwiftUI

// MARK: - Image Cropper View

/// Full-screen image cropping interface for profile pictures
/// Features:
/// - Circular crop area (250x250 pixels)
/// - Pinch-to-zoom gesture (1x-10x scale)
/// - Drag-to-reposition gesture
/// - Dark overlay highlighting crop area
/// - Real-time preview of cropped result
struct ImageCropperView: View {

    // MARK: - Input Properties

    /// Source image to crop (from photo library)
    let image: UIImage

    /// Callback when user confirms crop
    /// Receives cropped 250x250 circular image
    let onCrop: (UIImage) -> Void

    /// Callback when user cancels cropping
    let onCancel: () -> Void

    // MARK: - Gesture State

    /// Current scale factor applied to image (1.0 = original size)
    @State private var scale: CGFloat = 1.0

    /// Last scale value before current pinch gesture
    /// Used to calculate incremental scale changes
    @State private var lastScale: CGFloat = 1.0

    /// Current offset from center position
    /// Allows user to pan image within crop area
    @State private var offset: CGSize = .zero

    /// Last offset value before current drag gesture
    /// Preserved between drag gestures
    @State private var lastOffset: CGSize = .zero

    // MARK: - Constants

    /// Size of circular crop area in points
    /// Fixed at 250x250 for consistent profile picture size
    private let cropSize: CGFloat = 250

    // MARK: - Body

    var body: some View {
        ZStack {
            // MARK: Background
            /// Black background for professional cropping interface
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {

                // MARK: Header Bar
                /// Navigation-style header with Cancel/Done buttons
                HStack {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)

                    Spacer()

                    Text("Move and Scale")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)

                    Spacer()

                    Button("Done") {
                        cropImage()
                    }
                    .foregroundColor(.cyan)
                    .fontWeight(.bold)
                }
                .padding()

                Spacer()

                // MARK: Crop Area
                /// Image with overlay showing crop boundary
                ZStack {
                    // MARK: Interactive Image
                    /// Image with scale and drag gestures
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)

                        // MARK: Drag Gesture
                        /// Allows user to reposition image
                        /// Updates offset based on accumulated drag distance
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Add current drag to last offset
                                    offset = CGSize(
                                        width: lastOffset.width
                                            + value.translation.width,
                                        height: lastOffset.height
                                            + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    // Save offset for next drag
                                    lastOffset = offset
                                }
                        )

                        // MARK: Pinch Gesture
                        /// Allows user to zoom in/out
                        /// Scale limited between 1x (minimum) and 10x (maximum)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    // Calculate incremental scale change
                                    let delta = value / lastScale
                                    lastScale = value
                                    let newScale = scale * delta

                                    // Clamp between 1x and 10x
                                    scale = min(max(newScale, 1.0), 10.0)
                                }
                                .onEnded { _ in
                                    // Reset for next pinch gesture
                                    lastScale = 1.0
                                }
                        )

                    // MARK: Crop Overlay
                    /// Dark overlay with circular cutout
                    /// Shows user exactly what will be cropped
                    CropOverlay(cropSize: cropSize)
                        .allowsHitTesting(false)  // Allow gestures to pass through to image
                }
                .frame(maxWidth: .infinity, maxHeight: 450)
                .contentShape(Rectangle())  // Make entire area responsive to gestures

                Spacer()

                // MARK: Instructions
                /// User guidance text
                Text("Pinch to zoom • Drag to move")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.footnote)
                    .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Image Cropping

    /// Crops the image to circular 250x250 size based on current scale and offset
    /// Uses UIGraphicsImageRenderer for high-quality rendering
    ///
    /// ALGORITHM:
    /// 1. Calculate rendered image size based on aspect ratio
    /// 2. Apply current scale factor
    /// 3. Calculate position to center crop area
    /// 4. Render image section to 250x250 canvas
    /// 5. Return cropped result
    private func cropImage() {
        // Create 250x250 rendering context
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: cropSize, height: cropSize)
        )

        let croppedImage = renderer.image { context in
            // MARK: Calculate Display Size
            /// Determine how image is rendered on screen
            let imageSize = image.size
            let aspectRatio = imageSize.width / imageSize.height
            var renderWidth: CGFloat
            var renderHeight: CGFloat

            if aspectRatio > 1 {
                // Landscape: constrain by height
                renderHeight = 450
                renderWidth = renderHeight * aspectRatio
            } else {
                // Portrait or square: constrain by width
                renderWidth = UIScreen.main.bounds.width
                renderHeight = renderWidth / aspectRatio
            }

            // MARK: Apply Scale
            /// Include user's zoom level
            renderWidth *= scale
            renderHeight *= scale

            // MARK: Calculate Crop Position
            /// Determine which part of scaled image to extract
            /// Center the crop area, then adjust for user's pan offset
            let x = (renderWidth / 2) - (cropSize / 2) - offset.width
            let y = (renderHeight / 2) - (cropSize / 2) - offset.height

            // MARK: Render Cropped Section
            /// Draw the relevant portion of the image
            /// Negative coordinates allow drawing from offset position
            let drawRect = CGRect(
                x: -x,
                y: -y,
                width: renderWidth,
                height: renderHeight
            )
            image.draw(in: drawRect)
        }

        // Return cropped image to caller
        onCrop(croppedImage)
    }
}

// MARK: - Crop Overlay

/// Overlay view showing circular crop boundary
/// Creates Instagram-style crop interface with darkened outer area
struct CropOverlay: View {

    /// Size of circular crop area
    let cropSize: CGFloat

    var body: some View {
        ZStack {

            // MARK: Dark Overlay with Circular Cutout
            /// Semi-transparent black overlay over entire screen
            /// with transparent circle in center showing crop area
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .mask(
                    Canvas { context, size in
                        // Fill entire canvas with black
                        context.fill(
                            Path(CGRect(origin: .zero, size: size)),
                            with: .color(.black)
                        )

                        // MARK: Cut Out Center Circle
                        /// Create circular path in center
                        let center = CGPoint(
                            x: size.width / 2,
                            y: size.height / 2
                        )
                        let circlePath = Path(
                            ellipseIn: CGRect(
                                x: center.x - cropSize / 2,
                                y: center.y - cropSize / 2,
                                width: cropSize,
                                height: cropSize
                            )
                        )

                        // Use destination-out blend mode to "erase" the circle
                        // Creates transparent hole showing image underneath
                        context.blendMode = .destinationOut
                        context.fill(circlePath, with: .color(.black))
                    }
                )

            // MARK: White Circle Border
            /// Visible boundary showing exact crop area
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: cropSize, height: cropSize)
        }
    }
}

// MARK: - Preview

#Preview {
    ImageCropperView(
        image: UIImage(systemName: "person.circle.fill")!,
        onCrop: { _ in },
        onCancel: {}
    )
}
