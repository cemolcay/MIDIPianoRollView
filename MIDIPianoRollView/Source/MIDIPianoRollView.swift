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

  /// Gets custom dragging view from delegate. The view using for multiple selection visual cue.
  ///
  /// - Parameter midiPianoRollView: Editing piano roll.
  /// - Returns: Visual cue that represents the multiple selected item area.
  func midiPianoRollViewMultipleEditingDraggingView(_ midiPianoRollView: MIDIPianoRollView) -> UIView?
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
        return range.map({ Pitch(midiNote: Int($0)) }).sorted(by: { $0 > $1 })
      case .scale(let scale, let minOctave, let maxOctave):
        return scale.pitches(octaves: [Int](minOctave...maxOctave)).sorted(by: { $0 > $1 })
      case .custom(let pitches):
        return pitches.sorted(by: { $0 > $1 })
      }
    }
  }

  /// All grid lines for line with and color customisation.
  public struct GridLine {
    /// Width of the line.
    public var width: CGFloat
    /// Color of the line.
    public var color: UIColor
    /// Color of the line.
    public var dashPattern: [NSNumber]?

    /// Initilize grid line with width, color and optional dash pattern.
    ///
    /// - Parameters:
    ///   - width: Line width. Defaults 0.5.
    ///   - color: Line color. Defaults black.
    ///   - dashPattern: Optinoal line dash pattern. Defaults nil.
    public init(
      width: CGFloat = 1.0 / UIScreen.main.scale,
      color: UIColor = .black,
      dashPattern: [NSNumber]? = nil) {
      self.width = width
      self.color = color
      self.dashPattern = dashPattern
    }

    /// Initilize the line with piano roll position. Useful for initilizing for measure lines.
    ///
    /// - Parameter pianoRollPosition: Line's position on the piano roll.
    public init?(from pianoRollPosition: MIDIPianoRollPosition) {
      switch pianoRollPosition.noteValue {
      case .some(let position):
        switch position.type {
        case .whole: self = .bar
        case .half: self = .half
        case .quarter: self = .quarter
        case .eighth: self = .eighth
        case .sixteenth: self = .sixteenth
        case .thirtysecond: self = .thirtysecond
        case .sixtyfourth: self = .sixtyfourth
        default: return nil
        }
      case .none:
        return nil
      }
    }

    /// Default line styling.
    public static var `default` = GridLine()
    /// Horizontal line under each row.
    public static var rowHorizontal = GridLine()
    /// Vertical line between row keys and the grid.
    public static var rowVertical = GridLine()
    /// Vertical line under the measure.
    public static var measureBottom = GridLine(width: 1)
    /// Beat text on the measure. Width property represents the font size.
    public static var measureText = GridLine(width: 13)
    /// Vertical line for each bar line
    public static var bar = GridLine(width: 1)
    /// Vertical line for each half beat line.
    public static var half = GridLine(color: .gray)
    /// Vertical line for each quarter beat line.
    public static var quarter = GridLine(color: .gray)
    /// Vertical line for each eighth beat line.
    public static var eighth = GridLine(color: .gray)
    /// Vertical line for each sixteenth beat line.
    public static var sixteenth = GridLine(color: .gray)
    /// Vertical line for each thirtysecond beat line.
    public static var thirtysecond = GridLine(color: .gray)
    /// Vertical line for each sixthfourth beat line.
    public static var sixtyfourth = GridLine(color: .gray)
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

  /// Delegate that informs about cell changes.
  public weak var pianoRollDelegate: MIDIPianoRollViewDelegate?

  /// Enables/disables the edit mode. Defaults false.
  public var isEditing: Bool = false { didSet { isScrollEnabled = !isEditing }}
  /// Enables/disables the zooming feature. Defaults true.
  public var isZoomingEnabled: Bool = true { didSet { zoomGesture.isEnabled = isZoomingEnabled }}
  /// Enables/disables the measure rendering. Defaults true.
  public var isMeasureEnabled: Bool = true { didSet { needsRedrawBar = true }}
  /// Enables/disables the multiple note cell editing at once. Defaults false.
  public var isMultipleEditing: Bool = false { didSet { multipleEditingDidChange() }}

  /// Visual cue for editing multiple cells.
  private var multipleEditingDraggingView: UIView?
  /// Multiple editing start position on piano roll.
  private var multipleEditingDraggingViewStartPosition: CGPoint?
  /// Pan gesture that draws dragging view.
  private var multipleEditingDraggingViewPanGestureRecognizer: UIPanGestureRecognizer?
  /// Pinch gesture for zooming.
  private var zoomGesture = UIPinchGestureRecognizer()

  /// Layer that cells drawn on. Lowest layer.
  public private(set) var cellLayer = UIView()
  /// Reference of the all cell views.
  private var cellViews: [MIDIPianoRollCellView] = []

  /// Layer that grid drawn on. Middle low layer.
  public private(set) var gridLayer = UIView()
  /// Reference of the all horizontal grid lines.
  private var verticalGridLines: [CAShapeLayer] = []
  /// Reference of the all horizontal grid lines.
  private var horizontalGridLines: [CAShapeLayer] = []

  /// Layer that rows drawn on. Middle top layer.
  public private(set) var rowLayer = UIView()
  /// Reference of the all row views.
  private var rowViews: [MIDIPianoRollRowView] = []
  /// Reference of the line drawn on the right side between rows and piano roll grid.
  private var rowLine = CAShapeLayer()

  /// Layer that measure drawn on. Top most layer.
  public var measureLayer = UIView()
  /// Line layer that drawn under the measure.
  private var measureBottomLine = CAShapeLayer()
  /// Reference of the all vertical measure beat lines.
  private var measureLines: [MIDIPianoRollMeasureLineLayer] = []

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

  /// Reference for controlling bar line redrawing in layoutSubview function.
  private var needsRedrawBar: Bool = false {
    didSet {
      if needsRedrawBar {
        setNeedsLayout()
      }
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
    zoomGesture.addTarget(self, action: #selector(didZoom(pinch:)))
    addGestureRecognizer(zoomGesture)
    // Setup layers
    addSubview(cellLayer)
    addSubview(gridLayer)
    addSubview(rowLayer)
    addSubview(measureLayer)
    // Load
    reload()
  }

  // MARK: Lifecycle

  open override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)

    let contentFrame = CGRect(
      x: 0,
      y: 0,
      width: contentSize.width > 0 ? contentSize.width : frame.size.width,
      height: contentSize.height > 0 ? contentSize.height : frame.size.height)

    // Layout master layers
    cellLayer.frame = CGRect(
      x: rowWidth,
      y: isMeasureEnabled ? measureHeight : 0,
      width: contentFrame.size.width - rowWidth,
      height: contentFrame.size.height - measureHeight)

    gridLayer.frame = CGRect(
      x: rowWidth,
      y: isMeasureEnabled ? measureHeight : 0,
      width: contentFrame.size.width - rowWidth,
      height: contentFrame.size.height - measureHeight)

    rowLayer.frame = CGRect(
      x: contentOffset.x,
      y: (isMeasureEnabled ? measureHeight : 0),
      width: rowWidth,
      height: contentFrame.size.height
    )

    measureLayer.frame = CGRect(
      x: rowWidth,
      y: contentOffset.y,
      width: contentFrame.size.width - rowWidth,
      height: isMeasureEnabled ? measureHeight : 0)

    // Layout rows
    var currentY: CGFloat = 0
    for (index, rowView) in rowViews.enumerated() {
      // Layout row
      rowView.frame = CGRect(
        x: 0,
        y: currentY,
        width: rowWidth,
        height: rowHeight)

      // Layout horizontal line
      let horizontalGridLinePath = UIBezierPath()
      horizontalGridLinePath.move(to: CGPoint(x: contentOffset.x, y: currentY))
      horizontalGridLinePath.addLine(to: CGPoint(x: gridLayer.frame.size.width + contentOffset.x, y: currentY))
      horizontalGridLinePath.close()
      horizontalGridLines[index].path = horizontalGridLinePath.cgPath
      horizontalGridLines[index].lineWidth = GridLine.rowHorizontal.width

      // Go to next row.
      currentY += rowHeight
    }

    // Layout bottom row horizontal line
    let horizontalGridLinePath = UIBezierPath()
    horizontalGridLinePath.move(to: CGPoint(x: contentOffset.x, y: currentY))
    horizontalGridLinePath.addLine(to: CGPoint(x: gridLayer.frame.size.width + contentOffset.x, y: currentY))
    horizontalGridLinePath.close()
    horizontalGridLines.last?.path = horizontalGridLinePath.cgPath
    horizontalGridLines.last?.lineWidth = GridLine.rowHorizontal.width

    // Layout left row line
    let rowLinePath = UIBezierPath()
    rowLinePath.move(to: CGPoint(x: rowWidth, y: contentOffset.y - measureLayer.frame.size.height))
    rowLinePath.addLine(to: CGPoint(x: rowWidth, y: rowLayer.frame.size.height + contentOffset.y - measureLayer.frame.size.height))
    rowLinePath.close()
    rowLine.path = rowLinePath.cgPath
    rowLine.lineWidth = GridLine.rowVertical.width

    // Update content size vertically
    contentSize.height = currentY + measureLayer.frame.height

    // Check if needs redraw measure lines.
    if needsRedrawBar {
      // Reset measure
      measureLines.forEach({ $0.removeFromSuperlayer() })
      measureLines = []
      // Reset vertical lines
      verticalGridLines.forEach({ $0.removeFromSuperlayer() })
      verticalGridLines = []
      // Reset bottom measure line
      measureBottomLine.removeFromSuperlayer()
      measureLayer.layer.addSublayer(measureBottomLine)
      measureBottomLine.strokeColor = GridLine.measureBottom.color.cgColor
      measureBottomLine.lineDashPattern = GridLine.measureBottom.dashPattern
      measureBottomLine.contentsScale = UIScreen.main.scale

      let renderingTexts = zoomLevel.renderingMeasureTexts

      // Create lines
      let lineCount = barCount * zoomLevel.rawValue
      var linePosition: MIDIPianoRollPosition = .zero
      for _ in 0...lineCount {
        // Create measure line
        let measureLine = MIDIPianoRollMeasureLineLayer()
        let gridLine = GridLine(from: linePosition) ?? .default
        measureLine.pianoRollPosition = linePosition
        measureLine.lineLayer.strokeColor = gridLine.color.cgColor
        measureLine.lineLayer.lineDashPattern = gridLine.dashPattern
        measureLine.lineLayer.contentsScale = UIScreen.main.scale
        if isMeasureEnabled { measureLayer.layer.addSublayer(measureLine) }
        measureLines.append(measureLine)

        // Decide if render measure text.
        if let lineNoteValue = linePosition.noteValue,
          renderingTexts.contains(where: { $0.type == lineNoteValue.type }) {
          measureLine.showsBeatText = true
          measureLine.textLayer.foregroundColor = GridLine.measureText.color.cgColor
          measureLine.textLayer.fontSize = GridLine.measureText.width
        } else {
          measureLine.showsBeatText = false
        }

        // Draw beat text
        if measureLine.showsBeatText && isMeasureEnabled {
          measureLine.textLayer.string = "\(linePosition)"
        }

        // Create vertical grid line under the measure
        let verticalLine = CAShapeLayer()
        verticalLine.strokeColor = gridLine.color.cgColor
        verticalLine.lineDashPattern = gridLine.dashPattern
        verticalLine.contentsScale = UIScreen.main.scale
        verticalGridLines.append(verticalLine)
        gridLayer.layer.addSublayer(verticalLine)

        // Go next line
        linePosition = linePosition + zoomLevel.noteValue.pianoRollDuration
      }
      needsRedrawBar = false
    }

    // Layout measure and vertical lines.
    var currentX: CGFloat = 0
    for (index, measureLine) in measureLines.enumerated() {
      let gridLine = GridLine(from: measureLine.pianoRollPosition) ?? .default
      measureLine.frame = CGRect(
        x: currentX,
        y: 0,
        width: gridLine.width,
        height: measureHeight)

      // Layout measure line
      let measureLinePath = UIBezierPath()
      measureLinePath.move(to: CGPoint(x: 0, y: 0))
      measureLinePath.addLine(to: CGPoint(x: 0, y: measureLine.frame.size.height))
      measureLinePath.close()
      measureLine.lineLayer.path = measureLinePath.cgPath
      measureLine.lineLayer.lineWidth = gridLine.width

      // Layout measure text
      let measureTextOffset: CGFloat = 2
      measureLine.textLayer.frame = CGRect(
        x: measureTextOffset,
        y: measureHeight - GridLine.measureText.width - measureTextOffset,
        width: beatWidth - measureTextOffset,
        height: GridLine.measureText.width + measureTextOffset)
        
      // Layout vertical grid line
      let verticalGridLinePath = UIBezierPath()
      verticalGridLinePath.move(to: CGPoint(x: currentX, y: contentOffset.y))
      verticalGridLinePath.addLine(to: CGPoint(x: currentX, y: gridLayer.frame.size.height + contentOffset.y))
      verticalGridLinePath.close()
      verticalGridLines[index].path = verticalGridLinePath.cgPath
      verticalGridLines[index].lineWidth = gridLine.width

      currentX += beatWidth
    }

    // Layout measure bottom line
    let measureBottomLinePath = UIBezierPath()
    measureBottomLinePath.move(to: CGPoint(x: contentOffset.x - rowWidth, y: measureLayer.frame.size.height))
    measureBottomLinePath.addLine(to: CGPoint(x: measureLayer.frame.size.width + contentOffset.x - rowWidth, y: measureLayer.frame.size.height))
    measureBottomLinePath.close()
    measureBottomLine.path = measureBottomLinePath.cgPath
    measureBottomLine.lineWidth = GridLine.measureBottom.width

    // Update content size horizontally
    contentSize.width = currentX + rowWidth

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
        x: startPosition,
        y: row.frame.origin.y,
        width: cellWidth,
        height: rowHeight)
    }

    CATransaction.commit()
  }

  open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let cellPoint = convert(point, to: cellLayer)
    guard isEditing,
      let cell = cellViews.filter({ $0.frame.contains(cellPoint) }).first
      else { return super.hitTest(point, with: event) }

    // Check if cell is moving or resizing.
    if cell.resizeView.frame.contains(convert(point, to: cell)) {
      return cell.resizeView
    }
    return cell
  }

  /// Removes each component and creates them again.
  public func reload() {
    // Reset row views.
    rowViews.forEach({ $0.removeFromSuperview() })
    rowViews = []
    // Reset row line
    rowLine = CAShapeLayer()
    rowLine.lineDashPattern = GridLine.rowVertical.dashPattern
    rowLine.strokeColor = GridLine.rowVertical.color.cgColor
    rowLine.contentsScale = UIScreen.main.scale
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
      let line = CAShapeLayer()
      line.strokeColor = GridLine.rowHorizontal.color.cgColor
      line.lineDashPattern = GridLine.rowHorizontal.dashPattern
      line.contentsScale = UIScreen.main.scale
      gridLayer.layer.addSublayer(line)
      horizontalGridLines.append(line)
    }

    // Setup bottom horizontal line.
    let bottomRowLine = CAShapeLayer()
    bottomRowLine.strokeColor = GridLine.rowHorizontal.color.cgColor
    bottomRowLine.lineDashPattern = GridLine.rowHorizontal.dashPattern
    bottomRowLine.contentsScale = UIScreen.main.scale
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

  /// Returns a `MIDIPianoRollPosition`'s x-position on the screen.
  ///
  /// - Parameters:
  ///   - pianoRollPosition: Piano roll position that you want to get its x-position on the screen.
  ///   - barWidth: Optional bar width. Pre-calculate it if you are using this in a loop. Defaults nil.
  ///   - beatWidth: Optional beat width. Pre-calculate it if you are using this in a loop. Defaults nil.
  ///   - subbeatWidth: Optional subbeat width. Pre-calculate it if you are using this in a loop. Defaults nil.
  ///   - centWidth: Optional cent width. Pre-calculate it if you are using this in a loop. Defaults nil.
  /// - Returns: Returns the `MIDIPianoRollPosition`'s x-position on the screen.
  private func gridPosition(
    with pianoRollPosition: MIDIPianoRollPosition,
    barWidth: CGFloat? = nil,
    beatWidth: CGFloat? = nil,
    subbeatWidth: CGFloat? = nil,
    centWidth: CGFloat? = nil) -> CGFloat {
    let bars = CGFloat(pianoRollPosition.bar) * (barWidth ?? ((self.beatWidth * CGFloat(zoomLevel.rawValue) / 4.0) * CGFloat(timeSignature.beats)))
    let beats = CGFloat(pianoRollPosition.beat) * (beatWidth ?? self.beatWidth * CGFloat(zoomLevel.rawValue) / 4.0)
    let subbeats = CGFloat(pianoRollPosition.subbeat) * (subbeatWidth ?? ((self.beatWidth * CGFloat(zoomLevel.rawValue) / 4.0) * CGFloat(zoomLevel.rawValue) / 4.0))
    let cents = CGFloat(pianoRollPosition.cent) * (centWidth ?? (((self.beatWidth * CGFloat(zoomLevel.rawValue) / 4.0) / 4.0) / 240.0))
    return bars + beats + subbeats + cents
  }

  /// Returns the `MIDIPianoRollPosition` of a x-position on the screen.
  ///
  /// - Parameter point: x-position on the screen that you want to get `MIDIPianoRollPosition`.
  /// - Returns: Returns the `MIDIPianoRollPosition` value of a position on the grid.
  private func pianoRollPosition(for point: CGFloat) -> MIDIPianoRollPosition {
    // Calculate measure widths
    let normalizedBeatWidth = beatWidth * CGFloat(zoomLevel.rawValue) / 4.0
    let barWidth = normalizedBeatWidth * CGFloat(timeSignature.beats)
    let subbeatWidth = normalizedBeatWidth / 4.0
    let centWidth = subbeatWidth / 240.0

    // Calculate new position
    var position = point
    let bars = position / barWidth
    position -= CGFloat(Int(bars)) * barWidth
    let beats = position / normalizedBeatWidth
    position -= CGFloat(Int(beats)) * normalizedBeatWidth
    let subbeats = position / subbeatWidth
    position -= CGFloat(Int(subbeats)) * subbeatWidth
    let cents = position / centWidth

    return MIDIPianoRollPosition(
      bar: Int(bars),
      beat: Int(beats),
      subbeat: Int(subbeats),
      cent: Int(cents))
  }

  /// Returns the start `MIDIPianoRollPosition` of a cell.
  ///
  /// - Parameter cell: The cell that you want to get `MIDIPianoRollPosition`.
  /// - Returns: Returns the `MIDIPianoRollPosition` value of a position on the grid.
  private func pianoRollPosition(for cell: MIDIPianoRollCellView) -> MIDIPianoRollPosition {
    let point = cell.frame.origin.x
    return pianoRollPosition(for: point)
  }

  /// Calculates the duration of a `MIDIPianoCellView` in `MIDIPianoRollPosition` units calculated by the cell's width.
  ///
  /// - Parameter cell: Cell that you want to calculate its duration.
  /// - Returns: Returns the duration of a cell in `MIDIPianoRollPosition`.
  private func pianoRollDuration(for cell: MIDIPianoRollCellView) -> MIDIPianoRollPosition {
    // Calculate measure widths
    let normalizedBeatWidth = beatWidth * CGFloat(zoomLevel.rawValue) / 4.0
    let barWidth = normalizedBeatWidth * CGFloat(timeSignature.beats)
    let subbeatWidth = normalizedBeatWidth / 4.0
    let centWidth = subbeatWidth / 240.0

    // Calculate new position
    var width = cell.frame.size.width
    let bars = width / barWidth
    width -= CGFloat(Int(bars)) * barWidth
    let beats = width / normalizedBeatWidth
    width -= CGFloat(Int(beats)) * normalizedBeatWidth
    let subbeats = width / subbeatWidth
    width -= CGFloat(Int(subbeats)) * subbeatWidth
    let cents = width / centWidth

    return MIDIPianoRollPosition(
      bar: Int(bars),
      beat: Int(beats),
      subbeat: Int(subbeats),
      cent: Int(cents))
  }

  /// Returns the corresponding pitch of a row on a y-position on the screeen.
  ///
  /// - Parameter point: y-position on the screen that you want to get the pitch on that row.
  /// - Returns: Returns the pitch of the row at a y-point.
  private func pianoRollPitch(for point: CGFloat) -> UInt8 {
    let index = Int(point / rowHeight)
    return rowViews.indices.contains(index) ? UInt8(rowViews[index].pitch.rawValue) : 0
  }

  /// Returns the corresponding pitch of a row that a cell on.
  ///
  /// - Parameter cell: The cell you want to get the pitch of the row which the cell is on.
  /// - Returns: Returns the pitch of the row that the cell on.
  private func pianoRollPitch(for cell: MIDIPianoRollCellView) -> UInt8 {
    let point = cell.frame.origin.y
    return pianoRollPitch(for: point)
  }

  // MARK: Zooming

  /// Gets called when pinch gesture triggers.
  ///
  /// - Parameter pinch: The pinch gesture.
  @objc private func didZoom(pinch: UIPinchGestureRecognizer) {
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

  // MARK: Multiple Editing

  /// Called when user sets `isMultipleEditingEnabled`.
  private func multipleEditingDidChange() {
    if isMultipleEditing {
      multipleEditingDraggingViewPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didDrag(pan:)))
      multipleEditingDraggingViewPanGestureRecognizer?.maximumNumberOfTouches = 1
      multipleEditingDraggingViewPanGestureRecognizer?.minimumNumberOfTouches = 1
      guard let pan = multipleEditingDraggingViewPanGestureRecognizer else { return }
      addGestureRecognizer(pan)
    } else {
      guard let pan = multipleEditingDraggingViewPanGestureRecognizer else { return }
      pan.removeTarget(self, action: #selector(didDrag(pan:)))
      removeGestureRecognizer(pan)
      multipleEditingDraggingViewPanGestureRecognizer = nil
    }
  }

  /// Gets called when pan gesture triggered.
  ///
  /// - Parameter pan: The pan gesture.
  @objc private func didDrag(pan: UIPanGestureRecognizer) {
    guard isEditing, isMultipleEditing else { return }
    let touchLocation = pan.location(in: self)

    switch pan.state {
    case .began:
      // Reset cell views selected state.
      cellViews.forEach({ $0.isSelected = false })

      // Create dragging view.
      if let view = pianoRollDelegate?.midiPianoRollViewMultipleEditingDraggingView(self) {
        multipleEditingDraggingView = view
      } else {
        multipleEditingDraggingView = UIView()
        multipleEditingDraggingView?.layer.borderColor = UIColor.red.cgColor
        multipleEditingDraggingView?.layer.borderWidth = 2
        multipleEditingDraggingView?.layer.backgroundColor = UIColor.black.cgColor
        multipleEditingDraggingView?.layer.opacity = 0.3
      }

      // Add drag view.
      guard let view = multipleEditingDraggingView else { return }
      addSubview(view)

      // Layout dragging view
      multipleEditingDraggingViewStartPosition = touchLocation
      multipleEditingDraggingView?.frame = CGRect(
        x: touchLocation.x,
        y: touchLocation.y,
        width: beatWidth,
        height: rowHeight)

    case .changed:
      guard let dragView = multipleEditingDraggingView,
        let origin = multipleEditingDraggingViewStartPosition
        else { return }

      // Update drag view frame
      if touchLocation.y < origin.y && touchLocation.x < origin.x {
        dragView.frame = CGRect(
          x: touchLocation.x,
          y: touchLocation.y,
          width: origin.x - touchLocation.x,
          height: origin.y - touchLocation.y)
      } else if touchLocation.y < origin.y && touchLocation.x > origin.x {
        dragView.frame = CGRect(
          x: origin.x,
          y: touchLocation.y,
          width: touchLocation.x - origin.x,
          height: origin.y - touchLocation.y)
      } else if touchLocation.y > origin.y && touchLocation.x > origin.x {
        dragView.frame = CGRect(
          x: origin.x,
          y: origin.y,
          width: touchLocation.x - origin.x,
          height: touchLocation.y - origin.y)
      } else if touchLocation.y > origin.y && touchLocation.x < origin.x {
        dragView.frame = CGRect(
          x: touchLocation.x,
          y: origin.y,
          width: origin.x - touchLocation.x,
          height: touchLocation.y - origin.y)
      }

      cellViews.forEach({ $0.isSelected = $0.frame.intersects(dragView.frame) })

    case .cancelled, .failed, .ended:
      // Remove dragging view
      multipleEditingDraggingView?.removeFromSuperview()
      multipleEditingDraggingView = nil

    default:
      return
    }
  }

  // MARK: MIDIPianoRollViewCellDelegate

  public func midiPianoRollCellViewDidMove(_ midiPianoRollCellView: MIDIPianoRollCellView, pan: UIPanGestureRecognizer) {
    guard isEditing else { return }
    let translationView = self
    let translation = pan.translation(in: translationView)

    // Mark the panning cell selected.
    if case .began = pan.state {
      midiPianoRollCellView.isSelected = true
    }

    // Get cell bounds.
    let selectedCells = cellViews.filter({ $0.isSelected })
    let topMostCellPosition = selectedCells.map({ $0.frame.minY }).sorted().first ?? 0
    let lowestCellPosition = selectedCells.map({ $0.frame.maxX }).sorted().last ?? 0
    let leftMostCellPosition = selectedCells.map({ $0.frame.minX }).sorted().first ?? 0
    let farMostCellPosition = selectedCells.map({ $0.frame.maxX }).sorted().last ?? 0

    // Get all selected cells (in case of multiple selection).
    for cell in selectedCells {
      // Horizontal move
      if translation.x > beatWidth,
        cell.frame.maxX < cellLayer.frame.size.width,
        farMostCellPosition + beatWidth <= cellLayer.frame.size.width { // Right
        cell.frame.origin.x += beatWidth
        pan.setTranslation(CGPoint(x: 0, y: translation.y), in: translationView)
      } else if translation.x < -beatWidth,
        cell.frame.minX > 0,
        leftMostCellPosition - beatWidth >= 0 { // Left
        cell.frame.origin.x -= beatWidth
        pan.setTranslation(CGPoint(x: 0, y: translation.y), in: translationView)
      }

      // Vertical move
      if translation.y > rowHeight,
        cell.frame.maxY < cellLayer.frame.size.height,
        lowestCellPosition + rowWidth <= cellLayer.frame.size.height { // Down
        cell.frame.origin.y += rowHeight
        pan.setTranslation(CGPoint(x: translation.x, y: 0), in: translationView)
      } else if translation.y < -rowHeight,
        cell.frame.minY > 0,
        topMostCellPosition - rowHeight >= 0 { // Up
        cell.frame.origin.y -= rowHeight
        pan.setTranslation(CGPoint(x: translation.x, y: 0), in: translationView)
      }

      if case .ended = pan.state {
        let newCellPosition = pianoRollPosition(for: cell)
        let newCellRow = pianoRollPitch(for: cell)
        pianoRollDelegate?.midiPianoRollView(self, didMove: cell, to: newCellPosition, pitch: newCellRow)
      }
    }
  }

  public func midiPianoRollCellViewDidResize(_ midiPianoRollCellView: MIDIPianoRollCellView, pan: UIPanGestureRecognizer) {
    guard isEditing else { return }
    let translation = pan.translation(in: self)

    // Mark the panning cell selected.
    if case .began = pan.state {
      midiPianoRollCellView.isSelected = true
    }

    let selectedCells = cellViews.filter({ $0.isSelected })
    let farMostCellPosition = selectedCells.map({ $0.frame.maxX }).sorted().last ?? 0

    for cell in selectedCells {
      if translation.x > beatWidth,
        cell.frame.maxX < contentSize.width - beatWidth,
        farMostCellPosition + beatWidth <= contentSize.width { // Increase
        cell.frame.size.width += beatWidth
        pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
      } else if translation.x < -beatWidth,
        cell.frame.width > beatWidth { // Decrease
        cell.frame.size.width -= beatWidth
        pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
      }

      if case .ended = pan.state {
        let newDuration = pianoRollDuration(for: cell)
        pianoRollDelegate?.midiPianoRollView(self, didResize: cell, to: newDuration)
      }
    }
  }

  public func midiPianoRollCellViewDidTap(_ midiPianoRollCellView: MIDIPianoRollCellView) {
    guard isEditing else { return }
  }

  public func midiPianoRollCellViewDidDelete(_ midiPianoRollCellView: MIDIPianoRollCellView) {
    guard isEditing else { return }
  }
}
