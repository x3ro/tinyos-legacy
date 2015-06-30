/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	FTPSimpleM.nc
**
**	Purpose:	Module to allow users to transfer whole files
**				to mote, and read them back
**
**	Future:		Finish!!!!!
**
*********************************************************/
includes FTPMsgs;

module FTPSimpleM {
	provides interface StdControl;
	uses {
		interface StdControl as RadioControl;
		interface BareSendMsg as RadioSend;
		interface ReceiveMsg as RadioReceive; 
		
		//interface LoggerRead;
		//interface LoggerWrite;
		
		interface StdControl as EEPROMControl;
		interface EEPROMRead;
		interface EEPROMWrite;
		
		
		interface Timer;
		
		interface Leds;
	}
}
implementation {
	enum {
		FILENAMESIZE = 20,
		FILEDATASIZE = 26
	};
	enum {
		FILELENGTHOFFSET = 16,
		FILENAMEOFFSET = 20,
		FILEDATAOFFSET = 40
	};
	enum {
		OK = 0,
		WRITE_LENGTH = 1,
		WRITE_NAME = 2,
		WRITE_DATA = 3,
		READ_LENGTH = 11,
		READ_NAME = 12,
		READ_DATA = 13,
		GET_LENGTH = 21,
		GET_NAME = 22,
		CLEAR_FLASH = 31,
		CLEAR_LENGTH_NAME = 32
	};
	enum {
		NOTHING = 0,
		NAME_SUCCESS = 1,
		NAME_FAILURE = 2,
		DATA_SUCCESS = 3, 
		DATA_FAILURE = 4
	};
	
	TOS_MsgPtr RxMsg;
	TOS_MsgPtr TxMsg;
	TOS_Msg Msg;
	typedef struct ReadLogMsg {
		uint8_t fileName[20];
		uint8_t fileData[26];
		uint8_t fileLength[2];
	} ReadLogMsg;
	
	uint8_t clearMsg[2];
	uint8_t nameCounter;
	uint8_t dataCounter;
	uint16_t clearCounter;
	
	ReadLogMsg readMsg;
	ReadLogMsg *readLogMsg;
	uint16_t sequenceNo;
	uint8_t SuccessFlags;
	
	uint8_t FTPFlags;
	void clearReadLogMsg();
	void clearFlash();
	// Clear Memory before anything goes on
	
	command result_t StdControl.init() {
		SuccessFlags = NOTHING;
		FTPFlags = OK;
		Msg.length = 0;
		TxMsg = &Msg;
		sequenceNo = 0;
		clearMsg[0] = 0x00;
		clearMsg[1] = 0x00;
		readLogMsg = &readMsg;
		clearReadLogMsg();
		call EEPROMControl.init();	
		return rcombine(call RadioControl.init(), call Leds.init());
	}
	command result_t StdControl.start() {
		call EEPROMControl.start();
		return call RadioControl.start();
	}
	command result_t StdControl.stop() {
		call EEPROMControl.stop();
		return call RadioControl.stop();
	}
	void clearReadLogMsg() {
		uint8_t i;
		for(i=0; i < sizeof(readLogMsg->fileName); i++)
			readLogMsg->fileName[i] = 0;
		for(i=0; i < sizeof(readLogMsg->fileData); i++)
			readLogMsg->fileData[i] = 0;
		for(i=0; i < sizeof(readLogMsg->fileLength); i++)
			readLogMsg->fileLength[i] = 0;
		nameCounter = 0xfe;
		dataCounter = 0xfe;
	}
	
	void clearFlash() {
		clearCounter = 0;
		atomic FTPFlags = CLEAR_FLASH;
		call EEPROMWrite.startWrite();
		call EEPROMWrite.write(0, &clearMsg[0]);
	}
	void clearLengthName() {
		clearCounter = 0;
		atomic FTPFlags = CLEAR_LENGTH_NAME;
		call EEPROMWrite.startWrite();
		call EEPROMWrite.write(clearCounter, &clearMsg[0]);
	}
	task void SendNameMsg() {
		FtpSimpleName *namePacket;
		uint8_t i;
		namePacket = (struct FtpSimpleName *)TxMsg->data;
		
		TxMsg->addr = 0;
		TxMsg->type = AM_FTPSIMPLENAME;
		TxMsg->group = TOS_AM_GROUP;
		TxMsg->length = sizeof(FtpSimpleName);
		for(i=0; i < FILENAMESIZE; i++)
			namePacket->fileName[i] = readLogMsg->fileName[i];
			
		namePacket->fileLength = readLogMsg->fileLength[0] + (readLogMsg->fileLength[1] << 8);
		namePacket->sourceAddr = TOS_LOCAL_ADDRESS;
		
		if(call RadioSend.send(TxMsg))
			;
		//clearReadLogMsg();
	}
	
	
	task void ReadName() {
		//FtpSimpleName *namePacket;
		//namePacket = (struct FtpSimpleName *)TxMsg->data;
		if(call EEPROMRead.read(FILELENGTHOFFSET, &(readLogMsg->fileLength[0]))) 
			;
	}
	
	task void CmdInterpret() {
		FtpSimpleCmd * cmdPacket;
		cmdPacket = (struct FtpSimpleCmd *)RxMsg->data;
		if(FTPFlags == OK) {
			switch(cmdPacket->action) {
				case CMD_DELETE:
					break;
				case CMD_CLEAR:
					break;
				case CMD_WRITE:
					break;
				case CMD_GETNAME:
					atomic FTPFlags = GET_LENGTH;
					post ReadName();
					break;
				case CMD_GETFILE:
					atomic FTPFlags = READ_LENGTH;
					break;
				default:
			}				
		}
	}
	task void FileNameAck() {
		FtpSimpleAck * simpleAck = (struct FtpSimpleAck *)TxMsg->data;
		simpleAck->sourceAddr = TOS_LOCAL_ADDRESS;
		simpleAck->sequenceNo = -1;
		simpleAck->done = 0;
		if(SuccessFlags == NAME_SUCCESS)
			simpleAck->ackOK = 1;
		else
			simpleAck->ackOK = 0;
		
		TxMsg->addr = 0;
		TxMsg->type = AM_FTPSIMPLEACK;
		TxMsg->length = sizeof(FtpSimpleAck);
		TxMsg->group = TOS_AM_GROUP;
		SuccessFlags = NOTHING;
		if(call RadioSend.send(TxMsg))
			;
		
	}
	task void FileDataAck() {
		FtpSimpleAck * simpleAck = (struct FtpSimpleAck *)TxMsg->data;
		simpleAck->sourceAddr = TOS_LOCAL_ADDRESS;
		simpleAck->sequenceNo = sequenceNo;
		simpleAck->done = 0;
		if(SuccessFlags == DATA_SUCCESS)
			simpleAck->ackOK = 1;
		else
			simpleAck->ackOK = 0;
		//call Leds.redToggle();
		
		TxMsg->addr = 0;
		TxMsg->type = AM_FTPSIMPLEACK;
		TxMsg->length = sizeof(FtpSimpleAck);
		TxMsg->group = TOS_AM_GROUP;
		SuccessFlags = NOTHING;
		FTPFlags = OK;
		if(call RadioSend.send(TxMsg))
			;
		
	}
	
	
	task void FileNameLog() {
		uint8_t i;
		FtpSimpleName *FTPName = (struct FtpSimpleName *)RxMsg->data;
		for(i = 0; i < FILENAMESIZE; i++)
			readLogMsg->fileName[i] = FTPName->fileName[i];
			
		readLogMsg->fileLength[0] = FTPName->fileLength & 0xff;
		readLogMsg->fileLength[1] = FTPName->fileLength >> 8;
		
		if(FTPFlags == OK && call EEPROMWrite.startWrite()) {
			atomic FTPFlags = WRITE_LENGTH;
			if(call EEPROMWrite.write(FILELENGTHOFFSET, &(readLogMsg->fileLength[0]))) {
				;
			}
		}
	}
	task void FileDataLog() {
		FtpSimpleData * dataPacket;
		uint16_t offset;
		uint8_t i;
		dataPacket = (struct FtpSimpleData *)RxMsg->data;
		sequenceNo = dataPacket->sequenceNo;
		// Not sure what to do if done with file transfer
		// Will work on that later.
		// Maybe create fileData of packet 0xFF bytes to write to flash
		for(i = 0; i < FILEDATASIZE; i++)
			readLogMsg->fileData[i] = dataPacket->data[i];
			
		// Calculate offset to write data into flash
		offset = (sequenceNo * FILEDATASIZE)+FILEDATAOFFSET;
		if(FTPFlags == OK && call EEPROMWrite.startWrite()) {
			atomic FTPFlags = WRITE_DATA;
			if(call EEPROMWrite.write(offset, &(readLogMsg->fileData[0])))
				;//call Leds.greenToggle();
		}	
	}
	task void RadioRcvdTask() {
		switch(RxMsg->type) {
			case(AM_FTPSIMPLECMD):
				call Leds.redToggle();
				post CmdInterpret();
				break;
			case(AM_FTPSIMPLENAME):
				//clearLengthName();
				post FileNameLog();
				break;
			case(AM_FTPSIMPLEDATA):
				post FileDataLog();
				break;
			case(AM_FTPSIMPLEACK):
				post FileDataAck();
				break;
			default:
				break;
		}
	}
	event result_t Timer.fired() {
		call Timer.stop();
		return SUCCESS;
	}
	
	
	event result_t EEPROMWrite.writeDone(uint8_t *buf){
		if(FTPFlags == WRITE_LENGTH) {
			call Leds.greenToggle();
			atomic FTPFlags = WRITE_NAME;
		}
		if(FTPFlags == WRITE_NAME) {
			nameCounter++;
			if(nameCounter == FILENAMESIZE) {
				SuccessFlags = NAME_SUCCESS;
				call EEPROMWrite.endWrite();
				atomic FTPFlags = OK;
				call Leds.yellowToggle();
				post FileNameAck();
			}else
				call EEPROMWrite.write(FILENAMEOFFSET+nameCounter, &(readLogMsg->fileName[nameCounter*2]));	
		}
		if(FTPFlags == WRITE_DATA) {
			dataCounter++;
			if(dataCounter == FILEDATASIZE) {
				call EEPROMWrite.endWrite();
				SuccessFlags = DATA_SUCCESS;
				atomic FTPFlags = OK;
				call Leds.redToggle();
				post FileDataAck();
			}else
				call EEPROMWrite.write(FILEDATAOFFSET+dataCounter, &(readLogMsg->fileData[dataCounter*2]));
		}
		if(FTPFlags == CLEAR_FLASH) {
			call Leds.redToggle();
			clearCounter++;
			if(clearCounter == 0xffff) {
				atomic FTPFlags = OK;	
				call Leds.redOff();
				call EEPROMWrite.endWrite();
				clearCounter = 0;
			}else {
				call EEPROMWrite.write(clearCounter, &clearMsg[0]);
			}
		}
		if(FTPFlags == CLEAR_LENGTH_NAME) {
			clearCounter++;
			if(clearCounter == 40) {
				atomic FTPFlags = OK;
				call EEPROMWrite.endWrite();
				clearCounter = 0;
			}else
				call EEPROMWrite.write(clearCounter, &clearMsg[0]);
		}
		return SUCCESS;
	}
	
	event result_t EEPROMRead.readDone(uint8_t *buf, result_t result) {
		if(FTPFlags == GET_LENGTH) {
			atomic FTPFlags = GET_NAME;
		}
		if(FTPFlags == GET_NAME) {
			nameCounter++;
			if(nameCounter == FILENAMESIZE) {
				atomic FTPFlags = OK;
				post SendNameMsg();
			}else {
				call EEPROMRead.read(FILENAMEOFFSET+nameCounter, &(readLogMsg->fileName[nameCounter*2]));
			}
			call Leds.yellowToggle();
		}else if(FTPFlags == READ_LENGTH) {
		}else if(FTPFlags == READ_NAME) {
		}else if(FTPFlags == READ_DATA) {
		}
		
		//clearReadLogMsg();
		return SUCCESS;
	}
	event result_t EEPROMWrite.endWriteDone(result_t result) {
		return SUCCESS;
	}
	event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr pMsg) {
		RxMsg = pMsg;
		//call Leds.yellowToggle();
		post RadioRcvdTask();		
		return pMsg;
	}
	event result_t RadioSend.sendDone(TOS_MsgPtr pMsg, result_t result) {
		//call Leds.greenToggle();
		TxMsg->length = 0;
		clearReadLogMsg();
		return SUCCESS;
	}
}