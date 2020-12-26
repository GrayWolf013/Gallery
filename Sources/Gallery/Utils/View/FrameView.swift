import UIKit

class FrameView: UIView {
    
    lazy var selectedImageView = makeSelectedImage()
    
    lazy var gradientLayer = makeGradientLayer()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setup() {
        layer.addSublayer(gradientLayer)
        layer.borderColor = Config.Grid.FrameView.borderColor.cgColor
        layer.borderWidth = 3
        
        addSubview(selectedImageView)
        selectedImageView.g_pin(on: .bottom, constant: -8)
        selectedImageView.g_pin(on: .right, constant: -8)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.frame = bounds
    }
    
    // MARK: - Controls
    
    private func makeSelectedImage() -> UIImageView {
        let imageView = UIImageView.init(image: Config.Grid.FrameView.selectedImage)
        
        return imageView
    }
    
    private func makeGradientLayer() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [
            Config.Grid.FrameView.fillColor.withAlphaComponent(0.25).cgColor,
            Config.Grid.FrameView.fillColor.withAlphaComponent(0.4).cgColor
        ]
        
        return layer
    }
}
