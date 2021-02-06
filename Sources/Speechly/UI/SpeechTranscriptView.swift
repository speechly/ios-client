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
    
    private var labels: [SpeechTranscriptLabel] = []
    
    private func reloadText(animated: Bool = false) {
        if let segment = segment {
            for (index, transcript) in segment.transcripts.enumerated() {
                var label: SpeechTranscriptLabel! = (index < labels.count) ? labels[index] : nil
                if label == nil {
                    label = SpeechTranscriptLabel(parent: self)
                    addSubview(label)
                    label.snp.makeConstraints { (make) in
                        make.edges.equalToSuperview().inset(12)
                    }
                    labels.append(label)
                    label.alpha = 0
                }
                
                label.configure(segment: segment, transcript: transcript)
                
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    label.alpha = 1
                }, completion: nil)
            }
        }
        
        for (index, label) in labels.enumerated() {
            if index >= (segment?.transcripts ?? []).count {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    label.alpha = 0
                }, completion: { _ in
                    label.text = " "
                })
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.alpha = (self.segment != nil) ? 1 : 0
            }, completion: nil)
        } else {
            alpha = (segment != nil) ? 1 : 0
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
    
    public var highlightedTextColor: UIColor = UIColor(red: 30 / 255.0, green: 211 / 255.0, blue: 242 / 255.0, alpha: 1) {
        didSet {
            reloadText()
        }
    }
}

class SpeechTranscriptLabel: UILabel {
    
    private(set) var transcript: SpeechTranscript?
    
    private unowned let parent: SpeechTranscriptView
    
    init(parent: SpeechTranscriptView) {
        self.parent = parent
        
        super.init(frame: .zero)
        
        text = " "
        numberOfLines = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(segment: SpeechSegment, transcript: SpeechTranscript) {
        self.transcript = transcript
        
        attributedText = segment.attributedText(attributedBy: { (transcript, entity) in
            let color: UIColor
            if transcript == self.transcript {
                if segment.isFinal {
                    color = (entity != nil) ? parent.highlightedTextColor : parent.textColor
                } else {
                    color = parent.textColor
                }
            } else {
                color = UIColor.clear
            }
            
            return [
                .font: parent.font,
                .foregroundColor: color
            ]
        })
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
