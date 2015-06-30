/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 * Authors:	Sam Madden
 *              Design by Sam Madden, Wei Hong, and Joe Hellerstein
 * Date last modified:  6/26/02
 *
 *
 */


typedef enum {
  err_NoError = 1,
  err_UnknownError = 0,
  err_OutOfMemory = 2,
  err_UnknownAllocationState = 3,
  err_InvalidGetDataCommand = 4,
  err_InvalidAggregateRecord =5,
  err_NoMoreResults = 6, //no more results this epoch
  err_MessageBufferInUse = 7, //generic message failure due to shared buffer conflict
  err_MessageSendFailed = 8, //generic message failure
  err_RemoveFailedRouterBusy = 9,
  err_MessageBufferFull = 10, //no space in data buffer for data tuple
  err_MSF_DelMsg = 11, //MSF == message send failed , on message deletion
  err_MSF_DelMsgBusy = 12, //message send failed due to radio busy on message deletion
  err_MSF_ForwardKnownQuery = 13, //message send failed while forwarding a known query
  err_MSF_ForwardKnownQueryBusy = 14, // due to radio busy
  err_MSF_ForwardNewQuery = 15, //message send failed while forwarding a new query
  err_MSF_ForwardNewQueryBusy = 16,// due to radio busy 
  err_MSF_SendWaiting = 17, //message send failed sending an outgoing data tuple
  err_MSF_SendWaitingBusy = 18,  // due to radio busy
  err_InvalidIndex = 19, //and invalid index was passed to an accessor routine
  err_UnsupportedPolicy = 20, //an unsupported buffer eviction policy was requested
  err_ResultBufferInUse = 21,
  err_ResultBufferBusy = 22,
  err_UnknownCommand = 23,
  err_UnsupportedBuffer = 24,
  err_IndexOutOfBounds = 25,
  err_InvalidQueryId = 26, //specified query id was incorrect
  err_AlreadyTupleResult = 27, //tuple-based query results can't contain aggregate results also
  err_InvalidResultType = 29
} TinyDBError;



/* Tuples are always full, but with null compression
   Fields in the tuple are defined on a per query basis,
   with mappings defined by the appropriate query
   data structure.  
   If a field is null (e.g. not defined on the local sensor), its
   notNull bit is set to 0.

   Tuples should be accesses exclusively through TUPLE.comp
*/

typedef struct {
  char qid;  //1
  char numFields; //2
  long notNull;  //bitmap defining the fields that are null or not null //6
  //bit i corresponds to ith entry in ParsedQuery.queryToSchemaFieldMap
  
  char fields[0]; //Access only through TUPLE.comp!
} Tuple, *TuplePtr, **TupleHandle;


enum {QUERY_FIELD_SIZE = 8,
      COMMAND_SIZE = 8};

/* Fields are just an 8 character name , plus a transformation operator? */
typedef struct {
  char name[QUERY_FIELD_SIZE]; //8
  uint8_t op; //9
} Field, *FieldPtr;


/* We can (optionally) invoke a command in response to a query.
   The command may include a single, short parameter.
*/
typedef struct {
  char name[COMMAND_SIZE]; //8
  bool hasParam;  //9
  short param; //11
} CmdBufInfo;

typedef struct {
  uint16_t numRows;
  BufferPolicy policy;
} RamBufInfo;

typedef union {
  CmdBufInfo cmd;
  RamBufInfo ram; //11
} BufInfo; 



typedef struct {
  uint16_t group;
  //  uint8_t len;
  char *data;
} AggResultRef;

enum {
  kMAX_RESULTS = 4 //(DATA_LENGTH)/sizeof(AggResultRef)
};

//for now, a query result is really just a tuple
typedef struct {
  char qid; //note that this byte must be qid
  int8_t result_idx;
  uint16_t epoch;
  uint8_t qrType;

  union {
    Tuple t;
    char data[DATA_LENGTH];
    AggResultRef buf[kMAX_RESULTS]; //pointers for results
  } d;
  
} QueryResult, *QueryResultPtr;



/* Query consists of a list of fields followed by a list of expressions.  Fields are
   a mapping from query fields to local schema fields.  Fields that are in the query
   but not the local schema are defined to be NULL.

   Access variable size parts of this data structure via PQ_ methods defined above
*/
typedef struct {
  uint8_t qid; //1
  uint8_t numFields; //2
  uint8_t numExprs; //3
  short epochDuration; //in millisecs //5
  short clocksPerSample, clockCount; //9
  short currentEpoch; //11
  BufInfo buf; //22
  uint8_t fromQid; //what queryid should we read from (kNO_QUERY == produce results locally) //23
  uint16_t curResult; //what result idx are we currently reading -- 25
  char bufferType; //see Buffer.h:BufferType //26
  uint8_t bufferId; //27
  uint8_t markedForDeletion; //if non-zero, number of epochs until we remove this query -- 28
  uint16_t queryRoot; //root of this query -- 30
  //mapping from query field to local schema field id 
  char queryToSchemaFieldMap[1]; //access via PQ_GET_FIELD_ID, test for NULL with QUERY_FIELD_IS_NULL // 31
  //offset: sizeof(Query) + (numFields - 1) * sizeof(char) 
  //Expr exprs[1];  -- access via PQ_GET/SET_EXPR
  //Tuple t;  -- allocate one tuple per query -- access via PQ_GET_TUPLE
} ParsedQuery, *ParsedQueryPtr;

enum {
  kONE_SHOT = 0xFFFF, //instead of epoch duration, just drain all the results in a buffer
  NULL_QUERY_FIELD = 0x80,
  GROUP_FIELD = 0x7F //magic code that indicates the value of this 
                     //attribute is the aggregate group of a nested query
};


/* Query gets translated into parsed query by mapping field names into
   local field ids
   
   Access via GET_, SET_ methods described above
   Note that SET_ methods don't set knownFields or knownExprs bitmaps
*/
typedef struct {
  uint8_t qid;
  uint8_t numFields;
  uint8_t numExprs;
  uint8_t fromQid; //what queryid should we read from (kNO_QUERY == produce results locally)
  char bufferType; //see Buffer.h:BufferType
  uint8_t bufferId; //6

  short epochDuration; //in millisecs
  short knownFields; //bitmask indicating what fields we've seen
  short knownExprs; //bitmask indicating what exprs we've seen //12
  uint16_t queryRoot; //root of this query

  bool hasBuf; //13
  BufInfo buf; //24

  Field fields[1]; //access via GET_FIELD, SET_FIELD //33
  //Expr exprs[1] //access vis GET_EXPR, SET_EXPR
} Query, *QueryPtr;



enum {
  MAX_FIELDS = 16,
  MAX_EXPRS = 16,
  kNO_QUERY = 0xFF

};

typedef char Op;

enum {
  EQ = 0,
  NEQ = 1,
  GT = 2,
  GE = 3,
  LT = 4,
  LE = 5
};


typedef char Agg;
enum {
  SUM = 0,
  MIN = 1,
  MAX = 2,
  COUNT = 3,
  AVERAGE = 4,
  MIN3 = 5,
  NOOP = 6,
  EXP_AVG = 7,
  WIN_AVG = 8,
  WIN_SUM = 9,
  WIN_MIN = 10,
  WIN_MAX = 11,
  WIN_CNT = 12
};
	
//field operators, for use in exprs
enum {
  FOP_NOOP = 0,
  FOP_TIMES = 1,
  FOP_DIVIDE = 2,
  FOP_ADD = 3,
  FOP_SUBTRACT = 4,
  FOP_MOD = 5,
  FOP_RSHIFT = 6
};

//expressions are either aggregates or selections
//for now we support the simplest imagineable types (e.g.
//no nested expressions, joins, or modifiers on fields)
typedef struct {
  short field;  //2
  Op op; //3
  short value; //5
} OpValExpr;

typedef struct {
  short field;  //2
  short groupingField;  //field to group on //4
  short groupFieldOp; //6
  short groupFieldConst; //8
  
  Agg op; //9
} AggregateExpression;

typedef struct {
  AggregateExpression agg; //9
    union {
	short epochsPerWindow; //11 -- for windowed aggs
	uint8_t newBitsPerSample; //for exponentially decaying aggs
    } u;
  short epochsLeft; //13
} TemporalAggExpr;

enum {
  kNO_GROUPING_FIELD = 0xFFFF
};

//operator state represents the per operator
//query state stored in the tuple router and
//sent to the operators on invocation
typedef char** OperatorStateHandle;

enum {
  kSEL = 0,
  kAGG = 1,
  kTEMP_AGG = 2

};

typedef struct {
  char opType:7;
  bool success:1; //boolean indicating if this query was successfully applied //1
  char idx; //index of this expression in the query //2
  union {
    OpValExpr opval;
    AggregateExpression agg;
    TemporalAggExpr tagg;
  } ex; //15
  short fieldOp; //17 -- from FOP... defines above
  short fieldConst; //19
  
  OperatorStateHandle opState; //21
} Expr, *ExprPtr;


enum {
  kFIRST_RESULT = 0xFF,
  
};

//enums for the QueryResult qrType (what kind of query result)
enum {
  kUNDEFINED = 0,
  kIS_AGG = 1,
  kNOT_AGG = 2,
  kAGG_SINGLE_FIELD = 3
};

typedef struct {
  char qid; //query this result corresponds to
  bool isAgg; //is this an aggregate result, or a base tuple
  uint16_t epoch; //epoch this result corresponds to
  TinyDBError error; //error flag for return
  union {
    uint16_t tupleField; //which record of this result is this?
    struct {
      int16_t group; //aggregate result group id
      uint8_t id;
      uint8_t len; //and length in bytes
    } agg;
  } u;
  char *data; //the data corresponding to this result
} ResultTuple;

//header information that MUST be in every message
//if it is to be send via TINYDB_NETWORK -- we require
//so that TINYDB_NETWORK doesn't have to copy messages
typedef struct {
    short senderid; //id of the sender
    short parentid; //id of senders parent
    uint8_t level; //level of the sender
  //  unsigned char xmitSlots; //number of transmission slots? -- unused now
    unsigned char timeRemaining; //number of clock cyles til end of epoch
  //    short idx; //message index
  uint8_t idx;
} DbMsgHdr;

  /* ----------------------- Query Types ------------------------ */

  //queries have to be decomposed into multiple messages
  //these are sent one by one to fill in a query data structure,
  //which is then converted to a parsed query
  

  //in query message -- is this a field or an expression
  enum {
    kFIELD = 0,
    kEXPR =1,
    kBUF_MSG = 2
  };

  // type of query message
  enum {ADD_MSG = 0,
	DEL_MSG = 1,
	MODIFY_MSG = 2
  };


  /** Message type for carrying query messages */
  typedef struct QueryMessage {
    DbMsgHdr hdr; //7
    char qid; //query id //8 -- note that this byte must be qid
    uint16_t queryRoot; //10
    char msgType;  //type of message (e.g. add, modify, delete q) //11
    char numFields; //12
    char numExprs; //13
    char fromQid; //14
    char bufferType; //15
    short epochDuration; //in millisecs -- 17
    char type;  //is this a field, expression, or output buffer msg -- 18
    char idx; //19
    union {
      Field field;
      Expr expr; //40
      BufInfo buf;
    } u; //40
  } QueryMessage;

  

struct QueryResultMsg {
  DbMsgHdr hdr;
  QueryResult qr;
};

struct UartMsg {
  char data[30];
};



typedef bool *BoolPtr;
typedef char *CharPtr;


enum {
  kDATA_MESSAGE_ID = 100,
  kQUERY_MESSAGE_ID = 101, 
  kQUERY_REQUEST_MESSAGE_ID = 104,
  kMSG_LEN = DATA_LENGTH,
  AM_QUERYRESULTMSG = kDATA_MESSAGE_ID,
  AM_QUERYMESSAGE = kQUERY_MESSAGE_ID,
  AM_UARTMSG = 1,
};



