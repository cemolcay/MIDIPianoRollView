//
//  MIDIPianoRollCellView.swift
//  MIDIPianoRollView
//
//  Created by cem.olcay on 26/11/2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit

/// Delegate functions to inform about editing or deleting cell.
public protocol MIDIPianoRollCellViewDelegate: class {
  /// Informs about moving the cell with the pan gesture.
  ///
  /// - Parameters:
  ///   - midiPianoRollCellView: Cell that moving around.
  ///   - pan: Pan gesture that moves the cell.
  func midiPianoRollCellViewDidMove(_ midiPianoRollCellView: MIDIPianoRollCellView, pan: UIPanGestureRecognizer)

  /// Informs about resizing the cell with the pan gesture.
  ///
  /// - Parameters:
  ///   - midiPianoRollCellView: Cell that resizing.
  ///   - pan: Pan gesture that resizes the cell.
  func midiPianoRollCellViewDidResize(_ midiPianoRollCellView: MIDIPianoRollCellView, pan: UIPanGestureRecognizer)

  /// Informs about the cell has been tapped.
  ///
  /// - Parameter midiPianoRollCellView: The cell that tapped.
  func midiPianoRollCellViewDidTap(_ midiPianoRollCellView: MIDIPianoRollCellView)

  /// Informs about the cell is about to delete.
  ///
  /// - Parameter midiPianoRollCellView: Cell is going to delete.
  func midiPianoRollCellViewDidDelete(_ midiPianoRollCellView: MIDIPianoRollCellView)
}

/// Represents a MIDI note of the `MIDIPianoRollView`.
open class MIDIPianoRollCellView: UIView {
  /// The rendering note data.
  public var note: MIDIPianoRollNote
  /// Inset from the rightmost side on the cell to capture resize gesture.
  public var resizingViewWidth: CGFloat = 20
  /// View that holds the pan gesture on right most side in the view to use in resizing cell.
  internal let resizeView = UIView()

  /// Delegate that informs about editing cell.
  public weak var delegate: MIDIPianoRollCellViewDelegate?

  /// Is cell selected or not.
  public var isSelected: Bool = false {
    didSet {
      layer.borderWidth = isSelected ? 2 : 0
      layer.borderColor = isSelected ? UIColor.blue.cgColor : UIColor.clear.cgColor
    }
  }

  // MARK: Init

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
    self.note = MIDIPianoRollNote(midiNote: 0, velocity: 0, position: .zero, duration: .zero)
    super.init(coder: aDecoder)
    commonInit()
  }

  /// Default initilization function.
  private func commonInit() {
    backgroundColor = .green

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
      x: frame.size.width - resizingViewWidth,
      y: 0,
      width: resizingViewWidth,
      height: frame.size.height)
  }

  // MARK: Gestures

  @objc public func didTap(tap: UITapGestureRecognizer) {
    delegate?.midiPianoRollCellViewDidTap(self)
  }

  @objc public func didMove(pan: UIPanGestureRecognizer) {
    delegate?.midiPianoRollCellViewDidMove(self, pan: pan)
  }

  @objc public func didResize(pan: UIPanGestureRecognizer) {
    delegate?.midiPianoRollCellViewDidResize(self, pan: pan)
  }
}
