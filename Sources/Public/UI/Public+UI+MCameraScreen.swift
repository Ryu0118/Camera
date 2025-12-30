//
//  Public+UI+MCameraScreen.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.

import AVFoundation
import MijickTimer
import SwiftUI

/**
 Screen that displays the camera view and manages camera actions.

 - important: A view conforming to **MCameraScreen** has to be passed directly to ``MCamera``. See ``MCamera/setCameraScreen(_:)`` for more details.

 ## Usage
 ```swift
 struct ContentView: View {
    var body: some View {
        MCamera()
            .setCameraScreen(CustomCameraErrorScreen.init)

            // MUST BE CALLED!
            .startSession()
    }
 }

 // MARK: Custom Camera Screen
 struct CustomCameraScreen: MCameraScreen {
    @ObservedObject var cameraManager: CameraManager
    let namespace: Namespace.ID
    let closeMCameraAction: () -> ()

    var body: some View {
        VStack(spacing: 0) {
            createNavigationBar()
            createCameraOutputView()
            createCaptureButton()
        }
    }
 }
 private extension CustomCameraScreen {
    func createNavigationBar() -> some View {
        Text("This is a Custom Camera View")
            .padding(.top, 12)
            .padding(.bottom, 12)
    }
    func createCaptureButton() -> some View {
        Button(action: captureOutput) { Text("Click to capture") }
            .padding(.top, 12)
            .padding(.bottom, 12)
    }
 }
 ```
 */
public protocol MCameraScreen: View {
    var cameraManager: CameraManager { get }
    var namespace: Namespace.ID { get }
    var closeMCameraAction: () -> Void { get }
}

// MARK: Methods

extension MCameraScreen {
    /**
     View that displays the camera output.

     ## Usage
     ```swift
     struct CustomCameraScreen: MCameraScreen {
        @ObservedObject var cameraManager: CameraManager
        let namespace: Namespace.ID
        let closeMCameraAction: () -> ()

        var body: some View {
            (...)
            createCameraOutputView()
            (...)
        }
     }
     ```
     */
    public func createCameraOutputView() -> some View { CameraBridgeView(cameraManager: cameraManager).equatable() }
}

extension MCameraScreen {
    /**
     Capture the current camera output.

     The output type depends on what ``cameraOutputType`` is set to.
     */
    public func captureOutput() { cameraManager.captureOutput() }

    /**
     Set the output type of the camera.

     For available options, please refer to the ``CameraOutputType`` documentation.
     */
    public func setOutputType(_ outputType: CameraOutputType) { cameraManager.setOutputType(outputType) }

    /**
     Set the camera position.

     For available options, please refer to the ``CameraPosition`` documentation.

     - note: If the selected camera position is not available, the camera will not be changed.
     */
    public func setCameraPosition(_ cameraPosition: CameraPosition) async throws {
        try await cameraManager.setCameraPosition(cameraPosition)
    }

    /**
     Set the zoom factor of the camera.

     - note: If the zoom factor is out of bounds, it will be set to the closest available value.
     */
    public func setZoomFactor(_ zoomFactor: CGFloat) throws { try cameraManager.setCameraZoomFactor(zoomFactor) }

    /**
     Set the flash mode of the camera.

     For available options, please refer to the ``CameraFlashMode`` documentation.

     - note: If the selected flash mode is not available, the flash mode will not be changed.
     */
    public func setFlashMode(_ flashMode: CameraFlashMode) { cameraManager.setFlashMode(flashMode) }

    /**
     Set the light mode of the camera.

     For available options, please refer to the ``CameraLightMode`` documentation.

     - note: If the selected light mode is not available, the light mode will not be changed.
     */
    public func setLightMode(_ lightMode: CameraLightMode) throws { try cameraManager.setLightMode(lightMode) }

    /**
     Set the camera resolution.

     - important: Changing the resolution may affect the maximum frame rate that can be set.
     */
    public func setResolution(_ resolution: AVCaptureSession.Preset) { cameraManager.setResolution(resolution) }

    /**
     Set the camera frame rate.

     - important: Changing the resolution may affect the maximum frame rate that can be set.
     - note: If the frame rate is out of bounds, it will be set to the closest available value.
     */
    public func setFrameRate(_ frameRate: Int32) throws { try cameraManager.setFrameRate(frameRate) }

    /**
     Set the camera exposure duration.

     - note: If the exposure duration is out of bounds, it will be set to the closest available value.
     */
    public func setExposureDuration(_ exposureDuration: CMTime) throws {
        try cameraManager.setExposureDuration(exposureDuration)
    }

    /**
     Set the camera exposure target bias.

     - note: If the target bias is out of bounds, it will be set to the closest available value.
     */
    public func setExposureTargetBias(_ exposureTargetBias: Float) throws {
        try cameraManager.setExposureTargetBias(exposureTargetBias)
    }

    /**
     Set the camera ISO.

     - note: If the ISO is out of bounds, it will be set to the closest available value.
     */
    public func setISO(_ iso: Float) throws { try cameraManager.setISO(iso) }

    /**
     Set the camera exposure mode.

     - note: If the exposure mode is not supported, the exposure mode will not be changed.
     */
    public func setExposureMode(_ exposureMode: AVCaptureDevice.ExposureMode) throws {
        try cameraManager.setExposureMode(exposureMode)
    }

    /**
     Set the camera HDR mode.

     For available options, please refer to the ``CameraHDRMode`` documentation.
     */
    public func setHDRMode(_ hdrMode: CameraHDRMode) throws { try cameraManager.setHDRMode(hdrMode) }

    /**
     Set the camera filters to be applied to the camera output.

     - important: Setting multiple filters simultaneously can affect the performance of the camera.
     */
    public func setCameraFilters(_ filters: [CIFilter]) { cameraManager.setCameraFilters(filters) }

    /**
     Set whether the camera output should be mirrored.
     */
    public func setMirrorOutput(_ shouldMirror: Bool) { cameraManager.setMirrorOutput(shouldMirror) }

    /**
     Set whether the camera grid should be visible.
     */
    public func setGridVisibility(_ shouldShowGrid: Bool) { cameraManager.setGridVisibility(shouldShowGrid) }
}

// MARK: Attributes

extension MCameraScreen {
    public var cameraOutputType: CameraOutputType { cameraManager.attributes.outputType }
    public var cameraPosition: CameraPosition { cameraManager.attributes.cameraPosition }
    public var zoomFactor: CGFloat { cameraManager.attributes.zoomFactor }
    public var flashMode: CameraFlashMode { cameraManager.attributes.flashMode }
    public var lightMode: CameraLightMode { cameraManager.attributes.lightMode }
    public var resolution: AVCaptureSession.Preset { cameraManager.attributes.resolution }
    public var frameRate: Int32 { cameraManager.attributes.frameRate }
    public var exposureDuration: CMTime { cameraManager.attributes.cameraExposure.duration }
    public var exposureTargetBias: Float { cameraManager.attributes.cameraExposure.targetBias }
    public var iso: Float { cameraManager.attributes.cameraExposure.iso }
    public var exposureMode: AVCaptureDevice.ExposureMode { cameraManager.attributes.cameraExposure.mode }
    public var hdrMode: CameraHDRMode { cameraManager.attributes.hdrMode }
    public var cameraFilters: [CIFilter] { cameraManager.attributes.cameraFilters }
    public var isOutputMirrored: Bool { cameraManager.attributes.mirrorOutput }
    public var isGridVisible: Bool { cameraManager.attributes.isGridVisible }
}

extension MCameraScreen {
    public var hasFlash: Bool { cameraManager.hasFlash }
    public var hasLight: Bool { cameraManager.hasLight }
    public var recordingTime: MTime { cameraManager.videoOutput.recordingTime }
    public var isRecording: Bool { cameraManager.videoOutput.timer.timerStatus == .running }
    public var isOrientationLocked: Bool {
        cameraManager.attributes.orientationLocked || cameraManager.attributes.userBlockedScreenRotation
    }

    public var deviceOrientation: AVCaptureVideoOrientation { cameraManager.attributes.deviceOrientation }

    /**
     The current scene luminance value (0.0 = dark, 1.0 = bright).

     Use this to adapt UI elements (like toolbar buttons) based on the camera preview brightness.
     For example, use white text with shadow on dark scenes, or black text on bright scenes.

     ## Usage
     ```swift
     var adaptiveForegroundColor: Color {
         sceneLuminance > 0.5 ? .black : .white
     }
     ```
     */
    public var sceneLuminance: CGFloat { cameraManager.sceneLuminance }
}
