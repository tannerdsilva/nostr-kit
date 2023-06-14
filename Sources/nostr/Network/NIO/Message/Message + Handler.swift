import NIOCore
import QuickJSON
import Logging

// needed for yyjson
#if os(Linux)
import Glibc
#else
import Darwin.C
#endif


internal final class Handler:ChannelDuplexHandler {
    typealias InboundIn = ByteBuffer
	typealias InboundOut = Message
    typealias OutboundIn = Message
	typealias OutboundOut = ByteBuffer

	static let logger = makeDefaultLogger(label:"net-jsonhandler", logLevel:.debug)
	
	// encoders and decoders

	// outbound data encoder
	private var encoder:QuickJSON.Encoder? = nil
	// inbound data decoder
	private var decoder:QuickJSON.Decoder? = nil
	private let decodingFlags:QuickJSON.Decoder.Flags

	// pointer to a buffer that is used to decode inbound data
	private var pool:MemoryPool? = nil
	private var decoderPointer:UnsafeMutableRawPointer? = nil
	private let maxMessageSize:size_t // informs how large our static parsing buffers should be
	
	#if DEBUG
	private let logger:Logger
	init(url:Relay.URL, maxMessageSize:size_t, flags:QuickJSON.Decoder.Flags) {
		var makeLogger = Self.logger
		makeLogger[metadataKey:"url"] = "\(url)"
		self.maxMessageSize = maxMessageSize
		self.logger = makeLogger
		self.decodingFlags = flags
	}
	#else
	init(maxMessageSize:size_t, flags:QuickJSON.Decoder.Flags) {
		self.maxMessageSize = maxMessageSize
		self.decodingFlags = flags
	}
	#endif

	public func channelActive(context: ChannelHandlerContext) {
		let recommendedSize = QuickJSON.MemoryPool.maxReadSize(inputSize:self.maxMessageSize, flags:QuickJSON.Decoder.Flags())
		#if DEBUG
		self.logger.debug("channel activated.", metadata: ["buff_size": "\(recommendedSize) bytes"])
		#endif
		self.decoderPointer = malloc(recommendedSize)
	}

	public func channelInactive(context: ChannelHandlerContext) {
		#if DEBUG
		self.logger.debug("channel deactivated.")
		#endif
		free(decoderPointer)
		decoderPointer = nil
	}

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		
	}
}