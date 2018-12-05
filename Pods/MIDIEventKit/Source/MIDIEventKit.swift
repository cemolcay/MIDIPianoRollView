//
//  MIDIEventKit.swift
//  MIDIEventKit
//
//  Created by Cem Olcay on 7.03.2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//
//  Created by the midi.org official specs.
//  https://www.midi.org/specifications/item/table-2-expanded-messages-list-status-bytes
//

import Foundation
import CoreMIDI

extension Collection where Iterator.Element == MIDIEvent {
  /// Creates a `MIDIPacketList` representation from `MIDIEvent` array.
  public var midiPacketList: UnsafeMutablePointer<MIDIPacketList> {
    guard let this = self as? [MIDIEvent] else { fatalError() }

    let packetListPointer = UnsafeMutablePointer<MIDIPacketList>.allocate(capacity: this.count)
    var packet = MIDIPacketListInit(packetListPointer)

    for midi in this {
      packet = MIDIPacketListAdd(packetListPointer, 1024, packet, midi.timestamp.value, midi.event.midiBytes.count, midi.event.midiBytes)
    }

    return packetListPointer

//    let packetList = MIDIPacketList(numPackets: UInt32(this.count), packet: packetListPointer.pointee.packet)
//
//    packetListPointer.deinitialize()
//    packetListPointer.deallocate(capacity: this.count)
//
//    return packetList
  }
}

public func ==(lhs: MIDIStatusEvent, rhs: MIDIStatusEvent) -> Bool {
  return lhs.statusByte == rhs.statusByte &&
    lhs.dataBytes == rhs.dataBytes
}

public protocol MIDIStatusEvent: CustomStringConvertible {
  /// Status byte of the midi event.
  var statusByte: UInt8 { get }
  /// Holds midi event's values within two data packets.
  var dataBytes: MIDIEventData { get }

  init?(statusByte: UInt8, dataBytes: MIDIEventData)
}

extension MIDIStatusEvent {
  /// Returns 3 data packets with status and values of the midi event.
  public var midiBytes: [UInt8] {
    return [statusByte, dataBytes.data1, dataBytes.data2]
  }

  public init?(midiPacket: MIDIPacket) {
    self.init(
      statusByte: midiPacket.data.0,
      dataBytes: MIDIEventData(
        data1: midiPacket.data.1,
        data2: midiPacket.data.2))
  }
}

public protocol MIDIEventUndefinable {
  static var undefinedEventStatusBytes: [UInt8] { get }
}

/// Timestamp value of the MIDI event message.
public enum MIDIEventTimeStamp: Equatable {
  /// Initilize timestamp with a MIDITimeStamp value.
  case timestamp(MIDITimeStamp)
  /// Timestamp is right now.
  case now
  /// Future timestamp with a double value in seconds.
  case secondsAfterNow(Double)

  /// MIDITimeStamp value for the MIDI message.
  public var value: MIDITimeStamp {
    switch self {
    case .timestamp(let timestamp):
      return timestamp
    case .now:
      return 0
    case .secondsAfterNow(let sec):
      let now = mach_absolute_time()
      let offset = UInt64(sec * 1000000)
      return now + offset
    }
  }

  // MARK: Equatable

  /// Check if two MIDIEventTimeStamp's equal.
  ///
  /// - Parameters:
  ///   - lhs: Left hand side of the equation.
  ///   - rhs: Right hand side of the equation.
  /// - Returns: Returns if two timestamps are equal or not.
  public static func ==(lhs: MIDIEventTimeStamp, rhs: MIDIEventTimeStamp) -> Bool {
    return lhs.value == rhs.value
  }
}

/// Holds two UInt8 MIDI data packets for the event messages.
public struct MIDIEventData: Equatable {
  /// First midi data packet.
  public var data1: UInt8
  /// Second midi data packet.
  public var data2: UInt8

  /// Both data packets are empty.
  public init() {
    data1 = 0
    data2 = 0
  }

  /// Initilze both data packets with a UInt8 value between 0 - 127.
  ///
  /// - Parameters:
  ///   - data1: First data packet value.
  ///   - data2: Second data packet value.
  public init(data1: UInt8, data2: UInt8) {
    self.data1 = data1
    self.data2 = data2
  }

  /// Initilize only first data packet with UInt8 value between 0 - 127.
  ///
  /// - Parameter data1: First data packet value.
  public init(data1: UInt8) {
    self.data1 = data1
    self.data2 = 0
  }

  /// Initilize both packets with a UInt16 value between 0 - 16383.
  ///
  /// - Parameter data: Both data packets will be created by spliting into two UInt8 data packets by this UInt16 value.
  public init(data: UInt16) {
    let mask: UInt16 = 0x007F
    self.data1 = UInt8(data & mask) // MSB, bit shift right 7
    self.data2 = UInt8((data & (mask << 7)) >> 7) // LSB, mask of 127
  }

  /// Initilize only first packet with a toggle on/off value.
  ///
  /// - Parameter on: On/off value of the first data packet.
  public init(on: Bool) {
    self.data1 = on ? 127 : 0
    self.data2 = 0
  }

  // MARK: Equatable

  public static func ==(lhs: MIDIEventData, rhs: MIDIEventData) -> Bool {
    return lhs.data1 == rhs.data1 && lhs.data2 == rhs.data2
  }
}

/// Create MIDI event messages with MIDIStatusEvent enums for sending or create them from MIDIPacket's for parsing received MIDI message.
public struct MIDIEvent: Equatable {
  /// Event type of the MIDI message.
  public var event: MIDIStatusEvent
  /// Timestamp of the MIDI message.
  public var timestamp: MIDIEventTimeStamp

  /// Initilize midi event with `MIDIStatusEvent` enums and a timestamp.
  ///
  /// - Parameters:
  ///   - event: Event type of the message.
  ///   - timestamp: Timestamp of the message.
  public init(event: MIDIStatusEvent, timestamp: MIDIEventTimeStamp) {
    self.event = event
    self.timestamp = timestamp
  }

  /// Initilize midi event by parsing received midi packet.
  ///
  /// - Parameter midiPacket: Received midi packet for parsing into `MIDIEvent` struct.
  public init?(midiPacket: MIDIPacket) {
    if let channelVoiceEvent = MIDIChannelVoiceEvent(midiPacket: midiPacket) {
      self.event = channelVoiceEvent
    } else if let systemCommonEvent = MIDISystemCommonEvent(midiPacket: midiPacket) {
      self.event = systemCommonEvent
    } else if let systemRealTimeEvent = MIDISystemRealTimeEvent(midiPacket: midiPacket) {
      self.event = systemRealTimeEvent
    } else {
      return nil
    }

    self.timestamp = .timestamp(midiPacket.timeStamp)
  }

  /// MIDI Packet representation for sending event message.
  public var midiPacket: MIDIPacket {
    var packet = MIDIPacket()
    packet.timeStamp = timestamp.value
    packet.length = 3
    packet.data.0 = event.statusByte
    packet.data.1 = event.dataBytes.data1
    packet.data.2 = event.dataBytes.data2
    return packet
  }

  /// Returns a MIDIPacketList packed with itself.
  public var midiPacketList: MIDIPacketList {
    return MIDIPacketList(numPackets: 1, packet: midiPacket)
  }

  // MARK: Equatable

  public static func ==(lhs: MIDIEvent, rhs: MIDIEvent) -> Bool {
    return lhs.event == rhs.event &&
      lhs.timestamp == rhs.timestamp
  }
}

// MARK: - MIDI Channel Voice Events

public enum MIDIChannelVoiceEvent: MIDIStatusEvent {
  case noteOff(note: UInt8, velocity: UInt8, channel: UInt8) // 128 - 143
  case noteOn(note: UInt8, velocity: UInt8, channel: UInt8) // 144 - 159
  case polyphonicAftertouch(note: UInt8, pressure: UInt8, channel: UInt8) // 160 - 175
  case controllerChange(event: MIDIControllerEvent, channel: UInt8) // 176 - 191
  case programChange(program: UInt8, channel: UInt8) // 192 - 207
  case channelAftertouch(pressure: UInt8, channel: UInt8) // 208 - 223
  case pitchBendChange(bend: UInt16, channel: UInt8) // 224 - 239

  // MARK: MIDIStatusEvent

  public var statusByte: UInt8 {
    switch self {
    case .noteOff(_, _, let channel): return 128 + channel
    case .noteOn(_, _, let channel): return 144 + channel
    case .polyphonicAftertouch(_, _, let channel): return 160 + channel
    case .controllerChange(_, let channel): return 176 + channel
    case .programChange(_, let channel): return 192 + channel
    case .channelAftertouch(_, let channel): return 208 + channel
    case .pitchBendChange(_, let channel): return 224 + channel
    }
  }

  public var dataBytes: MIDIEventData {
    switch self {
    case .noteOff(let note, let velocity, _): return MIDIEventData(data1: note, data2: velocity)
    case .noteOn(let note, let velocity, _): return MIDIEventData(data1: note, data2: velocity)
    case .polyphonicAftertouch(let note, let pressure, _): return MIDIEventData(data1: note, data2: pressure)
    case .controllerChange(let event, _): return MIDIEventData(data1: event.statusByte, data2: event.dataBytes.data1)
    case .programChange(let program, _): return MIDIEventData(data1: program)
    case .channelAftertouch(let pressure, _): return MIDIEventData(data1: pressure)
    case .pitchBendChange(let bend, _): return MIDIEventData(data: bend)
    }
  }

  public init?(statusByte: UInt8, dataBytes: MIDIEventData) {
    if statusByte >= 128 && statusByte <= 143 {
      let channel = statusByte - 128
      self = .noteOff(
        note: dataBytes.data1,
        velocity: dataBytes.data2,
        channel: channel)
    } else if statusByte >= 144 && statusByte <= 159 {
      let channel = statusByte - 144
      self = .noteOn(
        note: dataBytes.data1,
        velocity: dataBytes.data2,
        channel: channel)
    } else if statusByte >= 160 && statusByte <= 175 {
      let channel = statusByte - 160
      self = .polyphonicAftertouch(
        note: dataBytes.data1,
        pressure: dataBytes.data2,
        channel: channel)
    } else if statusByte >= 176 && statusByte <= 191,
      let event = MIDIControllerEvent(statusByte: statusByte, dataBytes: dataBytes) {
        let channel = statusByte - 176
        self = .controllerChange(
          event: event,
          channel: channel)
    } else if statusByte >= 192 && statusByte <= 207 {
      let channel = statusByte - 192
      self = .programChange(
        program: dataBytes.data1,
        channel: channel)
    } else if statusByte >= 208 && statusByte <= 223 {
      let channel = statusByte - 208
      self = .channelAftertouch(
        pressure: dataBytes.data1,
        channel: channel)
    } else if statusByte >= 224 && statusByte <= 234 {
      let channel = statusByte - 224
      self = .pitchBendChange(
        bend: UInt16((dataBytes.data2 << 8) | dataBytes.data1),
        channel: channel)
    } else {
      return nil
    }
  }

  // MARK: CustomStringConvertible

  public var description: String {
    switch self {
    case .noteOff: return NSLocalizedString("midi_noteOff", comment: "")
    case .noteOn: return NSLocalizedString("midi_noteOn", comment: "")
    case .polyphonicAftertouch: return NSLocalizedString("midi_polyphonicAftertouch", comment: "")
    case .controllerChange(let event, _): return event.description
    case .programChange(let event, _): return event.description
    case .channelAftertouch: return NSLocalizedString("midi_channelAftertouch", comment: "")
    case .pitchBendChange: return NSLocalizedString("midi_pitchBendChange", comment: "")
    }
  }
}

// MARK: MIDI Controller Events

public enum MIDIControllerEvent: MIDIStatusEvent, MIDIEventUndefinable {
  case bankSelect(value: UInt8) // 0
  case modulationWheel(value: UInt8) // 1
  case breathController(value: UInt8) // 2
  case footController(value: UInt8) // 4
  case portamentoTime(value: UInt8) // 5
  case dataEntryMSB(value: UInt8) // 6
  case channelVolume(value: UInt8) // 7
  case balance(value: UInt8) // 8
  case pan(value: UInt8) // 10
  case expressionController(value: UInt8) // 11
  case effectControl1(value: UInt8) // 12
  case effectControl2(value: UInt8) // 13
  case generalPurposeController1(value: UInt8) // 16
  case generalPurposeController2(value: UInt8) // 17
  case generalPurposeController3(value: UInt8) // 18
  case generalPurposeController4(value: UInt8) // 19
  case lsbBankSelect(value: UInt8) // 32
  case lsbModulationWheel(value: UInt8) // 33
  case lsbBreathController(value: UInt8) // 34
  case lsbFootController(value: UInt8) // 38
  case lsbPortamentoTime(value: UInt8) // 37
  case lsbDataEntryMSB(value: UInt8) // 38
  case lsbChannelVolume(value: UInt8) // 39
  case lsbBalance(value: UInt8) // 40
  case lsbPan(value: UInt8) // 42
  case lsbExpressionController(value: UInt8) // 43
  case lsbEffectControl1(value: UInt8) // 44
  case lsbEffectControl2(value: UInt8) // 45
  case lsbGeneralPurposeController1(value: UInt8) // 48
  case lsbGeneralPurposeController2(value: UInt8) // 49
  case lsbGeneralPurposeController3(value: UInt8) // 50
  case lsbGeneralPurposeController4(value: UInt8) // 51
  case damperPedal(on: Bool) // 64
  case portamentoOn(on: Bool) // 65
  case sostenutoOn(on: Bool) // 66
  case softPedalOn(on: Bool) // 67
  case legatoFootswitch(on: Bool) // 68
  case hold2(on: Bool) // 69
  case soundVariation(value: UInt8) // 70
  case timbreIntesity(value: UInt8) // 71
  case releaseTime(value: UInt8) // 72
  case attackTime(value: UInt8) // 73
  case brightness(value: UInt8) // 74
  case decayTime(value: UInt8) // 75
  case vibratoRate(value: UInt8) // 76
  case vibratoDepth(value: UInt8) // 77
  case vibratoDelay(value: UInt8) // 78
  case defaultUndefined(value: UInt8) // 79
  case generalPurposeController5(value: UInt8) // 80
  case generalPurposeController6(value: UInt8) // 81
  case generalPurposeController7(value: UInt8) // 82
  case generalPurposeController8(value: UInt8) // 83
  case portamentoControl(value: UInt8) // 84
  case highResolutionVelocityPrefix(value: UInt8) // 88
  case reverbSendLevel(value: UInt8) // 91
  case tremoloDepth(value: UInt8) // 92
  case chorusSendLevel(value: UInt8) // 93
  case celesteDepth(value: UInt8) // 94
  case phaserDepth(value: UInt8) // 95
  case dataIncrement // 96
  case dataDecrement // 97
  case nonRegisteredParameterNumberLSB(value: UInt8) // 98
  case nonRegisteredParameterNumberMSB(value: UInt8) // 99
  case registeredParameterNumberLSB(value: UInt8) // 100
  case registeredParameterNumberMSB(value: UInt8) // 101
  case channelMode(MIDIChannelModeEvent) // 120 - 127
  case undefined(status: UInt8, value: UInt8) // 3, 9, 14, 15, 20...31, 35, 21, 46, 47, 52...63, 85, 86, 87, 89, 90, 102...119

  // MARK: MIDIStatusEvent

  public var statusByte: UInt8 {
    switch self {
    case .bankSelect: return 0
    case .modulationWheel: return 1
    case .breathController: return 2
    case .footController: return 4
    case .portamentoTime: return 5
    case .dataEntryMSB: return 6
    case .channelVolume: return 7
    case .balance: return 8
    case .pan: return 10
    case .expressionController: return 11
    case .effectControl1: return 12
    case .effectControl2: return 13
    case .generalPurposeController1: return 16
    case .generalPurposeController2: return 17
    case .generalPurposeController3: return 18
    case .generalPurposeController4: return 19
    case .lsbBankSelect: return 32
    case .lsbModulationWheel: return 33
    case .lsbBreathController: return 34
    case .lsbFootController: return 38
    case .lsbPortamentoTime: return 37
    case .lsbDataEntryMSB: return 38
    case .lsbChannelVolume: return 39
    case .lsbBalance: return 40
    case .lsbPan: return 42
    case .lsbExpressionController: return 43
    case .lsbEffectControl1: return 44
    case .lsbEffectControl2: return 45
    case .lsbGeneralPurposeController1: return 48
    case .lsbGeneralPurposeController2: return 49
    case .lsbGeneralPurposeController3: return 50
    case .lsbGeneralPurposeController4: return 51
    case .damperPedal: return 64
    case .portamentoOn: return 65
    case .sostenutoOn: return 66
    case .softPedalOn: return 67
    case .legatoFootswitch: return 68
    case .hold2: return 69
    case .soundVariation: return 70
    case .timbreIntesity: return 71
    case .releaseTime: return 72
    case .attackTime: return 73
    case .brightness: return 74
    case .decayTime: return 75
    case .vibratoRate: return 76
    case .vibratoDepth: return 77
    case .vibratoDelay: return 78
    case .defaultUndefined: return 79
    case .generalPurposeController5: return 80
    case .generalPurposeController6: return 81
    case .generalPurposeController7: return 82
    case .generalPurposeController8: return 83
    case .portamentoControl: return 84
    case .highResolutionVelocityPrefix: return 88
    case .reverbSendLevel: return 91
    case .tremoloDepth: return 92
    case .chorusSendLevel: return 93
    case .celesteDepth: return 94
    case .phaserDepth: return 95
    case .dataIncrement: return 96
    case .dataDecrement: return 97
    case .nonRegisteredParameterNumberLSB: return 98
    case .nonRegisteredParameterNumberMSB: return 99
    case .registeredParameterNumberLSB: return 100
    case .registeredParameterNumberMSB: return 101
    case .channelMode(let mode): return mode.statusByte
    case .undefined(let status, _): return status
    }
  }

  public var dataBytes: MIDIEventData {
    switch self {
    case .bankSelect(let value): return MIDIEventData(data1: value)
    case .modulationWheel(let value): return MIDIEventData(data1: value)
    case .breathController(let value): return MIDIEventData(data1: value)
    case .footController(let value): return MIDIEventData(data1: value)
    case .portamentoTime(let value): return MIDIEventData(data1: value)
    case .dataEntryMSB(let value): return MIDIEventData(data1: value)
    case .channelVolume(let value): return MIDIEventData(data1: value)
    case .balance(let value): return MIDIEventData(data1: value)
    case .pan(let value): return MIDIEventData(data1: value)
    case .expressionController(let value): return MIDIEventData(data1: value)
    case .effectControl1(let value): return MIDIEventData(data1: value)
    case .effectControl2(let value): return MIDIEventData(data1: value)
    case .generalPurposeController1(let value): return MIDIEventData(data1: value)
    case .generalPurposeController2(let value): return MIDIEventData(data1: value)
    case .generalPurposeController3(let value): return MIDIEventData(data1: value)
    case .generalPurposeController4(let value): return MIDIEventData(data1: value)
    case .lsbBankSelect(let value): return MIDIEventData(data1: value)
    case .lsbModulationWheel(let value): return MIDIEventData(data1: value)
    case .lsbBreathController(let value): return MIDIEventData(data1: value)
    case .lsbFootController(let value): return MIDIEventData(data1: value)
    case .lsbPortamentoTime(let value): return MIDIEventData(data1: value)
    case .lsbDataEntryMSB(let value): return MIDIEventData(data1: value)
    case .lsbChannelVolume(let value): return MIDIEventData(data1: value)
    case .lsbBalance(let value): return MIDIEventData(data1: value)
    case .lsbPan(let value): return MIDIEventData(data1: value)
    case .lsbExpressionController(let value): return MIDIEventData(data1: value)
    case .lsbEffectControl1(let value): return MIDIEventData(data1: value)
    case .lsbEffectControl2(let value): return MIDIEventData(data1: value)
    case .lsbGeneralPurposeController1(let value): return MIDIEventData(data1: value)
    case .lsbGeneralPurposeController2(let value): return MIDIEventData(data1: value)
    case .lsbGeneralPurposeController3(let value): return MIDIEventData(data1: value)
    case .lsbGeneralPurposeController4(let value): return MIDIEventData(data1: value)
    case .damperPedal(let on): return MIDIEventData(on: on)
    case .portamentoOn(let on): return MIDIEventData(on: on)
    case .sostenutoOn(let on): return MIDIEventData(on: on)
    case .softPedalOn(let on): return MIDIEventData(on: on)
    case .legatoFootswitch(let on): return MIDIEventData(on: on)
    case .hold2(let on): return MIDIEventData(on: on)
    case .soundVariation(let value): return MIDIEventData(data1: value)
    case .timbreIntesity(let value): return MIDIEventData(data1: value)
    case .releaseTime(let value): return MIDIEventData(data1: value)
    case .attackTime(let value): return MIDIEventData(data1: value)
    case .brightness(let value): return MIDIEventData(data1: value)
    case .decayTime(let value): return MIDIEventData(data1: value)
    case .vibratoRate(let value): return MIDIEventData(data1: value)
    case .vibratoDepth(let value): return MIDIEventData(data1: value)
    case .vibratoDelay(let value): return MIDIEventData(data1: value)
    case .defaultUndefined(let value): return MIDIEventData(data1: value)
    case .generalPurposeController5(let value): return MIDIEventData(data1: value)
    case .generalPurposeController6(let value): return MIDIEventData(data1: value)
    case .generalPurposeController7(let value): return MIDIEventData(data1: value)
    case .generalPurposeController8(let value): return MIDIEventData(data1: value)
    case .portamentoControl(let value): return MIDIEventData(data1: value)
    case .highResolutionVelocityPrefix(let value): return MIDIEventData(data1: value)
    case .reverbSendLevel(let value): return MIDIEventData(data1: value)
    case .tremoloDepth(let value): return MIDIEventData(data1: value)
    case .chorusSendLevel(let value): return MIDIEventData(data1: value)
    case .celesteDepth(let value): return MIDIEventData(data1: value)
    case .phaserDepth(let value): return MIDIEventData(data1: value)
    case .dataIncrement: return MIDIEventData()
    case .dataDecrement: return MIDIEventData()
    case .nonRegisteredParameterNumberLSB(let value): return MIDIEventData(data1: value)
    case .nonRegisteredParameterNumberMSB(let value): return MIDIEventData(data1: value)
    case .registeredParameterNumberLSB(let value): return MIDIEventData(data1: value)
    case .registeredParameterNumberMSB(let value): return MIDIEventData(data1: value)
    case .channelMode(let mode): return mode.dataBytes
    case .undefined(let status, let value): return MIDIEventData(data1: status, data2: value)
    }
  }

  public init?(statusByte: UInt8, dataBytes: MIDIEventData) {
    switch dataBytes.data1 {
    case 0: self = .bankSelect(value: dataBytes.data2)
    case 1: self = .modulationWheel(value: dataBytes.data2)
    case 2: self = .breathController(value: dataBytes.data2)
    case 4: self = .footController(value: dataBytes.data2)
    case 5: self = .portamentoTime(value: dataBytes.data2)
    case 6: self = .dataEntryMSB(value: dataBytes.data2)
    case 7: self = .channelVolume(value: dataBytes.data2)
    case 8: self = .balance(value: dataBytes.data2)
    case 10: self = .pan(value: dataBytes.data2)
    case 11: self = .expressionController(value: dataBytes.data2)
    case 12: self = .effectControl1(value: dataBytes.data2)
    case 13: self = .effectControl2(value: dataBytes.data2)
    case 16: self = .generalPurposeController1(value: dataBytes.data2)
    case 17: self = .generalPurposeController2(value: dataBytes.data2)
    case 18: self = .generalPurposeController3(value: dataBytes.data2)
    case 19: self = .generalPurposeController4(value: dataBytes.data2)
    case 32: self = .lsbBankSelect(value: dataBytes.data2)
    case 33: self = .lsbModulationWheel(value: dataBytes.data2)
    case 34: self = .lsbBreathController(value: dataBytes.data2)
    case 36: self = .lsbFootController(value: dataBytes.data2)
    case 37: self = .lsbPortamentoTime(value: dataBytes.data2)
    case 38: self = .lsbDataEntryMSB(value: dataBytes.data2)
    case 39: self = .lsbChannelVolume(value: dataBytes.data2)
    case 40: self = .lsbBalance(value: dataBytes.data2)
    case 42: self = .lsbPan(value: dataBytes.data2)
    case 43: self = .lsbExpressionController(value: dataBytes.data2)
    case 44: self = .lsbEffectControl1(value: dataBytes.data2)
    case 45: self = .lsbEffectControl2(value: dataBytes.data2)
    case 48: self = .lsbGeneralPurposeController1(value: dataBytes.data2)
    case 49: self = .lsbGeneralPurposeController2(value: dataBytes.data2)
    case 50: self = .lsbGeneralPurposeController3(value: dataBytes.data2)
    case 51: self = .lsbGeneralPurposeController4(value: dataBytes.data2)
    case 64: self = .damperPedal(on: dataBytes.data2 >= 63)
    case 65: self = .portamentoOn(on: dataBytes.data2 >= 63)
    case 66: self = .sostenutoOn(on: dataBytes.data2 >= 63)
    case 67: self = .softPedalOn(on: dataBytes.data2 >= 63)
    case 68: self = .legatoFootswitch(on: dataBytes.data2 >= 63)
    case 69: self = .hold2(on: dataBytes.data2 >= 63)
    case 70: self = .soundVariation(value: dataBytes.data2)
    case 71: self = .timbreIntesity(value: dataBytes.data2)
    case 72: self = .releaseTime(value: dataBytes.data2)
    case 73: self = .attackTime(value: dataBytes.data2)
    case 74: self = .brightness(value: dataBytes.data2)
    case 75: self = .decayTime(value: dataBytes.data2)
    case 76: self = .vibratoRate(value: dataBytes.data2)
    case 77: self = .vibratoDepth(value: dataBytes.data2)
    case 78: self = .vibratoDelay(value: dataBytes.data2)
    case 79: self = .defaultUndefined(value: dataBytes.data2)
    case 80: self = .generalPurposeController5(value: dataBytes.data2)
    case 81: self = .generalPurposeController6(value: dataBytes.data2)
    case 82: self = .generalPurposeController7(value: dataBytes.data2)
    case 83: self = .generalPurposeController8(value: dataBytes.data2)
    case 84: self = .portamentoControl(value: dataBytes.data2)
    case 88: self = .highResolutionVelocityPrefix(value: dataBytes.data2)
    case 91: self = .reverbSendLevel(value: dataBytes.data2)
    case 92: self = .tremoloDepth(value: dataBytes.data2)
    case 93: self = .chorusSendLevel(value: dataBytes.data2)
    case 94: self = .celesteDepth(value: dataBytes.data2)
    case 95: self = .phaserDepth(value: dataBytes.data2)
    case 96: self = .dataIncrement
    case 97: self = .dataDecrement
    case 98: self = .nonRegisteredParameterNumberLSB(value: dataBytes.data2)
    case 99: self = .nonRegisteredParameterNumberMSB(value: dataBytes.data2)
    case 100: self = .registeredParameterNumberLSB(value: dataBytes.data2)
    case 101: self = .registeredParameterNumberMSB(value: dataBytes.data2)
    default:
      if dataBytes.data1 >= 120 && dataBytes.data1 <= 127,
        let mode = MIDIChannelModeEvent(statusByte: statusByte, dataBytes: dataBytes) {
        self = .channelMode(mode)
      } else if MIDIControllerEvent.undefinedEventStatusBytes.contains(dataBytes.data1) {
        self = .undefined(status: dataBytes.data1, value: dataBytes.data2)
      } else {
        return nil
      }
    }
  }

  // MARK: MIDIEventUndefinable

  public static var undefinedEventStatusBytes: [UInt8] {
    let bytes: [UInt8] = [3, 9, 14, 15, 35, 21, 46, 47, 85, 86, 87, 89, 90]
    return bytes + [UInt8](20...31) + [UInt8](52...63) + [UInt8](102...119)
  }

  // MARK: CustomStringConvertible

  public var description: String {
    switch self {
    case .bankSelect: return NSLocalizedString("midi_bankSelect", comment: "")
    case .modulationWheel: return NSLocalizedString("midi_modulationWheel", comment: "")
    case .breathController: return NSLocalizedString("midi_breathController", comment: "")
    case .footController: return NSLocalizedString("midi_footController", comment: "")
    case .portamentoTime: return NSLocalizedString("midi_portamentoTime", comment: "")
    case .dataEntryMSB: return NSLocalizedString("midi_dataEntryMSB", comment: "")
    case .channelVolume: return NSLocalizedString("midi_channelVolume", comment: "")
    case .balance: return NSLocalizedString("midi_balance", comment: "")
    case .pan: return NSLocalizedString("midi_pan", comment: "")
    case .expressionController: return NSLocalizedString("midi_expressionController", comment: "")
    case .effectControl1: return NSLocalizedString("midi_effectControl1", comment: "")
    case .effectControl2: return NSLocalizedString("midi_effectControl2", comment: "")
    case .generalPurposeController1: return NSLocalizedString("midi_generalPurposeController1", comment: "")
    case .generalPurposeController2: return NSLocalizedString("midi_generalPurposeController2", comment: "")
    case .generalPurposeController3: return NSLocalizedString("midi_generalPurposeController3", comment: "")
    case .generalPurposeController4: return NSLocalizedString("midi_generalPurposeController4", comment: "")
    case .lsbBankSelect: return NSLocalizedString("midi_lsbBankSelect", comment: "")
    case .lsbModulationWheel: return NSLocalizedString("midi_lsbModulationWheel", comment: "")
    case .lsbBreathController: return NSLocalizedString("midi_lsbBreathController", comment: "")
    case .lsbFootController: return NSLocalizedString("midi_lsbFootController", comment: "")
    case .lsbPortamentoTime: return NSLocalizedString("midi_lsbPortamentoTime", comment: "")
    case .lsbDataEntryMSB: return NSLocalizedString("midi_lsbDataEntryMSB", comment: "")
    case .lsbChannelVolume: return NSLocalizedString("midi_lsbChannelVolume", comment: "")
    case .lsbBalance: return NSLocalizedString("midi_lsbBalance", comment: "")
    case .lsbPan: return NSLocalizedString("midi_lsbPan", comment: "")
    case .lsbExpressionController: return NSLocalizedString("midi_lsbExpressionController", comment: "")
    case .lsbEffectControl1: return NSLocalizedString("midi_lsbEffectControl1", comment: "")
    case .lsbEffectControl2: return NSLocalizedString("midi_lsbEffectControl2", comment: "")
    case .lsbGeneralPurposeController1: return NSLocalizedString("midi_lsbGeneralPurposeController1", comment: "")
    case .lsbGeneralPurposeController2: return NSLocalizedString("midi_lsbGeneralPurposeController2", comment: "")
    case .lsbGeneralPurposeController3: return NSLocalizedString("midi_lsbGeneralPurposeController3", comment: "")
    case .lsbGeneralPurposeController4: return NSLocalizedString("midi_lsbGeneralPurposeController4", comment: "")
    case .damperPedal: return NSLocalizedString("midi_damperPedal", comment: "")
    case .portamentoOn: return NSLocalizedString("midi_portamentoOn", comment: "")
    case .sostenutoOn: return NSLocalizedString("midi_sostenutoOn", comment: "")
    case .softPedalOn: return NSLocalizedString("midi_softPedalOn", comment: "")
    case .legatoFootswitch: return NSLocalizedString("midi_legatoFootswitch", comment: "")
    case .hold2: return NSLocalizedString("midi_hold2", comment: "")
    case .soundVariation: return NSLocalizedString("midi_soundVariation", comment: "")
    case .timbreIntesity: return NSLocalizedString("midi_timbreIntesity", comment: "")
    case .releaseTime: return NSLocalizedString("midi_releaseTime", comment: "")
    case .attackTime: return NSLocalizedString("midi_attackTime", comment: "")
    case .brightness: return NSLocalizedString("midi_brightness", comment: "")
    case .decayTime: return NSLocalizedString("midi_decayTime", comment: "")
    case .vibratoRate: return NSLocalizedString("midi_vibratoRate", comment: "")
    case .vibratoDepth: return NSLocalizedString("midi_vibratoDepth", comment: "")
    case .vibratoDelay: return NSLocalizedString("midi_vibratoDelay", comment: "")
    case .defaultUndefined: return NSLocalizedString("midi_defaultUndefined", comment: "")
    case .generalPurposeController5: return NSLocalizedString("midi_generalPurposeController5", comment: "")
    case .generalPurposeController6: return NSLocalizedString("midi_generalPurposeController6", comment: "")
    case .generalPurposeController7: return NSLocalizedString("midi_generalPurposeController7", comment: "")
    case .generalPurposeController8: return NSLocalizedString("midi_generalPurposeController8", comment: "")
    case .portamentoControl: return NSLocalizedString("midi_portamentoControl", comment: "")
    case .highResolutionVelocityPrefix: return NSLocalizedString("midi_highResolutionVelocityPrefix", comment: "")
    case .reverbSendLevel: return NSLocalizedString("midi_reverbSendLevel", comment: "")
    case .tremoloDepth: return NSLocalizedString("midi_tremoloDepth", comment: "")
    case .chorusSendLevel: return NSLocalizedString("midi_chorusSendLevel", comment: "")
    case .celesteDepth: return NSLocalizedString("midi_celesteDepth", comment: "")
    case .phaserDepth: return NSLocalizedString("midi_phaserDepth", comment: "")
    case .dataIncrement: return NSLocalizedString("midi_dataIncrement", comment: "")
    case .dataDecrement: return NSLocalizedString("midi_dataDecrement", comment: "")
    case .nonRegisteredParameterNumberLSB: return NSLocalizedString("midi_nonRegisteredParameterNumberLSB", comment: "")
    case .nonRegisteredParameterNumberMSB: return NSLocalizedString("midi_nonRegisteredParameterNumberMSB", comment: "")
    case .registeredParameterNumberLSB: return NSLocalizedString("midi_registeredParameterNumberLSB", comment: "")
    case .registeredParameterNumberMSB: return NSLocalizedString("midi_registeredParameterNumberMSB", comment: "")
    case .channelMode(let mode): return mode.description
    case .undefined: return NSLocalizedString("midi_undefined", comment: "")
    }
  }
}

// MARK: - MIDI Channel Mode Events

public enum MIDIChannelModeEvent: MIDIStatusEvent {
  case allSoundOff // 120
  case resetAllControllers // 121
  case localControl(on: Bool) // 122
  case allNotesOff // 123
  case omniModeOff // 124
  case omniModeOn // 125
  case monoModeOn // 126
  case polyModeOn // 127

  // MARK: MIDIStatusEvent

  public var statusByte: UInt8 {
    switch self {
    case .allSoundOff: return 120
    case .resetAllControllers: return 121
    case .localControl: return 122
    case .allNotesOff: return 123
    case .omniModeOff: return 124
    case .omniModeOn: return 125
    case .monoModeOn: return 126
    case .polyModeOn: return 127
    }
  }

  public var dataBytes: MIDIEventData {
    switch self {
    case .allSoundOff: return MIDIEventData(data1: statusByte)
    case .resetAllControllers: return MIDIEventData(data1: statusByte)
    case .localControl(let on): return MIDIEventData(data1: statusByte, data2: on ? 127 : 0)
    case .allNotesOff: return MIDIEventData(data1: statusByte)
    case .omniModeOff: return MIDIEventData(data1: statusByte)
    case .omniModeOn: return MIDIEventData(data1: statusByte)
    case .monoModeOn: return MIDIEventData(data1: statusByte)
    case .polyModeOn: return MIDIEventData(data1: statusByte)
    }
  }

  public init?(statusByte: UInt8, dataBytes: MIDIEventData) {
    switch dataBytes.data1 {
    case 120: self = .allSoundOff
    case 121: self = .resetAllControllers
    case 122: self = .localControl(on: dataBytes.data2 > 63)
    case 123: self = .allNotesOff
    case 124: self = .omniModeOff
    case 125: self = .omniModeOn
    case 126: self = .monoModeOn
    case 127: self = .polyModeOn
    default: return nil
    }
  }

  // MARK: CustomStringConvertible

  public var description: String {
    switch self {
    case .allSoundOff: return NSLocalizedString("midi_allSoundOff", comment: "")
    case .resetAllControllers: return NSLocalizedString("midi_resetAllControllers", comment: "")
    case .localControl: return NSLocalizedString("midi_localControl", comment: "")
    case .allNotesOff: return NSLocalizedString("midi_allNotesOff", comment: "")
    case .omniModeOff: return NSLocalizedString("midi_omniModeOff", comment: "")
    case .omniModeOn: return NSLocalizedString("midi_omniModeOn", comment: "")
    case .monoModeOn: return NSLocalizedString("midi_monoModeOn", comment: "")
    case .polyModeOn: return NSLocalizedString("midi_polyModeOn", comment: "")
    }
  }
}

// MARK: MIDI Quarter Frame Events

public enum SMPTERate: UInt8 {
  case fps24 = 0x00
  case fps25 = 0x01
  case fps30 = 0x02
  case fps30drop = 0x03
}

public enum MIDIQuarterFrameEvent: CustomStringConvertible {
  case framesLowNibble(UInt8)
  case framesHighNibble(UInt8)
  case secondsLowNibble(UInt8)
  case secondsHighNibble(UInt8)
  case minutesLowNibble(UInt8)
  case minutesHighNibble(UInt8)
  case hoursLowNibble(UInt8)
  case hoursHighNibble(nibble: UInt8, rate: SMPTERate)

  public var dataBytes: MIDIEventData {
    switch self {
    case .framesLowNibble(let nibble): return MIDIEventData(data1: 0x00 + nibble)
    case .framesHighNibble(let nibble): return MIDIEventData(data1: 0x10 + nibble)
    case .secondsLowNibble(let nibble): return MIDIEventData(data1: 0x20 + nibble)
    case .secondsHighNibble(let nibble): return MIDIEventData(data1: 0x30 + nibble)
    case .minutesLowNibble(let nibble): return MIDIEventData(data1: 0x40 + nibble)
    case .minutesHighNibble(let nibble): return MIDIEventData(data1: 0x50 + nibble)
    case .hoursLowNibble(let nibble): return MIDIEventData(data1: 0x60 + nibble)
    case .hoursHighNibble(let nibble, let rate): return MIDIEventData(data1: 0x70 + (rate.rawValue + nibble))
    }
  }

  public var description: String {
    return NSLocalizedString("midi_quarterFrameEvent", comment: "")
  }

  public init?(data: MIDIEventData) {
    if data.data1 >= 0x00 && data.data1 < 0x10 {
      let nibble = data.data1 - 0x00
      self = .framesLowNibble(nibble)
    } else if data.data1 >= 0x10 && data.data1 < 0x20 {
      let nibble = data.data1 - 0x10
      self = .framesHighNibble(nibble)
    } else if data.data1 >= 0x20 && data.data1 < 0x30 {
      let nibble = data.data1 - 0x20
      self = .secondsLowNibble(nibble)
    } else if data.data1 >= 0x30 && data.data1 < 0x40 {
      let nibble = data.data1 - 0x30
      self = .secondsHighNibble(nibble)
    } else if data.data1 >= 0x40 && data.data1 < 0x50 {
      let nibble = data.data1 - 0x40
      self = .minutesLowNibble(nibble)
    } else if data.data1 >= 0x50 && data.data1 < 0x60 {
      let nibble = data.data1 - 0x50
      self = .minutesHighNibble(nibble)
    } else if data.data1 >= 0x60 && data.data1 < 0x70 {
      let nibble = data.data1 - 0x60
      self = .hoursLowNibble(nibble)
    } else if data.data1 >= 0x70 && data.data1 < 0x80 {
      let nibble = data.data1 - 0x70
      // FIXME: I don't know how to get both rate and nibble from single byte.
      self = .hoursHighNibble(nibble: nibble, rate: .fps24)
    } else {
      return nil
    }
  }
}

// MARK: MIDI System Common Events

public enum MIDISystemCommonEvent: MIDIStatusEvent, MIDIEventUndefinable {
  case systemExclusive(data1: UInt8, data2: UInt8) // 240
  case midiTimeCodeQuarterFrame(MIDIQuarterFrameEvent) // 241
  case songPositionPointer(pointer: UInt16) // 242
  case songSelect(song: UInt8) // 243
  case tuneRequest // 246
  case eox // 247
  case reserved(status: UInt8, data: MIDIEventData) // 245, 244

  // MARK: MIDIStatusEvent

  public var statusByte: UInt8 {
    switch self {
    case .systemExclusive: return 240
    case .midiTimeCodeQuarterFrame: return 241
    case .songPositionPointer: return 242
    case .songSelect: return 243
    case .tuneRequest: return 246
    case .eox: return 247
    case .reserved(let status, _): return status
    }
  }

  public var dataBytes: MIDIEventData {
    switch self {
    case .systemExclusive(let data1, let data2): return MIDIEventData(data1: data1, data2: data2)
    case .midiTimeCodeQuarterFrame(let frame): return frame.dataBytes
    case .songPositionPointer(let pointer): return MIDIEventData(data: pointer)
    case .songSelect(let song): return MIDIEventData(data1: song)
    case .tuneRequest: return MIDIEventData()
    case .eox: return MIDIEventData()
    case .reserved(_, let data): return data
    }
  }

  public init?(statusByte: UInt8, dataBytes: MIDIEventData) {
    switch statusByte {
    case 240: self = .systemExclusive(data1: dataBytes.data1, data2: dataBytes.data2)
    case 241:
      if let event = MIDIQuarterFrameEvent(data: dataBytes) {
        self = .midiTimeCodeQuarterFrame(event)
      } else {
        return nil
      }
    case 242: self = .songPositionPointer(pointer: UInt16((dataBytes.data2 << 8) | dataBytes.data1))
    case 243: self = .songSelect(song: dataBytes.data1)
    case 246: self = .tuneRequest
    case 247: self = .eox
    default:
      if MIDISystemCommonEvent.undefinedEventStatusBytes.contains(statusByte) {
        self = .reserved(status: statusByte, data: dataBytes)
      } else {
        return nil
      }
    }
  }

  // MARK: MIDIEventUndefinable

  public static var undefinedEventStatusBytes: [UInt8] {
    return [245, 244]
  }

  // MARK: CustomStringConvertible

  public var description: String {
    switch self {
    case .systemExclusive: return NSLocalizedString("midi_systemExclusive", comment: "")
    case .midiTimeCodeQuarterFrame(let qt): return qt.description
    case .songPositionPointer: return NSLocalizedString("midi_songPositionPointer", comment: "")
    case .songSelect: return NSLocalizedString("midi_songSelect", comment: "")
    case .tuneRequest: return NSLocalizedString("midi_tuneRequest", comment: "")
    case .eox: return NSLocalizedString("midi_eox", comment: "")
    case .reserved: return NSLocalizedString("midi_undefined", comment: "")
    }
  }
}

// MARK: MIDI System Real Time Events

public enum MIDISystemRealTimeEvent: MIDIStatusEvent, MIDIEventUndefinable {
  case timingClock // 248
  case start // 250
  case `continue` // 251
  case stop // 252
  case activeSensing // 254
  case reset // 255
  case reserved(status: UInt8, data: MIDIEventData) // 253, 249

  // MARK: MIDIStatusEvent

  public var statusByte: UInt8 {
    switch self {
    case .timingClock: return 248
    case .start: return 250
    case .`continue`: return 251
    case .stop: return 252
    case .activeSensing: return 254
    case .reset: return 255
    case .reserved(let status, _): return status
    }
  }

  public var dataBytes: MIDIEventData {
    switch self {
    case .timingClock: return MIDIEventData()
    case .start: return MIDIEventData()
    case .`continue`: return MIDIEventData()
    case .stop: return MIDIEventData()
    case .activeSensing: return MIDIEventData()
    case .reset: return MIDIEventData()
    case .reserved(_, let data): return data
    }
  }

  public init?(statusByte: UInt8, dataBytes: MIDIEventData) {
    switch statusByte {
    case 248: self = .timingClock
    case 250: self = .start
    case 251: self = .`continue`
    case 252: self = .stop
    case 254: self = .activeSensing
    case 255: self = .reset
    default:
      if MIDISystemRealTimeEvent.undefinedEventStatusBytes.contains(statusByte) {
        self = .reserved(status: statusByte, data: dataBytes)
      } else {
        return nil
      }
    }
  }

  // MARK: MIDIEventUndefinable

  public static var undefinedEventStatusBytes: [UInt8] {
    return [253, 249]
  }

  // MARK: CustomStringConvertible

  public var description: String {
    switch self {
    case .timingClock: return NSLocalizedString("midi_timingClock", comment: "")
    case .start: return NSLocalizedString("midi_start", comment: "")
    case .`continue`: return NSLocalizedString("midi_continue", comment: "")
    case .stop: return NSLocalizedString("midi_stop", comment: "")
    case .activeSensing: return NSLocalizedString("midi_activeSensing", comment: "")
    case .reset: return NSLocalizedString("midi_reset", comment: "")
    case .reserved: return NSLocalizedString("midi_undefined", comment: "")
    }
  }
}
