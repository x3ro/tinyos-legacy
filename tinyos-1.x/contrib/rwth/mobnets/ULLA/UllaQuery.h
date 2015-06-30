/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */

/*
 *
 * Query Message header file
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 */
 
#ifndef _ULLA_QUERY_H_
#define _ULLA_QUERY_H_

#ifdef TELOS_PLATFORM
	#define TELOS_SENSOR
#endif

  #ifdef  HISTORICAL_STORAGE
    #define BLOCKSTORAGE // works with TOSSIM
    //#define BYTEEEPROM
  #endif

#ifndef FIELD_SIZE
#define FIELD_SIZE   8
#endif

#define FIELD_CONDITION_SIZE   2
#define CONDITION_SIZE         4
#define COMMAND_SIZE           26
#define TUPLE_SIZE 	           25
#define MAX_ATTR               8

/*  Message Type = msgType */
enum {
  ADD_MSG = 10,
  MOD_MSG = 11,
  DEL_MSG = 12,
};

/*  Data type - dataType */
enum {
  FIELD_MSG = 1,
  COND_MSG  = 2,
};
/*  SELECT types  */

/*  Supported classes   */
enum {
  ullaLink = 0x1,
	ullaLinkProvider = 0x2,
	sensorMeter = 0x4,
	sensorDescription = 0x8,
	allClasses = 0,
  UNDEFINED = 0xff,
};


/* operation types */
enum {
  OP_EQ = 0,            /* =  */
  OP_NEQ = 1,           /* <> */
  OP_GT = 2,            /* >  */
  OP_GE = 3,            /* >= */
  OP_LT = 4,            /* <  */
  OP_LE = 5,            /* <= */
};

/* bitmask */
enum {
  BITMASK_ONE_BYTE = 0xFF,
  BITMASK_TWO_BYTE = 0xFFFF,
};

/* AM message types */
enum {
  AM_QUERY   = 101,
	AM_NOTIFICATION = 102,
	AM_QUERY_REPLY   = 103,
	AM_NOTIFICATION_REPLY = 104,
	AM_PROBING = 105,
	AM_PROBING_REPLY = 106,
	AM_COMMAND = 107,
  AM_DEBUG_MESSAGE   = 109,
};


/* error messages */
enum {
  errorNoError,
  errorSendFailed,

};

enum {
  REMOTE_QUERY = 1,
  LOCAL_QUERY =2,
};

enum {
  REMOTE_LU = 3,
  LOCAL_LU = 4,
};

enum {
  NOTIFICATION = 1,
  QUERY = 2,
};

typedef uint8_t UllaError;

typedef struct Cond {
  uint8_t field;  				   //1
  uint8_t op; 							 //2
  short value; 							 //4
} Cond, *CondPtr;

/*
 * Query & Notification data structure
 */
typedef struct QueryMsgNew {
  uint8_t ruId; 						 //1 //notification id 
  uint8_t msgType;  	  		 //2 type of message (e.g. add, modify, delete q) 
  uint8_t dataType;  	  		 //3 is this a field, condition, buffer, or event msg 
	uint8_t queryType; 	  		 //4 notification or query
	uint8_t index; 						 //5  
	uint8_t className; 				 //6 ullaLink, ullaLinkProvider, sensorMeter
  uint8_t numFields; 				 //7 total number of fields
	uint8_t numConds;  				 //8 total number of conditions
	uint16_t interval; 				 //10 in millisecs 
  uint16_t nsamples; 				 //12
	
  union {
		uint8_t fields[FIELD_SIZE];
    Cond cond[CONDITION_SIZE]; //28+ (4*numConds+ = 16+)  
  } u; 											 //28+ (Routing-upto 10Bytes, BMAC-10Bytes) //total 48+ Bytes

} QueryMsgNew, *QueryMsgNewPtr;


typedef struct TreeCond {


} TreeCond;



#if 1
typedef struct QueryMsg {
  uint8_t ruId; //query id //1
  uint8_t msgType;  //type of message (e.g. add, modify, delete q) //2
  uint8_t dataType;  //is this a field, condition, buffer, or event msg -- 8
  uint8_t queryType; // (remote or local query) // 21
  uint8_t index; //9
  uint8_t className;
  uint8_t numFields; //5
  uint8_t numConds; //6
  uint16_t interval; //in millisecs -- 18
  uint16_t nsamples; // 20
  union {
    uint8_t fields[FIELD_SIZE]; //(8)
    Cond cond; //(8)
  } u; //29 2006/03/14

} QueryMsg, *QueryMsgPtr;
#endif
typedef struct CommandMsg {
  uint8_t cid;      //command id //1
  uint8_t msgType;  //type of message //2
  uint8_t cmdType;  //type of command //3
  uint8_t action;   //command action //4
  uint16_t param;   //parameter
  uint16_t interval;
  uint16_t ntimes;

} CommandMsg, *CommandMsgPtr;

typedef struct DebugMsg {
  uint8_t did;      //debug id //1

} DebugMsg, *DebugMsgPtr;

typedef struct DataMsg {
  uint8_t did;      //debug id //1

} DataMsg, *DataMsgPtr;

typedef struct UllaQuery {
  uint8_t qid; //1
  uint8_t numFields; //5
  uint8_t numConds; //6
  uint16_t interval; //18
  uint16_t nsamples; // 20

} UllaQuery, *UllaQueryPtr;

// FIXME: needs to be changed to dynamic size. 01.08.06
// FIXME: also includes a class type (e.g. ullaLinkProvider, ullaLink)
typedef struct Query {
	uint8_t qid; //1
  uint8_t numFields; //5
  uint8_t numConds; //6
  uint8_t seenFields;
  uint8_t seenConds; //bitmask for conditions we have seen already
	uint8_t className; // new 01.08.06 
  //uint16_t interval; //18
  //uint16_t nsamples; // 20
  
  uint8_t fields[FIELD_SIZE];
  Cond cond[CONDITION_SIZE];
	
} Query, *QueryPtr, **QueryHandle;

typedef struct SubTuple {
  uint8_t fields;
	uint16_t data; 

} SubTuple;

typedef struct ResultTuple {
	uint8_t qid;               //1   
	uint8_t replyType;         //2 Query or Notification
	uint8_t supportedClasses;  //3 bit mask to be defined
	uint8_t numTuples;         //4 
	uint8_t index;             //5
	uint8_t fields[MAX_ATTR];
	uint16_t data[MAX_ATTR]; 

	//SubTuple subTuple[5];
} ResultTuple, *ResultTuplePtr, **ResultTupleHandle;

/*
typedef struct ResultTuple {
	uint8_t qid;
	uint8_t dummy; //for testing
  uint8_t numFields;
  uint8_t numConds;
  uint8_t fields[FIELD_SIZE];
  uint16_t data[FIELD_SIZE];

} ResultTuple, *ResultTuplePtr, **ResultTupleHandle;
*/
//----------------------------------------------------------------------------//
//                              Functions                                     //
//----------------------------------------------------------------------------//

/**
 *
 **/






#endif
