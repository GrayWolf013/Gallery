//
//  PreviewImageViewController.swift
//  Gallery
//
//  Created by Suhaib Al Saghir on 20/12/2020.
//

import UIKit

protocol PreviewImageDelegate: class {
	func didSelect(_ image: Image?)
}

class PreviewImageViewController: UIViewController {

	private lazy var topBar = createTopBar()
	private lazy var imageView = UIImageView()
	private var image: Image?
	private weak var delegate: PreviewImageDelegate?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		setup()
		
		image?.resolve(completion: { image in
			DispatchQueue.main.async { [weak self] in
				self?.imageView.image = image
			}
		})
	}
	
	func configure(with image: Image?, delegate: PreviewImageDelegate) {
		self.image = image
		self.delegate = delegate
	}
}

private extension PreviewImageViewController {
	func createTopBar() -> UIStackView {
		let closeButton = UIButton()
		closeButton.setTitle("  Cancel", for: .normal)
		closeButton.setTitleColor(.systemBlue, for: .normal)
		closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
		
		let doneButton = UIButton()
		doneButton.setTitle("Select  ", for: .normal)
		doneButton.setTitleColor(.systemBlue, for: .normal)
		doneButton.addTarget(self, action: #selector(selectButtonPressed), for: .touchUpInside)

		let stack = UIStackView(arrangedSubviews: [closeButton, doneButton])
		stack.distribution = .equalSpacing
		stack.axis = .horizontal
	
		return stack
	}
	
	private func setup() {
		view.backgroundColor = .white
		
		let stackView = UIStackView(arrangedSubviews: [topBar, imageView])
		stackView.axis = .vertical
		
		view.addSubview(stackView)
		
		topBar.translatesAutoresizingMaskIntoConstraints = false
		topBar.heightAnchor.constraint(equalToConstant: 44).isActive = true

		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
		stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
		stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
		stackView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
	}
	
	@objc private func closeButtonPressed() {
		self.dismiss(animated: true, completion: nil)
	}
	
	@objc private func selectButtonPressed() {
		delegate?.didSelect(image)
		self.dismiss(animated: true, completion: nil)
	}
}
