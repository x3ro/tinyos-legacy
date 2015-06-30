enum{
	RECEIVING,
    NOT_RECEIVING
};

enum{
	AM_ATMEGA8RESET=190,
	AM_SENSITIVITYMSG=195,
	AM_TOF=196,
	AM_CHIRPMSG=197,
	AM_TRANSMITMODEMSG=199,
	AM_TIMESTAMPMSG=198
};

enum{
	LEN_SENSITIVITY=1,
	LEN_CHIRPMSG=2,
	LEN_TRANSMITMODEMSG=1,
	LEN_TIMESTAMPMSG=4
};

enum{TRANSMIT,RECEIVE};

typedef struct TransmitModeMsg{
	uint8_t mode;
} TransmitModeMsg;

typedef struct TimestampMsg{
	uint16_t transmitterId;
	uint16_t timestamp;
} TimestampMsg;

typedef struct ChirpMsg{
	uint16_t transmitterId;
} ChirpMsg;

typedef struct SensitivityMsg{
	uint8_t potLevel;
} SensitivityMsg;







