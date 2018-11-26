//
//  MIDIPianoRollView.swift
//  MIDIPianoRollView
//
//  Created by cem.olcay on 26/11/2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit
import ALKit
import MusicTheorySwift
import MIDIEventKit

/// Piano roll with customisable row count, row range, beat count and editable note cells.
public class MIDIPianoRollView: UIScrollView {

  /// Number of bars in the piano roll view grid.
  public enum BarCount {
    /// Fixed number of bars.
    case fixed(Int)
    /// Always a bar more than the last note's bar.
    case auto
  }

  /// All notes in the piano roll.
  public var notes: [MIDIPianoRollNote] = []
  /// Time signature of the piano roll. Defaults to 4/4.
  public var timeSignature = TimeSignature()
  /// Bar count of the piano roll. Defaults to auto.
  public var barCount: BarCount = .auto
  /// Rendering note range of the piano roll. Defaults all MIDI notes, from 0 to 127.
  public var noteRange: ClosedRange<UInt8> = 0...127
  /// Enables/disables the edit mode. Defaults false.
  public var isEditing: Bool = false

  /// Maximum width of a beat on the measure, max zoomed in.
  public var maxMeasureWidth: CGFloat = 120
  /// Minimum width of a beat on the measure, max zoomed out.
  public var minMeasureWidth: CGFloat = 50
  /// Fixed height of the measure on the top.
  public var measureHeight: CGFloat = 40
  /// Left hand side row width on the piano roll.
  public var rowWidth: CGFloat = 120
  /// Fixed height of a row on the piano roll.
  public var rowHeight: CGFloat = 40

  /// Enables/disables the zooming feature. Defaults true.
  public var isZoomingEnabled: Bool = true
  /// Enables/disables the measure rendering. Defaults true.
  public var isMeasureEnabled: Bool = true
  /// Enables/disables the multiple note cell editing at once. Defaults true.
  public var isMultipleEditingEnabled: Bool = true

  /// Renders the piano roll.
  public override func layoutSubviews() {
    super.layoutSubviews()


  }
}
