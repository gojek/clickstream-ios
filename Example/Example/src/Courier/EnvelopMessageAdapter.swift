//
//  EnvelopeMessageAdapter.swift
//  CourierCommonClient
//
//  Created by Alfian Losari on 31/10/22.
//
import CourierCore
import CourierMQTT
import Foundation

fileprivate let BLACKLISTED_TOPICS_REGEX = #"^(chat/[\w-]+/client-events/0)"#

public struct EnvelopeMessageAdapter: MessageAdapter {

    public var contentType: String { "application/x-protobuf" }
    public let isToMessageEnabled: Bool
    public let messageAdapters: [MessageAdapter]
    
    public init(messageAdapters: [MessageAdapter], isToMessageEnabled: Bool) {
        self.messageAdapters = messageAdapters
        self.isToMessageEnabled = isToMessageEnabled
    }

    public func fromMessage<T>(_ message: Data, topic: String) throws -> T {
        do {
            let envelope = try Message_V1_Envelope(serializedBytes: message)
            return try decodeMessage(envelope.payload, topic: topic)
        } catch {
            return try decodeMessage(message, topic: topic)
        }
    }
  
    public func toMessage<T>(data: T, topic: String) throws -> Data {
        let (payload, contentType) = try encodeMessage(data, topic: topic)
        if !isToMessageEnabled || isRegexMatchedTopic(topic) {
            return payload
        } else {
            var envelope = Message_V1_Envelope()
            envelope.contentType = contentType
            envelope.payload = payload
            return try envelope.serializedData()
        }
    }
    
    func isRegexMatchedTopic(_ topic: String) -> Bool {
        topic.range(of: BLACKLISTED_TOPICS_REGEX, options: .regularExpression) != nil
    }
    
    func decodeMessage<D>(_ data: Data, topic: String) throws ->  D {
        for adapter in messageAdapters {
            do {
                let decoded: D = try adapter.fromMessage(data, topic: topic)
                return decoded
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        throw CourierError.decodingError.asNSError
    }
    
    func encodeMessage<E>(_ data: E, topic: String) throws -> (Data, String) {
        for adapter in messageAdapters {
            if let encoded = try? adapter.toMessage(data: data, topic: topic) {
                return (encoded, adapter.contentType)
            }
        }
        throw CourierError.encodingError
    }
    
}
