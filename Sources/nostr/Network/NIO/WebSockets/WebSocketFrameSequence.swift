// this code was taken from the excellent hummingbird-websocket server project.

import NIOCore
import NIOWebSocket

extension WebSocket {
	/// Sequence of fragmented WebSocket frames
	struct FrameSequence {
		enum SequenceType {
			case text
			case binary

			var opcode:WebSocketOpcode {
				switch self {
					case .text:
					return .text
					case .binary:
					return .binary
				}
			}
		}

		var buffers:[ByteBuffer]
		var size:Int
		var type:SequenceType

		init(type: SequenceType) {
			self.buffers = []
			self.type = type
			self.size = 0
		}

		mutating func append(_ frame: WebSocketFrame) {
			assert(frame.opcode == self.type.opcode)
			self.buffers.append(frame.unmaskedData)
			self.size += frame.unmaskedData.readableBytes
		}

		/// Combined frames
		var combinedResult:Data {
			var result = ByteBufferAllocator().buffer(capacity: self.size)
			for var buffer in self.buffers {
				result.writeBuffer(&buffer)
			}
			switch self.type {
			case .text:
				return .text(String(buffer: result))
			case .binary:
				return .binary(result)
			}
		}
	}
}
