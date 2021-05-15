import UIKit
import Photos

class ImagesController: UIViewController {
	
	lazy var dropdownController: DropdownController = self.makeDropdownController()
	lazy var gridView: GridView = self.makeGridView()
	lazy var stackView: StackView = self.makeStackView()
    private let generator = UIImpactFeedbackGenerator(style: .medium)
    
	var items: [Image] = []
	let library = ImagesLibrary()
	var selectedAlbum: Album?
	let once = Once()
	let cart: Cart
	
    private var isMultipleSelectionModeActive: Bool {
        return !cart.images.isEmpty
    }
	
	// MARK: - Init
	public required init(cart: Cart) {
		self.cart = cart
		super.init(nibName: nil, bundle: nil)
		cart.delegates.add(self)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setup()
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gridView.collectionView.reloadData()
    }
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			self.gridView.collectionView.collectionViewLayout.invalidateLayout()
		}
	}
	
	// MARK: - Setup
	
	func setup() {
		view.backgroundColor = .backgroundColor
		
		view.addSubview(gridView)
		
		addChild(dropdownController)
		gridView.insertSubview(dropdownController.view, belowSubview: gridView.topView)
		dropdownController.didMove(toParent: self)
		
		gridView.bottomView.addSubview(stackView)
		
		gridView.g_pinEdges()
		
		dropdownController.view.g_pin(on: .left)
		dropdownController.view.g_pin(on: .right)
		dropdownController.view.g_pin(on: .height, constant: -40) // subtract gridView.topView height
		
		dropdownController.expandedTopConstraint = dropdownController.view.g_pin(on: .top, view: gridView.topView, on: .bottom, constant: 1)
		dropdownController.expandedTopConstraint?.isActive = false
		dropdownController.collapsedTopConstraint = dropdownController.view.g_pin(on: .top, on: .bottom)
		
		stackView.g_pin(on: .centerY, constant: -4)
		stackView.g_pin(on: .left, constant: 38)
		stackView.g_pin(size: CGSize(width: 56, height: 56))
		
		gridView.closeButton.addTarget(self, action: #selector(closeButtonTouched(_:)), for: .touchUpInside)
		gridView.doneButton.addTarget(self, action: #selector(doneButtonTouched(_:)), for: .touchUpInside)
		gridView.arrowButton.addTarget(self, action: #selector(arrowButtonTouched(_:)), for: .touchUpInside)
        gridView.cameraButton.addTarget(self, action: #selector(cameraButtonTouched(_:)), for: .touchUpInside)
		stackView.addTarget(self, action: #selector(stackViewTouched(_:)), for: .touchUpInside)
		
		gridView.collectionView.dataSource = self
		gridView.collectionView.delegate = self
		gridView.collectionView.register(ImageCell.self, forCellWithReuseIdentifier: String(describing: ImageCell.self))
		
		let longGesture = UILongPressGestureRecognizer.init(target: self, action: #selector(handleLongPress(gesture:)))
		gridView.collectionView.addGestureRecognizer(longGesture)
	}
	
	// MARK: - Action
	
	@objc func closeButtonTouched(_ button: UIButton) {
        EventHub.shared.close?(())
	}
	
	@objc func doneButtonTouched(_ button: UIButton) {
		EventHub.shared.doneWithImages?(())
	}
	
	@objc func arrowButtonTouched(_ button: ArrowButton) {
		dropdownController.toggle()
		button.toggle(dropdownController.expanding)
	}
    
    @objc func cameraButtonTouched(_ button: ArrowButton) {
        EventHub.shared.requestScrollToCamera?(())
    }
	
	@objc func stackViewTouched(_ stackView: StackView) {
		EventHub.shared.stackViewTouched?(())
	}
	
	// MARK: - Logic
    func handleToast(_ isHidden: Bool) {
        gridView.handleToast(isHidden)
    }
    
	func show(album: Album) {
		gridView.arrowButton.updateText(album.collection.localizedTitle ?? "")
		items = album.items
		gridView.collectionView.reloadData()
		gridView.collectionView.g_scrollToTop()
		gridView.emptyView.isHidden = !items.isEmpty
	}
	
	func refreshSelectedAlbum() {
		if let selectedAlbum = selectedAlbum {
			selectedAlbum.reload()
			show(album: selectedAlbum)
		}
	}
	
	// MARK: - View
	
	func refreshView() {
		let hasImages = !cart.images.isEmpty
		gridView.bottomView.g_fade(visible: hasImages)
		gridView.collectionView.g_updateBottomInset(hasImages ? gridView.bottomView.frame.size.height : 0)
	}
	
	// MARK: - Controls
	
	func makeDropdownController() -> DropdownController {
		let controller = DropdownController()
		controller.delegate = self
		
		return controller
	}
	
	func makeGridView() -> GridView {
		let view = GridView()
		view.bottomView.alpha = 0
		
		return view
	}
	
	func makeStackView() -> StackView {
		let view = StackView()
		
		return view
	}
}

extension ImagesController: PageAware {
	
	func pageDidShow() {
		once.run {
			library.reload {
				self.gridView.loadingIndicator.stopAnimating()
				self.dropdownController.albums = self.library.albums
				self.dropdownController.tableView.reloadData()
				
				if let album = self.library.albums.first {
					self.selectedAlbum = album
					self.show(album: album)
				}
			}
		}
	}
}

extension ImagesController: CartDelegate {
	
	func cart(_ cart: Cart, didAdd image: Image, newlyTaken: Bool) {
        reload(with: cart.images, added: true)
		refreshView()
		
		if newlyTaken {
			refreshSelectedAlbum()
		}
	}
	
	func cart(_ cart: Cart, didRemove image: Image) {
        reload(with: cart.images, added: false)
		refreshView()
	}
	
	func cartDidReload(_ cart: Cart) {
        reload(with: cart.images, added: false)
		refreshView()
		refreshSelectedAlbum()
	}
    
    private func reload(with images: [Image], added: Bool) {
    
        stackView.reload(images, added: added)
    
        let limit = Config.Camera.imageLimit
        let selected = images.count
        gridView.progressLabel.text = "\(selected)/\(limit) Items Selected"
    }
}

extension ImagesController: DropdownControllerDelegate {
	
	func dropdownController(_ controller: DropdownController, didSelect album: Album) {
		selectedAlbum = album
		show(album: album)
		
		dropdownController.toggle()
		gridView.arrowButton.toggle(controller.expanding)
	}
}

extension ImagesController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	
	// MARK: - UICollectionViewDataSource
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return items.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ImageCell.self), for: indexPath)
			as! ImageCell
		let item = items[(indexPath as NSIndexPath).item]
		
		cell.configure(item)
		configureFrameView(cell, indexPath: indexPath)
		
		return cell
	}
	
	// MARK: - UICollectionViewDelegateFlowLayout
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		
		let size = (collectionView.bounds.size.width - (Config.Grid.Dimension.columnCount - 1) * Config.Grid.Dimension.cellSpacing)
			/ Config.Grid.Dimension.columnCount
		return CGSize(width: size, height: size)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let item = items[(indexPath as NSIndexPath).item]
		
		if isMultipleSelectionModeActive {
			handleSelect(item)
		} else {
            cart.add(item)
            EventHub.shared.doneWithImages?(())
		}
	}
    
    func handleSelect(_ image: Image) {
        if cart.images.contains(image) {
            cart.remove(image)
        } else {
            if Config.Camera.imageLimit == 0 || Config.Camera.imageLimit > cart.images.count {
                cart.add(image)
            }
        }
                
        configureFrameViews()
    }
	
	@objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            gridView.collectionView.allowsSelection = false
            
            generator.impactOccurred()
            
            let collectionView = gridView.collectionView
            let location = gesture.location(in: collectionView)
            
            if let indexPath = collectionView.indexPathForItem(at: location) {
                let item = items[(indexPath as NSIndexPath).item]
                handleSelect(item)
            } else {
                print("No index found at gesture location")
            }
            
        case .ended:
            gridView.collectionView.allowsSelection = true
            
        default: break
        }
	}
	
	func configureFrameViews() {
		for case let cell as ImageCell in gridView.collectionView.visibleCells {
			if let indexPath = gridView.collectionView.indexPath(for: cell) {
				configureFrameView(cell, indexPath: indexPath)
			}
		}
	}
	
	func configureFrameView(_ cell: ImageCell, indexPath: IndexPath) {
		let item = items[(indexPath as NSIndexPath).item]
		if let index = cart.images.firstIndex(of: item) {
			cell.frameView.g_quickFade()
            cell.frameView.selectedImageView.isHidden = false
			cell.contentView.alpha = 1
		} else {
			cell.frameView.alpha = 0
			if Config.Camera.imageLimit == cart.images.count {
				cell.contentView.alpha = 0.5
			} else {
				cell.contentView.alpha = 1
			}
		}
	}
}
