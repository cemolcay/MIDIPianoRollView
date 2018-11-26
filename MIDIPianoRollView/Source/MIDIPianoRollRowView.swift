//
//  MIDIPianoRollRowView.swift
//  MIDIPianoRollView
//
//  Created by cem.olcay on 26/11/2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit
import ALKit
import MusicTheorySwift

/// Represents a MIDI note row of the `MIDIPianoRollView`.
public class MIDIPianoRollRowView: UIView {
  /// Pitch of the row.
  public var pitch: Pitch
  /// Label of the pitch.
  public var pitchLabel = UILabel()
  /// Minimum font size of the pitch label.
  public var maxFontSize: CGFloat = 17
  /// Maximum font size of the pitch label.
  public var minFontSize: CGFloat = 11
  /// Row line at the bottom.
  public var bottomLine = CALayer()

  // MARK: Init

  /// Initilizes the row with an assigned MIDI pitch.
  ///
  /// - Parameter pitch: MIDI pitch of the row.
  public init(pitch: Pitch) {
    self.pitch = pitch
    super.init(frame: .zero)
    commonInit()
  }

  /// Initilizes the row from a coder with 0 pitch value.
  ///
  /// - Parameter aDecoder: Decoder.
  public required init?(coder aDecoder: NSCoder) {
    self.pitch = Pitch(midiNote: 0)
    super.init(coder: aDecoder)
    commonInit()
  }

  /// Default init function.
  private func commonInit() {
    // Setup pitch label
    pitchLabel.textAlignment = .center
    addSubview(pitchLabel)
    translatesAutoresizingMaskIntoConstraints = false
    pitchLabel.translatesAutoresizingMaskIntoConstraints = false
    pitchLabel.fill(to: self)
    pitchLabel.text = "\(pitch)"
    // Setup default coloring
    backgroundColor = pitch.key.accidental == .natural ? UIColor.white : UIColor.black
    pitchLabel.textColor = pitch.key.accidental == .natural ? UIColor.black : UIColor.white
    // Setup bottom line
    layer.addSublayer(bottomLine)
    layer.masksToBounds = false
  }

  /// Renders row.
  public override func layoutSubviews() {
    super.layoutSubviews()
    let fontSize = min(maxFontSize, max(minFontSize, frame.size.height - 4))
    pitchLabel.font = pitchLabel.font.withSize(fontSize)
    bottomLine.frame = CGRect(x: 0, y: frame.size.height - 1, width: 0, height: 1)
  }
}
