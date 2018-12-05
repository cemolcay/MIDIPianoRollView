//
//  MIDIPianoRollView+MIDIExport.swift
//  MIDIPianoRollView
//
//  Created by cem.olcay on 05/12/2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import Foundation
import CoreMIDI
import MIDIEventKit
import MusicTheorySwift

extension MIDIPianoRollNote {
  public func noteOn(channel: UInt8 = 0, timestamp: MIDIEventTimeStamp = .now) -> MIDIEvent {
    return MIDIEvent(
      event: MIDIChannelVoiceEvent.noteOn(
        note: midiNote,
        velocity: velocity,
        channel: channel),
      timestamp: timestamp)
  }

  public func noteOff(channel: UInt8 = 0, timestamp: MIDIEventTimeStamp = .now) -> MIDIEvent {
    return MIDIEvent(
      event: MIDIChannelVoiceEvent.noteOff(
        note: midiNote,
        velocity: 0,
        channel: channel),
      timestamp: timestamp)
  }
}

extension MIDIPianoRollPosition {
  public func seconds(for tempo: Tempo) -> Double {
    let barDuration = tempo.duration(of: NoteValue(type: .whole)) * Double(bar)
    let beatDuration = barDuration / Double(tempo.timeSignature.beats) * Double(beat)
    let subbeatDuration = beatDuration / 4.0 * Double(subbeat)
    let centDuration = subbeatDuration / 240.0 * Double(cent)
    return barDuration + beatDuration + subbeatDuration + centDuration
  }
}

extension Collection where Iterator.Element == MIDIPianoRollNote {
  public func exportMIDI(tempo: Tempo, channel: UInt8 = 0) -> MIDIPacketList {
    var events = [MIDIEvent]()
    var currentTime = 0.0
    for note in self {
      // note on
      currentTime = note.position.seconds(for: tempo)
      let noteOn = note.noteOn(channel: channel, timestamp: .secondsAfterNow(currentTime))
      events.append(noteOn)
      // note off
      currentTime += note.duration.seconds(for: tempo)
      let noteOff = note.noteOff(channel: channel, timestamp: .secondsAfterNow(currentTime))
      events.append(noteOff)
    }
    return events.midiPacketList.pointee
  }
}

extension MIDIPianoRollView {
  public func exportMIDI(bpm: Double, channel: UInt8 = 0) -> MIDIPacketList {
    let tempo = Tempo(timeSignature: timeSignature, bpm: bpm)
    return notes.exportMIDI(tempo: tempo)
  }
}
