//
//  MIDIPianoRollViewTests.swift
//  MIDIPianoRollViewTests
//
//  Created by cem.olcay on 26/11/2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import XCTest
@testable import MIDIPianoRollView
import MIDIEventKit
import MusicTheorySwift

class MIDIPianoRollViewTests: XCTestCase {

  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
}

extension MIDIPianoRollViewTests {
  func testPosition() {
    let position = MIDIPianoRollPosition(bar: 0, beat: 0, subbeat: 0, cent: 0)
    XCTAssert(position == .zero)

    let add = MIDIPianoRollPosition(bar: 0, beat: 0, subbeat: 0, cent: 240)
    XCTAssert(position + add == MIDIPianoRollPosition(bar: 0, beat: 0, subbeat: 1, cent: 0))

    let sub1 = MIDIPianoRollPosition(bar: 2, beat: 3, subbeat: 3, cent: 123)
    let sub2 = MIDIPianoRollPosition(bar: 1, beat: 4, subbeat: 2, cent: 232)
    XCTAssert(sub1 - sub2 == MIDIPianoRollPosition(bar: 0, beat: 3, subbeat: 0, cent: 131))
    XCTAssert(sub2 - sub1 == .zero)

    XCTAssertTrue(sub1 > sub2)
  }

  func testMIDITimestamp() {
    let tempo = Tempo()
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
    notes.exportMIDI(tempo: tempo)
  }
}
