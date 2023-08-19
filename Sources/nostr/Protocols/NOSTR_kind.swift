// (c) tanner silva 2023. all rights reserved.

/// a protocol for types that can be used as a kind for an event.
public protocol NOSTR_kind:FixedWidthInteger, Hashable, Codable {}

/// any unsigned integer can be used as a nostr kind
extension UInt:NOSTR_kind {}
extension UInt8:NOSTR_kind {}
extension UInt16:NOSTR_kind {}
extension UInt32:NOSTR_kind {}
extension UInt64:NOSTR_kind {}

/// any signed integer can be used as a nostr kind
extension Int:NOSTR_kind {}
extension Int8:NOSTR_kind {}
extension Int16:NOSTR_kind {}
extension Int32:NOSTR_kind {}
extension Int64:NOSTR_kind {}

