import Foundation
import AVFoundation
import UIKit
import SnapKit

public protocol MicrophoneButtonDelegate {
    func didOpenMicrophone(_ button: MicrophoneButtonView)
    
    func didCloseMicrophone(_ button: MicrophoneButtonView)
    
    func speechButtonImageForAuthorizationStatus(_ button: MicrophoneButtonView, status: AVAuthorizationStatus) -> UIImage?
}

public extension MicrophoneButtonDelegate {    
    func speechButtonImageForAuthorizationStatus(_ button: MicrophoneButtonView, status: AVAuthorizationStatus) -> UIImage? {
        return nil
    }
}

public class MicrophoneButtonView: UIView {
    
    private let diameter: CGFloat
    
    var delegate: MicrophoneButtonDelegate?
    
    public init(diameter: CGFloat = 80, delegate: MicrophoneButtonDelegate) {
        self.diameter = diameter
        self.delegate = delegate
        
        super.init(frame: .zero)
        
        addSubview(contentView)
        addSubview(speechBubbleView)
        
        contentView.addSubview(blurEffectView)
        contentView.addSubview(borderView)
        contentView.addSubview(iconView)
        
        snp.makeConstraints { (make) in
            make.width.height.equalTo(diameter)
        }
        
        contentView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
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
            make.bottom.equalTo(snp.top).offset(-4)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
        
        let press = UILongPressGestureRecognizer(target: self, action: #selector(didPress(_:)))
        press.minimumPressDuration = 0.1
        addGestureRecognizer(press)
        
        let center = NotificationCenter.default
        center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.initializeRotationAnimation()
            self?.reloadAuthorizationStatus()
        }
        
        speechBubbleView.hide(animated: false)
        
        func initializeState() {
            borderImage = image(named: "mic-button-frame")
            
            blurEffectImage = image(named: "mic-button-fx")
            
            holdToTalkText = "Hold to talk"
            
            isPressed = false
        }
        
        initializeState()
        initializeRotationAnimation()
        
        isAccessibilityElement = true
        accessibilityTraits = [.button]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var borderImage: UIImage? {
        didSet {
            borderView.image = borderImage
        }
    }
    
    public var blurEffectImage: UIImage? {
        didSet {
            blurEffectView.image = blurEffectImage
        }
    }
    
    public var holdToTalkText: String! {
        didSet {
            speechBubbleView.text = holdToTalkText.uppercased()
        }
    }
    
    public var pressedScale: CGFloat = 1.5
    
    private var normalScale: CGFloat {
        return diameter / borderView.intrinsicContentSize.width
    }

    public private(set) var isPressed: Bool = false {
        didSet {
            let scale = normalScale * (isPressed ? pressedScale : 1)
            
            contentView.transform = CGAffineTransform(scaleX: scale, y: scale)
            blurEffectView.alpha = isPressed ? 1 : 0
            
            if isPressed != oldValue {
                if audioAuthorizationStatus == .authorized {
                    if let delegate = delegate {
                        if isPressed {
                            delegate.didOpenMicrophone(self)
                        } else {
                            delegate.didCloseMicrophone(self)
                        }
                    }
                } else {
                    if isPressed {
                        didTap()
                    }
                }
            }
            
            if speechBubbleView.isShowing {
                speechBubbleView.hide()
            }
        }
    }
    
    private let contentView = UIView()
    
    private let iconView = UIImageView()
    
    private let borderView = UIImageView()
    
    private let blurEffectView = UIImageView()
    
    private let speechBubbleView = SpeechBubbleView()
    
    private func initializeRotationAnimation() {
        blurEffectView.startRotating()
        borderView.startRotating()
    }
    
    @objc private func didTap() {
        switch audioAuthorizationStatus {
        case .authorized:
            if speechBubbleView.isShowing {
                speechBubbleView.pulse()
            } else {
                speechBubbleView.show()
            }
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                DispatchQueue.main.async {
                    self.reloadAuthorizationStatus()
                }
            }

        case .denied, .restricted:
            let settingsURL = URL(string: UIApplication.openSettingsURLString)!
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            
        @unknown default:
            break
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
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.isPressed = isPressed
            }, completion: nil)
        }
    }
    
    private var audioAuthorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .audio)
    }
    
    public func reloadAuthorizationStatus() {
        if let image = delegate?.speechButtonImageForAuthorizationStatus(self, status: audioAuthorizationStatus) {
            iconView.image = image
        } else {
            switch audioAuthorizationStatus {
            case .authorized:
                iconView.image = image(named: "mic")
            case .notDetermined:
                iconView.image = image(named: "power-on")
            case .denied, .restricted:
                iconView.image = image(named: "mic-no-permission")
            @unknown default:
                break
            }
        }
    }
    
    private func image(named name: String) -> UIImage? {
        return UIImage(named: name, in: Bundle.module, compatibleWith: nil)
    }
}

private extension UIView {
    
    func startRotating(duration: TimeInterval = 2) {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
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
