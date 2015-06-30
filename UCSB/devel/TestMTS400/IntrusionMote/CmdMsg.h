enum {
	AM_SENSORMSG400 = 0,
	AM_CMDMSG = 1
};

enum {
	LED_ON = 1,
	LED_OFF = 2,
	RADIO_POWER = 3,
	DATA_RATE = 4
};

enum {
	RF_POWER_LEVEL = 0x0B
};
  

typedef struct CmdMsg {
	uint8_t node_id;
	uint8_t action; 
	uint32_t interval;
	uint8_t power;
} CmdMsg; 

typedef struct MTS400DataMsg {
	uint16_t vref;			// 0, 1
	uint16_t humidity;		// 2, 3
	uint16_t temperature;	// 4, 5
	uint16_t taosch0;		// 6, 7
	uint16_t taosch1;		// 8, 9
	uint16_t strength;		// 10, 11
	uint16_t cal_wrod1;		// 12, 13
	uint16_t cal_wrod2;		// 14, 15
	uint16_t cal_wrod3;		// 16, 17
	uint16_t cal_wrod4;		// 18, 19
	uint16_t intersematemp;	// 20, 21
	uint16_t pressure;		// 22, 23
	uint16_t accel_x;		// 24, 25
	uint16_t accel_y;		// 26, 27
} MTS400DataMsg;	// Size = 28bytes

typedef struct MTS310DataMsg {
	uint16_t vref;			// 0, 1
	uint16_t thermistor;	// 2, 3
	uint16_t light;			// 4, 5
	uint16_t mic;			// 6, 7
	uint16_t accelX;		// 8, 9
	uint16_t accelY;		// 10, 11
	uint16_t magX;			// 12, 13
	uint16_t magY;			// 14, 15
	uint16_t strength;		// 16, 17
} MTS310DataMsg;

typedef MTS400DataMsg * MTS400DataMsgPtr;
typedef MTS310DataMsg * MTS310DataMsgPtr;
