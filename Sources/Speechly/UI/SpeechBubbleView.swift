//
//  SpeechBubbleView.swift
//  Speechly
//
//  Created by Janne Käki on 4.2.2021.
//

import Foundation
import UIKit
import SnapKit

public class SpeechBubbleView: UIView {
    
    public init() {
        super.init(frame: .zero)
        
        pointerView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)
        
        addSubview(contentView)
        
        contentView.addSubview(pointerView)
        contentView.addSubview(textLabel)
        
        contentView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        
        pointerView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(contentView.snp.bottom)
            make.width.height.equalTo(16)
            make.bottom.equalTo(self).inset(4)
        }
        
        textLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(12)
            make.left.right.equalToSuperview().inset(24)
        }
        
        func initializeStyle() {
            font = UIFont(name: "AvenirNextCondensed-Bold", size: 17)
            color = UIColor.darkGray
            textColor = UIColor.white
        }
        
        initializeStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var isShowing: Bool {
        return alpha > 0
    }
    
    public func show(animated: Bool = true) {
        let updates = {
            self.alpha = 1
            self.transform = .identity
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: updates, completion: nil)
        } else {
            updates()
        }
    }
    
    public func hide(animated: Bool = true) {
        let updates = {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: updates, completion: nil)
        } else {
            updates()
        }
    }
    
    func pulse(duration: TimeInterval = 0.5, scale: CGFloat = 1.2) {
        UIView.animate(withDuration: duration / 2, delay: 0, options: .curveEaseInOut, animations: {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }, completion: {  _ in
            UIView.animate(withDuration: duration / 2, delay: 0, options: .curveEaseInOut, animations: {
                self.transform = .identity
            }, completion: nil)
        })
        
        restartAutohideTimer()
    }
    
    public var text: String? {
        get {
            return textLabel.text
        }
        set {
            textLabel.text = newValue
        }
    }
    
    public var font: UIFont! {
        get {
            return textLabel.font
        }
        set {
            textLabel.font = newValue
        }
    }
    
    public var textColor: UIColor! {
        get {
            return textLabel.textColor
        }
        set {
            textLabel.textColor = newValue
        }
    }
    
    public var color: UIColor! {
        didSet {
            contentView.backgroundColor = color
            pointerView.backgroundColor = color
        }
    }
    
    private let textLabel = UILabel()
    
    private let contentView = UIView()
    
    private let pointerView = UIView()
}
