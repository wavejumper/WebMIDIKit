//
//  MIDIPacketList.swift
//  WebMIDIKit
//
//  Created by Adam Nemecek on 2/3/17.
//
//

import AVFoundation
import CoreAudio

extension MIDIPacketList {
    /// this needs to be mutating since we are potentionally changint the timestamp
    /// we cannot make a copy since that woulnd't copy the whole list
    internal mutating func send(to output: MIDIOutput, offset: Double? = nil) {

        _ = offset.map {

            let current = AudioGetCurrentHostTime()
            let _offset = AudioConvertNanosToHostTime(UInt64($0 * 1000000))

            let ts = current + _offset
            packet.timeStamp = ts
        }

        OSAssert(MIDISend(output.ref, output.endpoint.ref, &self))
        /// this let's us propagate the events to everyone subscribed to this
        /// endpoint not just this port, i'm not sure if we actually want this
        /// but for now, it let's us create multiple ports from different MIDIAccess
        /// objects and have them all receive the same messages
        OSAssert(MIDIReceived(output.endpoint.ref, &self))
    }

    internal init<S: Sequence>(_ data: S, timestamp: MIDITimeStamp = 0) where S.Iterator.Element == UInt8 {
        self.init(packet: MIDIPacket(data, timestamp: timestamp))
    }

    internal init(packet: MIDIPacket) {
        self.init(numPackets: 1, packet: packet)
    }
}

extension UnsafeMutablePointer where Pointee == UInt8 {
    @inline(__always)
    init(ptr : UnsafeMutableRawBufferPointer) {
        self = ptr.baseAddress!.assumingMemoryBound(to: UInt8.self)
    }
}

extension MIDIPacket {
    @inline(__always)
    internal init<S: Sequence>(_ data: S, timestamp: MIDITimeStamp = 0) where S.Iterator.Element == UInt8 {
        self.init()

        timeStamp = timestamp

        var d = Data(data)
        length = UInt16(d.count)

        /// write out bytes to data
        withUnsafeMutableBytes(of: &self.data) {
            d.copyBytes(to: .init(ptr: $0), count: d.count)
        }

//        var ptr = UnsafeMutableRawBufferPointer(packet: &self)
    }
}

extension Data {
    @inline(__always)
    init(packet p: inout MIDIPacket) {
        self = Swift.withUnsafeBytes(of: &p.data) {
            .init(bytes: $0.baseAddress!, count: Int(p.length))
        }
    }
}

extension MIDIEvent {
    @inline(__always)
    fileprivate init(packet p: inout MIDIPacket) {
        timestamp = p.timeStamp
        data = .init(packet: &p)
    }
}

extension MIDIPacketList: Sequence {
    public typealias Element = MIDIEvent

    public func makeIterator() -> AnyIterator<Element> {
        var p: MIDIPacket = packet
        var i = (0..<numPackets).makeIterator()

        return AnyIterator {
            defer {
                p = MIDIPacketNext(&p).pointee
            }

            return i.next().map { _ in .init(packet: &p) }
        }
    }
}
