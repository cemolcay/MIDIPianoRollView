//
//  MIDIPianoRollCellView.swift
//  MIDIPianoRollView
//
//  Created by cem.olcay on 26/11/2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit

/// Represents a MIDI note of the `MIDIPianoRollView`.
public class MIDIPianoRollCellView: UIView {
  /// The rendering note data.
  public var note: MIDIPianoRollNote
  /// Is cell selected or not.
  public var isSelected: Bool = false

  /// Initilizes the cell view with a note data.
  ///
  /// - Parameter note: Rendering note data.
  public init(note: MIDIPianoRollNote) {
    self.note = note
    super.init(frame: .zero)
  }

  /// Initilizes the cell view with a decoder.
  ///
  /// - Parameter aDecoder: Decoder.
  public required init?(coder aDecoder: NSCoder) {
    self.note = MIDIPianoRollNote(note: 0, velocity: 0, position: 0, duration: 0)
    super.init(coder: aDecoder)
  }
}
