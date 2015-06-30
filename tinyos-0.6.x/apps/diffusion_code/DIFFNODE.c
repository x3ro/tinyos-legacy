/* A modified version of diffusion for code segment transmission */

/* NOTE: the following ifdefs are used:
 -IS_SENDER: node is a sender (also called supernode). It has the entire
 file from the beginning
 -IS_RECEIVER: node is a receiver. It doesn't have the file but asks for it
 (sends interest)
 If none of the above is defined, node is an intermediate. It doesn't have
 the file but will store pieces that arrive and will reply to interests
*/


#include "tos.h"
#include "DIFFNODE.h"

#include <inttypes.h>
#include <string.h>
#include "DIFFNODE.inc"

#include "DiffNodeInc/DiffTable.inc"
#include "DiffNodeInc/DataCache.inc"
#include "DiffNodeInc/InterestMessage.inc"
#include "DiffNodeInc/DataMessage.inc"
#include "DiffNodeInc/LocalCode.inc"

#define EXPLINT_TIMER	4	
#define DUMP_TIMER 60


static inline void td_expired();
static inline void tcheck_expired();
static inline void texplint_expired();
static inline void tdump_expired();
static inline void tstart_expired();
void flip_error_led();
void flip_tx_led();
void flip_rx_led();
void sendExploratoryInterest();
void sendReinforcement();
static inline void createInterest(InterestMessage *msg, uint8_t expiration);
void frwdData(TOS_MsgPtr datMsg);
void checkData();
uint8_t produceData(GradientEntry * curGrad, uint8_t GradId); 
uint8_t checkCodeTable();
char checkForwarding();
static inline void create_dump_msg(struct dump_msg *msg);
static inline char checkInterest(TOS_MsgPtr intMsg);

//uint8_t haveData(uint8_t codeId, uint8_t frag);

TOS_FRAME_BEGIN(DIFFNODE_frame)
{
	uint8_t	 x_loc, y_loc;
	uint32_t seqNum;

	uint8_t	 dataChooser;
	uint8_t	 tempData, photoData;

	uint8_t	clockDiv;
	uint8_t lCodeId;
	uint8_t lMinRange;
	uint8_t lMaxRange;

	char error_led_state;
	char tx_led_state;
	char rx_led_state;
	char uart_to_host_busy;

	Timer Td;
	Timer Tcheck;
	Timer Texplint;
	Timer Tdump;
	Timer Tstart;

	TOS_Msg tos_dataMsg;
	TOS_Msg tos_intMsg;

	TOS_Msg uart_pkt;

	/* Associative array
	 * key: gradient ID
	 * result: next segment pointer, as an offset of minRange
	*/ 
	uint8_t GradIdTable[MAX_GRADIENTS];

	struct Code LocalCodeTable[MAX_CODES];

	/* requested stuff */
	uint8_t rCodeId;
	uint8_t rMinRange;
	uint8_t rMaxRange;

	uint8_t interestTime;

	uint16_t explint_sent;
	uint16_t reinfs_sent;
	uint16_t total_data_sent;
	uint16_t local_data_sent;
	uint16_t explint_rcvd;
	uint16_t reinfs_rcvd;
	uint16_t datapkts_rcvd;
	uint8_t frags_received;
	uint8_t last_source;
	uint8_t num_sources;

}
TOS_FRAME_END(DIFFNODE_frame);


/* UART Xmit task */
/* Currently unused */
TOS_TASK(DIFFNODE_UART_DUMP)
{
	if (VAR(uart_to_host_busy)==1) {
		return;
	}

	memset(&VAR(uart_pkt), 0, sizeof(TOS_Msg));
	VAR(uart_pkt).type=DIFFNODE_DUMP;
	VAR(uart_pkt).addr=TOS_LOCAL_ADDRESS;
	VAR(uart_pkt).group=DEFAULT_LOCAL_GROUP;

	create_dump_msg((struct dump_msg *)(VAR(uart_pkt).data));
	if (TOS_CALL_COMMAND(DIFFNODE_UART_TX_MSG)(&(VAR(uart_pkt)))==1) {
		VAR(uart_to_host_busy)=1;
	}

}

/* TIMER TASKS */
/* Check timer task */
TOS_TASK(DIFFNODE_CHECK_TIMER_TASK)
{
	if (TOS_CALL_COMMAND(DIFFNODE_ADD_TIMER)
		(&VAR(Tcheck), 
		((VAR(interestTime)+EXPLINT_TIMER)*timer1ps*DIFF_RATE))==0) {
		TOS_POST_TASK(DIFFNODE_CHECK_TIMER_TASK);
	}
}

/* Interest timer task */
TOS_TASK(DIFFNODE_EXPLINT_TIMER_TASK)
{
	if (TOS_CALL_COMMAND(DIFFNODE_ADD_TIMER)
		(&VAR(Texplint), (EXPLINT_TIMER+2)*timer1ps*DIFF_RATE)==0) {
		TOS_POST_TASK(DIFFNODE_EXPLINT_TIMER_TASK);
	}
}

/* Heartbeat timer task */
TOS_TASK(DIFFNODE_TIMER_TASK)
{
	if (TOS_CALL_COMMAND(DIFFNODE_ADD_TIMER)
		(&VAR(Td), timer8ps)==0) {
		TOS_POST_TASK(DIFFNODE_TIMER_TASK);
	}
}


/* Dump timer task. Needed because a sender and/or intermediate dont
 * send interests but they still need to dump stuff
*/
TOS_TASK(DIFFNODE_DUMP_TIMER_TASK)
{
	if (TOS_CALL_COMMAND(DIFFNODE_ADD_TIMER)
		(&VAR(Tdump), timer1ps*DUMP_TIMER)==0) {
			TOS_POST_TASK(DIFFNODE_DUMP_TIMER_TASK);
	}
}


TOS_TASK(DIFFNODE_START_TIMER_TASK)
{
	if (TOS_CALL_COMMAND(DIFFNODE_ADD_TIMER)
		(&VAR(Tstart), timer1ps*(TOS_LOCAL_ADDRESS+60))==0) {
		TOS_POST_TASK(DIFFNODE_START_TIMER_TASK);
	}
}


TOS_TASK(DIFFNODE_CHECKDATA_TASK)
{
	checkData();
}



char TOS_COMMAND(DIFFNODE_INIT)()
{
	TOS_CALL_COMMAND(LEDS_INIT)();
	TOS_CALL_COMMAND(DIFFNODE_TIMER_HEAP_INIT)();

	// Setup the clock callbacks

	// Init sub components 
	TOS_CALL_COMMAND(DIFFNODE_SUB_INIT)();
	
	TOS_CALL_COMMAND(DIFFNODE_UART_INIT)();

	// Power up the sensors
	TOS_CALL_COMMAND(DIFFNODE_SUB_ADC_INIT)();

	// Initialize remote power control component
	// (this will read value from the EEPROM and set the tx power)
	TOS_CALL_COMMAND(DIFFNODE_POWER_RC_INIT)();

	// Init local state
	diffTableInit();
	DataCacheInit();


	VAR(lCodeId)=0;
	VAR(lMaxRange)=MAX_FRAGS;
#ifdef IS_SENDER	// Fill up the code table
	VAR(lMinRange)=1;
	LocalCodeInit(&VAR(LocalCodeTable[0]),VAR(lCodeId),
					VAR(lMinRange),VAR(lMaxRange));
#else 
	VAR(lMinRange)=MAX_FRAGS;	
#endif // IS_SENDER

	VAR(clockDiv) = CLOCK_DIV;
	VAR(dataChooser) = 0;

	initTimer(&VAR(Td));
	setPeriodic(&VAR(Td), timer8ps);
	VAR(Td).f=td_expired;

	if (TOS_CALL_COMMAND(DIFFNODE_ADD_TIMER)
		(&VAR(Td), timer8ps)==0) {
			TOS_POST_TASK(DIFFNODE_TIMER_TASK);
	}

	VAR(x_loc)=TOS_LOCAL_ADDRESS / 100;
	VAR(y_loc)=TOS_LOCAL_ADDRESS % 100;
	TOS_CALL_COMMAND(DIFFNODE_TXMAN_SEED)((char)TOS_LOCAL_ADDRESS);


	initTimer(&VAR(Tcheck));
	initTimer(&VAR(Texplint));
	initTimer(&VAR(Tdump));
	initTimer(&VAR(Tstart));
	setAperiodic(&VAR(Tcheck));
	setAperiodic(&VAR(Texplint));
	setPeriodic(&VAR(Tdump), DUMP_TIMER*timer1ps);
	setAperiodic(&VAR(Tstart));
	VAR(Tcheck).f=tcheck_expired;
	VAR(Texplint).f=texplint_expired;   
	VAR(Tdump).f=tdump_expired;
	VAR(Tstart).f=tstart_expired;

#ifdef IS_RECEIVER
	if (TOS_CALL_COMMAND(DIFFNODE_ADD_TIMER)
		(&VAR(Tstart), timer1ps*(TOS_LOCAL_ADDRESS+60))==0) {
		TOS_POST_TASK(DIFFNODE_START_TIMER_TASK);
	} 
#endif //IS_RECEIVER


	if (TOS_CALL_COMMAND(DIFFNODE_ADD_TIMER)
		(&VAR(Tdump), timer1ps*DUMP_TIMER)==0) {
		TOS_POST_TASK(DIFFNODE_DUMP_TIMER_TASK);                            
	}



#ifdef IS_RECEIVER
	/* Initial request parameters */
	VAR(rCodeId)=0;
	VAR(rMinRange)=1;
	VAR(rMaxRange)=MAX_FRAGS;	

//	sendExploratoryInterest();
#else
	VAR(rCodeId)=0xFF;
	VAR(rMinRange)=0xFF;
	VAR(rMaxRange)=0xFF;
#endif // IS_RECEIVER


//	TOS_LOCAL_ADDRESS = TOS_BCAST_ADDR;
	return 1;
}


char TOS_COMMAND(DIFFNODE_START)()
{
		return 1;
}

//********* Periodic Tasks ***************
TOS_TASK(ClockTickTask)
{
	checkData();
	// Refresh the gradient table
	flip_error_led();	// heartbeat
	expireGradients();
}


// Send messages that are waiting in the TXqueue
TOS_TASK(TXTickTask)
{
	TOS_CALL_COMMAND(DIFFNODE_TXMAN_TICK)();
}


// Timer callback
//void TOS_EVENT(DIFFNODE_CLOCK_EVENT)()
static inline void td_expired()
{
	// run expiration task
	if( VAR(clockDiv) <= 0 ) {
		TOS_POST_TASK(ClockTickTask);
		VAR(clockDiv) = CLOCK_DIV;

	// Signal heartbeat
	} else {
		VAR(clockDiv)--;
	}
	
	// send messages
	TOS_POST_TASK(TXTickTask);
}



//************* Message Handlers *****************
int handleExplInterest(TOS_MsgPtr intMsg);
int handleReinforcement(TOS_MsgPtr intMsg);

TOS_MsgPtr TOS_MSG_EVENT(DIFFNODE_RX_INTEREST_MSG)(TOS_MsgPtr intMsg)
{
	// If the message is broadcast ...
	if( intMsg->addr == TOS_BCAST_ADDR ) {
		// it is an exploratory interest
			handleExplInterest(intMsg);
		}
	// if the message is directed ...
	else if( intMsg->addr == TOS_LOCAL_ADDRESS ) {
		// ????? If it is a reinforcement for someone else then what????
		// it is a reinforcement
			handleReinforcement(intMsg);
		}
	return intMsg;
}


int handleExplInterest(TOS_MsgPtr intMsg) {
	char rebroadcast=0;

	InterestEntry* curInt;
	LocationEntry* curLoc;
	GradientEntry* curGrad;
	CodeEntry *curCode;
	InterestMessage* msg = (InterestMessage*)intMsg->data;
	

	VAR(explint_rcvd)++;

	// Check if we already have interests of this type
	curInt = findInterest(msg->type);
	if( curInt == NULL ) {
		// If the interest message is new
		// then see if we have space for it.
		curInt = findFreeInterestEntry();
		// Need to check if memory was allocated
		if( curInt == NULL ) {
			return(1); // ERROR.
		}
		InterestEntryInit(curInt, msg->type);

		// New interest, need to reboroadcast is later
		rebroadcast = 1;
	}

	// Check if we already have this location
	curLoc = findLocation(msg->x1, msg->y1, msg->x2, msg->y2);
	curCode = findCode(msg->codeId, msg->minRange, msg->maxRange);
	if( curLoc == NULL) {
		// Try to find space for it in the cache.
		curLoc = findFreeLocationEntry();
		// check to see if memory was allocated
		if( curLoc == NULL ) {
			// ERROR.
			return(1);
		}
		
		// Initialize the location entry.
		LocationEntryInit(curLoc, msg->x1, msg->y1, msg->x2, msg->y2);
		
		// New location, need to rebroadcast the interest		 
		rebroadcast = 1;
	}

	// Identical checks for Code
	if (curCode==NULL) {
		curCode=findFreeCodeEntry();
		if(curCode==NULL) {
			return(1);
		}
		CodeEntryInit(curCode, msg->codeId, msg->minRange, msg->maxRange);
		rebroadcast = 1;
	}


	// Look for a gradient and create it if neccessary.
	curGrad = findGradientCode(curInt, curLoc, curCode);
	if( curGrad == NULL ) {
		rebroadcast = 1;
		curGrad = addGradient(curInt, curLoc, curCode,
						msg->interval, msg->expiration);
		// check for allocation
		if( curGrad == NULL ) {
			// ERROR.
			return(1);
		}
	}

	// Rebroadcast the interest, if necessary
	if( rebroadcast == 1 ) {
		intMsg->addr = TOS_BCAST_ADDR;
		intMsg->type = INTEREST_TYPE;
		msg->sender = TOS_LOCAL_ADDRESS;
		TOS_CALL_COMMAND(GREEN_TOGGLE)();
		TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(intMsg);
/*
		if (VAR(uart_to_host_busy)==0) {
			TOS_CALL_COMMAND(DIFFNODE_UART_TX_MSG)(intMsg);
			VAR(uart_to_host_busy)=1;
		}
*/
	}

	return(0); // success 
}


int handleReinforcement(TOS_MsgPtr intMsg) {
	InterestEntry* curInt=NULL;
	LocationEntry* curLoc=NULL;
	GradientEntry* curGrad=NULL;
	DataEntry* curData=NULL;
	CodeEntry *curCode=NULL;

	InterestMessage* msg = (InterestMessage*)intMsg->data;

	// Look for matching interest
	curInt = findInterest(msg->type);
	if( curInt == NULL ) {
		// If this interest is new, try to create an interest
		curInt = findFreeInterestEntry();
		if( curInt == NULL ) {
			return (1); // ERROR
		}
		InterestEntryInit(curInt, msg->type);
	}

	// Look for matching location
	curLoc = findLocation(msg->x1, msg->y1, msg->x1, msg->y1);
	curCode = findCode(msg->codeId, msg->minRange, msg->maxRange);
	if( curLoc == NULL ) {
		// If this location is new, try to create a new location entry
		curLoc = findFreeLocationEntry();
		if( curLoc == NULL ) {

			return(1); // ERROR
		}
		LocationEntryInit(curLoc, msg->x1, msg->y1, msg->x1, msg->y1);
	}

	if (curCode == NULL) {
		curCode=findFreeCodeEntry();
		if (curCode==NULL) {
			return(1);
		}
		CodeEntryInit(curCode, msg->codeId, msg->minRange, msg->maxRange);
	}
		

	// Try to find a gradient that has is based on a given interest and location
	curGrad = findGradientCode(curInt, curLoc, curCode);
	if( curGrad == NULL ) {
		// If no such gradinet create new gradient
		curGrad = addGradient(curInt, curLoc, curCode,
					msg->interval, msg->expiration);
		if (curGrad==NULL) {
			return(1);
		}
	} else {
		// if gradient already exists, update it's expiration and interval
		curGrad->expiration = msg->expiration;
		curGrad->interval = msg->interval;
	}

	// Look in data cache for data that matches the reinforcement 
	curData = findDataWithinRange(msg->x1, msg->y1, msg->codeId, msg->minRange,
					msg->maxRange);
	if( curData == NULL ) {
		// The following creates problems for diffcode. Disabled it
/*
		// If we don't know where to forward the reiforcement,
		// transform it into an interest for single source and broadcast
		msg->x2 = msg->x1;
		msg->y2 = msg->y1;
		// the above can create an invalid source though 
		intMsg->addr = TOS_BCAST_ADDR;
		intMsg->type = INTEREST_TYPE;
		msg->sender = TOS_LOCAL_ADDRESS;
		TOS_CALL_COMMAND(GREEN_TOGGLE)();
		TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(intMsg);
		if (VAR(uart_to_host_busy)==0) {
			TOS_CALL_COMMAND(DIFFNODE_UART_TX_MSG)(intMsg);
			VAR(uart_to_host_busy)=1;                                                   }              
*/
	} else if(curData->prevHop != TOS_LOCAL_ADDRESS) {

	// If this was not a local data, forward the reinforcment
	// otherwise we are done with this reinforcment
		// direct reinforcement to where this data came from 
		// (see POLICY NOTE in data handler)
		intMsg->addr = curData->prevHop;

	// reinforcement is a directed interest
		intMsg->type = INTEREST_TYPE;
		msg->sender = TOS_LOCAL_ADDRESS;

		TOS_CALL_COMMAND(GREEN_TOGGLE)();
		TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(intMsg);

	} else if (curData->prevHop==TOS_LOCAL_ADDRESS) {
		// the reinforcement is for us, increment reinfs_rcvd counter
//		VAR(reinfs_rcvd)++;
	}
		
	if (((100*msg->x1)+msg->y1)==TOS_LOCAL_ADDRESS)
		VAR(reinfs_rcvd)++;
	
	return(0);
}


TOS_MsgPtr TOS_MSG_EVENT(DIFFNODE_RX_DATA_MSG)(TOS_MsgPtr tos_dataMsg)
{
#ifndef IS_SENDER
	DataMessage* dataMsg= (DataMessage*)tos_dataMsg->data;
#endif // IS_SENDER

	checkForwarding(tos_dataMsg);
	// If we have a gradient for the data forward it

#ifndef IS_SENDER	// intermediates need this too. Only senders dont
	if ((dataMsg!=NULL) && dataMsg->codeId<MAX_CODES) {
	/* I should probably have something like isFree here */
		if (VAR(LocalCodeTable[dataMsg->codeId]).frag[dataMsg->data]==0) {
			/* If the (ID, frag[data]) reference is zero, it
			 * means we don't have the data, so we store it
			*/	
			VAR(LocalCodeTable[dataMsg->codeId]).ID=dataMsg->codeId;
			VAR(LocalCodeTable[dataMsg->codeId]).frag[dataMsg->data]=
				dataMsg->data;
//			VAR(frags_received)++;
		}
	}
#endif //IS_SENDER

	VAR(datapkts_rcvd)++;	
				

	return tos_dataMsg;
}


void frwdData(TOS_MsgPtr tos_dataMsg)
{
	DataMessage* dataMsg = (DataMessage*)tos_dataMsg->data; 
 
	dataMsg->sender = TOS_LOCAL_ADDRESS;
	dataMsg->hopsToSrc++;

	tos_dataMsg->type = DATA_TYPE;
	tos_dataMsg->addr = TOS_BCAST_ADDR;

	TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(tos_dataMsg);
	VAR(total_data_sent)++;
/*
	if (VAR(uart_to_host_busy)==0) {
		TOS_CALL_COMMAND(DIFFNODE_UART_TX_MSG)(tos_dataMsg);
		VAR(uart_to_host_busy)=1;
	}
*/
}



// --- SENSOR APP CODE -- START -----------
void checkData(void)
{
	unsigned char i;
	unsigned char data;
	GradientEntry *curGrad;	 
	DataMessage* msg = (DataMessage*)(VAR(tos_dataMsg).data);	 


	for( i = 0; i < MAX_GRADIENTS; i++ ) {
		curGrad=&gradientTable[i];

		// If gradient is valid and fresh
		// and we are contained inside of the region
		// and code regions and Id match we can produce data of interest
		// ... generate data
/*
		if (GradientEntryIsFree(curGrad)==1) {
//			flip_error_led();
			continue;
		}
		if (curGrad->expiration<=0) {
//			flip_error_led();
			continue;
		}
		if ((curGrad->curInterval--)!=0) {
//			flip_error_led();
			continue;
		}
		if (LocationEntryDoesContain(curGrad->locationRef, VAR(x_loc),
				VAR(y_loc))==0) {
//			flip_error_led();
			continue;
		}

		if (CodeEntryContains(curGrad->codeRef, VAR(lCodeId),
			VAR(lMinRange), VAR(lMaxRange))==0) {
//			flip_error_led();
			continue;
		}
*/
		if (!GradientEntryIsFree(curGrad)	
			&& curGrad->expiration > 0
			&& curGrad->curInterval-- == 0

			&& LocationEntryDoesContain(curGrad->locationRef,
				VAR(x_loc), VAR(y_loc))

			&& CodeEntryContains(curGrad->codeRef, VAR(lCodeId),
				VAR(lMinRange), VAR(lMaxRange))) {
	
	//		flip_error_led();

		/* If code was able to reach this part the filter was
		 * able to match data that we have
		 * So, i is the gradient ID to be used as a key
		 * to the GradIdTable associative array
		*/

			data = produceData(curGrad, i);
			if (data==0xFF) {
				return;
			}
			msg->type = curGrad->interestRef->type;
			msg->x = VAR(x_loc);
			msg->y = VAR(y_loc);
			msg->orgSeqNum = VAR(seqNum)++;
			msg->minRange=VAR(lMinRange);
			msg->maxRange=VAR(lMaxRange);
			msg->codeId=VAR(lCodeId);
			msg->data = data;
			msg->sender = TOS_LOCAL_ADDRESS;
			msg->hopsToSrc = 0;

			VAR(tos_dataMsg).type = DATA_TYPE;
			VAR(tos_dataMsg).addr = TOS_BCAST_ADDR;
	
			curGrad->curInterval = curGrad->interval;

//		TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(&VAR(tos_dataMsg)); 
			VAR(local_data_sent)+=checkForwarding(&VAR(tos_dataMsg));
		}	
	}
}

/* Transmit the requested piece of data */
unsigned char produceData(GradientEntry *curGrad, uint8_t GradId)
{
	CodeEntry *curCode=curGrad->codeRef;
	uint8_t i=curCode->codeId;
	uint8_t j=(curCode->minRange)+VAR(GradIdTable[GradId]);
	/* curCode->minRange is >= lMinRangeRange, for the filter to
	 * match. 
	*/


	if ((j>=MAX_FRAGS || j>=curCode->maxRange)  
		&& (curCode->minRange!=curCode->maxRange)) {
		/* last segment sent, init pointer, expire gradient */	
		VAR(GradIdTable)[GradId]=0;
		removeGradient(curGrad);
		return 0xFF;
	}

	/* Increment the index pointer by 1 */
	VAR(GradIdTable[GradId])++;

	if (VAR(LocalCodeTable[i].frag[j])!=0) {
		return (VAR(LocalCodeTable[i]).frag[j]);
	} else {
		return 0xFF;
	}
}


char TOS_EVENT(DIFFNODE_SUB_ADC_PHOTO_DATA)(short data) 
{
	VAR(photoData) = data >> 2;
	return 1;
}


char TOS_EVENT(DIFFNODE_SUB_ADC_TEMP_DATA)(short data)
{
	VAR(tempData) = data >> 2;
	return 1;
}
// --- SENSOR APP CODE -- END -------------


// ---- Utility functions -- START ---
struct id {
	uint16_t id;
};

TOS_MsgPtr TOS_MSG_EVENT(DIFFNODE_RX_ID_MSG)(TOS_MsgPtr msg)
{
	TOS_CALL_COMMAND(GREEN_TOGGLE)();

	if( TOS_LOCAL_ADDRESS == TOS_BCAST_ADDR ) {
		TOS_LOCAL_ADDRESS = ((struct id *)&(msg->data))->id;
		TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(msg);
/*
		if (VAR(uart_to_host_busy)==0) {
			TOS_CALL_COMMAND(DIFFNODE_UART_TX_MSG)(msg);
			VAR(uart_to_host_busy)=1;
		}
*/
		TOS_CALL_COMMAND(DIFFNODE_TXMAN_SEED)((char)TOS_LOCAL_ADDRESS);
		// may be location should be in the structure attached to the id...
		VAR(x_loc) = TOS_LOCAL_ADDRESS / 100;
		VAR(y_loc) = TOS_LOCAL_ADDRESS % 100;
	}
/*
	if (VAR(uart_to_host_busy)==0) {
		TOS_CALL_COMMAND(DIFFNODE_UART_TX_MSG)(msg);
		VAR(uart_to_host_busy)=1;
	}
*/
	return msg;
}


TOS_MsgPtr TOS_MSG_EVENT(DIFFNODE_RX_RESET_MSG)(TOS_MsgPtr msg)
{
	// XXX Do we need this? Or does it just screw things up?
	TOS_CALL_COMMAND(DIFFNODE_INIT)();

	return msg;
}
// ---- Utility functions -- END -----


void flip_error_led()
{
	if (VAR(error_led_state)==0)
		CLR_YELLOW_LED_PIN();
	else
		SET_YELLOW_LED_PIN();
	VAR(error_led_state)=!VAR(error_led_state);
}


void flip_tx_led()
{
	if (VAR(tx_led_state)==0)
		CLR_RED_LED_PIN();
	else
		SET_YELLOW_LED_PIN();
	VAR(tx_led_state)=!VAR(tx_led_state);
}


void flip_rx_led()
{
	if (VAR(rx_led_state)==0)
		CLR_GREEN_LED_PIN();
	else
		SET_GREEN_LED_PIN();
		VAR(rx_led_state)=!VAR(rx_led_state); 
}

/* Additional utility functions for diffcode */
void sendExploratoryInterest()
{
	VAR(tos_intMsg).addr=TOS_BCAST_ADDR;
	VAR(tos_intMsg).type=INTEREST_TYPE;
	VAR(tos_intMsg).group=0x7d;
	
	/* Check the code table, set the rMin, rMax and lMin values */	
	VAR(frags_received)=checkCodeTable();
	if ((VAR(frags_received)==0xFF) || 
		(VAR(frags_received)==(MAX_FRAGS-1))) {
		return;
	}

	createInterest((InterestMessage *)(VAR(tos_intMsg).data), 
			EXPLINT_TIMER);

	if (checkInterest(&VAR(tos_intMsg))==0)
		TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(&VAR(tos_intMsg));

/*
	if (VAR(uart_to_host_busy)==0) {
		TOS_CALL_COMMAND(DIFFNODE_UART_TX_MSG)(&VAR(tos_intMsg));
		VAR(uart_to_host_busy)=1;
	}
*/
	/* Set a timer to expire after EXPLINT_TIMER secs */
	if (TOS_CALL_COMMAND(DIFFNODE_ADD_TIMER)
		(&VAR(Texplint), ((EXPLINT_TIMER+2)*timer1ps*DIFF_RATE))==0)
		TOS_POST_TASK(DIFFNODE_EXPLINT_TIMER_TASK);

	/* Set a timer to expire after (rMaxRange-rMinRange)*DIFF_RATE + 10 */
	/* After that timer expires, an exploratory interest will be
	 * sent again
	*/

	VAR(interestTime)=VAR(rMaxRange)-VAR(rMinRange);
	if (VAR(interestTime)<=0)
		return;

   if (TOS_CALL_COMMAND(DIFFNODE_ADD_TIMER)
		(&VAR(Tcheck),
		((VAR(interestTime)+EXPLINT_TIMER)*timer1ps*DIFF_RATE))==0)
		TOS_POST_TASK(DIFFNODE_CHECK_TIMER_TASK);

	VAR(explint_sent)++;
	TOS_POST_TASK(DIFFNODE_UART_DUMP);
}


static inline void createInterest(InterestMessage *msg, uint8_t expiration)
{

	msg->type=3;
	msg->x1=0;
	msg->x2=100;
	msg->y1=0;
	msg->y2=100;
	msg->codeId=VAR(rCodeId);

	/* rMin and rMax are valid, since checkCodeTable has set them */
	msg->minRange=VAR(rMinRange);
	msg->maxRange=VAR(rMaxRange);
	msg->interval=0;
	// TODO: timer must be randomized otherwise a node can 
	// jam the network
	msg->expiration=expiration;
	msg->sender=TOS_LOCAL_ADDRESS;
}


void sendReinforcement()
{
	uint8_t source=0;
	DataEntry *curData;
	InterestMessage *msg=(InterestMessage *)(VAR(tos_intMsg).data);

	
	/* First check which path I must reinforce */
	curData = findDataSource(VAR(rCodeId), VAR(rMinRange), VAR(rMaxRange));
	
	if (curData==NULL)
		return;

	
//	VAR(tos_intMsg).addr=(100*curData->x)+curData->y;
	VAR(tos_intMsg).addr=curData->prevHop;
	VAR(tos_intMsg).type=INTEREST_TYPE;
	VAR(tos_intMsg).group=0x7d;

// tentative, see if it works here
	VAR(frags_received)=checkCodeTable();

	VAR(interestTime)=VAR(rMaxRange)-VAR(rMinRange);
	if (VAR(interestTime)<=0)
		return;

	msg->type=3;
	msg->x1=curData->x;
	msg->x2=curData->x;
	msg->y1=curData->y;
	msg->y2=curData->y;

	source=(100*curData->x)+curData->y;
	if (source!=VAR(last_source)) {
		VAR(num_sources)++;
		VAR(last_source)=source;
	}

	msg->codeId=VAR(rCodeId);
	

	msg->minRange=VAR(rMinRange);
	msg->maxRange=VAR(rMaxRange);
	msg->interval=0;

	msg->expiration=VAR(interestTime)+1;
	msg->sender=TOS_LOCAL_ADDRESS;
	

	checkInterest(&VAR(tos_intMsg));
	TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(&VAR(tos_intMsg));

	VAR(reinfs_sent)++;

	TOS_POST_TASK(DIFFNODE_UART_DUMP);

}


/* Uart */
char TOS_EVENT(DIFFNODE_UART_TX_PACKET_DONE)(TOS_MsgPtr data)
{
	VAR(uart_to_host_busy)=0;
	return 1;
}


TOS_MsgPtr TOS_EVENT(DIFFNODE_UART_RX_PACKET_DONE)(TOS_MsgPtr data)
{
	/* empty */
	return 0;
}



/* Assigning values to rMin rMax, lMin, lMax 
 * Assignment of rMin, rMax follows a minimalistic approach.
 * Assignment of lMin is accurate: it's the first non-zero element
 * However, lMax is always MAX_FRAGS, so the range here is optimistic and
 * might have gaps. However, produceData checks for data validity, so
 * the optimistic range is not such big of a problem
*/
uint8_t checkCodeTable()
{
	uint8_t i,j,locked_lMin=0, locked_rMin=0, full=0;
	uint8_t locked_rMax=0;

	if (VAR(rCodeId)==0xFF || VAR(rMinRange)==0xFF || VAR(rMaxRange)==0xFF) 
		return 0xFF;

	j=VAR(rCodeId);
		
	for(i=1;i<MAX_FRAGS;i++) {
		if ((VAR(LocalCodeTable)[j].frag[i])==0) {
		/* If I find a zero and this is the first zero */
			if (locked_rMin==0) {
				/* remote minimum is set */
				VAR(rMinRange)=i;
				locked_rMin=1;
			}
		} else {	/* Non-zero */
			full++;
			/* I set the local minimum to the first non-zero element I find */
			if (locked_lMin==0) {
				VAR(lMinRange)=i;
				locked_lMin=1;
			}
			/* If i find a non-zero and I already have the min range */
			if (locked_rMin==1 && locked_rMax==0) {
				VAR(rMaxRange)=i;
				locked_rMax=1;
			}
		}
	}

	
	if (((VAR(rMinRange)>VAR(rMaxRange))) && VAR(rMinRange)<(MAX_FRAGS-1)) {
		// This shouldn't happen, but it does. 
		// Solution: redo the calcs
		VAR(rMaxRange)=VAR(rMinRange)+5;
	}


	// if at this point, locked_rMin==0, I didn't find any zeroes-
	// array is full
	if (locked_rMin==0) {
//		VAR(rMinRange)=VAR(rMaxRange);
		VAR(LocalCodeTable)[j].is_full=1;
		CLR_YELLOW_LED_PIN();
		VAR(lMinRange)=1;
		VAR(lMaxRange)=MAX_FRAGS;
		TOS_POST_TASK(DIFFNODE_UART_DUMP);
		return full;
	}

	if (full==(MAX_FRAGS-1)) {
//		VAR(rMinRange)=VAR(rMaxRange);
		VAR(LocalCodeTable)[j].is_full=1;
		CLR_YELLOW_LED_PIN();
		TOS_POST_TASK(DIFFNODE_UART_DUMP);
		return full;
	}

	return full;
}



static inline void tcheck_expired()
{
	sendExploratoryInterest();
}


static inline void texplint_expired()
{
	sendReinforcement();
}	 


static inline void tdump_expired()
{
	TOS_POST_TASK(DIFFNODE_UART_DUMP);
}


static inline void tstart_expired()
{
	sendExploratoryInterest();
}

// checkForwarding returns 1 if it forwards data, 0 otherwise
char checkForwarding(TOS_MsgPtr tos_dataMsg)
{
	DataEntry* cacheData;
	DataMessage* dataMsg= (DataMessage*)tos_dataMsg->data;
	// If we have a gradient for the data forward it

	if( findGradient3Code(dataMsg->type, dataMsg->x, dataMsg->y,
		dataMsg->codeId, dataMsg->minRange, dataMsg->maxRange) !=NULL) {

		// Verify freshness of the data
		cacheData = findExactData(dataMsg->x, dataMsg->y, dataMsg->codeId,
					dataMsg->data);
		if (cacheData==NULL) {
		// If the data is brand new, cache and forward it
			cacheData = findFreeDataEntry();
		// findFreeDataEntry never returns NULL
			DataEntryInit(cacheData, dataMsg->x, dataMsg->y,
				dataMsg->codeId, dataMsg->data,
				dataMsg->orgSeqNum, dataMsg->hopsToSrc, dataMsg->sender);
			frwdData(tos_dataMsg);
			return 1;
		// POLICY NOTE: we save the data with the lowest hopsToSrc
		 } else if (cacheData->hopsToSrc >= dataMsg->hopsToSrc
			&& cacheData->orgSeqNum < dataMsg->orgSeqNum) {
		// The data is newer than what we have seem update cache and forward it
			cacheData->orgSeqNum = dataMsg->orgSeqNum;
			cacheData->hopsToSrc = dataMsg->hopsToSrc;
			cacheData->prevHop = dataMsg->sender;
			frwdData(tos_dataMsg);
			return 1;
		} else {
 	// this is old data, do not rebroadcast it
		}
	}
	return 0;
}


static inline void create_dump_msg(struct dump_msg *msg)
{
	if (msg==NULL)
		return;
	msg->explint_sent_H=((VAR(explint_sent)>>8) &0xFF);
	msg->explint_sent_L=(VAR(explint_sent) & 0xFF);
	msg->reinfs_sent_H=((VAR(reinfs_sent)>>8) & 0xFF);
	msg->reinfs_sent_L=(VAR(reinfs_sent) & 0xFF);
	msg->local_data_sent_H=((VAR(local_data_sent)>>8) & 0xFF);
	msg->local_data_sent_L=(VAR(local_data_sent) & 0xFF);
	msg->total_data_sent_H=((VAR(total_data_sent)>>8) & 0xFF);
	msg->total_data_sent_L=(VAR(total_data_sent) & 0xFF);
	msg->explint_rcvd_H=((VAR(explint_rcvd)>>8) &0xFF);
	msg->explint_rcvd_L=(VAR(explint_rcvd) & 0xFF);
	msg->reinfs_rcvd_H=((VAR(reinfs_rcvd)>>8) & 0xFF);
	msg->reinfs_rcvd_L=(VAR(reinfs_rcvd) & 0xFF);
	msg->datapkts_rcvd_H=((VAR(datapkts_rcvd)>>8) & 0xFF);
	msg->datapkts_rcvd_L=(VAR(datapkts_rcvd) & 0xFF);
	msg->rCodeId=VAR(rCodeId);
	if (VAR(rCodeId)==0xFF) {		// Dedicated sender
		memcpy((char *)(msg->CodeTable), 
			(char *)(VAR(LocalCodeTable[VAR(lCodeId)]).frag), MAX_FRAGS);
	} else {
		memcpy((char *)(msg->CodeTable), 
			(char *)(VAR(LocalCodeTable[VAR(rCodeId)]).frag), MAX_FRAGS);
	}
	msg->rMinRange=VAR(rMinRange);
	msg->rMaxRange=VAR(rMaxRange);
	msg->lMinRange=VAR(lMinRange);
	msg->lMaxRange=VAR(lMaxRange);
	msg->frags_received=VAR(frags_received);
	msg->num_sources=VAR(num_sources);

}


static inline char checkInterest(TOS_MsgPtr intMsg)
{
	InterestEntry* curInt;
	LocationEntry* curLoc;
	GradientEntry* curGrad;
	CodeEntry *curCode;
	InterestMessage* msg = (InterestMessage*)intMsg->data;                                                                                         
    // Check if we already have interests of this type
	curInt = findInterest(msg->type);
    if( curInt == NULL ) {
		// If the interest message is new
		// then see if we have space for it.
	    curInt = findFreeInterestEntry();
	    // Need to check if memory was allocated
	    if( curInt == NULL ) {
			return(1); // ERROR.
	    }
	    InterestEntryInit(curInt, msg->type);
    }
    // Check if we already have this location
    curLoc = findLocation(msg->x1, msg->y1, msg->x2, msg->y2);
    curCode = findCode(msg->codeId, msg->minRange, msg->maxRange);
    if( curLoc == NULL) {
    // Try to find space for it in the cache.
    	curLoc = findFreeLocationEntry();
    // check to see if memory was allocated
    	if( curLoc == NULL ) {
    		// ERROR.
    		return(1);
    	}
    // Initialize the location entry.
    	LocationEntryInit(curLoc, msg->x1, msg->y1, msg->x2, msg->y2);
    }
    // Identical checks for Code
    if (curCode==NULL) {
    	curCode=findFreeCodeEntry();
    	if(curCode==NULL) {
    		return(1);
    	}
    	CodeEntryInit(curCode, msg->codeId, msg->minRange, msg->maxRange);
    }
    // Look for a gradient and create it if neccessary.
   	curGrad = findGradientCode(curInt, curLoc, curCode);
   	if( curGrad == NULL ) {
   		curGrad = addGradient(curInt, curLoc, curCode,
   		msg->interval, msg->expiration);                                
   		// check for allocation
   		if( curGrad == NULL ) {
	   		// ERROR.
   			 return(1);
   		}
   	}                                     	
	return 0;
}
