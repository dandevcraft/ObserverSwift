//
//  Created by Daniel Coleman on 1/6/22.
//

import Foundation
import Combine

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class SimpleSerializingChannel<Decoder: TopLevelDecoder, Encoder: TopLevelEncoder> : SerializingChannel where Decoder.Input == Encoder.Output {

    init<UnderlyingChannel: TypedChannel>(
        underlyingChannel: UnderlyingChannel,
        decoder: Decoder,
        encoder: Encoder
    ) where UnderlyingChannel.Event == Decoder.Input {

        self.publishImp = underlyingChannel.publish

        self.decoder = decoder
        self.encoder = encoder

        self.underlyingSubscription = underlyingChannel.subscribe(channel.publish)
    }

    func publish<Event: Encodable>(_ event: Event) {

        guard let payload = try? encoder.encode(event) else { return }

        self.publishImp(payload)
    }

    func subscribe<Event: Decodable>(_ handler: @escaping (Event) -> Void) -> Subscription {

        let decoder = self.decoder

        return channel.subscribe { (payload: Decoder.Input) in

            guard let event = try? decoder.decode(Event.self, from: payload) else {
                return
            }

            handler(event)
        }
    }

    private let publishImp: (Encoder.Output) -> Void
    private var underlyingSubscription: Subscription!

    private let decoder: Decoder
    private let encoder: Encoder

    private let channel = SimpleChannel()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
typealias SimpleJSONChannel = SimpleSerializingChannel<JSONDecoder, JSONEncoder>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension SimpleSerializingChannel where Decoder == JSONDecoder, Encoder == JSONEncoder {

    convenience init<UnderlyingChannel: TypedChannel>(
        underlyingChannel: UnderlyingChannel
    ) where UnderlyingChannel.Event == Decoder.Input {

        self.init(
            underlyingChannel: underlyingChannel,
            decoder: JSONDecoder(),
            encoder: JSONEncoder()
        )
    }
}
