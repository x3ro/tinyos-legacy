enum {
	AM_BWMSG = 1,
};

typedef struct BWMsg {
	uint8_t expId;
	uint8_t destAddr;
	uint16_t startCount;
	uint16_t endTotalCount;
	uint16_t endGoodCount;
	uint32_t sigStrength;
	uint32_t sendTime;
	uint32_t receiveTime;
	uint8_t reserved[9];
} BWMsg;



		
