//
//  RealCameraPreviewView.swift
//  NutriSync
//
//  Created on 8/17/25.
//

import SwiftUI
import AVFoundation

struct RealCameraPreviewView: UIViewRepresentable {
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
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            print("Unable to access back camera!")
            return view
        }
        
        let photoOutput = AVCapturePhotoOutput()
        photoOutput.isHighResolutionCaptureEnabled = true
        
        if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
            captureSession.addInput(input)
            captureSession.addOutput(photoOutput)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.captureSession = captureSession
        context.coordinator.previewLayer = previewLayer
        context.coordinator.photoOutput = photoOutput
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if capturePhoto {
            capturePhoto = false
            
            guard let photoOutput = context.coordinator.photoOutput else { return }
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            
            photoOutput.capturePhoto(with: settings, delegate: context.coordinator)
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