//
//  MIDIPianoRollNote.swift
//  MIDIPianoRollView
//
//  Created by cem.olcay on 26/11/2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import Foundation
import MusicTheorySwift

/// Checks if the two `MIDIPianoRollNote`s are the same by their unique ID.
///
/// - Parameters:
///   - lhs: Left hand side of the equation.
///   - rhs: Right hand side of the equation.
/// - Returns: Returns the equality of the `MIDIPianoRollNote`s.
public func ==(lhs: MIDIPianoRollNote, rhs: MIDIPianoRollNote) -> Bool {
  return lhs.uuid == rhs.uuid
}

/// Checks if the two `MIDIPianoRollNote`s are the same by their values.
///
/// - Parameters:
///   - lhs: Left hand side of the equation.
///   - rhs: Right hand side of the equation.
/// - Returns: Returns the equality of the `MIDIPianoRollNote`s.
public func ===(lhs: MIDIPianoRollNote, rhs: MIDIPianoRollNote) -> Bool {
  return lhs.midiNote == rhs.midiNote &&
    lhs.velocity == rhs.velocity &&
    lhs.position == rhs.position &&
    lhs.duration == rhs.duration
}

/// Data structure that represents a MIDI note in the piano roll grid.
public struct MIDIPianoRollNote: Equatable, Codable {
  /// Note's unique ID that create on initilization.
  public var uuid: String
  /// MIDI note number.
  public var midiNote: UInt8
  /// MIDI velocity.
  public var velocity: UInt8
  /// Starting beat position on the grid.
  public var position: MIDIPianoRollPosition
  /// Duration of the note in beats.
  public var duration: MIDIPianoRollPosition

  /// Initilizes the data structure.
  ///
  /// - Parameters:
  ///   - midiNote: MIDI note number.
  ///   - velocity: MIDI velocity.
  ///   - position: Starting beat position of the note.
  ///   - duration: Duration of the note in beats
  public init(midiNote: UInt8, velocity: UInt8, position: MIDIPianoRollPosition, duration: MIDIPianoRollPosition) {
    self.uuid = UUID().uuidString
    self.midiNote = midiNote
    self.velocity = velocity
    self.position = position
    self.duration = duration
  }
}
