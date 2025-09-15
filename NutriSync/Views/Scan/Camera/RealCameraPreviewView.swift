//
//  RealCameraPreviewView.swift
//  NutriSync
//
//  Created on 8/17/25.
//

import SwiftUI
import AVFoundation

// Camera Session Manager for pre-warming
class CameraSessionManager: ObservableObject {
    private var session: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    @Published var isReady = false
    
    func preWarmSession() {
        guard session == nil else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let newSession = AVCaptureSession()
            newSession.sessionPreset = .photo
            
            guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: backCamera) else {
                print("Unable to access back camera during pre-warm!")
                return
            }
            
            let newPhotoOutput = AVCapturePhotoOutput()
            
            if newSession.canAddInput(input) && newSession.canAddOutput(newPhotoOutput) {
                newSession.addInput(input)
                newSession.addOutput(newPhotoOutput)
                
                // Configure high resolution AFTER adding to session
                if #available(iOS 16.0, *) {
                    // Safely configure max photo dimensions after connection
                    if let maxDimensions = backCamera.activeFormat.supportedMaxPhotoDimensions.last,
                       maxDimensions.width > 0 && maxDimensions.height > 0 {
                        newPhotoOutput.maxPhotoDimensions = maxDimensions
                    }
                } else {
                    newPhotoOutput.isHighResolutionCaptureEnabled = true
                }
            }
            
            // Start the session to pre-warm
            newSession.startRunning()
            
            DispatchQueue.main.async {
                self.session = newSession
                self.photoOutput = newPhotoOutput
                self.isReady = true
            }
        }
    }
    
    func getSession() -> AVCaptureSession? {
        return session
    }
    
    func getPhotoOutput() -> AVCapturePhotoOutput? {
        return photoOutput
    }
    
    func stopSession() {
        session?.stopRunning()
    }
}

// Custom UIView to handle layout updates
class CameraPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update preview layer frame whenever view layout changes
        previewLayer?.frame = bounds
    }
}

struct RealCameraPreviewView: UIViewRepresentable {
    // Shared camera session for pre-warming
    static let sharedCameraSession = CameraSessionManager()
    @Binding var capturedImage: UIImage?
    @Binding var capturePhoto: Bool
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: RealCameraPreviewView
        var previewLayer: AVCaptureVideoPreviewLayer?
        var captureSession: AVCaptureSession?
        var photoOutput: AVCapturePhotoOutput?
        
        init(_ parent: RealCameraPreviewView) {
            self.parent = parent
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard error == nil else {
                print("Error capturing photo: \(error!)")
                return
            }
            
            // Process photo in autoreleasepool to manage memory
            autoreleasepool {
                guard let imageData = photo.fileDataRepresentation() else { return }
                
                // Compress image immediately to reduce memory usage
                guard let originalImage = UIImage(data: imageData) else { return }
                
                // Resize if needed (max 2048px for initial capture)
                let maxDimension: CGFloat = 2048
                let scale = min(maxDimension / originalImage.size.width, 
                               maxDimension / originalImage.size.height, 
                               1.0)
                
                let finalImage: UIImage
                if scale < 1.0 {
                    let newSize = CGSize(width: originalImage.size.width * scale,
                                        height: originalImage.size.height * scale)
                    UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
                    defer { UIGraphicsEndImageContext() }
                    originalImage.draw(in: CGRect(origin: .zero, size: newSize))
                    finalImage = UIGraphicsGetImageFromCurrentImageContext() ?? originalImage
                } else {
                    finalImage = originalImage
                }
                
                DispatchQueue.main.async {
                    self.parent.capturedImage = finalImage
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = .black // Set background to prevent flashing
        
        // Try to use pre-warmed session if available
        let captureSession: AVCaptureSession
        let photoOutput: AVCapturePhotoOutput
        
        if RealCameraPreviewView.sharedCameraSession.isReady,
           let preWarmedSession = RealCameraPreviewView.sharedCameraSession.getSession(),
           let preWarmedOutput = RealCameraPreviewView.sharedCameraSession.getPhotoOutput() {
            // Use pre-warmed session
            captureSession = preWarmedSession
            photoOutput = preWarmedOutput
            print("Using pre-warmed camera session")
        } else {
            // Create new session if pre-warm not available
            captureSession = AVCaptureSession()
            captureSession.sessionPreset = .photo
            
            // Try to get back camera first, then any camera as fallback
            let camera: AVCaptureDevice
            if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                camera = backCamera
                print("✅ Using back camera")
            } else if let anyCamera = AVCaptureDevice.default(for: .video) {
                camera = anyCamera
                print("⚠️ Using fallback camera (not back camera)")
            } else {
                print("❌ No camera available on device")
                return view
            }
            
            guard let input = try? AVCaptureDeviceInput(device: camera) else {
                print("❌ Unable to create camera input")
                return view
            }
            
            photoOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(photoOutput)
                print("✅ Camera input and output configured")
                
                // Configure high resolution AFTER adding to session
                if #available(iOS 16.0, *) {
                    // Safely configure max photo dimensions after connection
                    if let maxDimensions = camera.activeFormat.supportedMaxPhotoDimensions.last,
                       maxDimensions.width > 0 && maxDimensions.height > 0 {
                        photoOutput.maxPhotoDimensions = maxDimensions
                    }
                } else {
                    photoOutput.isHighResolutionCaptureEnabled = true
                }
            } else {
                print("❌ Failed to add input/output to capture session")
                return view
            }
            
            // Start session on background queue
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
                DispatchQueue.main.async {
                    print("✅ Camera session started")
                }
            }
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        // Use view bounds instead of screen bounds
        previewLayer.frame = view.bounds
        
        view.layer.addSublayer(previewLayer)
        view.previewLayer = previewLayer // Store reference for layout updates
        
        context.coordinator.captureSession = captureSession
        context.coordinator.previewLayer = previewLayer
        context.coordinator.photoOutput = photoOutput
        
        // Ensure the preview layer updates when view layout changes
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if capturePhoto {
            guard let photoOutput = context.coordinator.photoOutput else { 
                print("❌ Photo output not available")
                capturePhoto = false
                return 
            }
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            
            photoOutput.capturePhoto(with: settings, delegate: context.coordinator)
            print("📸 Photo capture initiated")
            
            // Reset the trigger after a small delay to ensure the capture is initiated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                capturePhoto = false
            }
        }
        
        // Always update preview layer frame to match view bounds
        if let previewLayer = context.coordinator.previewLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = uiView.bounds
            CATransaction.commit()
        }
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.captureSession?.stopRunning()
    }
}

// Camera permission check view
struct CameraView: View {
    @Binding var capturedImage: UIImage?
    @Binding var capturePhoto: Bool
    @State private var isCameraAuthorized = false
    @State private var showingPermissionAlert = false
    @State private var permissionStatus: AVAuthorizationStatus = .notDetermined
    
    var body: some View {
        ZStack {
            if isCameraAuthorized {
                RealCameraPreviewView(
                    capturedImage: $capturedImage,
                    capturePhoto: $capturePhoto
                )
                .ignoresSafeArea()
            } else {
                // Show different UI based on permission status
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        
                        if permissionStatus == .notDetermined {
                            Text("Camera Permission Required")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Tap to enable camera access for meal scanning")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                requestCameraPermission()
                            }) {
                                Text("Enable Camera")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .cornerRadius(25)
                            }
                            .padding(.top, 8)
                        } else if permissionStatus == .denied || permissionStatus == .restricted {
                            Text("Camera Access Disabled")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Please enable camera access in Settings to scan your meals")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }) {
                                Text("Open Settings")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .cornerRadius(25)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                .onTapGesture {
                    if permissionStatus == .notDetermined {
                        requestCameraPermission()
                    } else if permissionStatus == .denied || permissionStatus == .restricted {
                        showingPermissionAlert = true
                    }
                }
            }
        }
        .onAppear {
            checkCameraAuthorization()
        }
        .alert("Camera Access Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable camera access in Settings to scan your meals.")
        }
    }
    
    private func checkCameraAuthorization() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("📷 Camera authorization status: \(status.rawValue)")
        permissionStatus = status
        
        switch status {
        case .authorized:
            print("✅ Camera authorized")
            isCameraAuthorized = true
            // Pre-warm the camera session when authorized
            RealCameraPreviewView.sharedCameraSession.preWarmSession()
        case .notDetermined:
            print("❓ Camera authorization not determined")
            // Don't automatically request - wait for user interaction
            isCameraAuthorized = false
        case .denied:
            print("❌ Camera access denied")
            isCameraAuthorized = false
        case .restricted:
            print("❌ Camera access restricted")
            isCameraAuthorized = false
        @unknown default:
            print("❌ Unknown camera authorization status")
            isCameraAuthorized = false
        }
    }
    
    private func requestCameraPermission() {
        print("📷 Requesting camera permission...")
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                print(granted ? "✅ Camera access granted" : "❌ Camera access denied by user")
                self.isCameraAuthorized = granted
                self.permissionStatus = granted ? .authorized : .denied
                if granted {
                    // Pre-warm after getting permission
                    RealCameraPreviewView.sharedCameraSession.preWarmSession()
                }
            }
        }
    }
}

#Preview {
    CameraView(
        capturedImage: .constant(nil),
        capturePhoto: .constant(false)
    )
    .preferredColorScheme(.dark)
}