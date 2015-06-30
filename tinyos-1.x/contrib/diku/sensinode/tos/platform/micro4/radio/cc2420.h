
enum cc2420_defaults {

	CC2420_DEFAULT_CHANNEL	= 17, // IEEE channel 11-26
	CC2420_DEFAULT_POWER	= 100, // Power in procent

};

enum cc2420_error_codes {

	// FAIL = 0,
	// SUCCESS = 1,
	CC2420_ERROR_CCA = 0x02,
	CC2420_ERROR_TX = 0x03,
};
