#include "tos.h"
#include "VIBES_LOGGER.h"

#define BASE_STATION_REPLY_TYPE 10
#define MAX_ADC_COUNT 1000

// Data stored for each accel sample
// 6 bytes
typedef struct {
 int timestamp;
 int x_filt;
 int y_filt;
}vibes_data_struct;


// Size of buffer written to LOGGER
// Set LOG_ENTRY_SIZE to 64 in LOGGER for this to work
// Padding to fit to packet
typedef struct {
  vibes_data_struct vdata[10];
  unsigned char padding[4];
}log_data_struct;

#define TOS_FRAME_TYPE VIBES_LOGGER_frame
TOS_FRAME_BEGIN(VIBES_LOGGER_frame) 
{
  char send_pending;
  TOS_Msg msg;

  unsigned int log_line;
  int read_line;
  
  unsigned int adc_count;

  unsigned vcount;

  char eeprom_pending;
  char eeprom_send_pending;
  
  log_data_struct log_data;

}
TOS_FRAME_END(VIBES_LOGGER_frame);

/*
  This does not really have to be a task...but doesn't hurt
*/
TOS_TASK(Read_Next_Log_Task) {
    VAR(read_line)++;
    TOS_CALL_COMMAND(VIBES_LOGGER_READ_LOG)(VAR(read_line), (char*)&VAR(log_data));
    return;
}

char TOS_COMMAND(VIBES_LOGGER_INIT)(void) {
  VAR(log_line)=0;
  VAR(send_pending)=0;
  VAR(eeprom_pending)=0;
  
  VAR(adc_count) = 0;
  VAR(vcount) = 0;
  VAR(eeprom_send_pending) = 0;
  
  TOS_CALL_COMMAND(VIBES_LOGGER_CLOCK_INIT)(tick64ps);    /* set clock interval */

  TOS_CALL_COMMAND(VIBES_LOGGER_ADC_INIT)();

  TOS_CALL_COMMAND(VIBES_LOGGER_SUB_LOGGER_INIT)();
  return TOS_CALL_COMMAND(VIBES_LOGGER_SUB_COMM_INIT)();
}

char TOS_COMMAND(VIBES_LOGGER_START)(void) 
{
  return 1;
}

/* Clock Event Handler: 
   signaled at end of each clock interval.

 */

void TOS_EVENT(VIBES_LOGGER_CLOCK_EVENT)(){
  char temp;
  if (++VAR(adc_count) < MAX_ADC_COUNT) {
	//turn on the red led while data is being read.
	CLR_RED_LED_PIN();
    	temp = TOS_CALL_COMMAND(VIBES_LOGGER_GET_DATA)(2); /* start data reading */
  }
}

char TOS_EVENT(VIBES_LOGGER_DATA_EVENT_2)(int data){
  VAR(log_data).vdata[VAR(vcount)].x_filt = data;
  return TOS_CALL_COMMAND(VIBES_LOGGER_GET_DATA)(3);
}

/*  VIBES_LOGGER_DATA_EVENT(data):
    handler for subsystem data event, fired when data ready.
    Put int data in a broadcast message to handler 0.
    Post msg.
 */
char TOS_EVENT(VIBES_LOGGER_DATA_EVENT_3)(int data){
  // log data into EEPROM
  if( ! VAR(eeprom_pending)) {
    VAR(log_data).vdata[VAR(vcount)].y_filt = data;
    
    SET_RED_LED_PIN();
    
    if (++VAR(vcount) == 10) {
      VAR(vcount) = 0;
      if (TOS_CALL_COMMAND(VIBES_LOGGER_APPEND_LOG)((char*)&VAR(log_data))) {
	CLR_GREEN_LED_PIN();
	VAR(eeprom_pending)=1;
      }
    }
  }
  return 1;
}


//Request for an EEPROM entry 
TOS_MsgPtr TOS_MSG_EVENT(VIBES_LOGGER_RX_REQUEST)(TOS_MsgPtr msgptr)
{
  CLR_RED_LED_PIN();
  
  // Check to see if message is corrupted
  if( !VAR(eeprom_pending)) {
    VAR(eeprom_pending)=1;
    
    CLR_GREEN_LED_PIN();

    VAR(read_line)=0;
    TOS_CALL_COMMAND(VIBES_LOGGER_READ_LOG)(VAR(read_line), (char*)&VAR(log_data));
  }
  return msgptr;
}


char TOS_EVENT(VIBES_LOGGER_MSG_SEND_DONE)(TOS_MsgPtr sent_msgptr)
{
  int i;
  char *packet;

  if( VAR(send_pending) && sent_msgptr==&VAR(msg)) {
    VAR(send_pending)=0;
    SET_RED_LED_PIN();
    
    if (VAR(eeprom_send_pending)==1) {
      VAR(send_pending)=1;
      
      VAR(eeprom_send_pending) = 0;
    
      packet = (char*)&VAR(log_data);
      for (i=0; i<30; i++)
	VAR(msg).data[i] = packet[30+i];

      if(TOS_CALL_COMMAND(VIBES_LOGGER_SEND_MSG)(TOS_BCAST_ADDR,
						 BASE_STATION_REPLY_TYPE,
						 &VAR(msg) ) ) {
	CLR_RED_LED_PIN();
      } else {
	SET_RED_LED_PIN();
      }
    } else {
      TOS_POST_TASK(Read_Next_Log_Task);
    }
    return 1;
  }
  return 0;
}


// EEPROM events
char TOS_EVENT(VIBES_LOGGER_APPEND_LOG_DONE)(char success) {
  VAR(eeprom_pending)=0;
  SET_GREEN_LED_PIN();
  return 1;
}

char TOS_EVENT(VIBES_LOGGER_READ_LOG_DONE)(char* packet, char success) {
  int i;
  
  VAR(eeprom_pending)=0;

  SET_GREEN_LED_PIN();
  
  // send data back to the destination 
  if( ! VAR(send_pending) ) {
    VAR(send_pending)=1;
    
    VAR(eeprom_send_pending) = 1;
    
    for (i=0; i<30; i++)
      VAR(msg).data[i] = packet[i];

    if(TOS_CALL_COMMAND(VIBES_LOGGER_SEND_MSG)(TOS_BCAST_ADDR,
					  BASE_STATION_REPLY_TYPE,
					  &VAR(msg) ) ) {
      CLR_RED_LED_PIN();
    } else {
      SET_RED_LED_PIN();
    }
  }
  return 1;
}













