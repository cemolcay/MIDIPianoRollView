//
//  ViewController.swift
//  MIDIPianoRollView
//
//  Created by cem.olcay on 26/11/2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  @IBOutlet weak var pianoRollView: MIDIPianoRollView?

  let notes: [MIDIPianoRollNote] = [
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

  override func viewDidLoad() {
    super.viewDidLoad()
    pianoRollView?.keys = .ranged(50...70)
    pianoRollView?.notes = notes
  }
}

