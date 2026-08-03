//
//  SingleImageViewController.swift
//  Image Feed
//
//  Created by Иульяния on 19.07.2026.
//

import UIKit

final class SingleImageViewController: UIViewController, UIScrollViewDelegate {
    
    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            imageView.image = image
            imageView.frame.size = image?.size ?? .zero
            
            if let image = image {
                rescaleAndCenterImageInScrollView(image: image)
            }
        }
    }
    
    @IBOutlet private weak var imageView: UIImageView!
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
        view.backgroundColor = UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        
        view.addSubview(shareButton)
            
            NSLayoutConstraint.activate([
                shareButton.widthAnchor.constraint(equalToConstant: 50),
                shareButton.heightAnchor.constraint(equalToConstant: 50),
                shareButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 711),
                shareButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 162.5)
            ])
        
        if let image = image {
            imageView.image = image
            imageView.frame.size = image.size
            rescaleAndCenterImageInScrollView(image: image)
        }
        
    }
    
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        
        view.layoutIfNeeded()
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        
        let newContentSize = scrollView.contentSize
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2
        
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "Sharing")?.withRenderingMode(.alwaysOriginal)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapShareButton), for: .touchUpInside)
        return button
    }()

    @objc private func didTapShareButton() {
        guard let image = image else { return }
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
}
    

    /*
    // MARK: - Navigation

   

     */
