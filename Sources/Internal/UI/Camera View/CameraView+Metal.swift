//
//  CameraView+Metal.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import AVKit
import MetalKit
import SwiftUI

@MainActor
class CameraMetalView: MTKView {
    private(set) var parent: CameraManager?
    private(set) var ciContext: CIContext?
    private(set) var commandQueue: MTLCommandQueue?
    private(set) var currentFrame: CIImage?
    private(set) var focusIndicator: CameraFocusIndicatorView = .init()
    private(set) var isAnimating: Bool = false

    /// The current scene luminance value (0.0 = dark, 1.0 = bright)
    private(set) var currentLuminance: CGFloat = 0.5
    private var frameCount: Int = 0
}

// MARK: Setup

extension CameraMetalView {
    func setup(parent: CameraManager) throws(MCameraError) {
        guard let metalDevice = MTLCreateSystemDefaultDevice() else { throw .cannotSetupMetalDevice }

        self.assignInitialValues(parent: parent, metalDevice: metalDevice)
        self.configureMetalView(metalDevice: metalDevice)
        self.addToParent(parent.cameraView)

        #if targetEnvironment(simulator)
            setupSimulatorMockPreview(parent: parent)
        #endif
    }

    #if targetEnvironment(simulator)
        private func setupSimulatorMockPreview(parent: CameraManager) {
            print("🎬 [Simulator] setupSimulatorMockPreview called")

            // Load mock image from app bundle (Development Assets)
            guard let mockImage = UIImage(named: "MockCameraPreview") else {
                print("❌ [Simulator] Failed to load MockCameraPreview image")
                return
            }
            print("✅ [Simulator] MockCameraPreview loaded: \(mockImage.size)")

            guard let cgImage = mockImage.cgImage else {
                print("❌ [Simulator] Failed to get cgImage")
                return
            }
            print("✅ [Simulator] cgImage obtained")

            let ciImage = CIImage(cgImage: cgImage)
            currentFrame = ciImage
            parent.cameraView.alpha = 1
            print("✅ [Simulator] currentFrame set, calling draw()")
            draw()
        }
    #endif
}

extension CameraMetalView {
    private func assignInitialValues(parent: CameraManager, metalDevice: MTLDevice) {
        self.parent = parent
        self.ciContext = CIContext(mtlDevice: metalDevice)
        self.commandQueue = metalDevice.makeCommandQueue()
    }

    private func configureMetalView(metalDevice: MTLDevice) {
        self.parent?.cameraView.alpha = 0

        self.delegate = self
        self.device = metalDevice
        self.isPaused = true
        self.enableSetNeedsDisplay = false
        self.framebufferOnly = false
        self.autoResizeDrawable = false
        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
    }
}

// MARK: - ANIMATIONS

// MARK: Camera Entrance

extension CameraMetalView {
    func performCameraEntranceAnimation() {
        guard let parent else { return }
        UIView.animate(withDuration: 0.33) {
            parent.cameraView.alpha = 1
        }
    }
}

// MARK: Image Capture

extension CameraMetalView {
    func performImageCaptureAnimation() {
        guard let parent else { return }
        let blackMatte = createBlackMatte()

        parent.cameraView.addSubview(blackMatte)
        animateBlackMatte(blackMatte)
    }
}

extension CameraMetalView {
    private func createBlackMatte() -> UIView {
        let view = UIView()
        view.frame = parent?.cameraView.frame ?? .zero
        view.backgroundColor = .init(resource: .mijickBackgroundPrimary)
        view.alpha = 0
        return view
    }

    private func animateBlackMatte(_ view: UIView) {
        UIView.animate(withDuration: 0.16, animations: { view.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.16, animations: { view.alpha = 0 }) { _ in
                view.removeFromSuperview()
            }
        }
    }
}

// MARK: Camera Flip

extension CameraMetalView {
    func beginCameraFlipAnimation() async {
        guard let parent else { return }
        let snapshot = createSnapshot()
        isAnimating = true
        insertBlurView(snapshot, parent: parent)
        animateBlurFlip(parent: parent)

        await Task.sleep(seconds: 0.01)
    }

    func finishCameraFlipAnimation() async {
        guard let parent,
              let blurView = parent.cameraView.viewWithTag(.blurViewTag) else { return }

        await Task.sleep(seconds: 0.44)
        UIView.animate(withDuration: 0.3, animations: { blurView.alpha = 0 }) { [self] _ in
            blurView.removeFromSuperview()
            isAnimating = false
        }
    }
}

extension CameraMetalView {
    private func createSnapshot() -> UIImage? {
        guard let currentFrame else { return nil }

        let image = UIImage(ciImage: currentFrame)
        return image
    }

    private func insertBlurView(_ snapshot: UIImage?, parent: CameraManager) {
        let blurView = UIImageView(frame: parent.cameraView.frame)
        blurView.image = snapshot
        blurView.contentMode = .scaleAspectFill
        blurView.clipsToBounds = true
        blurView.tag = .blurViewTag
        blurView.applyBlurEffect(style: .regular)

        parent.cameraView.addSubview(blurView)
    }

    private func animateBlurFlip(parent: CameraManager) {
        let transition: UIView.AnimationOptions = parent.attributes.cameraPosition == .back
            ? .transitionFlipFromLeft
            : .transitionFlipFromRight
        UIView.transition(with: parent.cameraView, duration: 0.44, options: transition) {}
    }
}

// MARK: Camera Focus

extension CameraMetalView {
    func performCameraFocusAnimation(touchPoint: CGPoint) {
        guard let parent else { return }
        removeExistingFocusIndicatorAnimations(parent: parent)

        let focusIndicator = focusIndicator.create(at: touchPoint)
        parent.cameraView.addSubview(focusIndicator)
        animateFocusIndicator(focusIndicator)
    }
}

extension CameraMetalView {
    private func removeExistingFocusIndicatorAnimations(parent: CameraManager) {
        if let view = parent.cameraView.viewWithTag(.focusIndicatorTag) {
            view.removeFromSuperview()
        }
    }

    private func animateFocusIndicator(_ focusIndicator: UIImageView) {
        UIView.animate(
            withDuration: 0.44,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0,
            animations: { focusIndicator.transform = .init(scaleX: 1, y: 1) }
        ) { _ in
            UIView.animate(withDuration: 0.44, delay: 1.44, animations: { focusIndicator.alpha = 0.2 }) { _ in
                UIView.animate(withDuration: 0.44, delay: 1.44, animations: { focusIndicator.alpha = 0 })
            }
        }
    }
}

// MARK: Camera Orientation

extension CameraMetalView {
    func beginCameraOrientationAnimation(if shouldAnimate: Bool) async {
        guard shouldAnimate, let parent else { return }
        parent.cameraView.alpha = 0
        await Task.sleep(seconds: 0.1)
    }

    func finishCameraOrientationAnimation(if shouldAnimate: Bool) {
        guard shouldAnimate, let parent else { return }
        UIView.animate(withDuration: 0.2, delay: 0.1) {
            parent.cameraView.alpha = 1
        }
    }
}

// MARK: - CAPTURING FRAMES

// MARK: Capture

extension CameraMetalView: @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let cvImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let currentFrame = captureCurrentFrame(cvImageBuffer)
        let currentFrameWithFiltersApplied = applyingFiltersToCurrentFrame(currentFrame)
        redrawCameraView(currentFrameWithFiltersApplied)

        // Calculate luminance from EXIF brightness or frame sampling
        updateLuminance(from: sampleBuffer, frame: currentFrameWithFiltersApplied)
    }
}

// MARK: - Luminance Calculation

extension CameraMetalView {
    private func updateLuminance(from sampleBuffer: CMSampleBuffer, frame: CIImage) {
        // Only update every 6 frames (~5 times per second at 30fps) to reduce overhead
        frameCount += 1
        guard frameCount % 6 == 0 else { return }

        let newLuminance: CGFloat
            // Try to get brightness from EXIF metadata first (more efficient)
            = if let brightness = getBrightnessFromMetadata(sampleBuffer)
        {
            normalizeBrightness(brightness)
        } else {
            // Fallback: sample the center region of the frame
            calculateLuminanceFromFrame(frame)
        }

        // Apply exponential smoothing to avoid jitter
        let smoothingFactor: CGFloat = 0.3
        let smoothedLuminance = currentLuminance + smoothingFactor * (newLuminance - currentLuminance)

        currentLuminance = smoothedLuminance
        // Update CameraManager's published property for SwiftUI reactivity
        parent?.sceneLuminance = smoothedLuminance
    }

    private func getBrightnessFromMetadata(_ sampleBuffer: CMSampleBuffer) -> Float? {
        guard let metadataDict = CMCopyDictionaryOfAttachments(
            allocator: nil,
            target: sampleBuffer,
            attachmentMode: kCMAttachmentMode_ShouldPropagate
        ) as? [String: Any],
            let exifMetadata = metadataDict[kCGImagePropertyExifDictionary as String] as? [String: Any],
            let brightnessValue = exifMetadata[kCGImagePropertyExifBrightnessValue as String] as? Float
        else { return nil }
        return brightnessValue
    }

    private func normalizeBrightness(_ brightness: Float) -> CGFloat {
        // EXIF BrightnessValue typically ranges from about -4 (very dark) to +12 (very bright)
        // Map this to 0-1 range with threshold around 3-4 for "bright" scenes
        // Using sigmoid-like mapping for smoother transitions
        let minBrightness: Float = -2
        let maxBrightness: Float = 8
        let normalized = (brightness - minBrightness) / (maxBrightness - minBrightness)
        return CGFloat(max(0, min(1, normalized)))
    }

    private func calculateLuminanceFromFrame(_ frame: CIImage) -> CGFloat {
        // Sample center region for performance
        let extent = frame.extent
        let sampleSize: CGFloat = 100
        let centerRect = CGRect(
            x: extent.midX - sampleSize / 2,
            y: extent.midY - sampleSize / 2,
            width: sampleSize,
            height: sampleSize
        )

        guard let ciContext,
              let cgImage = ciContext.createCGImage(frame, from: centerRect)
        else {
            return 0.5
        }

        // Calculate average luminance from the sample
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data)
        else { return 0.5 }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let width = cgImage.width
        let height = cgImage.height

        var totalLuminance: CGFloat = 0
        var pixelCount: CGFloat = 0

        // Sample every 4th pixel for performance
        let step = 4
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = CGFloat(bytes[offset]) / 255.0
                let g = CGFloat(bytes[offset + 1]) / 255.0
                let b = CGFloat(bytes[offset + 2]) / 255.0

                // Standard luminance formula (ITU-R BT.709)
                let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
                totalLuminance += luminance
                pixelCount += 1
            }
        }

        return pixelCount > 0 ? totalLuminance / pixelCount : 0.5
    }
}

extension CameraMetalView {
    private func captureCurrentFrame(_ cvImageBuffer: CVImageBuffer) -> CIImage {
        let currentFrame = CIImage(cvImageBuffer: cvImageBuffer)
        let orientation = parent?.attributes.frameOrientation ?? .right
        return currentFrame.oriented(orientation)
    }

    private func applyingFiltersToCurrentFrame(_ currentFrame: CIImage) -> CIImage {
        let filters = parent?.attributes.cameraFilters ?? []
        return currentFrame.applyingFilters(filters)
    }

    private func redrawCameraView(_ frame: CIImage) {
        currentFrame = frame
        draw()
    }
}

// MARK: Draw

extension CameraMetalView: MTKViewDelegate {
    func draw(in view: MTKView) {
        guard let commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let ciImage = currentFrame,
              let currentDrawable = view.currentDrawable
        else { return }

        changeDrawableSize(view, ciImage)
        renderView(view, currentDrawable, commandBuffer, ciImage)
        commitBuffer(currentDrawable, commandBuffer)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

extension CameraMetalView {
    private func changeDrawableSize(_ view: MTKView, _ ciImage: CIImage) {
        view.drawableSize = ciImage.extent.size
    }

    private func renderView(
        _ view: MTKView,
        _ currentDrawable: any CAMetalDrawable,
        _ commandBuffer: any MTLCommandBuffer,
        _ ciImage: CIImage
    ) {
        ciContext?.render(
            ciImage,
            to: currentDrawable.texture,
            commandBuffer: commandBuffer,
            bounds: .init(origin: .zero, size: view.drawableSize),
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
    }

    private func commitBuffer(_ currentDrawable: any CAMetalDrawable, _ commandBuffer: any MTLCommandBuffer) {
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
}
