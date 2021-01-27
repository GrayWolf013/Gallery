import UIKit
import Photos

class GridView: UIView {
    
    // MARK: - Initialization
    
    lazy var topView: UIView = self.makeTopView()
    lazy var bottomView: UIView = self.makeBottomView()
    lazy var bottomBlurView: UIVisualEffectView = self.makeBottomBlurView()
    lazy var arrowButton: ArrowButton = self.makeArrowButton()
    lazy var collectionView: UICollectionView = self.makeCollectionView()
    lazy var closeButton: UIButton = self.makeCloseButton()
    lazy var cameraButton: UIButton = self.makeCameraButton()
    lazy var doneButton: UIButton = self.makeDoneButton()
    lazy var emptyView: UIView = self.makeEmptyView()
    lazy var loadingIndicator: UIActivityIndicatorView = self.makeLoadingIndicator()
    lazy var progressLabel: UILabel = self.makeProgressLabel()
    lazy var maxToastView: UIView = self.makeMaxSizeToast()

    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
        loadingIndicator.startAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setup() {
        [collectionView, bottomView, topView, emptyView, loadingIndicator, maxToastView].forEach {
            addSubview($0)
        }
        
        [closeButton, arrowButton, cameraButton].forEach {
            topView.addSubview($0)
        }
        
        [bottomBlurView, doneButton, progressLabel].forEach {
            bottomView.addSubview($0)
        }
                
        Constraint.on(
            topView.leftAnchor.constraint(equalTo: self.leftAnchor),
            topView.rightAnchor.constraint(equalTo: self.rightAnchor),
            topView.topAnchor.constraint(equalTo: self.topAnchor),
            topView.heightAnchor.constraint(equalToConstant: 48),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingIndicator.superview!.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingIndicator.superview!.centerYAnchor)
        )
        
        bottomView.g_pinDownward()
        bottomView.g_pin(height: 80)
        
        emptyView.g_pinEdges(view: collectionView)
        
        collectionView.g_pinDownward()
        collectionView.g_pin(on: .top, view: topView, on: .bottom, constant: 1)
        
        bottomBlurView.g_pinEdges()
        
        closeButton.g_pin(on: .top)
        closeButton.g_pin(on: .left)
        closeButton.g_pin(size: CGSize(width: 48, height: 48))
        
        cameraButton.g_pin(on: .top)
        cameraButton.g_pin(on: .right)
        cameraButton.g_pin(size: CGSize(width: 48, height: 48))

        arrowButton.g_pin(on: .centerX)
        arrowButton.g_pin(on: .top)
        arrowButton.g_pin(height: 48)
        
        doneButton.g_pin(on: .centerY)
        doneButton.g_pin(on: .right, constant: -38)
        
        progressLabel.g_pin(on: .centerX)
        progressLabel.g_pin(on: .centerY)

        maxToastView.g_pin(on: .centerX)
        maxToastView.g_pin(on: .bottom, view: bottomView, on: .top, constant: -8)
    }
    
    func handleToast(_ isHidden: Bool) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.maxToastView.alpha = isHidden ? 0 : 1
            self?.closeButton.alpha = isHidden ? 1 : 0
            self?.doneButton.alpha = isHidden ? 1 : 0
        }
    }
    
    // MARK: - Controls
    
    private func makeTopView() -> UIView {
        let view = UIView()
        view.backgroundColor = .backgroundColor
        
        return view
    }
    
    private func makeBottomView() -> UIView {
        let view = UIView()
        
        return view
    }
    
    private func makeBottomBlurView() -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        
        return view
    }
    
    private func makeArrowButton() -> ArrowButton {
        let button = ArrowButton()
        button.layoutSubviews()
        
        return button
    }
    
    private func makeCloseButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(GalleryBundle.image("gallery_close")?.withRenderingMode(.alwaysTemplate), for: UIControl.State())
        button.tintColor = Config.Grid.CloseButton.tintColor
        
        return button
    }
    
    private func makeCameraButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(Config.Grid.CameraButton.image?.withRenderingMode(.alwaysTemplate), for: UIControl.State())
        button.tintColor = Config.Grid.CameraButton.tintColor
        
        return button
    }
    
    private func makeDoneButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitleColor(UIColor.white, for: UIControl.State())
        button.setTitleColor(UIColor.lightGray, for: .disabled)
        button.titleLabel?.font = Config.Font.Text.regular.withSize(16)
        button.setTitle("Gallery.Done".g_localize(fallback: "Done"), for: UIControl.State())
        
        return button
    }
    
    private func makeMaxSizeToast() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        view.layer.cornerRadius = 12
        
        let label = UILabel()
        label.text = Config.Toast.maxImageSizeText
        label.textColor = .white
        label.font = Config.Toast.toastFont
        
        let infoImage = UIImageView()
        infoImage.image = Config.Toast.infoImage
        infoImage.tintColor = .white
        infoImage.g_pin(height: 16)
        infoImage.g_pin(width: 16)
        
        let stack = UIStackView.init(arrangedSubviews: [infoImage, label])
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        
        view.addSubview(stack)
        stack.g_pinEdges(insets: .init(top: 12, left: 8, bottom: -12, right: -8))
        
        view.alpha = 0
        return view
    }
    
    private func makeProgressLabel() -> UILabel {
        let label = UILabel()
        label.text = "1/5 Items Selected"
        label.textColor = .white
        return label
    }
    
    private func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = UIColor.backgroundColor
        
        return view
    }
    
    private func makeEmptyView() -> EmptyView {
        let view = EmptyView()
        view.isHidden = true
        
        return view
    }
    
    private func makeLoadingIndicator() -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: .whiteLarge)
        view.color = .gray
        view.hidesWhenStopped = true
        
        return view
    }
}
