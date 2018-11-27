//
//  MIDIPianoRollCellView.swift
//  MIDIPianoRollView
//
//  Created by cem.olcay on 26/11/2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit

/// Delegate functions to inform about editing or deleting cell.
public protocol MIDIPianoRollgCellViewDelegate: class {
  /// Informs about moving the cell with the pan gesture.
  ///
  /// - Parameters:
  ///   - midiTimeTableCellView: Cell that moving around.
  ///   - pan: Pan gesture that moves the cell.
  func midiTimeTableCellViewDidMove(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer)

  /// Informs about resizing the cell with the pan gesture.
  ///
  /// - Parameters:
  ///   - midiTimeTableCellView: Cell that resizing.
  ///   - pan: Pan gesture that resizes the cell.
  func midiTimeTableCellViewDidResize(_ midiTimeTableCellView: MIDITimeTableCellView, pan: UIPanGestureRecognizer)

  /// Informs about the cell has been tapped.
  ///
  /// - Parameter midiTimeTableCellView: The cell that tapped.
  func midiTimeTableCellViewDidTap(_ midiTimeTableCellView: MIDITimeTableCellView)

  /// Informs about the cell is about to delete.
  ///
  /// - Parameter midiTimeTableCellView: Cell is going to delete.
  func midiTimeTableCellViewDidDelete(_ midiTimeTableCellView: MIDITimeTableCellView)
}

/// Represents a MIDI note of the `MIDIPianoRollView`.
open class MIDIPianoRollCellView: UIView {
  /// The rendering note data.
  public var note: MIDIPianoRollNote
  /// View that holds the pan gesture on right most side in the view to use in resizing cell.
  private let resizeView = UIView()
  /// Inset from the rightmost side on the cell to capture resize gesture.
  public var resizePanThreshold: CGFloat = 10
  /// Delegate that informs about editing cell.
  open weak var delegate: MIDIPianoRollCellViewDelegate?
  /// Is cell selected or not.
  public var isSelected: Bool = false

  /// Initilizes the cell view with a note data.
  ///
  /// - Parameter note: Rendering note data.
  public init(note: MIDIPianoRollNote) {
    self.note = note
    super.init(frame: .zero)
    commonInit()
  }

  /// Initilizes the cell view with a decoder.
  ///
  /// - Parameter aDecoder: Decoder.
  public required init?(coder aDecoder: NSCoder) {
    self.note = MIDIPianoRollNote(note: 0, velocity: 0, position: .zero, duration: .zero)
    super.init(coder: aDecoder)
    commonInit()
  }

  /// Default initilization function.
  private func commonInit() {
    addSubview(resizeView)
    let resizeGesture = UIPanGestureRecognizer(target: self, action: #selector(didResize(pan:)))
    resizeView.addGestureRecognizer(resizeGesture)

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(tap:)))
    addGestureRecognizer(tapGesture)

    let moveGesture = UIPanGestureRecognizer(target: self, action: #selector(didMove(pan:)))
    addGestureRecognizer(moveGesture)
  }

  // MARK: Layout

  open override func layoutSubviews() {
    super.layoutSubviews()
    resizeView.frame = CGRect(
      x: frame.size.width - resizePanThreshold,
      y: 0,
      width: resizePanThreshold,
      height: frame.size.height)
  }

  // MARK: Gestures
  @objc public func didTap(tap: UITapGestureRecognizer) {
    delegate?.midiTimeTableCellViewDidTap(self)
  }

  @objc public func didMove(pan: UIPanGestureRecognizer) {
    delegate?.midiTimeTableCellViewDidMove(self, pan: pan)
  }

  @objc public func didResize(pan: UIPanGestureRecognizer) {
    delegate?.midiTimeTableCellViewDidResize(self, pan: pan)
  }

}
