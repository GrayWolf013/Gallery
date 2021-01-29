import Foundation
import AVFoundation
import PhotosUI
import Photos

protocol CameraManDelegate: class {
	func cameraManNotAvailable(_ cameraMan: CameraMan)
	func cameraManDidStart(_ cameraMan: CameraMan)
	func cameraMan(_ cameraMan: CameraMan, didChangeInput input: AVCaptureDeviceInput)
}

class CameraMan: NSObject {
	weak var delegate: CameraManDelegate?
	
	let session = AVCaptureSession()
	let queue = DispatchQueue(label: "no.hyper.Gallery.Camera.SessionQueue", qos: .background)
    let savingQueue = DispatchQueue(label: "no.hyper.Gallery.Camera.SavingQueue", qos: .userInteractive)
	let orientationMan = OrientationMan()
	
	var backCamera: AVCaptureDeviceInput?
	var frontCamera: AVCaptureDeviceInput?
    var photoOutput: AVCapturePhotoOutput?
        
    private var captureImageCompletion: ((PHAsset?) -> Void)?
    private var flashMode: AVCaptureDevice.FlashMode = .off
    
	deinit {
		stop()
	}
	
	// MARK: - Setup
	func setup() {
		if Permission.Camera.status == .authorized {
			self.start()
		} else {
			self.delegate?.cameraManNotAvailable(self)
		}
	}
    
    func configurePreset() {
        configurePreset(device: currentInput?.device)
    }
	
	func setupDevices() {
		// Input
		AVCaptureDevice
			.devices()
			.filter {
				return $0.hasMediaType(.video)
			}.forEach {
				switch $0.position {
				case .front:
					self.frontCamera = try? AVCaptureDeviceInput(device: $0)
				case .back:
					self.backCamera = try? AVCaptureDeviceInput(device: $0)
				default:
					break
				}
			}
		
		// Output
        photoOutput = AVCapturePhotoOutput()
        photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])])
	}
	
	func addInput(_ input: AVCaptureDeviceInput) {
        configurePreset(device: input.device)
		
		if session.canAddInput(input) {
			session.addInput(input)
			
			DispatchQueue.main.async {
				self.delegate?.cameraMan(self, didChangeInput: input)
			}
		}
	}
	
	// MARK: - Session
	
	var currentInput: AVCaptureDeviceInput? {
		return session.inputs.first as? AVCaptureDeviceInput
	}
	
	fileprivate func start() {
		// Devices
		setupDevices()
		
		guard let input = backCamera, let output = photoOutput else { return }
		
		addInput(input)
		
		if session.canAddOutput(output) {
			session.addOutput(output)
		}
		
		queue.async {
			self.session.startRunning()
			
			DispatchQueue.main.async {
				self.delegate?.cameraManDidStart(self)
			}
		}
	}
	
	func stop() {
		self.session.stopRunning()
	}
	
	func switchCamera(_ completion: (() -> Void)? = nil) {
		guard let currentInput = currentInput
		else {
			completion?()
			return
		}
		
		queue.async {
			guard let input = (currentInput == self.backCamera) ? self.frontCamera : self.backCamera
			else {
				DispatchQueue.main.async {
					completion?()
				}
				return
			}
			
			self.configure {
				self.session.removeInput(currentInput)
				self.addInput(input)
			}
			
			DispatchQueue.main.async {
				completion?()
			}
		}
	}
	
	func takePhoto(_ previewLayer: AVCaptureVideoPreviewLayer, completion: @escaping ((PHAsset?) -> Void)) {
        self.captureImageCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
	}
	
	func savePhoto(_ image: UIImage) {
		var localIdentifier: String?
		
		savingQueue.async { [weak self] in
			do {
				try PHPhotoLibrary.shared().performChangesAndWait {
					let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
					localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
					
					request.creationDate = Date()
				}
                if let localIdentifier = localIdentifier {
                    self?.captureImageCompletion?(Fetcher.fetchAsset(localIdentifier))
                } else {
                    self?.captureImageCompletion?(nil)
                }
				
			} catch {
                self?.captureImageCompletion?(nil)
			}
		}
	}
    
	func flash(_ mode: AVCaptureDevice.FlashMode) {
        self.flashMode = mode
	}
	
	func focus(_ point: CGPoint) {
		guard let device = currentInput?.device ,
              device.isFocusModeSupported(AVCaptureDevice.FocusMode.locked) else { return }
		
		queue.async {
			self.lock {
				device.focusPointOfInterest = point
			}
		}
	}
	
	// MARK: - Lock
	
	func lock(_ block: () -> Void) {
		if let device = currentInput?.device , (try? device.lockForConfiguration()) != nil {
			block()
			device.unlockForConfiguration()
		}
	}
	
	// MARK: - Configure
	func configure(_ block: () -> Void) {
		session.beginConfiguration()
		block()
		session.commitConfiguration()
	}
	
	// MARK: - Preset
    func configurePreset(device: AVCaptureDevice?) {
        guard let device = device else { return }
        switch Config.cameraPreset {
        case .low:
            if device.supportsSessionPreset(.low),
               session.canSetSessionPreset(.low) {
                self.session.sessionPreset = .low
            }
            
        case .medium:
            if device.supportsSessionPreset(.medium),
               session.canSetSessionPreset(.medium) {
                self.session.sessionPreset = .medium
            }
            
        case .high:
            if device.supportsSessionPreset(.high),
               session.canSetSessionPreset(.high) {
                self.session.sessionPreset = .high
            }
            
        case.original:
            if device.supportsSessionPreset(.photo),
               session.canSetSessionPreset(.photo) {
                self.session.sessionPreset = .photo
            }
        }
    }
}


extension CameraMan: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData)
        else {
            self.captureImageCompletion?(nil)
            self.reset()
            return
        }
        
        self.savePhoto(image)
    }
    
    
    private func reset() {
        self.captureImageCompletion = nil
    }
}
