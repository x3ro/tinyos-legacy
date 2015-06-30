// $Id: ConsoleMsg.h,v 1.1.1.1 2005/12/15 22:40:29 cepett01 Exp $

/***									tab:4
 * - Description ----------------------------------------------------------
 * Message type created for simple console command messages.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.1.1 $
 * $Date: 2005/12/15 22:40:29 $
 * @author Chris Pettus
 * @author cepett01@gmail.google.com
 * ========================================================================
 */

enum {
  // This is limited by the TOSH_DATA_LENGTH in the AM.h
  // Though I do believe that it can be changed with
  // an environmental variable during compile.
  BUFFER_SIZE_CONSOLEMSG = 20
};

enum {
  LED_ON = 1,
  LED_OFF = 2,
  SEND_DATA  = 3,
  SERIAL_DATA = 4
};

// Format of the message sent from a mote to a base station
// running the java application.
typedef struct ConsoleMsg
{
    uint16_t sourceMoteID;
	uint16_t length;
	uint8_t msgType;
    uint8_t data[BUFFER_SIZE_CONSOLEMSG];
} ConsoleMsg_t;

// Format of the message received by the mote from a base
// station.
typedef struct ConsoleCmdMsg
{
	uint8_t seqno;
	uint8_t	hop_count;
    uint16_t source;
	uint16_t destaddr;
	uint8_t	cmdType;
	uint8_t length;
	uint8_t data[BUFFER_SIZE_CONSOLEMSG];
} ConsoleCmdMsg_t;

enum {
  AM_CONSOLEMSG = 11,
  AM_CONSOLECMDMSG = 33
};
