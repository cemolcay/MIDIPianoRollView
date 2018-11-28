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

/// Informs delegate about cell changes.
public protocol MIDIPianoRollViewDelegate: class {
  /// Informs delegate about that the cell is moved a new position and/or row.
  ///
  /// - Parameters:
  ///   - midiPianoRollView: Edited piano roll view.
  ///   - cellView: Moved cell.
  ///   - newPosition: New position of the cell.
  ///   - pitch: Moved pitch of the cell.
  func midiPianoRollView(_ midiPianoRollView: MIDIPianoRollView,
                         didMove cellView: MIDIPianoRollCellView,
                         to newPosition: MIDIPianoRollPosition,
                         pitch: UInt8)

  /// Informs delegate about that the cell's duration changed.
  ///
  /// - Parameters:
  ///   - midiPianoRollView: Edited piano roll view.
  ///   - cellView: Moved cell.
  ///   - newDuration: New duration of the cell.
  func midiPianoRollView(_ midiPianoRollView: MIDIPianoRollView,
                         didResize cellView: MIDIPianoRollCellView,
                         to newDuration: MIDIPianoRollPosition)
}

/// Piano roll with customisable row count, row range, beat count and editable note cells.
open class MIDIPianoRollView: UIScrollView, MIDIPianoRollCellViewDelegate {
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
  public enum ZoomLevel: Int {
    /// A beat represent whole note. See one beat in a bar.
    case wholeNotes = 1
    /// A beat represent sixtyfourth note. See 2 beats in a bar.
    case halfNotes = 2
    /// A beat represent quarter note. See 4 beats in a bar.
    case quarterNotes = 4
    /// A beat represent eighth note. See 8 beats in a bar.
    case eighthNotes = 8
    /// A beat represent sixteenth note. See 16 beats in a bar.
    case sixteenthNotes = 16
    /// A beat represent thirtysecond note. See 32 beats in a bar.
    case thirtysecondNotes = 32
    /// A beat represent sixtyfourth note. See 64 beats in a bar.
    case sixtyfourthNotes = 64

    /// Corresponding note value for the zoom level.
    public var noteValue: NoteValue {
      switch self {
      case .wholeNotes: return NoteValue(type: .whole)
      case .halfNotes: return NoteValue(type: .half)
      case .quarterNotes: return NoteValue(type: .quarter)
      case .eighthNotes: return NoteValue(type: .eighth)
      case .sixteenthNotes: return NoteValue(type: .sixteenth)
      case .thirtysecondNotes: return NoteValue(type: .thirtysecond)
      case .sixtyfourthNotes: return NoteValue(type: .sixtyfourth)
      }
    }

    /// Next level after zooming in.
    public var zoomedIn: ZoomLevel? {
      switch self {
      case .wholeNotes: return .halfNotes
      case .halfNotes: return .quarterNotes
      case .quarterNotes: return .eighthNotes
      case .eighthNotes: return .sixteenthNotes
      case .sixteenthNotes: return .thirtysecondNotes
      case .thirtysecondNotes: return .sixtyfourthNotes
      case .sixtyfourthNotes: return nil
      }
    }

    /// Previous level after zooming out.
    public var zoomedOut: ZoomLevel? {
      switch self {
      case .wholeNotes: return nil
      case .halfNotes: return .wholeNotes
      case .quarterNotes: return .halfNotes
      case .eighthNotes: return .quarterNotes
      case .sixteenthNotes: return .eighthNotes
      case .thirtysecondNotes: return .sixteenthNotes
      case .sixtyfourthNotes: return .thirtysecondNotes
      }
    }

    /// Rendering measure texts for note values in each zoom level.
    public var renderingMeasureTexts: [NoteValue] {
      switch self {
      case .wholeNotes:
        return [NoteValue(type: .whole)]
      case .halfNotes:
        return [NoteValue(type: .whole)]
      case .quarterNotes:
        return [NoteValue(type: .whole)]
      case .eighthNotes:
        return [NoteValue(type: .whole), NoteValue(type: .half)]
      case .sixteenthNotes:
        return [NoteValue(type: .whole), NoteValue(type: .half), NoteValue(type: .quarter)]
      case .thirtysecondNotes:
        return [NoteValue(type: .whole), NoteValue(type: .half), NoteValue(type: .quarter), NoteValue(type: .eighth)]
      case .sixtyfourthNotes:
        return [NoteValue(type: .whole), NoteValue(type: .half), NoteValue(type: .quarter), NoteValue(type: .eighth), NoteValue(type: .sixteenth)]
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
  public var zoomLevel: ZoomLevel = .quarterNotes
  /// Minimum amount of the zoom level.
  public var minZoomLevel: ZoomLevel = .wholeNotes
  /// Maximum amount of the zoom level.
  public var maxZoomLevel: ZoomLevel = .sixteenthNotes
  /// Speed of zooming by pinch gesture.
  public var zoomSpeed: CGFloat = 0.4
  /// Maximum width of a beat on the bar, max zoomed in.
  public var maxBeatWidth: CGFloat = 40
  /// Minimum width of a beat on the bar, max zoomed out.
  public var minBeatWidth: CGFloat = 20
  /// Current with of a beat on the measure.
  public var beatWidth: CGFloat = 30
  /// Fixed height of the bar on the top.
  public var measureHeight: CGFloat = 20
  /// Fixed left hand side row width on the piano roll.
  public var rowWidth: CGFloat = 60
  /// Current height of a row on the piano roll.
  public var rowHeight: CGFloat = 40
  /// Maximum height of a row on the piano roll.
  public var maxRowHeight: CGFloat = 80
  /// Minimum height of a row on the piano roll.
  public var minRowHeight: CGFloat = 30
  /// Label configuration for the measure beat labels.
  public var measureLabelConfig = UILabel()
  /// Global variable for all line widths.
  public var lineWidth: CGFloat = 0.5

  /// Delegate that informs about cell changes.
  public weak var pianoRollDelegate: MIDIPianoRollViewDelegate?

  /// Enables/disables the edit mode. Defaults false.
  public var isEditing: Bool = false { didSet { isScrollEnabled = !isEditing }}
  /// Enables/disables the zooming feature. Defaults true.
  public var isZoomingEnabled: Bool = true { didSet { pinchGesture.isEnabled = isZoomingEnabled }}
  /// Enables/disables the measure rendering. Defaults true.
  public var isMeasureEnabled: Bool = true { didSet { needsRedrawBar = true }}
  /// Enables/disables the multiple note cell editing at once. Defaults true.
  public var isMultipleEditingEnabled: Bool = true

  /// Pinch gesture for zooming.
  private var pinchGesture = UIPinchGestureRecognizer()

  /// Layer that cells drawn on. Lowest layer.
  private var cellLayer = UIView()
  /// Reference of the all cell views.
  private var cellViews: [MIDIPianoRollCellView] = []

  /// Layer that grid drawn on. Middle low layer.
  private var gridLayer = UIView()
  /// Reference of the all horizontal grid lines.
  private var verticalGridLines: [CALayer] = []
  /// Reference of the all horizontal grid lines.
  private var horizontalGridLines: [CALayer] = []
  /// Layer that rows drawn on. Middle top layer.

  private var rowLayer = UIView()
  /// Reference of the all row views.
  private var rowViews: [MIDIPianoRollRowView] = []
  /// Reference of the line drawn on the right side between rows and piano roll grid.
  private var rowLine = CALayer()

  /// Layer that measure drawn on. Top most layer.
  private var measureLayer = UIView()
  /// Line layer that drawn under the measure.
  private var measureLine = CALayer()
  /// Reference of the all vertical measure beat lines.
  private var measureLines: [MIDIPianoRollMeasureLineLayer] = []

  /// Reference for controlling bar line redrawing in layoutSubview function.
  private var needsRedrawBar: Bool = false
  /// The last bar by notes position and duration. Updates on cells notes array change.
  private var lastBar: Int = 0

  /// Calculates the number of bars in the piano roll by the `BarCount` rule.
  private var barCount: Int {
    switch bars {
    case .fixed(let count):
      return count
    case .auto:
      return lastBar + 1
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
    // Setup pinch gesture
    pinchGesture.addTarget(self, action: #selector(didPinch(pinch:)))
    addGestureRecognizer(pinchGesture)
    // Setup layers
    addSubview(cellLayer)
    addSubview(gridLayer)
    addSubview(rowLayer)
    addSubview(measureLayer)
    measureLayer.backgroundColor = .white
    // Load
    reload()
  }

  // MARK: Lifecycle

  /// Renders the piano roll.
  open override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)

    // Layout master layers
    cellLayer.frame = CGRect(origin: .zero, size: frame.size)
    gridLayer.frame = CGRect(origin: .zero, size: frame.size)
    rowLayer.frame = CGRect(
      x: contentOffset.x,
      y: contentOffset.y,
      width: rowWidth,
      height: frame.size.height
    )
    measureLayer.frame = CGRect(
      x: contentOffset.x,
      y: contentOffset.y,
      width: frame.size.width,
      height: isMeasureEnabled ? measureHeight : 0)

    // Layout rows
    var currentY: CGFloat = isMeasureEnabled ? measureHeight : 0
    for (index, rowView) in rowViews.reversed().enumerated() {
      // Layout row
      rowView.frame = CGRect(
        x: 0,
        y: currentY - contentOffset.y,
        width: rowWidth,
        height: rowHeight)

      // Layout horizontal line
      horizontalGridLines[index].frame = CGRect(
        x: contentOffset.x,
        y: currentY,
        width: frame.size.width,
        height: lineWidth)

      // Go to next row.
      currentY += rowHeight
    }

    // Layout bottom horizontal line
    horizontalGridLines.last?.frame = CGRect(
      x: contentOffset.x,
      y: currentY,
      width: frame.size.width,
      height: lineWidth)
    horizontalGridLines.forEach({ $0.backgroundColor = UIColor.gray.cgColor })

    // Layout left row line
    rowLine.frame = CGRect(
      x: rowWidth,
      y: 0,
      width: lineWidth,
      height: frame.size.height)
    rowLine.backgroundColor = UIColor.black.cgColor

    // Update content size vertically
    contentSize.height = currentY

    // Check if needs redraw measure lines.
    if needsRedrawBar {
      // Reset measure
      measureLines.forEach({ $0.removeFromSuperlayer() })
      measureLines = []
      // Reset vertical lines
      verticalGridLines.forEach({ $0.removeFromSuperlayer() })
      verticalGridLines = []
      // Reset bottom measure line
      measureLine.removeFromSuperlayer()
      measureLayer.layer.addSublayer(measureLine)

      let renderingTexts = zoomLevel.renderingMeasureTexts

      // Create lines
      let lineCount = barCount * timeSignature.beats * zoomLevel.rawValue
      var linePosition: MIDIPianoRollPosition = .zero
      for _ in 0...lineCount {
        // Create measure line
        let measureLine = MIDIPianoRollMeasureLineLayer()
        measureLine.pianoRollPosition = linePosition
        measureLayer.layer.addSublayer(measureLine)
        measureLines.append(measureLine)

        // Create vertical line
        let verticalLine = CALayer()
        verticalGridLines.append(verticalLine)
        gridLayer.layer.addSublayer(verticalLine)

        // Decide if render measure text.
        if let lineNoteValue = linePosition.noteValue,
          renderingTexts.contains(where: { $0.type == lineNoteValue.type }) {
          measureLine.showsBeatText = true
        } else {
          measureLine.showsBeatText = false
        }

        // Draw beat text
        if measureLine.showsBeatText && isMeasureEnabled {
          measureLine.textLayer.frame = CGRect(
            x: 2,
            y: measureHeight - 15,
            width: max(measureHeight, beatWidth),
            height: 15)
          measureLine.textLayer.fontSize = 13
          measureLine.textLayer.string = "\(linePosition)"
        }

        // Go next line
        linePosition = linePosition + zoomLevel.noteValue.pianoRollDuration
      }
      needsRedrawBar = false
    }

    // Layout measure and vertical lines.
    var currentX: CGFloat = rowWidth
    for (index, line) in measureLines.enumerated() {
      line.frame = CGRect(
        x: currentX - contentOffset.x,
        y: 0,
        width: lineWidth * (line.pianoRollPosition.isBarPosition ? 2 : 1),
        height: measureHeight)

      // Layout measure line
      line.lineLayer.frame = CGRect(origin: .zero, size: line.frame.size)
      line.lineLayer.backgroundColor = line.pianoRollPosition.isBarPosition ? UIColor.black.cgColor : UIColor.gray.cgColor

      // Layout vertical grid line
      verticalGridLines[index].frame = CGRect(
        x: currentX,
        y: contentOffset.y + measureHeight,
        width: lineWidth * (line.pianoRollPosition.isBarPosition ? 2 : 1),
        height: frame.size.height - measureHeight)
      verticalGridLines[index].backgroundColor = line.lineLayer.backgroundColor

      currentX += beatWidth
    }

    // Layout measure bottom line
    measureLine.frame = CGRect(
      x: 0,
      y: measureHeight,
      width: frame.size.width,
      height: lineWidth)
    measureLine.backgroundColor = UIColor.black.cgColor

    // Update content size horizontally
    contentSize.width = currentX

    // Layout cells
    let normalizedBeatWidth = beatWidth * CGFloat(zoomLevel.rawValue) / 4.0
    let barWidth = normalizedBeatWidth * CGFloat(timeSignature.beats)
    let subbeatWidth = normalizedBeatWidth / 4.0
    let centWidth = subbeatWidth / 240.0
    for cell in cellViews {
      guard let row = rowViews.filter({ $0.pitch.rawValue == cell.note.midiNote }).first
        else { continue }

      let startPosition = gridPosition(
        with: cell.note.position,
        barWidth: barWidth,
        beatWidth: normalizedBeatWidth,
        subbeatWidth: subbeatWidth,
        centWidth: centWidth)
      let endPosition = gridPosition(
        with: (cell.note.position + cell.note.duration),
        barWidth: barWidth,
        beatWidth: normalizedBeatWidth,
        subbeatWidth: subbeatWidth,
        centWidth: centWidth)
      let cellWidth = endPosition - startPosition

      cell.frame = CGRect(
        x: rowWidth + startPosition,
        y: row.frame.origin.y + contentOffset.y,
        width: cellWidth,
        height: rowHeight)
      cell.backgroundColor = .green
    }

    CATransaction.commit()
  }

  /// Removes each component and creates them again.
  public func reload() {
    // Reset row views.
    rowViews.forEach({ $0.removeFromSuperview() })
    rowViews = []
    // Reset row line
    rowLine = CALayer()
    rowLayer.layer.addSublayer(rowLine)
    // Reset horizontal lines
    horizontalGridLines.forEach({ $0.removeFromSuperlayer() })
    horizontalGridLines = []
    // Reset cell views.
    cellViews.forEach({ $0.removeFromSuperview() })
    cellViews = []

    // Setup cell views.
    for note in notes {
      let cellView = MIDIPianoRollCellView(note: note)
      cellView.delegate = self
      cellLayer.addSubview(cellView)
      cellViews.append(cellView)
    }

    // Setup row views.
    for pitch in keys.pitches {
      let rowView = MIDIPianoRollRowView(pitch: pitch)
      rowLayer.addSubview(rowView)
      rowViews.append(rowView)
      // Setup horizontal lines.
      let line = CALayer()
      gridLayer.layer.addSublayer(line)
      horizontalGridLines.append(line)
    }

    // Setup bottom horizontal line.
    let bottomRowLine = CALayer()
    gridLayer.layer.addSublayer(bottomRowLine)
    horizontalGridLines.append(bottomRowLine)

    // Update bar.
    lastBar = notes
      .map({ $0.position + $0.duration })
      .sorted(by: { $1 > $0 })
      .first?.bar ?? 0

    let barWidth = beatWidth * CGFloat(timeSignature.beats)
    if CGFloat(lastBar + 1) * barWidth < max(frame.size.width, frame.size.height) {
      lastBar = Int(ceil(Double(frame.size.width / barWidth)) + 1)
    }

    needsRedrawBar = true
    setNeedsLayout()
    layoutIfNeeded()
  }

  // MARK: Utils

  private func gridPosition(
    with pianoRollPosition: MIDIPianoRollPosition,
    barWidth: CGFloat,
    beatWidth: CGFloat,
    subbeatWidth: CGFloat,
    centWidth: CGFloat) -> CGFloat {
    let bars = CGFloat(pianoRollPosition.bar) * barWidth
    let beats = CGFloat(pianoRollPosition.beat) * beatWidth
    let subbeats = CGFloat(pianoRollPosition.subbeat) * subbeatWidth
    let cents = CGFloat(pianoRollPosition.cent) * centWidth
    return bars + beats + subbeats + cents
  }

  private func pianoRollPosition(for cell: MIDIPianoRollCellView) -> MIDIPianoRollPosition {
    // Calculate measure widths
    let normalizedBeatWidth = beatWidth * CGFloat(zoomLevel.rawValue) / 4.0
    let barWidth = normalizedBeatWidth * CGFloat(timeSignature.beats)
    let subbeatWidth = normalizedBeatWidth / 4.0
    let centWidth = subbeatWidth / 240.0

    // Calculate new position
    var position = cell.frame.origin.x - rowWidth
    let bars = position / barWidth
    position -= CGFloat(Int(bars))
    let beats = position / normalizedBeatWidth
    position -= CGFloat(Int(beats))
    let subbeats = position / subbeatWidth
    position -= CGFloat(Int(subbeats))
    let cents = position / centWidth

    return MIDIPianoRollPosition(
      bar: Int(bars),
      beat: Int(beats),
      subbeat: Int(subbeats),
      cent: Int(cents))
  }

  private func pianoRollPosition(for point: CGFloat) -> MIDIPianoRollPosition {
    // Calculate measure widths
    let normalizedBeatWidth = beatWidth * CGFloat(zoomLevel.rawValue) / 4.0
    let barWidth = normalizedBeatWidth * CGFloat(timeSignature.beats)
    let subbeatWidth = normalizedBeatWidth / 4.0
    let centWidth = subbeatWidth / 240.0

    // Calculate new position
    var position = point
    let bars = position / barWidth
    position -= CGFloat(Int(bars))
    let beats = position / normalizedBeatWidth
    position -= CGFloat(Int(beats))
    let subbeats = position / subbeatWidth
    position -= CGFloat(Int(subbeats))
    let cents = position / centWidth

    return MIDIPianoRollPosition(
      bar: Int(bars),
      beat: Int(beats),
      subbeat: Int(subbeats),
      cent: Int(cents))
  }

  private func pianoRollDuration(for cell: MIDIPianoRollCellView) -> MIDIPianoRollPosition {
    // Calculate measure widths
    let normalizedBeatWidth = beatWidth * CGFloat(zoomLevel.rawValue) / 4.0
    let barWidth = normalizedBeatWidth * CGFloat(timeSignature.beats)
    let subbeatWidth = normalizedBeatWidth / 4.0
    let centWidth = subbeatWidth / 240.0

    // Calculate new position
    var width = cell.frame.size.width
    let bars = width / barWidth
    width -= CGFloat(Int(bars))
    let beats = width / normalizedBeatWidth
    width -= CGFloat(Int(beats))
    let subbeats = width / subbeatWidth
    width -= CGFloat(Int(subbeats))
    let cents = width / centWidth

    return MIDIPianoRollPosition(
      bar: Int(bars),
      beat: Int(beats),
      subbeat: Int(subbeats),
      cent: Int(cents))
  }

  private func pianoRollPitch(for cell: MIDIPianoRollCellView) -> UInt8 {
    let position = cell.frame.origin.y - measureHeight
    let index = Int(position / rowHeight)
    return rowViews.indices.contains(index) ? UInt8(rowViews[index].pitch.rawValue) : 0
  }

  // MARK: Zooming

  @objc private func didPinch(pinch: UIPinchGestureRecognizer) {
    switch pinch.state {
    case .began, .changed:
      guard pinch.numberOfTouches == 2 else { return }

      // Calculate pinch direction.
      let t1 = pinch.location(ofTouch: 0, in: self)
      let t2 = pinch.location(ofTouch: 1, in: self)
      let xD = abs(t1.x - t2.x)
      let yD = abs(t1.y - t2.y)
      var isVertical = true
      if (xD == 0) { isVertical = true }
      if (yD == 0) { isVertical = false }
      let ratio = xD / yD
      if (ratio > 2) { isVertical = false }
      if (ratio < 0.5) { isVertical = true }

      // Vertical zooming
      if isVertical {
        var rowScale = pinch.scale
        rowScale = ((rowScale - 1) * zoomSpeed) + 1
        rowScale = min(rowScale, maxRowHeight/rowHeight)
        rowScale = max(rowScale, minRowHeight/rowHeight)
        rowHeight *= rowScale
        setNeedsLayout()
        pinch.scale = 1
      } else { // Horizontal zooming
        var barScale = pinch.scale
        barScale = ((barScale - 1) * zoomSpeed) + 1
        barScale = min(barScale, maxBeatWidth/beatWidth)
        barScale = max(barScale, minBeatWidth/beatWidth)
        beatWidth *= barScale
        setNeedsLayout()
        pinch.scale = 1

        // Get in new zoom level.
        if beatWidth >= maxBeatWidth {
          if let zoom = zoomLevel.zoomedIn, zoom != maxZoomLevel.zoomedIn {
            zoomLevel = zoom
            beatWidth = minBeatWidth
            needsRedrawBar = true
          }
        } else if beatWidth <= minBeatWidth {
          if let zoom = zoomLevel.zoomedOut, zoom != minZoomLevel.zoomedOut {
            zoomLevel = zoom
            beatWidth = maxBeatWidth
            needsRedrawBar = true
          }
        }
      }
    default:
      return
    }
  }

  // MARK: MIDIPianoRollViewCellDelegate

  public func midiPianoRollCellViewDidMove(_ midiPianoRollCellView: MIDIPianoRollCellView, pan: UIPanGestureRecognizer) {
    guard isEditing else { return }
    let translation = pan.translation(in: self)

    if case .began = pan.state {
      midiPianoRollCellView.isSelected = true
    }

    // Horizontal move
    if translation.x > beatWidth, midiPianoRollCellView.frame.maxX < contentSize.width { // Right
      midiPianoRollCellView.frame.origin.x += beatWidth
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    } else if translation.x < -beatWidth, midiPianoRollCellView.frame.minX > rowWidth { // Left
      midiPianoRollCellView.frame.origin.x -= beatWidth
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    }

    // Vertical move
    if translation.y > rowHeight,
      midiPianoRollCellView.frame.maxY < contentSize.height { // Down
      midiPianoRollCellView.frame.origin.y += rowHeight
      pan.setTranslation(CGPoint(x: translation.x, y: 0), in: self)
    } else if translation.y < -rowHeight,
      midiPianoRollCellView.frame.minY > measureHeight { // Up
      midiPianoRollCellView.frame.origin.y -= rowHeight
      pan.setTranslation(CGPoint(x: translation.x, y: 0), in: self)
    }

    if case .ended = pan.state {
      let newCellPosition = pianoRollPosition(for: midiPianoRollCellView)
      let newCellRow = pianoRollPitch(for: midiPianoRollCellView)
      pianoRollDelegate?.midiPianoRollView(self, didMove: midiPianoRollCellView, to: newCellPosition, pitch: newCellRow)
    }
  }

  public func midiPianoRollCellViewDidResize(_ midiPianoRollCellView: MIDIPianoRollCellView, pan: UIPanGestureRecognizer) {
    guard isEditing else { return }
    let translation = pan.translation(in: self)

    if translation.x > beatWidth, midiPianoRollCellView.frame.maxX < contentSize.width - beatWidth { // Increase
      midiPianoRollCellView.frame.size.width += beatWidth
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    } else if translation.x < -beatWidth, midiPianoRollCellView.frame.width > beatWidth { // Decrease
      midiPianoRollCellView.frame.size.width -= beatWidth
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
    }

    if case .ended = pan.state {
      let newDuration = pianoRollDuration(for: midiPianoRollCellView)
      pianoRollDelegate?.midiPianoRollView(self, didResize: midiPianoRollCellView, to: newDuration)
    }
  }

  public func midiPianoRollCellViewDidTap(_ midiPianoRollCellView: MIDIPianoRollCellView) {
    guard isEditing else { return }
  }

  public func midiPianoRollCellViewDidDelete(_ midiPianoRollCellView: MIDIPianoRollCellView) {
    guard isEditing else { return }
  }

  open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard isEditing,
      let cell = cellViews.filter({ $0.frame.contains(point) }).first
      else { return super.hitTest(point, with: event) }

    // Check if cell is moving or resizing.
    if cell.resizeView.bounds.contains(convert(point, to: cell.resizeView)) {
      return cell.resizeView
    }
    return cell
  }
}
