//
//  ViewController.swift
//  MIDIPianoRollView
//
//  Created by cem.olcay on 26/11/2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MIDIPianoRollViewDelegate {
  @IBOutlet weak var pianoRollView: MIDIPianoRollView?

  var notes: [MIDIPianoRollNote] = [
    MIDIPianoRollNote(
      midiNote: 60,
      velocity: 90,
      position: MIDIPianoRollPosition(bar: 0, beat: 0, subbeat: 0, cent: 0),
      duration: MIDIPianoRollPosition(bar: 0, beat: 2, subbeat: 0, cent: 0)),
    MIDIPianoRollNote(
      midiNote: 58,
      velocity: 90,
      position: MIDIPianoRollPosition(bar: 0, beat: 3, subbeat: 0, cent: 0),
      duration: MIDIPianoRollPosition(bar: 0, beat: 2, subbeat: 0, cent: 0)),
    MIDIPianoRollNote(
      midiNote: 60,
      velocity: 90,
      position: MIDIPianoRollPosition(bar: 1, beat: 3, subbeat: 3, cent: 0),
      duration: MIDIPianoRollPosition(bar: 0, beat: 4, subbeat: 2, cent: 0)),
    MIDIPianoRollNote(
      midiNote: 56,
      velocity: 90,
      position: MIDIPianoRollPosition(bar: 3, beat: 1, subbeat: 2, cent: 0),
      duration: MIDIPianoRollPosition(bar: 0, beat: 3, subbeat: 0, cent: 0)),
  ]

  // MARK: Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    pianoRollView?.pianoRollDelegate = self
    pianoRollView?.keys = .ranged(50...70)
    pianoRollView?.notes = notes
  }

  // MARK: Actions

  @IBAction func editModeValueChanged(sender: UISwitch) {
    pianoRollView?.isEditing = sender.isOn
  }

  @IBAction func multipleEditingModeValueChanged(sender: UISwitch) {
    pianoRollView?.isMultipleEditingEnabled = sender.isOn
  }

  // MARK: MIDIPianoRollViewDelegate
  
  func midiPianoRollView(_ midiPianoRollView: MIDIPianoRollView, didMove cellView: MIDIPianoRollCellView, to newPosition: MIDIPianoRollPosition, pitch: UInt8) {
    print(cellView, newPosition, pitch)
    guard let index = notes.lastIndex(of: cellView.note) else { return }
    notes[index].position = newPosition
    notes[index].midiNote = pitch
    pianoRollView?.notes = notes
  }

  func midiPianoRollView(_ midiPianoRollView: MIDIPianoRollView, didResize cellView: MIDIPianoRollCellView, to newDuration: MIDIPianoRollPosition) {
    print(cellView, newDuration)
    guard let index = notes.lastIndex(of: cellView.note) else { return }
    notes[index].duration = newDuration
    pianoRollView?.notes = notes
  }

  func midiPianoRollViewMultipleEditingDraggingView(_ midiPianoRollView: MIDIPianoRollView) -> UIView? {
    return nil
  }
}

