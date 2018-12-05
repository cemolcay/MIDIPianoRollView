//
//  MIDIPianoRollPosition.swift
//  MIDIPianoRollView
//
//  Created by cem.olcay on 27/11/2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import Foundation
import MusicTheorySwift

// MARK: - Equatable

/// Adds two `MIDIPianoRollPosition`s together.
///
/// - Parameters:
///   - lhs: Left hand side of the equation.
///   - rhs: Right hand side of the equation.
/// - Returns: Returns the new position.
public func +(lhs: MIDIPianoRollPosition, rhs: MIDIPianoRollPosition) -> MIDIPianoRollPosition {
  // Calculate cent
  var newCent = lhs.cent + rhs.cent
  let subbeatCarry = newCent / 240
  newCent -= subbeatCarry * 240
  // Calculate subbeat
  var newSubbeat = lhs.subbeat + rhs.subbeat + subbeatCarry
  let beatCarry = newSubbeat / 4
  newSubbeat -= beatCarry * 4
  // Calculate beat
  var newBeat = lhs.beat + rhs.beat + beatCarry
  let barCarry = newBeat / 4
  newBeat -= barCarry * 4
  // Calculate bar
  let newBar = lhs.bar + rhs.bar + barCarry
  // Return new position
  return MIDIPianoRollPosition(bar: newBar, beat: newBeat, subbeat: newSubbeat, cent: newCent)
}

/// Substracts the right hand side position from left hand side position.
///
/// - Parameters:
///   - lhs: Position to be substracted.
///   - rhs: Substraction amount.
/// - Returns: Returns the new position.
public func -(lhs: MIDIPianoRollPosition, rhs: MIDIPianoRollPosition) -> MIDIPianoRollPosition {
  // Calculate cent
  var newCent = lhs.cent - rhs.cent
  var subbeatCarry = 0
  if newCent < 0 {
    subbeatCarry = 1
    subbeatCarry += -newCent / 240
    newCent = 240 + (newCent * subbeatCarry)
  }

  // Calculate subbeat
  var newSubbeat = lhs.subbeat - rhs.subbeat - subbeatCarry
  var beatCarry = 0
  if newSubbeat < 0 {
    beatCarry = 1
    beatCarry += -newSubbeat / 4
    newSubbeat = 4 + (newSubbeat * beatCarry)
  }

  // Calculate beat
  var newBeat = lhs.beat - rhs.beat - beatCarry
  var barCarry = 0
  if newBeat < 0 {
    barCarry = 1
    barCarry += -newBeat / 4
    newBeat = 4 + (newBeat * barCarry)
  }
  
  // Calculate bar
  let newBar = lhs.bar - rhs.bar - barCarry
  if newBar < 0 {
    return .zero
  } else {
    return MIDIPianoRollPosition(bar: newBar, beat: newBeat, subbeat: newSubbeat, cent: newCent)
  }
}

/// Checks if the two `MIDIPianoRollPosition`s are the same by their values.
///
/// - Parameters:
///   - lhs: Left hand side of the equation.
///   - rhs: Right hand side of the equation.
/// - Returns: Returns the equality of the `MIDIPianoRollPosition`s.
public func ==(lhs: MIDIPianoRollPosition, rhs: MIDIPianoRollPosition) -> Bool {
  return lhs.bar == rhs.bar &&
    lhs.beat == rhs.beat &&
    lhs.subbeat == rhs.subbeat &&
    lhs.cent == rhs.cent
}

// MARK: - Comparable

/// Compares if left hand side position is less than right hand side position.
///
/// - Parameters:
///   - lhs: Left hand side of the equation.
///   - rhs: Right hand side of the equation.
/// - Returns: Returns true if left hand side position is less than right hand side position.
public func <(lhs: MIDIPianoRollPosition, rhs: MIDIPianoRollPosition) -> Bool {
  if lhs.bar < rhs.bar {
    return true
  } else if lhs.bar == rhs.bar {
    if lhs.beat < rhs.beat {
      return true
    } else if lhs.beat == rhs.beat {
      if lhs.subbeat < rhs.subbeat {
        return true
      } else if lhs.subbeat == rhs.subbeat {
        if lhs.cent < rhs.cent {
          return true
        }
      }
    }
  }
  return false
}

// MARK: - MIDIPianoRollPosition

/// Represents the position on the piano roll by bar, beat, subbeat and cent values.
public struct MIDIPianoRollPosition: Equatable, Comparable, Codable, CustomStringConvertible {
  /// Bar number.
  public var bar: Int
  /// Beat number of a bar, between 0 and 4.
  public var beat: Int
  /// Subbeat number of a beat, between 0 and 4.
  public var subbeat: Int
  /// Cent value of a subbeat, between 0 and 240
  public var cent: Int

  /// Zero position.
  public static let zero = MIDIPianoRollPosition(bar: 0, beat: 0, subbeat: 0, cent: 0)

  /// Returns true if beat, subbeat and cent is zero. The position is on the begining of a bar.
  public var isBarPosition: Bool {
    return beat == 0 && subbeat == 0 && cent == 0
  }

  /// Initilizes the position.
  ///
  /// - Parameters:
  ///   - bar: Bar number≥
  ///   - beat: Beat number.
  ///   - subbeat: Subbeat number.
  ///   - cent: Cent number.
  public init(bar: Int, beat: Int, subbeat: Int, cent: Int) {
    self.bar = bar
    self.beat = beat
    self.subbeat = subbeat
    self.cent = cent
  }

  /// Returns the next position.
  public var next: MIDIPianoRollPosition {
    var position = self
    position.cent += 1
    if position.cent > 240 {
      position.subbeat += 1
      position.cent = 0
    }
    if position.subbeat > 4 {
      position.beat += 1
      position.subbeat = 0
    }
    if position.beat > 4 {
      position.bar += 1
      position.beat = 0
    }
    return position
  }

  /// Returns the previous position.
  public var previous: MIDIPianoRollPosition {
    var position = self
    position.cent -= 1
    if position.cent < 0 {
      position.subbeat -= 1
      position.cent = 240
    }
    if position.subbeat < 0 {
      position.beat -= 1
      position.subbeat = 4
    }
    if position.beat < 0 {
      position.bar -= 1
      position.beat = position.bar < 0 ? 0 : 4
    }
    if position.bar < 0 {
      position.bar = 0
    }
    return self
  }

  /// Returns piano roll beat text friendly string.
  public var description: String {
    if beat == 0 && subbeat == 0 && cent == 0 {
      return "\(bar)"
    } else if subbeat == 0 && cent == 0 {
      return "\(bar).\(beat)"
    } else if cent == 0 {
      return "\(bar).\(beat).\(subbeat)"
    } else {
      return "\(bar).\(beat).\(subbeat).\(cent)"
    }
  }

  /// Flattens the beat, subbeat and cent values of the position. Useful for snapping to the closest bar.
  public mutating func flatten() {
    beat = 0
    subbeat = 0
    cent = 0
  }
}

// MARK: - NoteValueExtension

extension MIDIPianoRollPosition {
  public var noteValue: NoteValue? {
    if beat == 0, subbeat == 0, cent == 0 {
      return NoteValue(type: .whole)
    } else if beat == 2, subbeat == 0, cent == 0 {
      return NoteValue(type: .half)
    } else if subbeat == 0, cent == 0 {
      return NoteValue(type: .quarter)
    } else if subbeat == 2, cent == 0 {
      return NoteValue(type: .eighth)
    } else if cent == 120 {
      return NoteValue(type: .thirtysecond)
    } else if cent == 60 {
      return NoteValue(type: .sixtyfourth)
    }
    return nil
  }
}

extension NoteValue {
  public var pianoRollDuration: MIDIPianoRollPosition {
    switch self.type {
    case .doubleWhole:
      return MIDIPianoRollPosition(bar: 2, beat: 0, subbeat: 0, cent: 0)
    case .whole:
      return MIDIPianoRollPosition(bar: 1, beat: 0, subbeat: 0, cent: 0)
    case .half:
      return MIDIPianoRollPosition(bar: 0, beat: 2, subbeat: 0, cent: 0)
    case .quarter:
      return MIDIPianoRollPosition(bar: 0, beat: 1, subbeat: 0, cent: 0)
    case .eighth:
      return MIDIPianoRollPosition(bar: 0, beat: 0, subbeat: 2, cent: 0)
    case .sixteenth:
      return MIDIPianoRollPosition(bar: 0, beat: 0, subbeat: 1, cent: 0)
    case .thirtysecond:
      return MIDIPianoRollPosition(bar: 0, beat: 0, subbeat: 0, cent: 120)
    case .sixtyfourth:
      return MIDIPianoRollPosition(bar: 0, beat: 0, subbeat: 0, cent: 60)
    }
  }
}
