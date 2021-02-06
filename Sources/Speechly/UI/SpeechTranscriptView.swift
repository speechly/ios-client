//
//  SpeechTranscriptView.swift
//  Speechly
//
//  Created by Janne Käki on 5.2.2021.
//

import Foundation
import UIKit
import SnapKit

public class SpeechTranscriptView: UIView {
    
    public init() {
        super.init(frame: .zero)
        
        backgroundColor = UIColor.black
        
        textLabel.numberOfLines = 0
        
        addSubview(textLabel)
        
        textLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(12)
        }
        
        alpha = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public private(set) var segment: SpeechSegment?
    
    public func configure(segment: SpeechSegment, animated: Bool) {
        self.segment = segment
        
        reloadText(animated: animated)
    }
    
    private let textLabel = UILabel()
    
    private func reloadText(animated: Bool = false) {
        guard let segment = segment else {
            if animated {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    self.alpha = 0
                }, completion: { _ in
                    self.textLabel.attributedText = nil
                })
            } else {
                alpha = 0
                textLabel.attributedText = nil
            }
            return
        }
        
        let attributedText = segment.attributedText(attributedBy: { (transcript, entity) in
            let color: UIColor
            if segment.isFinal {
                color = (entity != nil) ? highlightedTextColor : textColor
            } else {
                color = textColor
            }
            
            return [
                .font: font,
                .foregroundColor: color
            ]
        })
        
        textLabel.attributedText = attributedText
        
        if animated, alpha == 0 {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.alpha = 1
            }, completion: nil)
        }
    }
    
    public var font: UIFont = UIFont(name: "AvenirNextCondensed-Bold", size: 20)! {
        didSet {
            reloadText()
        }
    }
    
    public var textColor: UIColor = UIColor.white {
        didSet {
            reloadText()
        }
    }
    
    public var highlightedTextColor: UIColor = UIColor.cyan {
        didSet {
            reloadText()
        }
    }
}

extension SpeechSegment {
    
    typealias AttributeProvider = (_ transcript: SpeechTranscript, _ entity: SpeechEntity?) -> [NSAttributedString.Key: Any]
    
    func attributedText(attributedBy attributeProvider: AttributeProvider) -> NSAttributedString {
        let attributedText = NSMutableAttributedString()
        
        for (index, transcript) in transcripts.enumerated() {
            var text = transcript.value
            if index > 0 {
                text = " " + text
            }
            
            let entity = entities.first(where: {
                transcript.index >= $0.startIndex && transcript.index < $0.endIndex
            })
            
            let attributes = attributeProvider(transcript, entity)
            
            let attributedTranscript = NSAttributedString(string: text, attributes: attributes)
            
            attributedText.append(attributedTranscript)
        }
        
        return attributedText
    }
}
