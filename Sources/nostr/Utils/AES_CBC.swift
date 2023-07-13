import RAW
import cnostr

internal struct AES_CBC {
	static func encrypt<D>(data:D, iv:InitializationVector, sharedSecret:SharedSecret) -> [UInt8] where D:RAW_encodable {
		sharedSecret.asRAW_val({ ssVal in
			iv.asRAW_val({ ivVal in
				var getAES = AES_ctx()
				AES_init_ctx_iv(&getAES, ssVal.mv_data, ivVal.mv_data)
				var getDat = data.asRAW_val({ dat in
					return Array(dat)
				})
				AES_CBC_encrypt_buffer(&getAES, &getDat, getDat.count)
				return getDat
			})
		})
	}

	static func decrypt<D>(data:D, iv:InitializationVector, sharedSecret:SharedSecret) -> [UInt8] where D:RAW_encodable {
		sharedSecret.asRAW_val({ ssVal in
			iv.asRAW_val({ ivVal in
				var getAES = AES_ctx()
				AES_init_ctx_iv(&getAES, ssVal.mv_data, ivVal.mv_data)
				var getDat = data.asRAW_val({ dat in
					return Array(dat)
				})
				AES_CBC_decrypt_buffer(&getAES, &getDat, getDat.count)
				return getDat
			})
		})
	}
}