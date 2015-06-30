/*									tab:4
 * ACCEL_REC.c - Samples accelerometer readings in both the x- and y- 
 * directions.  When prompted from the base, begins to save readings
 * to the eeprom.  Stops saving when prompted by the base to stop.  
 * Sends data saved in eeprom to base when prompted to do so.  
 *
 *
 * History:   modified 8/19/2000 
/* Crossbow
* Rev History:
* Date:         Author:  Comments:
* Sept 26,2001  Asb      Added documentation to original TOS code (JMitrani).
*               Asb      Changed EPROM storage     
*
*/

#include "tos.h"
#include "dbg.h"
#include "ACCEL_REC.h"

#define BASE_STATION_REQ 6
#define DATA_PORT_X 2
#define DATA_PORT_Y 3
#define PCKT_SAMPLES 7    //# of samples (x,y) in a xmitted data packet
#define EPROM_WSAMPLES 4  //# of samples to buffer before writing to EPROM
//Defines for commands from base station
#define CMD_STOP_SMPL    0    // stop sampling
#define CMD_START_WRITE  1    // sampl and write to eprom
#define CMD_STATUS       8    // xmit status
#define CMD_SS_READ      9    // read a snap-shot of the data
#define CMD_START_READ   32   // start reading data from ERPOM
#define CMD_TEST_1       120  // test message
#define CMD_RST          60   // reboot system

/*  Data stored for each sample reading */
typedef struct {
  int x_val;  //2 bytes
  int y_val;  //2 bytes
}accel_data_struct;


/* Writing/Reading EPROM 
* LOGGER.C writes in blocks of 16 bytes (4 x-y samples); eeprom_wline incs by 16 bytes each
*                 32Kbytes/16 bytes => 2K lines
*          reads  in blocks of 4 bytes (1 x-y sample);  eeprom_rline incs by 4  bytes each
*                 32Kbytes/4 bytes => 8K lines
* at end of sampling:
*  # of eprom block     written = eeprom_wline
*  # of eprom blocks to read    = 4 * eeprom_wLine
* Takes 5 msec to write 16 (max of 64) bytes in page mode.
*/


typedef struct {
   accel_data_struct adata[EPROM_WSAMPLES];   // 4 data points per eprom write => 16 bytes
}log_data_struct;


/* Define the TOS Frame and variables it owns */

#define TOS_FRAME_TYPE ACCEL_REC_frame
TOS_FRAME_BEGIN(ACCEL_REC_frame) 
{
  char seq_old;         // sequence # of radio messages
  char fld_hops;        // number of hops from last flooding broadcast
   
  char send_pending;
  char eeprom_pending;  //0 if EPROM available for write 
  
  TOS_Msg msg;          //double buffer
  TOS_MsgPtr ptrmsg;   // message ptr
  char msg_pending;    // true if message pending
  char msg_cmd;
  
  int read_line;          //line in eeprom read from
  
  char btest;           //true if test pattern is to be used
  int itest;            //test pattern incrementer
  
//  char bRst;            //true if system is to be reset  

  char logger_on;       //enabled to store to EPROM
  char send_data;   
  char samp_on;
  int eeprom_wline;      //Last eprom write address
  int eeprom_rline;      //Last eprom read address
  
  int pckt_cnt;              //number of data packets xmitted
  char smpl_cnt;         //count # of samples xmitted
  
  unsigned int adc_count;
  unsigned int  acount;     // Counts # of x,y samples in uart pckt, also number of bytes before a write
  
  char cTimeStamp[4];            //32 bit time stamp from base station
  
  
  log_data_struct log_data;
}
TOS_FRAME_END(ACCEL_REC_frame);


//*****************************************************************************
// ACCEL_REC_INIT
// - init all states
//*****************************************************************************
char TOS_COMMAND(ACCEL_REC_INIT)(void) {
 int i;
	VAR(seq_old) = 0;           
	VAR(send_pending)=0;
	VAR(fld_hops) = 0;
  
  VAR(logger_on) = 0;          //no logging after init

  VAR(send_data) = 0;
  VAR(samp_on) = 1;            //start sampling on init
  VAR(eeprom_wline) = 0;
  VAR(eeprom_pending) = 0;     //EPROM available to write
  VAR(adc_count) = 0;
  VAR(acount) = 0;
  VAR(pckt_cnt) = 0;            
  VAR(smpl_cnt) = 0;
  VAR(msg_cmd) = 0;
  VAR(itest) = 0;
  VAR(btest) = 1;             //no test pattern
  VAR(cTimeStamp[0]) = 0;       //reset time stamp bytes
  VAR(cTimeStamp[1]) = 0; 
  VAR(cTimeStamp[2]) = 0; 
  VAR(cTimeStamp[3]) = 0; 

  VAR(ptrmsg) = &VAR(msg);    //init pointer to buffer
  VAR(msg_pending) = 0;       //no message pending
  //VAR(bRst) = 0;

  TOS_CALL_COMMAND(ACCEL_REC_ADC_INIT)();        //initialize the ADC
  TOS_CALL_COMMAND(ACCEL_REC_SUB_INIT)();        //initialize LOGGER and I2C_OBJ


  //  TOS_CALL_COMMAND(ACCEL_REC_CLOCK_INIT)(128, 2);
//   TOS_CALL_COMMAND(ACCEL_REC_CLOCK_INIT)(82, 2); //rate at whick clock fires to collect accelerometer readings (50 Hz) 
  TOS_CALL_COMMAND(ACCEL_REC_CLOCK_INIT)(64, 2); //rate at whick clock fires to collect accelerometer readings (64 Hz) 

  SET_PW2_PIN();

  SET_RED_LED_PIN();     //clr LED 
  printf("ACCEL_REC is initialized\n");
  dbg(DBG_BOOT, ("ACCEL_REC is initialized.\n"));
  
  
  i = defaultMsgSize(&VAR(msg));
  dbg(DBG_BOOT, ("ACCEL_REC: MESSAGE LENGTH %d\n" , i));
  
  return 1;
}

//*****************************************************************************
// ACCEL_REC_START
// - send the start command
//*****************************************************************************
char TOS_COMMAND(ACCEL_REC_START)(void){
  return 1;
}

//*****************************************************************************
// ACCEL_REC_CLOCK_EVENT
// - clock triggered
// - check if sampling enabled
// - start ADC for x accel
//*****************************************************************************
void TOS_EVENT(ACCEL_REC_CLOCK_EVENT)(){
	if(VAR(samp_on) == 0){
		SET_RED_LED_PIN();                                 //led off		
		return;                    //break loop if logger is reading from eeprom  
    }
    TOS_CALL_COMMAND(RED_LED_TOGGLE)();
	TOS_CALL_COMMAND(ACCEL_REC_GET_DATA)(DATA_PORT_X); //start data reading from ADC port 2(x-axis) 
}

//*****************************************************************************
// ACCEL_REC_DATA_EVENT_2
// - x axis ADC data ready
// - start ADC for y accel
//*****************************************************************************

char TOS_EVENT(ACCEL_REC_DATA_EVENT_2)(int data){
  
    //printf("Got x reading from accelerometer\n");
	
    VAR(log_data).adata[VAR(acount)].x_val = data;
	
    TOS_CALL_COMMAND(ACCEL_REC_GET_DATA)(DATA_PORT_Y); //get data from ADC port 3 
    return 1;  
}

//*****************************************************************************
// ACCEL_REC_DATA_EVENT_3
// - y axis ADC data ready
// - if logging and not writing to eprom then start writing to EPROM
//*****************************************************************************
char TOS_EVENT(ACCEL_REC_DATA_EVENT_3)(int data){
    //printf("Got y reading from accelerometer\n");
  
  
    VAR(log_data).adata[VAR(acount)].y_val = data;
  
//	if (VAR(btest) == 1){                                       //use test pattern?
//	  VAR(log_data).adata[VAR(acount)].x_val = VAR(itest);
//	  VAR(log_data).adata[VAR(acount)].y_val = VAR(itest)++;
//	  if (VAR(itest) > 1023) VAR(itest) = 0;
//    }

	VAR(acount)++;
	if (VAR(acount) == EPROM_WSAMPLES){

     if(VAR(logger_on) == 1 && VAR(eeprom_pending)==0){
       VAR(eeprom_pending)=1;
       VAR(eeprom_wline) ++;
       TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();		
       TOS_CALL_COMMAND(ACCEL_REC_WRITE_LOG)((char*)&(VAR(log_data)));
     }
	 VAR(acount) = 0;
	}
  return 1;  
}
//*****************************************************************************
// ACCEL_REC_EVENT_LOG_DONE
// - logger finished writing data to eprom
//*****************************************************************************
char TOS_EVENT(ACCEL_REC_WRITE_LOG_DONE)(char success){
  VAR(eeprom_pending)=0;
  printf("LOG_WRITE_DONE\n");
  //CLR_GREEN_LED_PIN();                    //turn-on led
  return 1; 
}



  //*****************************************************************************
// BCAST_msg
// - broadcast messages from base station
// - 9th byte in packet is command number (CN)
// BroadCast Messages:
// - 
// If message is broadcast message then:msgptr->addr = TOS_BCAST_ADDR
// - msgptr->data[0] = seqno (1..255), sequence number of  the message
// - msgptr->data[1] = hops, # of hops, each mote increments this before retransmitting
// - seqno_old is sequence number of previous message
//*****************************************************************************
TOS_MsgPtr TOS_MSG_EVENT(BCAST_msg)(TOS_MsgPtr msgptr){
  int i;
//  TOS_MsgPtr tmp = msgptr;    //temporary message pointer 
  i = 1;
  return msgptr;
}


//*****************************************************************************
// ACCEL_REC_msg
// - message from base station
// - 9th byte in packet is command number (CN)
// BroadCast Messages:
// - 
// If message is broadcast message then:msgptr->addr = TOS_BCAST_ADDR
// - msgptr->data[0] = seqno (1..255), sequence number of  the message
// - msgptr->data[1] = hops, # of hops, each mote increments this before retransmitting
// - seqno_old is sequence number of previous message
//*****************************************************************************
TOS_MsgPtr TOS_MSG_EVENT(ACCEL_REC_msg)(TOS_MsgPtr msgptr){
  int i,iCnt;
  TOS_MsgPtr tmp = msgptr;    //temporary message pointer 
  int (*ptr)(void);

  if (VAR(msg_pending)) return msgptr;

  //reboot command
  if((msgptr->data[4] == CMD_RST) && (msgptr->addr == TOS_LOCAL_ADDRESS)){        
	    ptr = 0;
		ptr();
//		VAR(bRst) = 1;                        //reset after broadcast message completed	 
	}//reboot

  
  
  //start reading data
// data[5] = 0         : xmit all eprom packets, starting at EPROM address 0
//         = 1         : xmit a block of  packets
// data[6,7] = EPROM address to start reading from if data[5] > 0
//     [6]   = lo byte
//     [7]   = hi byte
// data[8,9] = Number of samples (x-y) to xmit
//     [8]   = lo byte
//     [9]   = hi byte
  if((msgptr->data[4] == CMD_START_READ) && (msgptr->addr == TOS_LOCAL_ADDRESS)){
      for (i = 10; i <= 20; i++){
	    if (msgptr->data[i] != 0x55) return msgptr;
	  }
	  
	  
	  CLR_YELLOW_LED_PIN();
//    if (msgptr->data[5] == 0){              //read all of EPROM
		VAR(read_line) = 0; 
        VAR(eeprom_rline) = VAR(eeprom_wline) << 2;   //read until last eeprom write address
 //   }	
//	else {                                      //read part of EPROM
//		VAR(read_line) = (msgptr->data[7] << 8) & msgptr->data[6];  //start reading here
//	    VAR(eeprom_rline) = (msgptr->data[8] << 8) & msgptr->data[9];	//!!DOESN"T TAKE CARE OF WRAP AROUND!!!!!	
//	}
	VAR(acount) = 0;
	VAR(msg_cmd) = 0;                   //read out
    VAR(pckt_cnt) = 0;                  //packets xmitted
    VAR(smpl_cnt) = 0;                  //samples xmitted
    TOS_CALL_COMMAND(ACCEL_REC_READ_LOG)(VAR(read_line), (char*)&VAR(log_data)); 
    return msgptr;
  }
//============================= BROADCAST MESSAGES ============================          
//if message is a broadcast message then 1) execute and 2)rebroadcast it
//data[0]: sequence # (seq#) : 1..255. 
//       : if (seq# > seq_old) then rebroadcast and execute command
//       : if (seq# < seq_old) then reset seq_old to seq# and rebroadcast
//data[1] is hop #; increment before rebroadcast
//data[3] is mote_id
//data[4] is command number
//NOTE: ALL FOLLOWING CMDS THAT XMIT BROADCAST MESSAGES (ex. status) 
//      MUST NOT CHANGE data[3] & data[4]
//============================= BROADCAST MESSAGES ============================          
  if(msgptr->addr == TOS_BCAST_ADDR){  
    if (msgptr->data[0] < VAR(seq_old)) VAR(seq_old) = msgptr->data[0] - 1;
	if ((msgptr->data[0] - VAR(seq_old)) > 0) { 
    VAR(seq_old) = msgptr->data[0];   //update sequence #
	VAR(msg_cmd) = 1;
    VAR(fld_hops) = msgptr->data[1]; 
	msgptr->data[1]++;   //inc hops

//start recording
//if data[5] = 1 then use test pattern to write
    if(msgptr->data[4] == CMD_START_WRITE){    

//	  if(msgptr->data[5] == 1){
//	    VAR(btest) = 1;                 //disable for now
//        VAR(itest) = 0;            //reset test pattern
//	  }  
//	  else{  
	    //VAR(btest) = 0;
//	  }
        
//	    VAR(acount) = 0;   
	    VAR(logger_on) = 1;        //enable logging
	    VAR(samp_on) = 1;          //enable sampling
        VAR(eeprom_wline) = 0;      //reset eprom address
        VAR(eeprom_pending)=0;     //reset any pending eprom writes    
        
	
	}  //if start
//stop recording
//data[5] is lo byte of time stamp from base station
//data[8] is hi byte of time stamp from base station
    else if(msgptr->data[4] == CMD_STOP_SMPL){
	    if (VAR(logger_on) == 1){                     //set time stamp if logging in progress
          VAR(cTimeStamp[0]) = msgptr->data[5];
	      VAR(cTimeStamp[1]) = msgptr->data[6];
	      VAR(cTimeStamp[2]) = msgptr->data[7];
	      VAR(cTimeStamp[3]) = msgptr->data[8];
		}
          VAR(logger_on) = 0;        //disable logging
          VAR(samp_on) = 0;          //disable sampling
          SET_GREEN_LED_PIN();       //clr led
	} //if stop
//xmit status
    else if((msgptr->data[4] == CMD_STATUS ) && (msgptr->data[3] == TOS_LOCAL_ADDRESS )){
          VAR(ptrmsg)->data[0] = ++VAR(seq_old); 
		  VAR(ptrmsg)->data[0]    =  ++VAR(seq_old);
		  VAR(ptrmsg)->data[1]    =  0;                     // hops
  	      VAR(ptrmsg)->data[3]    =  TOS_LOCAL_ADDRESS;
	      VAR(ptrmsg)->data[4]    =  CMD_STATUS;
		  VAR(ptrmsg)->data[5]    =  TOS_LOCAL_ADDRESS;
	      VAR(ptrmsg)->data[6]  =  VAR(logger_on);                    //logging status
          VAR(ptrmsg)->data[7]  =  VAR(samp_on);                     //sampling status
          VAR(ptrmsg)->data[8]  = (VAR(eeprom_wline) << 2) & 0xff;  //samples recorded,lower byte
          VAR(ptrmsg)->data[9]  =  VAR(eeprom_wline) >> 6;          //samples recorded,upper byte
          VAR(ptrmsg)->data[10]  =  VAR(cTimeStamp[0]);
	      VAR(ptrmsg)->data[11]  =  VAR(cTimeStamp[1]);
	      VAR(ptrmsg)->data[12]  =  VAR(cTimeStamp[2]);
	      VAR(ptrmsg)->data[13]  =  VAR(cTimeStamp[3]);
          VAR(ptrmsg)->data[14]  =  VAR(fld_hops);                    //# of hops from last broadcast message
          
		  //VAR(ptrmsg)->data[20]  =  msgptr->data[28];
          //VAR(ptrmsg)->data[21]  =  msgptr->data[29];

		    //VAR(msg).data[i++] =  VAR(seq_old);                    // last sequence number
	      VAR(msg_cmd) = 1;                   //command message is xmitting
          VAR(msg_pending) = 1;  
		  VAR(msg_pending) = TOS_CALL_COMMAND(ACCEL_REC_SEND_MSG)(TOS_BCAST_ADDR, BASE_STATION_REQ, VAR(ptrmsg));
 		  return msgptr;		
	} // if status

 //xmit a snap-shot of the data
    else if((msgptr->data[4] == CMD_SS_READ  ) && (msgptr->data[3] == TOS_LOCAL_ADDRESS)){
	        i = 0;
	        iCnt = 0;
	        VAR(ptrmsg)->data[0]    =  ++VAR(seq_old);
		    VAR(ptrmsg)->data[1]    =  0;                     // hops
  	        VAR(ptrmsg)->data[3]    =  TOS_LOCAL_ADDRESS;
	        VAR(ptrmsg)->data[4]    =  CMD_SS_READ;
		    VAR(ptrmsg)->data[5]    =  TOS_LOCAL_ADDRESS;
	        while (iCnt < (EPROM_WSAMPLES << 2)){
              VAR(ptrmsg)->data[6+iCnt++] =  VAR(log_data).adata[i].x_val & 0xff;  
              VAR(ptrmsg)->data[6+iCnt++] =  VAR(log_data).adata[i].x_val >> 8;
              VAR(ptrmsg)->data[6+iCnt++] =  VAR(log_data).adata[i].y_val & 0xff;  
	          VAR(ptrmsg)->data[6+iCnt++] =  VAR(log_data).adata[i].y_val >> 8;
              i++;
	}  
    VAR(msg_cmd) = 1;                   //command message is xmitting
    VAR(msg_pending) = 1;  
	if(TOS_CALL_COMMAND(ACCEL_REC_SEND_MSG)(TOS_BCAST_ADDR, BASE_STATION_REQ, &VAR(msg)));
    return msgptr;
 }
 TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
 tmp = VAR(ptrmsg);     
 VAR(ptrmsg) = msgptr;    //hold onto the buffer for next message
 VAR(msg_pending) = TOS_CALL_COMMAND(ACCEL_REC_SEND_MSG)(TOS_BCAST_ADDR, BASE_STATION_REQ, msgptr);		
 return tmp;   //return new buffer 	
}
} // if broadcast
  return msgptr;
}

//*****************************************************************************
// Read_Next_Log_Task
// - increment to next eprom line
// - check to see if we've read all of memory, if so done
// - Read next line of data from eprom
// - Data returned in log_data var
//*****************************************************************************
TOS_TASK(Read_Next_Log_Task){
  VAR(read_line)++;
  if(VAR(read_line) == VAR(eeprom_rline)-1){
    return;
  }else{
    TOS_CALL_COMMAND(ACCEL_REC_READ_LOG)(VAR(read_line), (char*)&VAR(log_data));
  }
  return;
}
//*****************************************************************************
// ACCEL_REC_READ_LOG_DONE
// - Reading from eprom is complete
// - each event returns EPROM_WSAMPLES samples of data for x and y 
// - xmit packet 
//*****************************************************************************
char TOS_EVENT(ACCEL_REC_READ_LOG_DONE)(char* packet, char success){
  
  int i;
  
  printf("LOG_READ_DONE\n");
  TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
 
  
  if (VAR(acount) == 0){                                    //insert packet count  
     VAR(pckt_cnt)++;                                          //inc packet count
	 VAR(ptrmsg)->data[0] = VAR(pckt_cnt) & 0xff;               //# of packets xmitted
     VAR(ptrmsg)->data[1] = VAR(pckt_cnt) >>8; 
     VAR(acount) = VAR(acount) + 2;
  }
  for (i= 0; i< 4; i++){                              //insert data
   	 VAR(ptrmsg)->data[VAR(acount)] = packet[i];
  	 VAR(acount)++;
  }
  VAR(smpl_cnt)++;
  if (VAR(smpl_cnt) < PCKT_SAMPLES){                              //get more data
     TOS_POST_TASK(Read_Next_Log_Task);
     return 1;
  }  
  VAR(msg).strength = TOS_LOCAL_ADDRESS;              //?????
  
  VAR(msg_pending) = 1; 
  if(TOS_CALL_COMMAND(ACCEL_REC_SEND_MSG)(TOS_UART_ADDR, BASE_STATION_REQ, VAR(ptrmsg)));
  return 1;
}
//*****************************************************************************
// ACCEL_REC_SUB_MESG_SEND_DONE
// - xmit message complete
//*****************************************************************************
char TOS_EVENT(ACCEL_REC_MSG_SEND_DONE)(TOS_MsgPtr sent_msgptr){
    
    printf("Message has been sent\n");

    VAR(msg_pending) = 0;  //broadcast message complete
    VAR(ptrmsg) = sent_msgptr;    //hold onto the buffer for next message

  if (VAR(msg_cmd) == 0){
    VAR(smpl_cnt) = 0;                       
	VAR(acount) = 0;                        //reset sample count
	TOS_POST_TASK(Read_Next_Log_Task);
    return 1;
  }
  else{
//	  if(sent_msgptr == VAR(ptrmsg)) 
	  
	  VAR(msg_cmd) = 0;                 //command message complete
  }   
  return 1;
}

