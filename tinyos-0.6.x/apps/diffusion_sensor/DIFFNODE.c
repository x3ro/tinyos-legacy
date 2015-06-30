/* Diffusion implementation for motes */

/* Impementation notes:
	 Save memory by using 'char' instead of longer datatypes
	 - this also help to avoid stack overflow

	 Pointers to structures seem to genereate smaller and faster code,
	 than arrays and indicies - this has to do with AVR arch 
*/

#include "tos.h"
#include "DIFFNODE.h"

#include <inttypes.h>
#include <string.h>
#include "DIFFNODE.inc"

#include "DiffNodeInc/defs.h"
#include "DiffNodeInc/DiffTable.inc"
#include "DiffNodeInc/DataCache.inc"
#include "DiffNodeInc/InterestMessage.inc"
#include "DiffNodeInc/DataMessage.inc"

#define EXPLINT_EXPIRATION 		5
#define REINFOR_EXPIRATION		15
#define EXPLINT_PERIOD			20


char checkDataForwarding(TOS_MsgPtr tos_dataMsg);
void createInterest(uint8_t type, uint8_t x1, uint8_t y1, 
		uint8_t x2, uint8_t y2, uint8_t interval,
		uint8_t expiration, uint8_t range);
char sendExplInterest(InterestMessage *explInt);
char sendReinforcement(InterestMessage *explInt);
void checkInterestTimers();



TOS_FRAME_BEGIN(DIFFNODE_frame)
{
	uint8_t	 x_loc, y_loc;
	uint32_t seqNum;

	uint8_t	 dataChooser;
	// we have a 10-bit adc, 8 bits arent enough
	uint8_t tempData, photoData;
	uint16_t threshold; 	

	uint8_t	 clockDiv;

	TOS_Msg tos_dataMsg;
	TOS_Msg tos_intMsg;
	
	InterestMessage explIntr;

	uint8_t iet;		// expiration time of the sent
						// interest
	uint8_t ipt;		// how often we send exploratory
						// interests
}
TOS_FRAME_END(DIFFNODE_frame);



char TOS_COMMAND(DIFFNODE_INIT)()
{
	TOS_CALL_COMMAND(LEDS_INIT)();

	
	// Setup the clock callbacks
	TOS_CALL_COMMAND(DIFFNODE_CLOCK_INIT)(128,3);	//tick8ps is undefined
													//for ETC_8

	// Init sub components 
	TOS_CALL_COMMAND(DIFFNODE_SUB_INIT)();

	// Power up the sensors
	TOS_CALL_COMMAND(DIFFNODE_SUB_ADC_INIT)();

	// Initialize remote power control component
	// (this will read value from the EEPROM and set the tx power)
	TOS_CALL_COMMAND(DIFFNODE_POWER_RC_INIT)();

	// Init local state
	diffTableInit();
	DataCacheInit();

	VAR(clockDiv) = CLOCK_DIV;
	VAR(dataChooser) = 0;


	// Set the location of the node based on its LOCAL_ADDRESS
	// Be sure to set the local address of nodes to different values
	// when programming them (use the install.# command)
	// Otherwise all motes will have local_address==1 
	// and location x=0, y=1

	VAR(x_loc)=TOS_LOCAL_ADDRESS / 100;
	VAR(y_loc)=TOS_LOCAL_ADDRESS % 100;
	// TX manager random generator is based on the local address
	TOS_CALL_COMMAND(DIFFNODE_TXMAN_SEED)((char)TOS_LOCAL_ADDRESS);

//	Old functionality. Not used anymore
//	TOS_LOCAL_ADDRESS = TOS_BCAST_ADDR;

	
#ifdef IS_INITIATOR
	// Set the timer expiration values
	VAR(iet)=EXPLINT_EXPIRATION+1;
	VAR(ipt)=EXPLINT_PERIOD+1;
	// Create an interest for PHOTO sensor values
	// for an area contained within (0,2)-(0,4)
	// with an interval of 0
	// an expiration of EXPLINT_EXPIRATION
	// and a range of 1 hop
	createInterest(PHOTO,0,2,0,4,0,EXPLINT_EXPIRATION,2);
	// send it
	sendExplInterest(&VAR(explIntr));
#else
	VAR(iet)=0xFF;
	VAR(ipt)=0xFF;
#endif	// IS_INITIATOR

	return 1;
}


char TOS_COMMAND(DIFFNODE_START)()
{
	return 1;
}

//********* Periodic Tasks ***************
TOS_TASK(ClockTickTask)
{
	// --- SENSOR APP CODE -- START -----------
	// Get the latest sensors values from ADC
	if (VAR(dataChooser)) {
		TOS_CALL_COMMAND(DIFFNODE_SUB_ADC_GET_DATA)(PHOTO);
	} else {
		TOS_CALL_COMMAND(DIFFNODE_SUB_ADC_GET_DATA)(TEMP);
	}
	VAR(dataChooser) = !VAR(dataChooser);

	// Create and send a data series message if necessary 
	senseData();
	// --- SENSOR APP CODE -- END ------------

	// Refresh the gradient table
	expireGradients();

	// See if an interest transmission timer has expired	
	checkInterestTimers();

}


// Send messages that are waiting in the TXqueue
TOS_TASK(TXTickTask)
{
	TOS_CALL_COMMAND(DIFFNODE_TXMAN_TICK)();
}


// Timer callback
void TOS_EVENT(DIFFNODE_CLOCK_EVENT)()
{
	// run expiration task
	if (VAR(clockDiv) <= 0 ) {
		TOS_POST_TASK(ClockTickTask);
		VAR(clockDiv) = CLOCK_DIV;

	// Signal heartbeat
	TOS_CALL_COMMAND(YELLOW_TOGGLE)();
	} else {
		VAR(clockDiv)--;
	}
	
	// send messages
	TOS_POST_TASK(TXTickTask);
}



//************* Message Handlers *****************
char handleExplInterest(TOS_MsgPtr intMsg);
char handleReinforcement(TOS_MsgPtr intMsg);

TOS_MsgPtr TOS_MSG_EVENT(DIFFNODE_RX_INTEREST_MSG)(TOS_MsgPtr intMsg)
{
	// Match interest against installed filters
	// If the message is broadcast ...
	if (intMsg->addr == TOS_BCAST_ADDR) {
		// it is an exploratory interest
		handleExplInterest(intMsg);
	// if the message is directed ...
	} else if (intMsg->addr == TOS_LOCAL_ADDRESS) {
		// it is a reinforcement
		handleReinforcement(intMsg);
	}

	return intMsg;
}


char handleExplInterest(TOS_MsgPtr intMsg) 
/*  Return codes:
 *  -1: error
 *   0: All cache lookups were hits; no rebroadcast
 *   1: Interest was rebroadcasted
*/
{

	uint8_t rebroadcast=0;
	InterestMessage* msg = (InterestMessage*)intMsg->data;

	InterestEntry* curInt;
	LocationEntry* curLoc;
	GradientEntry* curGrad;

	// Check if we already have interests of this type
	curInt = findInterest(msg->type);
	if (curInt == NULL) {
		// If the interest message is new
		// then see if we have space for it.
		curInt = findFreeInterestEntry();
		// Need to check if memory was allocated
		if( curInt == NULL ) {
			return -1; // ERROR.
		}
		InterestEntryInit(curInt, msg->type);

		// New interest, need to reboroadcast is later
		rebroadcast = 1;
	}

	// Check if we already have this location
	curLoc = findLocation(msg->x1, msg->y1, msg->x2, msg->y2);
	if (curLoc == NULL) {
		// Try to find space for it in the cache.
		curLoc = findFreeLocationEntry();
		// check to see if memory was allocated
		if (curLoc == NULL) {
			// ERROR.
			return -1;
		}
		
		// Initialize the location entry.
		LocationEntryInit(curLoc, msg->x1, msg->y1, msg->x2, msg->y2);
		
		// New location, need to rebroadcast the interest		 
		rebroadcast = 1;
	}

	// Look for a gradient and create it if neccessary.
	curGrad = findGradient2(curInt, curLoc);
	if (curGrad == NULL) {
		rebroadcast = 1;
		curGrad = addGradient(curInt, curLoc, msg->interval, 
			msg->expiration, msg->range);
		// check for allocation
		if (curGrad == NULL) {
			// ERROR.
			return -1;
		}
	}


	// Rebroadcast the interest, if indicated by filters
	// AND the TTL has not expired
	if (rebroadcast == 1 && msg->ttl > 0) {
		intMsg->addr = TOS_BCAST_ADDR;
		intMsg->type = INTEREST_TYPE;
		msg->ttl--;
		msg->sender = TOS_LOCAL_ADDRESS;
		TOS_CALL_COMMAND(GREEN_TOGGLE)();
		TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(intMsg);
	}

	return ((rebroadcast) & (msg->ttl)); 
	// indicates whether we rebroadcasted or not
}


char handleReinforcement(TOS_MsgPtr intMsg) 
/* Return codes:
 * -1: error
 *  0: reinforcement was for us, no transmission
 *  1: reinforcement was not for us and has been forwarded (transmitted)
*/
{

	InterestEntry* curInt;
	LocationEntry* curLoc;
	GradientEntry* curGrad;
	DataEntry* curData;

	InterestMessage* msg = (InterestMessage*)intMsg->data;

	// Look for matching interest
	curInt = findInterest(msg->type);
	if (curInt == NULL) {
		// If this interest is new, try to create an interest
		curInt = findFreeInterestEntry();
		if( curInt == NULL ) {
			return -1; // ERROR
		}
		InterestEntryInit(curInt, msg->type);
	}

	// Look for matching location
	curLoc = findLocation(msg->x1, msg->y1, msg->x1, msg->y1);
	if( curLoc == NULL ) {
		// If this location is new, try to create a new location entry
		curLoc = findFreeLocationEntry();
		if (curLoc == NULL) {
			return -1; // ERROR
		}
		LocationEntryInit(curLoc, msg->x1, msg->y1, msg->x1, msg->y1);
	}

	// Try to find a gradient that has is based on a given interest and location
	curGrad = findGradient2(curInt, curLoc);
	if (curGrad == NULL) {
		// If no such gradinet create new gradient
		curGrad = addGradient(curInt, curLoc, msg->interval, 
				msg->expiration, msg->range);
	} else {
		// if gradient already exists, update it's expiration and interval
		curGrad->expiration = msg->expiration;
		curGrad->interval = msg->interval;
	}

	// Look for data cache for data that matches the reinforcement 
	curData = findDataByLocation(msg->x1, msg->y1);
	if (curData == NULL) {
		// If we don't know where to forward the reiforcement,
		// transform it into an interest for single source and broadcast
		// NOTE: we need to re-assess the usefuleness of this approach
		
		msg->x2 = msg->x1;
		msg->y2 = msg->y1;
		intMsg->addr = TOS_BCAST_ADDR;
		intMsg->type = INTEREST_TYPE;
		msg->sender = TOS_LOCAL_ADDRESS;
		msg->ttl--;

		TOS_CALL_COMMAND(GREEN_TOGGLE)();

		if (msg->ttl > 0) {
			TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(intMsg);
			return 1;
		} else {
			return 0;
		}
		
	} else if (curData->prevHop != TOS_LOCAL_ADDRESS) {
		// If this was not a local data, forward the reinforcment
		// otherwise we are done with this reinforcment
		// direct reinforcement to where this data came from 
		// (see POLICY NOTE in data handler)
		intMsg->addr = curData->prevHop;
		intMsg->type = INTEREST_TYPE;
		msg->sender = TOS_LOCAL_ADDRESS;
		msg->ttl--;
	
		TOS_CALL_COMMAND(GREEN_TOGGLE)();

		if (msg->ttl > 0) {
			TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(intMsg);		
			return 1;
		} else {
			return 0;
		}
	}

	return 0;
}


TOS_MsgPtr TOS_MSG_EVENT(DIFFNODE_RX_DATA_MSG)(TOS_MsgPtr tos_dataMsg)
{

	// If the check is successful, forward the packet
	if ((checkDataForwarding(tos_dataMsg))==1) {
		frwdData(tos_dataMsg);
	}		

	// Additional sink-specific code goes here

	
	return tos_dataMsg;
}



// Send data to the TX manager, if the TTL is > 0
void frwdData(TOS_MsgPtr tos_dataMsg)
{
	DataMessage* dataMsg = (DataMessage*)tos_dataMsg->data; 
 
	dataMsg->sender = TOS_LOCAL_ADDRESS;
	dataMsg->hopsToSrc++;
	// Decrement TTL
	dataMsg->ttl--;

	tos_dataMsg->type = DATA_TYPE;
	tos_dataMsg->addr = TOS_BCAST_ADDR;


	// Only forward if TTL is > 0
	// TODO: Determine if the ttl check should be here or 
	// in checkDataForwarding
	if (dataMsg->ttl > 0)
		TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(tos_dataMsg);
}



// --- SENSOR APP CODE -- START -----------
void senseData(void)
{
	uint8_t i;
	uint8_t data;
	GradientEntry *curGrad;	 
	DataMessage* msg = (DataMessage*)(VAR(tos_dataMsg).data);	 


	for( i = 0; i < MAX_GRADIENTS; i++ ) {
		curGrad=&gradientTable[i];

		// If the gradient is valid
		if (!GradientEntryIsFree(curGrad)					 
				// and it hasn't expired
				&& curGrad->expiration > 0
				// and we need to generate data now				
				&& curGrad->curInterval-- == 0	
				// and we are contained inside of the region
				&& LocationEntryDoesContain
					(curGrad->locationRef, VAR(x_loc), VAR(y_loc))) {

			// THEN: create a data packet		
				
			data = produceData(curGrad->interestRef);
			msg->type = curGrad->interestRef->type;
			msg->x = VAR(x_loc);
			msg->y = VAR(y_loc);
			// Original sender is the producing node. This field doesn't
			// get changed on forwarding
			// Starting TTL is the specified gradient range
			// Care must be taken since the ttl will be decremented 
			// when the message goes through the loopback iface
			// That's why TTL is set to range + 1
			msg->ttl = curGrad->range + 1;
			msg->orgSeqNum = VAR(seqNum)++;
			msg->data = data;
			msg->sender = TOS_LOCAL_ADDRESS;
			// hopsToSrc must be 0 since we first send the data 
			// to ourselves, through the loopback interface
			msg->hopsToSrc = 0;

			VAR(tos_dataMsg).type = DATA_TYPE;
			VAR(tos_dataMsg).addr = TOS_BCAST_ADDR;

			curGrad->curInterval = curGrad->interval;

			// Loopback interface: send the data to yourself as if you 
			// just received it. 
			if (checkDataForwarding(&VAR(tos_dataMsg))==1)
				frwdData(&VAR(tos_dataMsg));
		}
	}
}


// Produce data based on the type of the interest
uint8_t produceData(InterestEntry* curInt)
{
	switch(curInt->type) {
	case PHOTO:		
			return VAR(photoData);
	case TEMP:
			return VAR(tempData);
	default:
			return 42;
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

//  Remove the BCAST_ADDR restriction. Use with care since a second
//  ID message will overwrite the first one.
//	if (TOS_LOCAL_ADDRESS == TOS_BCAST_ADDR) {
		TOS_LOCAL_ADDRESS = ((struct id *)&(msg->data))->id;
		TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(msg);
		TOS_CALL_COMMAND(DIFFNODE_TXMAN_SEED)((char)TOS_LOCAL_ADDRESS);
		// may be location should be in the structure attached to the id...
		VAR(x_loc) = TOS_LOCAL_ADDRESS / 100;
		VAR(y_loc) = TOS_LOCAL_ADDRESS % 100;
//	}

	return msg;
}


TOS_MsgPtr TOS_MSG_EVENT(DIFFNODE_RX_RESET_MSG)(TOS_MsgPtr msg)
{
	// XXX Do we need this? Or does it just screw things up?
	TOS_CALL_COMMAND(DIFFNODE_INIT)();
	return msg;
}
// ---- Utility functions -- END -----



// Additional Functions
char checkDataForwarding(TOS_MsgPtr tos_dataMsg)
/* Return codes:
 * 0: data should not be forwarded
 * 1: data should be forwarded
*/
{
	DataEntry* cacheData;
	DataMessage* dataMsg=(DataMessage*)tos_dataMsg->data;


	// If we have a gradient for the data forward it
	if (findGradient3(dataMsg->type, dataMsg->x, dataMsg->y) != NULL) {
		
		// Verify freshness of the data
		cacheData = findDataByLocation(dataMsg->x, dataMsg->y);
		if (cacheData==NULL) {
		// If the data is brand new, cache and forward it
			cacheData = findFreeDataEntry();
		// findFreeDataEntry never returns NULL
			DataEntryInit(cacheData, dataMsg->x, dataMsg->y, dataMsg->type,
				dataMsg->orgSeqNum, dataMsg->hopsToSrc, 
				dataMsg->sender, dataMsg->data);
//			frwdData(tos_dataMsg);
			return 1;
			// POLICY NOTE: we save the data with the lowest hopsToSrc
		} else if (cacheData->hopsToSrc >= dataMsg->hopsToSrc
			&& cacheData->orgSeqNum < dataMsg->orgSeqNum) {
		// The data is newer than what we have seem update cache and forward it
			cacheData->orgSeqNum = dataMsg->orgSeqNum;
			cacheData->hopsToSrc = dataMsg->hopsToSrc;
			cacheData->prevHop = dataMsg->sender;
//			frwdData(tos_dataMsg);
			return 1;
		} else {
		// this is old data, do not rebroadcast it
		}
	}
	return 0;
}



/* create and send an exploratory interest
 * Input variables:
 * type: type of interest
 * x1,y1,x2,y2: Location of interest (used in filter matching)
 * interval: data generation rate
 * expiration: lifetime of interest
 * range: range of interest, in hops
*/ 
char sendExplInterest(InterestMessage *explInt)
{
	InterestMessage *msg=(InterestMessage *)(VAR(tos_intMsg).data);

	if (explInt==NULL)
		return -1;
	
	// Fill in standard TOS msg fields
	memset(&VAR(tos_intMsg), 0, sizeof(TOS_Msg));
	VAR(tos_intMsg).addr=TOS_BCAST_ADDR;
	VAR(tos_intMsg).type=INTEREST_TYPE;
	VAR(tos_intMsg).group=LOCAL_GROUP;


	// Fill in interest-specific fields based on input variables
	msg->type=explInt->type;
	msg->x1=explInt->x1;	
	msg->y1=explInt->y1;
	msg->x2=explInt->x2;
	msg->y2=explInt->y2;
	msg->interval=explInt->interval;
	msg->expiration=EXPLINT_EXPIRATION;
	msg->range=explInt->range;
	msg->sender=TOS_LOCAL_ADDRESS;

	// NOTE: Interest TTL MUST be set to range + 1 because the message
	// has to go through the loopback interface first

	msg->ttl=msg->range + 1;

	// Copy the msg fields to the explIntr buffer, to be used
	// by the impending reinforcement
	
	memcpy((InterestMessage *)&(VAR(explIntr)), 
		(InterestMessage *)msg, sizeof(InterestMessage));

	// Send the message to the loopback interface
	// This will create an interest entry for the particular interest
	// So if somebody else sends the interest to us, we will not
	// consider it a new one and re-broadcast it 
	
	if ((handleExplInterest(&VAR(tos_intMsg))==1)) { 
		return 1;		// the interest was sent
	} else {
		return 0;
	}
	
}	
	

/* Create and send a reinforcement 
 * Input variables:
 * x,y: coordinates of the location we need to reinforce
 * Return values:
 * -1: No data found in cache for specific exploratory interest
 *  0: Data was found but no path was reinforced
 *  1: Data was found and a path was reinforced
 * 
 * NOTE: Reinforcement policy is somewhat flexible. It depends on 
 * which 'findData' function one chooses to use, so as to find a data
 * path that one wants to reinforce
 * 
*/
char sendReinforcement(InterestMessage *explInt)
{
	DataEntry *curData=NULL;;
	InterestMessage *msg=(InterestMessage *)(VAR(tos_intMsg).data);

	// In this example, we pick the first entry in the cache that
	// is greater or equal to the defined threshold
	curData=findDataByThreshold(VAR(threshold), GE);


	if (curData==NULL || explInt==NULL)
		// Nothing to reinforce, bail out
		return -1;		

	
	// Fill in standard TOS msg fields	
	memset(&VAR(tos_intMsg), 0, sizeof(TOS_Msg));
	VAR(tos_intMsg).type=INTEREST_TYPE;
	VAR(tos_intMsg).group=LOCAL_GROUP;
	// Direct the reinforcement to ourselves so that the reinforcement handler
	// doesn't reject it. The handler will find the correct next hop to
	// direct the reinforcement to

	// NOTE: loopback breaks things here because we reinforce ourselves
	// thus we generate data as well
//	VAR(tos_intMsg).addr=TOS_LOCAL_ADDRESS;
	VAR(tos_intMsg).addr=curData->prevHop;

	// Fill in interest-specific fields
	msg->type=explInt->type;
	msg->x1=curData->x;
	msg->y1=curData->y;
	msg->x2=curData->x;
	msg->y2=curData->y;
	msg->interval=explInt->interval;
	msg->expiration=REINFOR_EXPIRATION;
	msg->range=explInt->range;
	
	msg->ttl=msg->range /*+ 1*/;	// direct transmission
	msg->sender=TOS_LOCAL_ADDRESS;

	// NOTE: loopback breaks things here because we reinforce ourselves
	// thus we generate data as well

	TOS_CALL_COMMAND(DIFFNODE_TX_MSG)(&VAR(tos_intMsg));

	return 1;
	
/*
	if ((handleReinforcement(&VAR(tos_intMsg))==1)) {
		return 1;
	} else {
		return 0;
	}	
*/
}



/* Returns an interest message pointer based on input values */
void createInterest(uint8_t type, uint8_t x1, uint8_t y1,
		uint8_t x2, uint8_t y2, uint8_t interval,
		uint8_t expiration, uint8_t range) 
{

	VAR(explIntr).type=type;
	VAR(explIntr).x1=x1;
	VAR(explIntr).y1=y1;
	VAR(explIntr).x2=x2;
	VAR(explIntr).y2=y2;
	VAR(explIntr).interval=interval;
	VAR(explIntr).expiration=expiration;
	VAR(explIntr).range=range;
	
}



/* check the interest timer values and 
 * re-transmit an interest if necessary */
void checkInterestTimers()
{
	if ((VAR(iet)==0xFF) || (VAR(ipt)==0xFF)) 
		// if either one of the counters is invalid, bail
		return;

	if (VAR(iet)!=0) {
		VAR(iet)--;
		// Exploratory interest expired, send reinforcement
		if (VAR(iet)==0) {
			sendReinforcement(&VAR(explIntr));
		}
	}


	VAR(ipt)--;
	// Interest period expired, send another exploratory interest
	if (VAR(ipt)==0) {
		VAR(ipt)=EXPLINT_PERIOD+1;
		VAR(iet)=EXPLINT_EXPIRATION+1;
		sendExplInterest(&VAR(explIntr));
	}
					
}	
