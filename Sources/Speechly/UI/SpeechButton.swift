import Foundation
import UIKit
import SnapKit

public class SpeechButton: UIView {
    
    let client: SpeechClient
    
    public init(client: SpeechClient) {
        self.client = client
        
        super.init(frame: .zero)
        
        addSubview(contentView)
        addSubview(speechBubbleView)
        
        contentView.addSubview(blurEffectView)
        contentView.addSubview(borderView)
        contentView.addSubview(iconView)
        
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        blurEffectView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        borderView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        iconView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        speechBubbleView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(contentView.snp.top)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        addGestureRecognizer(tap)
        
        let press = UILongPressGestureRecognizer(target: self, action: #selector(didPress(_:)))
        press.minimumPressDuration = 0.1
        addGestureRecognizer(press)
        
        let center = NotificationCenter.default
        center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.initializeRotationAnimation()
        }
        
        speechBubbleView.hide(animated: false)
        
        func initializeState() {
            isPressed = false
            
            holdToTalkText = "Hold to talk"
        }
        
        initializeState()
        initializeRotationAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var holdToTalkText: String! {
        didSet {
            speechBubbleView.text = holdToTalkText.uppercased()
        }
    }
    
    private var isPressed: Bool = false {
        didSet {
            contentView.transform = isPressed ? CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
            blurEffectView.alpha = isPressed ? 1 : 0
            
            if isPressed != oldValue {
                if isPressed {
                    client.start()
                } else {
                    client.stop()
                }
            }
            
            if speechBubbleView.isShowing {
                speechBubbleView.hide()
            }
        }
    }
    
    private let contentView = UIView()
    
    private let iconView = UIImageView(image: UIImage(named: "mic"))
    
    private let borderView = UIImageView(image: UIImage(named: "mic-button-frame"))
    
    private let blurEffectView = UIImageView(image: UIImage(named: "mic-button-fx"))
    
    private let speechBubbleView = SpeechBubbleView()
    
    private func initializeRotationAnimation() {
        blurEffectView.startRotating()
        borderView.startRotating()
    }
    
    @objc private func didTap(_ sender: UITapGestureRecognizer) {
        if speechBubbleView.isShowing {
            speechBubbleView.pulse()
        } else {
            speechBubbleView.show()
        }
    }
    
    @objc private func didPress(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: self)
        let isInside = self.point(inside: point, with: nil)
        
        let isPressed: Bool
        
        switch sender.state {
        case .began:
            isPressed = true
        case .ended, .cancelled:
            isPressed = false
        default:
            isPressed = isInside
        }
        
        if isPressed != self.isPressed {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.isPressed = isPressed
            }, completion: nil)
        }
    }
}

private extension UIView {
    
    func startRotating(duration: TimeInterval = 2) {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = duration
        rotation.isCumulative = true
        rotation.repeatCount = .infinity
        layer.add(rotation, forKey: "rotation")
    }
    
    func stopRotating() {
        layer.removeAnimation(forKey: "rotation")
    }
}
