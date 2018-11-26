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

/// Vertical line layer for the each beat of the measure on the `MIDIPianoRollView`.
public class MIDIPianoRollMeasureLineLayer: CALayer {
  /// Position on the measure in beats.
  public var measurePosition: Double = 0
  /// Is visible or not.
  public var isVisible: Bool = true

  /// Initilizes the line with the position on the measure and visibility.
  ///
  /// - Parameters:
  ///   - measurePosition: Position on the measure.
  ///   - isVisible: 
  init(measurePosition: Double, isVisible: Bool = true) {
    self.measurePosition = measurePosition
    self.isVisible = true
    super.init()
  }

  /// Initilizes with a coder.
  ///
  /// - Parameter aDecoder: Coder.
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}

/// Piano roll with customisable row count, row range, beat count and editable note cells.
public class MIDIPianoRollView: UIScrollView {

  /// Number of bars in the piano roll view grid.
  public enum BarCount {
    /// Fixed number of bars.
    case fixed(Int)
    /// Always a bar more than the last note's bar.
    case auto
  }

  /// Zoom level of the piano roll that showing the mininum amount of beat.
  public enum ZoomLevel: Double {
    /// Whole bar.
    case whole = 1.0
    /// Half of a bar.
    case half = 0.5
    /// Quarter of a bar.
    case quarter = 0.25
    /// Eighth of a bar.
    case eighth = 0.125
    /// Sixteenth of a bar.
    case sixteenth = 0.0625
    /// Thirtysecond of a bar.
    case thirtysecond = 0.03125
    /// Sixtyfourth of a bar.
    case sixtyfourth = 0.015625

    /// Corresponding note value for the zoom level.
    public var noteValue: NoteValue {
      switch self {
      case .whole:
        return NoteValue(type: .whole)
      case .half:
        return NoteValue(type: .half)
      case .quarter:
        return NoteValue(type: .quarter)
      case .eighth:
        return NoteValue(type: .eighth)
      case .sixteenth:
        return NoteValue(type: .sixteenth)
      case .thirtysecond:
        return NoteValue(type: .thirtysecond)
      case .sixtyfourth:
        return NoteValue(type: .sixtyfourth)
      }
    }
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

  /// Current `ZoomLevel` of the piano roll.
  public var zoomLevel: ZoomLevel = .quarter
  /// Maximum width of a beat on the measure, max zoomed in.
  public var maxMeasureWidth: CGFloat = 120
  /// Minimum width of a beat on the measure, max zoomed out.
  public var minMeasureWidth: CGFloat = 50
  /// Current with of a beat on the measure.
  public var measureWidth: CGFloat = 90
  /// Fixed height of the measure on the top.
  public var measureHeight: CGFloat = 40
  /// Fixed left hand side row width on the piano roll.
  public var rowWidth: CGFloat = 120
  /// Fixed height of a row on the piano roll.
  public var rowHeight: CGFloat = 40
  /// Label configuration for the measure beat labels.
  public var measureLabelConfig = UILabel()

  /// Enables/disables the zooming feature. Defaults true.
  public var isZoomingEnabled: Bool = true
  /// Enables/disables the measure rendering. Defaults true.
  public var isMeasureEnabled: Bool = true
  /// Enables/disables the multiple note cell editing at once. Defaults true.
  public var isMultipleEditingEnabled: Bool = true

  /// Reference of the all labels of the measure
  private var measureBeatLabels: [UILabel] = []
  /// Reference of the all row views.
  private var rowViews: [MIDIPianoRollRowView] = []
  /// Reference of the all cell views.
  private var cellViews: [MIDIPianoRollCellView] = []
  /// Reference of the all horizontal row lines.
  private var rowLines: [CALayer] = []
  /// Reference of the all vertical measure beat lines.
  private var measureLines: [MIDIPianoRollMeasureLineLayer] = []

  /// Renders the piano roll.
  public override func layoutSubviews() {
    super.layoutSubviews()

    // References of the current width and height for laying out.
    var currentWidth: CGFloat = 0
    var currentHeight: CGFloat = 0


  }
}
