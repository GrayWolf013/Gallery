import UIKit
import AVFoundation

protocol CameraViewDelegate: class {
	func cameraView(_ cameraView: CameraView, didTouch point: CGPoint)
}

class CameraView: UIView, UIGestureRecognizerDelegate {
	
	lazy var closeButton: UIButton = self.makeCloseButton()
    lazy var flashButton: TripleButton = self.makeFlashButton()
    
	lazy var rotateButton: UIButton = self.makeRotateButton()
    lazy var galleryButton: UIButton = self.makeGalleryButton()
    
	lazy var bottomContainer: UIView = self.makeBottomContainer()
	lazy var bottomView: UIView = self.makeBottomView()
	lazy var stackView: StackView = self.makeStackView()
	lazy var shutterButton: ShutterButton = self.makeShutterButton()
	lazy var doneButton: UIButton = self.makeDoneButton()
	lazy var focusImageView: UIImageView = self.makeFocusImageView()
	lazy var tapGR: UITapGestureRecognizer = self.makeTapGR()
	lazy var rotateOverlayView: UIView = self.makeRotateOverlayView()
	lazy var shutterOverlayView: UIView = self.makeShutterOverlayView()
	lazy var blurView: UIVisualEffectView = self.makeBlurView()
    lazy var toastView: UIView = self.makeToastView()
    
	var timer: Timer?
	var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let toastLabel = UILabel()
    private var isMaxLimit = false
    private var isMaxSize = false

	weak var delegate: CameraViewDelegate?
	
	// MARK: - Initialization
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		backgroundColor = UIColor.black
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Setup
	
	func setup() {
		addGestureRecognizer(tapGR)
        
		[closeButton, flashButton, galleryButton, shutterButton, rotateButton, bottomContainer, toastView].forEach {
			addSubview($0)
		}
		
		[bottomView].forEach {
			bottomContainer.addSubview($0)
		}
		
		[stackView, doneButton].forEach {
			bottomView.addSubview($0)
		}
		
		[closeButton, flashButton, rotateButton, galleryButton].forEach {
			$0.g_addShadow()
		}
		
		rotateOverlayView.addSubview(blurView)
		insertSubview(rotateOverlayView, belowSubview: rotateButton)
		insertSubview(focusImageView, belowSubview: bottomContainer)
		insertSubview(shutterOverlayView, belowSubview: bottomContainer)
		
		closeButton.g_pin(on: .left)
		closeButton.g_pin(size: CGSize(width: 44, height: 44))
		
		flashButton.g_pin(on: .centerY, view: closeButton)
        flashButton.g_pin(on: .right)
		flashButton.g_pin(size: CGSize(width: 60, height: 44))
		
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        shutterButton.bottomAnchor.constraint(equalTo: bottomView.topAnchor, constant: -32).isActive = true
        shutterButton.g_pin(on: .centerX)
        shutterButton.g_pin(size: CGSize(width: 70, height: 70))
        
        rotateButton.g_pin(on: .right, constant: -32)
		rotateButton.g_pin(size: CGSize(width: 52, height: 52))
        rotateButton.g_pin(on: .centerY, view: shutterButton)
        
        galleryButton.g_pin(on: .left, constant: 32)
        galleryButton.g_pin(size: CGSize(width: 52, height: 52))
        galleryButton.g_pin(on: .centerY, view: shutterButton)
        
        Constraint.on(
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
        )
		
		bottomContainer.g_pinDownward()
		bottomContainer.g_pin(height: 80)
		bottomView.g_pinEdges()
		
		stackView.g_pin(on: .centerY, constant: -4)
		stackView.g_pin(on: .left, constant: 38)
		stackView.g_pin(size: CGSize(width: 56, height: 56))
		
		doneButton.g_pin(on: .centerY)
		doneButton.g_pin(on: .right, constant: -38)
		
		rotateOverlayView.g_pinEdges()
		blurView.g_pinEdges()
		shutterOverlayView.g_pinEdges()
        
        toastView.g_pin(on: .centerX)
        toastView.g_pin(on: .bottom, view: bottomView, on: .top, constant: -8)
	}
    
    func handleToast(_ isHidden: Bool, isMaxSize: Bool) {
        
        if isMaxSize {
            if isHidden {
                self.isMaxSize = false
            } else {
                self.isMaxSize = true
                toastLabel.text = Config.Toast.maxImageSizeText
            }
        } else {
            if isHidden {
                self.isMaxLimit = false
            } else {
                self.isMaxLimit = true
                toastLabel.text = Config.Toast.maxLimitText
            }
        }
        
        let shouldShow = !(self.isMaxLimit || self.isMaxSize)
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.toastView.alpha = shouldShow ? 0 : 1
            self?.shutterButton.alpha = shouldShow ? 1 : 0
            self?.closeButton.alpha = shouldShow ? 1 : 0
            self?.doneButton.alpha = shouldShow ? 1 : 0
        }
    }
	
	func setupPreviewLayer(_ session: AVCaptureSession) {
		guard previewLayer == nil else { return }
		
		let layer = AVCaptureVideoPreviewLayer(session: session)
		layer.autoreverses = true
		layer.videoGravity = .resizeAspectFill
		layer.connection?.videoOrientation = Utils.videoOrientation()
		
		self.layer.insertSublayer(layer, at: 0)
		layer.frame = self.layer.bounds
		
		previewLayer = layer
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		previewLayer?.frame = self.layer.bounds
	}
	
	// MARK: - Action
	
	@objc func viewTapped(_ gr: UITapGestureRecognizer) {
		let point = gr.location(in: self)
		
		focusImageView.transform = CGAffineTransform.identity
		timer?.invalidate()
		delegate?.cameraView(self, didTouch: point)
		
		focusImageView.center = point
		
		UIView.animate(withDuration: 0.5, animations: {
			self.focusImageView.alpha = 1
			self.focusImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
		}, completion: { _ in
			self.timer = Timer.scheduledTimer(timeInterval: 1, target: self,
											  selector: #selector(CameraView.timerFired(_:)), userInfo: nil, repeats: false)
		})
	}
	
	// MARK: - Timer
	
	@objc func timerFired(_ timer: Timer) {
		UIView.animate(withDuration: 0.3, animations: {
			self.focusImageView.alpha = 0
		}, completion: { _ in
			self.focusImageView.transform = CGAffineTransform.identity
		})
	}
	
	// MARK: - UIGestureRecognizerDelegate
	override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		let point = gestureRecognizer.location(in: self)
		
		return point.y > closeButton.frame.maxY
			&& point.y < bottomContainer.frame.origin.y
	}
	
	// MARK: - Controls
	
	func makeCloseButton() -> UIButton {
		let button = UIButton(type: .custom)
		button.setImage(GalleryBundle.image("gallery_close"), for: UIControl.State())
		
		return button
	}
	
	func makeFlashButton() -> TripleButton {
        let offImage = Config.Camera.FlashButton.offImage ?? GalleryBundle.image("gallery_camera_flash_off")!
        let onImage = Config.Camera.FlashButton.onImage ?? GalleryBundle.image("gallery_camera_flash_on")!
        
		let states: [TripleButton.ButtonState] = [
			TripleButton.ButtonState(title: "", image: offImage),
			TripleButton.ButtonState(title: "", image: onImage),
			TripleButton.ButtonState(title: "Gallery.Camera.Flash.Auto".g_localize(fallback: "AUTO"), image: GalleryBundle.image("gallery_camera_flash_auto")!)
		]
		
		let button = TripleButton(states: states)
		
		return button
	}
	
	func makeRotateButton() -> UIButton {
		let button = UIButton(type: .custom)
        if let image = Config.Camera.RotateButton.image {
            button.setImage(image, for: UIControl.State())
        } else {
            button.setImage(GalleryBundle.image("gallery_camera_rotate"), for: UIControl.State())
        }
		
		return button
	}
    
    func makeGalleryButton() -> UIButton {
        let button = UIButton()
        if let image = Config.Camera.GalleryButton.image {
            button.setImage(image, for: UIControl.State())
        } else {
            button.setTitle("gallery", for: .normal)
        }
        return button
    }
	
	func makeBottomContainer() -> UIView {
		let view = UIView()
		
		return view
	}
	
	func makeBottomView() -> UIView {
		let view = UIView()
		view.backgroundColor = Config.Camera.BottomContainer.backgroundColor
		view.alpha = 0
		
		return view
	}
	
	func makeStackView() -> StackView {
		let view = StackView()
		
		return view
	}
	
	func makeShutterButton() -> ShutterButton {
		let button = ShutterButton()
		button.g_addShadow()
		
		return button
	}
    
    private func makeToastView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        view.layer.cornerRadius = 12
        
        toastLabel.text = Config.Toast.maxImageSizeText
        toastLabel.textColor = .white
        toastLabel.font = Config.Toast.toastFont
        
        let infoImage = UIImageView()
        infoImage.image = Config.Toast.infoImage
        infoImage.tintColor = .white
        infoImage.g_pin(height: 16)
        infoImage.g_pin(width: 16)
        
        let stack = UIStackView.init(arrangedSubviews: [infoImage, toastLabel])
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        
        view.addSubview(stack)
        stack.g_pinEdges(insets: .init(top: 12, left: 8, bottom: -12, right: -8))
        
        view.alpha = 0
        return view
    }
	
	func makeDoneButton() -> UIButton {
		let button = UIButton(type: .system)
		button.setTitleColor(UIColor.white, for: UIControl.State())
		button.setTitleColor(UIColor.lightGray, for: .disabled)
		button.titleLabel?.font = Config.Font.Text.regular.withSize(16)
		button.setTitle("Gallery.Done".g_localize(fallback: "Done"), for: UIControl.State())
		
		return button
	}
	
	func makeFocusImageView() -> UIImageView {
		let view = UIImageView()
		view.frame.size = CGSize(width: 110, height: 110)
		view.image = GalleryBundle.image("gallery_camera_focus")
		view.backgroundColor = .clear
		view.alpha = 0
		
		return view
	}
	
	func makeTapGR() -> UITapGestureRecognizer {
		let gr = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
		gr.delegate = self
		
		return gr
	}
	
	func makeRotateOverlayView() -> UIView {
		let view = UIView()
		view.alpha = 0
		
		return view
	}
	
	func makeShutterOverlayView() -> UIView {
		let view = UIView()
		view.alpha = 0
		view.backgroundColor = UIColor.black
		
		return view
	}
	
	func makeBlurView() -> UIVisualEffectView {
		let effect = UIBlurEffect(style: .dark)
		let blurView = UIVisualEffectView(effect: effect)
		
		return blurView
	}
}
