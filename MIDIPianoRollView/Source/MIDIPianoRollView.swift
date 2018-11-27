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
  /// Piano roll bars.
  public enum Bars {
    /// Fixed number of bars.
    case fixed(Int)
    /// Always a bar more than the last note's bar.
    case auto
  }

  /// Piano roll keys.
  public enum Keys {
    /// In a MIDI note range between 0 - 127
    case ranged(ClosedRange<UInt8>)
    /// In a musical scale.
    case scale(scale: Scale, minOctave: Int, maxOctave: Int)
    /// With custom keys.
    case custom([Pitch])

    /// Returns the pitches.
    public var pitches: [Pitch] {
      switch self {
      case .ranged(let range):
        return range.map({ Pitch(midiNote: Int($0)) })
      case .scale(let scale, let minOctave, let maxOctave):
        return scale.pitches(octaves: [Int](minOctave...maxOctave))
      case .custom(let pitches):
        return pitches
      }
    }
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
      case .whole: return NoteValue(type: .whole)
      case .half: return NoteValue(type: .half)
      case .quarter: return NoteValue(type: .quarter)
      case .eighth: return NoteValue(type: .eighth)
      case .sixteenth: return NoteValue(type: .sixteenth)
      case .thirtysecond: return NoteValue(type: .thirtysecond)
      case .sixtyfourth: return NoteValue(type: .sixtyfourth)
      }
    }

    /// Next level after zooming in.
    public var zoomedIn: ZoomLevel? {
      switch self {
      case .whole: return .half
      case .half: return .quarter
      case .quarter: return .eighth
      case .eighth: return .sixteenth
      case .sixteenth: return .thirtysecond
      case .thirtysecond: return .sixtyfourth
      case .sixtyfourth: return nil
      }
    }

    /// Previous level after zooming out.
    public var zoomedOut: ZoomLevel? {
      switch self {
      case .whole: return nil
      case .half: return .whole
      case .quarter: return .half
      case .eighth: return .quarter
      case .sixteenth: return .eighth
      case .thirtysecond: return .sixteenth
      case .sixtyfourth: return .thirtysecond
      }
    }
  }

  /// All notes in the piano roll.
  public var notes: [MIDIPianoRollNote] = [] { didSet { reload() }}
  /// Time signature of the piano roll. Defaults to 4/4.
  public var timeSignature = TimeSignature() { didSet { reload() }}
  /// Bar count of the piano roll. Defaults to auto.
  public var bars: Bars = .auto { didSet { reload() }}
  /// Rendering note range of the piano roll. Defaults all MIDI notes, from 0 to 127.
  public var keys: Keys = .ranged(0...127) { didSet { reload() }}

  /// Current `ZoomLevel` of the piano roll.
  public var zoomLevel: ZoomLevel = .whole
  /// Speed of zooming by pinch gesture.
  public var zoomSpeed: CGFloat = 0.4
  /// Maximum width of a beat on the bar, max zoomed in.
  public var maxBeatWidth: CGFloat = 20
  /// Minimum width of a beat on the bar, max zoomed out.
  public var minBeatWidth: CGFloat = 10
  /// Current with of a beat on the measure.
  public var beatWidth: CGFloat = 10
  /// Fixed height of the bar on the top.
  public var barHeight: CGFloat = 40
  /// Fixed left hand side row width on the piano roll.
  public var rowWidth: CGFloat = 60
  /// Fixed height of a row on the piano roll.
  public var rowHeight: CGFloat = 40
  /// Label configuration for the measure beat labels.
  public var measureLabelConfig = UILabel()
  /// Global variable for all line widths.
  public var lineWidth: CGFloat = 0.5

  /// Enables/disables the edit mode. Defaults false.
  public var isEditing: Bool = false
  /// Enables/disables the zooming feature. Defaults true.
  public var isZoomingEnabled: Bool = true { didSet { pinchGesture.isEnabled = isZoomingEnabled }}
  /// Enables/disables the measure rendering. Defaults true.
  public var isMeasureEnabled: Bool = true { didSet { needsRedrawBar = true }}
  /// Enables/disables the multiple note cell editing at once. Defaults true.
  public var isMultipleEditingEnabled: Bool = true

  /// Pinch gesture for zooming.
  private var pinchGesture = UIGestureRecognizer()
  /// Reference of the all row views.
  private var rowViews: [MIDIPianoRollRowView] = []
  /// Reference of the all cell views.
  private var cellViews: [MIDIPianoRollCellView] = []
  /// Reference of the all vertical measure beat lines.
  private var measureLines: [MIDIPianoRollMeasureLineLayer] = []
  /// Reference of the line on the top, drawn between measure and the piano roll grid.
  private var topMeasureLine = CALayer()
  /// Reference for controlling bar line redrawing in layoutSubview function.
  private var needsRedrawBar: Bool = false
  /// The last bar by notes position and duration. Updates on cells notes array change.
  private var lastBar: Double = 0

  /// Calculates the number of bars in the piano roll by the `BarCount` rule.
  private var barCount: Int {
    switch bars {
    case .fixed(let count):
      return count
    case .auto:
      return Int(lastBar + 1)
    }
  }

  // MARK: Init

  /// Initilizes the piano roll with a frame.
  ///
  /// - Parameter frame: Frame of the view.
  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  /// Initilizes the piano roll with a coder.
  ///
  /// - Parameter aDecoder: Coder.
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  /// Default initilizer.
  private func commonInit() {
    reload()
    let pinch = UIPinchGestureRecognizer(
      target: self,
      action: #selector(didPinch(pinch:)))
    addGestureRecognizer(pinch)
  }

  // MARK: Lifecycle

  /// Renders the piano roll.
  public override func layoutSubviews() {
    super.layoutSubviews()

    // Start laying out rows under the measure.
    var currentY: CGFloat = isMeasureEnabled ? barHeight : 0

    // Layout rows
    for rowView in rowViews.reversed() {
      rowView.frame = CGRect(
        x: contentOffset.x,
        y: currentY,
        width: rowWidth,
        height: rowHeight)
      rowView.layer.zPosition = 1
      // Bottom line
      rowView.bottomLine.backgroundColor = UIColor.black.cgColor
      rowView.bottomLine.frame = CGRect(
        x: 0,
        y: rowView.frame.size.height - lineWidth,
        width: frame.size.width,
        height: lineWidth)
      // Go to next row.
      currentY += rowHeight
    }

    // Update content size vertically
    contentSize.height = currentY

    // Check if needs redraw measure lines.
    if needsRedrawBar {
      measureLines.forEach({ $0.removeFromSuperlayer() })
      measureLines = []
      topMeasureLine.removeFromSuperlayer()

      if isMeasureEnabled {
        topMeasureLine = CALayer()
        layer.addSublayer(topMeasureLine)

        for bar in 0...barCount {
          for beat in 0..<timeSignature.beats * Int(zoomLevel.noteValue.type.rawValue) {
            let line = MIDIPianoRollMeasureLineLayer()
            layer.addSublayer(line)
            measureLines.append(line)

            if beat == 0 || (beat == (timeSignature.beats - 1) && bar == barCount) {
              line.isBarLine = true
              line.beatTextLayer.frame = CGRect(
                x: 0,
                y: 0,
                width: 20,
                height: 20)
              line.beatTextLayer.string = "\(bar)"
            }
          }
        }
      }

      needsRedrawBar = false
    }

    // Start laying out bars after the key rows.
    var currentX: CGFloat = rowWidth

    for line in measureLines {
      line.beatLineLayer.frame = CGRect(
        x: currentX,
        y: 0,
        width: lineWidth * (line.isBarLine ? 2 : 1),
        height: contentSize.height > 0 ? contentSize.height : frame.size.height)
      line.beatLineLayer.backgroundColor = line.isBarLine ? UIColor.black.cgColor : UIColor.gray.cgColor
      currentX += beatWidth
    }

    // Update content size horizontally
    contentSize.width = currentX

    // Update top line.
    topMeasureLine.frame = CGRect(
      x: 0,
      y: barHeight - lineWidth,
      width: (contentSize.width > 0 ? contentSize.width : frame.size.width) - beatWidth,
      height: lineWidth)
    topMeasureLine.backgroundColor = UIColor.black.cgColor
  }

  /// Removes each component and creates them again.
  public func reload() {
    // Reset row views.
    rowViews.forEach({ $0.removeFromSuperview() })
    rowViews = []
    // Reset cell views.
    cellViews.forEach({ $0.removeFromSuperview() })
    cellViews = []

    // Setup row views.
    for pitch in keys.pitches {
      let rowView = MIDIPianoRollRowView(pitch: pitch)
      addSubview(rowView)
      rowViews.append(rowView)
    }

    // Setup cell views.
    for note in notes {
      let cellView = MIDIPianoRollCellView(note: note)
      addSubview(cellView)
      cellViews.append(cellView)
    }

    // Update bar.
    lastBar = notes
      .map({ $0.position + $0.duration })
      .sorted(by: { $1 > $0 })
      .first?.rounded() ?? 0

    let barWidth = beatWidth * CGFloat(timeSignature.beats)
    if CGFloat(lastBar + 1) * barWidth < max(frame.size.width, frame.size.height) {
      lastBar = ceil(Double(frame.size.width / barWidth)) + 1
    }

    needsRedrawBar = true
  }

  // MARK: Zooming

  @objc private func didPinch(pinch: UIPinchGestureRecognizer) {
    switch pinch.state {
    case .began, .changed:
      var deltaScale = pinch.scale
      deltaScale = ((deltaScale - 1) * zoomSpeed) + 1
      deltaScale = min(deltaScale, maxBeatWidth/beatWidth)
      deltaScale = max(deltaScale, minBeatWidth/beatWidth)
      beatWidth *= deltaScale
      setNeedsLayout()
      pinch.scale = 1

      // Get in new zoom level.
      if beatWidth >= maxBeatWidth {
        if let zoom = zoomLevel.zoomedIn {
          zoomLevel = zoom
          beatWidth = minBeatWidth
          needsRedrawBar = true
        }
      } else if beatWidth <= minBeatWidth {
        if let zoom = zoomLevel.zoomedOut {
          zoomLevel = zoom
          beatWidth = maxBeatWidth
          needsRedrawBar = true
        }
      }

    default:
      return
    }
  }
}
