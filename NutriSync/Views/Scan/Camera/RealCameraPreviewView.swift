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
            newPhotoOutput.isHighResolutionCaptureEnabled = true
            
            if newSession.canAddInput(input) && newSession.canAddOutput(newPhotoOutput) {
                newSession.addInput(input)
                newSession.addOutput(newPhotoOutput)
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
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else { return }
            
            DispatchQueue.main.async {
                self.parent.capturedImage = image
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        // Try to use pre-warmed session if available
        let captureSession: AVCaptureSession
        let photoOutput: AVCapturePhotoOutput
        
        if RealCameraPreviewView.sharedCameraSession.isReady,
           let preWarmedSession = RealCameraPreviewView.sharedCameraSession.getSession(),
           let preWarmedOutput = RealCameraPreviewView.sharedCameraSession.getPhotoOutput() {
            // Use pre-warmed session
            captureSession = preWarmedSession
            photoOutput = preWarmedOutput
        } else {
            // Create new session if pre-warm not available
            captureSession = AVCaptureSession()
            captureSession.sessionPreset = .photo
            
            guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: backCamera) else {
                print("Unable to access back camera!")
                return view
            }
            
            photoOutput = AVCapturePhotoOutput()
            photoOutput.isHighResolutionCaptureEnabled = true
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(photoOutput)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.captureSession = captureSession
        context.coordinator.previewLayer = previewLayer
        context.coordinator.photoOutput = photoOutput
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if capturePhoto {
            guard let photoOutput = context.coordinator.photoOutput else { 
                capturePhoto = false
                return 
            }
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            
            photoOutput.capturePhoto(with: settings, delegate: context.coordinator)
            
            // Reset the trigger after a small delay to ensure the capture is initiated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                capturePhoto = false
            }
        }
        
        // Update preview layer frame on orientation changes
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
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
    
    var body: some View {
        ZStack {
            if isCameraAuthorized {
                RealCameraPreviewView(
                    capturedImage: $capturedImage,
                    capturePhoto: $capturePhoto
                )
                .ignoresSafeArea()
            } else {
                // Fallback to mock camera if no permission
                CameraPreviewView()
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingPermissionAlert = true
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
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    isCameraAuthorized = granted
                }
            }
        case .denied, .restricted:
            isCameraAuthorized = false
            showingPermissionAlert = true
        @unknown default:
            isCameraAuthorized = false
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