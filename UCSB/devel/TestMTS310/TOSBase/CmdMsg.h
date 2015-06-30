
// If the sensorboard is of type MTS300
// Comment out the following line
//#define MTS300

enum {
	AM_SENSORMSG310 = 0,
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

typedef struct MTS310DataMsg {
	uint16_t vref;			// 0, 1
	uint16_t temp;			// 2, 3
	uint16_t light;			// 4, 5
	uint16_t mic;			// 6, 7
	uint16_t accelX;			// 8, 9
	uint16_t accelY;			// 10, 11
	uint16_t magX;			// 12, 13
	uint16_t magY;			// 14, 15
	uint16_t strength;		// 16, 17
} MTS310DataMsg;

typedef MTS310DataMsg * MTS310DataMsgPtr;

