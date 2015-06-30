enum {
	AM_FTPSIMPLECMD = 100,
	AM_FTPSIMPLENAME = 101,
	AM_FTPSIMPLEDATA = 102,
	AM_FTPSIMPLEACK = 103
};
enum {
	FILENAMESIZE = 20,
	DATAPACKETSIZE = 26
};
enum {
	CMD_DELETE = 1,
	CMD_CLEAR = 2,
	CMD_WRITE = 3,
	CMD_GETNAME = 4,
	CMD_GETFILE = 5
};


typedef struct FtpSimpleCmd {
	
	uint8_t action;
	
} FtpSimpleCmd;

typedef struct FtpSimpleName {
	uint8_t sourceAddr;
	uint16_t fileLength;
	uint8_t fileName[FILENAMESIZE];
} FtpSimpleName; // Size = 23

typedef struct FtpSimpleData {
	uint8_t sourceAddr;
	uint16_t sequenceNo;
	uint8_t data[DATAPACKETSIZE];
} FtpSimpleData; // Size = 29

typedef struct FtpSimpleAck {
	uint8_t sourceAddr;
	uint16_t sequenceNo;
	uint8_t done;
	uint8_t ackOK;
} FtpSimpleAck; // Size = 4

