import UIKit
import AVFoundation

public protocol GalleryControllerDelegate: class {
	
    func galleryController(_ controller: GalleryController, didCapture images: [Image])
	func galleryController(_ controller: GalleryController, didSelectImages images: [Image])
	func galleryController(_ controller: GalleryController, didSelectVideo video: Video)
	func galleryController(_ controller: GalleryController, requestLightbox images: [Image])
    func galleryController(_ controller: GalleryController, requestLightbox image: Image)
	func galleryControllerDidCancel(_ controller: GalleryController)
}

open class GalleryController: UIViewController {
	
	public weak var delegate: GalleryControllerDelegate?
    
    private var imagesController: ImagesController?
    private var cameraController: CameraController?
    private var pagesController: PagesController?

    private var shouldHideElement = false
    
	public let cart = Cart()
	// MARK: - Init
	
	public required init() {
		super.init(nibName: nil, bundle: nil)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	// MARK: - Life cycle
	
	open override func viewDidLoad() {
		super.viewDidLoad()
        self.isModalInPresentation = true
        setup()
		
		if let pagesController = makePagesController() {
            self.pagesController = pagesController
			g_addChildController(pagesController)
		} else {
			let permissionController = makePermissionController()
			g_addChildController(permissionController)
		}
	}
	
	open override var prefersStatusBarHidden : Bool {
		return Config.showStatusBar
	}
    
    // MARK: - Public func
    public func handleSelect(_ image: Image) {
        imagesController?.handleSelect(image)
    }
    
    public func shouldHideElements(_ isHidden: Bool) {
        self.shouldHideElement = isHidden
        cameraController?.cameraView.closeButton.isHidden = isHidden
        imagesController?.gridView.closeButton.isHidden = isHidden
        
        
        cameraController?.cameraMan
    }
    
    public func configurePreset() {
        cameraController?.configurePreset()
    }
    
    public func present(tab: Config.GalleryTab) {
        pagesController?.scroll(to: tab)
    }
	
	// MARK: - Child view controller
	func makeImagesController() -> ImagesController {
		let controller = ImagesController(cart: cart)
		controller.title = "Gallery.Images.Title".g_localize(fallback: "PHOTOS")
        controller.gridView.closeButton.isHidden = shouldHideElement

		return controller
	}
	
	func makeCameraController() -> CameraController {
		let controller = CameraController(cart: cart)
		controller.title = "Gallery.Camera.Title".g_localize(fallback: "CAMERA")
        controller.cameraView.closeButton.isHidden = shouldHideElement
		return controller
	}
	
	func makeVideosController() -> VideosController {
		let controller = VideosController(cart: cart)
		controller.title = "Gallery.Videos.Title".g_localize(fallback: "VIDEOS")
		
		return controller
	}
	
	func makePagesController() -> PagesController? {
		guard Permission.Photos.status == .authorized else {
			return nil
		}
		
		let useCamera = Permission.Camera.needsPermission && Permission.Camera.status == .authorized
		
		let tabsToShow = Config.tabsToShow.compactMap { $0 != .cameraTab ? $0 : (useCamera ? $0 : nil) }
		
		let controllers: [UIViewController] = tabsToShow.compactMap { tab in
			if tab == .imageTab {
                imagesController = makeImagesController()
				return imagesController
			} else if tab == .cameraTab {
				cameraController = makeCameraController()
                return cameraController
			} else if tab == .videoTab {
				return makeVideosController()
			} else {
				return nil
			}
		}
		
		guard !controllers.isEmpty else {
			return nil
		}
		
		let controller = PagesController(controllers: controllers)
		controller.selectedIndex = tabsToShow.firstIndex(of: Config.initialTab ?? .cameraTab) ?? 0
		
		return controller
	}
	
	func makePermissionController() -> PermissionController {
		let controller = PermissionController()
		controller.delegate = self
		
		return controller
	}
	
	// MARK: - Setup
	
	func setup() {
		EventHub.shared.close = {[weak self] _ in
			if let self = self {
                self.delegate?.galleryControllerDidCancel(self)
			}
		}
		
		EventHub.shared.doneWithImages = { [weak self] _ in
			if let self = self {
                self.delegate?.galleryController(self, didSelectImages: self.cart.images)
			}
		}
		
		EventHub.shared.doneWithVideos = { [weak self] _ in
			if let self = self, let video = self.cart.video {
                self.delegate?.galleryController(self, didSelectVideo: video)
			}
		}
		
		EventHub.shared.stackViewTouched = { [weak self] _ in
			if let self = self {
                self.delegate?.galleryController(self, requestLightbox: self.cart.images)
			}
		}
        
        EventHub.shared.previewImage = { [weak self] image in
            if let self = self {
                self.delegate?.galleryController(self, requestLightbox: image)
            }
        }
        
        EventHub.shared.imageCaptured = { [weak self] _ in
            if let self = self {
                self.delegate?.galleryController(self, didCapture: self.cart.images)
            }
        }
       
        EventHub.shared.requestScrollToGallery = { [weak self] _ in
            self?.pagesController?.scroll(to: .imageTab)
        }
        
        EventHub.shared.imageSize = { [weak self] imageSize in
            let isMaxReached = imageSize > Config.Toast.maxImagesSize
            print("isMaxReached: \(isMaxReached)")
            self?.imagesController?.handleToast(!isMaxReached)
            self?.cameraController?.handleToast(!isMaxReached)
        }
	}
}

// MARK: - PermissionControllerDelegate
extension GalleryController: PermissionControllerDelegate {
    func permissionControllerDidFinish(_ controller: PermissionController) {
        if let pagesController = makePagesController() {
            self.pagesController = pagesController
            g_addChildController(pagesController)
            controller.g_removeFromParentController()
        }
    }
}
