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
    
    public func configure(segment: SpeechSegment?, animated: Bool) {
        self.segment = segment
        
        reloadText(animated: animated)
    }
    
    public func hide(animated: Bool) {
        configure(segment: nil, animated: animated)
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
    
    public var autohideInterval: TimeInterval? = 3 {
        didSet {
            if autohideInterval != oldValue {
                restartAutohideTimer()
            }
        }
    }
    
    private var labels: [SpeechTranscriptLabel] = []
    
    private var autohideTimer: Timer?
    
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
                
                let entity = segment.entity(for: transcript)
                
                label.configure(segment: segment, transcript: transcript, entity: entity)
                
                if animated {
                    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                        label.alpha = 1
                    }, completion: nil)
                } else {
                    label.alpha = 1
                }
            }
        }
        
        for (index, label) in labels.enumerated() {
            if index >= (segment?.transcripts ?? []).count {
                if animated {
                    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                        label.alpha = 0
                    }, completion: { _ in
                        label.text = " "
                    })
                } else {
                    label.text = " "
                    label.alpha = 0
                }
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.alpha = (self.segment != nil) ? 1 : 0
            }, completion: nil)
        } else {
            alpha = (segment != nil) ? 1 : 0
        }
        
        restartAutohideTimer()
    }
    
    private func restartAutohideTimer() {
        autohideTimer?.invalidate()
        
        guard let autohideInterval = autohideInterval else {
            return
        }
        
        autohideTimer = Timer.scheduledTimer(withTimeInterval: autohideInterval, repeats: false) { [weak self] _ in
            self?.hide(animated: true)
        }
    }
}

class SpeechTranscriptLabel: UILabel {
    
    private(set) var transcript: SpeechTranscript?
    private(set) var entity: SpeechEntity?
    
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
    
    func configure(segment: SpeechSegment, transcript: SpeechTranscript, entity: SpeechEntity?) {
        self.transcript = transcript
        
        let shouldHighlightEntity = entity != nil && self.entity == nil && segment.isFinal
        self.entity = segment.isFinal ? entity : nil
        
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
        
        if shouldHighlightEntity {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.transform = CGAffineTransform(translationX: 0, y: -self.font.lineHeight / 4)
            }, completion: { _ in
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                    self.transform = .identity
                }, completion: nil)
            })
        }
    }
}

extension SpeechSegment {
    
    typealias AttributeProvider = (_ transcript: SpeechTranscript, _ entity: SpeechEntity?) -> [NSAttributedString.Key: Any]
    
    func entity(for transcript: SpeechTranscript) -> SpeechEntity? {
        return entities.first(where: {
            transcript.index >= $0.startIndex && transcript.index < $0.endIndex
        })
    }
    
    func attributedText(attributedBy attributeProvider: AttributeProvider) -> NSAttributedString {
        let attributedText = NSMutableAttributedString()
        
        for (index, transcript) in transcripts.enumerated() {
            var text = transcript.value
            if index > 0 {
                text = " " + text
            }
            
            let entity = self.entity(for: transcript)
            
            let attributes = attributeProvider(transcript, entity)
            
            let attributedTranscript = NSAttributedString(string: text, attributes: attributes)
            
            attributedText.append(attributedTranscript)
        }
        
        return attributedText
    }
}
