//A bunch of constants

//max number of expressions in a query
//#define  MAX_QUERY 16
#define  MAX_QUERY 2
#define  NUM_EPOCH_LEVEL 4

#define  BASE_PERIOD 500 //min sample rate: 0.5 second

#define  NEGINF -2000
#define  INF 2000

//interval tree
#define  NUM_ATTRIBS_IN_INDEX 2
#define  NIL 0xff
//#define  MAX_INTERVAL_BUF 64
#define  MAX_INTERVAL_BUF 2

//Histogram
#define HIST_SIZE 32 //2^n to make the tree easier to build and more balanced
#define MAX_TEMP 1024
#define MIN_TEMP 0
#define MAX_LIGHT 1024 
#define MIN_LIGHT 0


#define SUBBAND_SIZE_TEMP ((MAX_TEMP-MIN_TEMP)/HIST_SIZE)
#define SUBBAND_SIZE_LIGHT ((MAX_LIGHT-MIN_LIGHT)/HIST_SIZE)

//network topology
#define NUM_CLUSTERS_X 1 //how many clusters in a row
#define NUM_CLUSTERS_Y 2 //how many clusters in a column
#define NUM_CLUSTERS (NUM_CLUSTERS_X * NUM_CLUSTERS_Y)
#define CLUSTER_SIZE 9


typedef uint8_t EpochLevel;
//check epoch_factor for the radio of different epoches
enum {
    L1 = 1, 
    L2 = 2, 
    L3 = 3, 
    L4 = 4 
};

typedef enum {
//    Err_NONE = 0,

    //Network error
    Error_Network_HeaderTooLarge = 11,
    Error_Network_MessageQueueFull = 12,
    
    //Query index error
    Err_QueryIndex_Pending = 21,
    Err_QueryIndex_QueryExist = 22,
    Err_QueryIndex_BufferFull = 23,
    Err_QueryIndex_QueryNotFound = 24,

    //interval tree error
    Err_IntervalTree_Full = 31,
    Err_IntervalTree_NotFound = 32,
    Err_IntervalTree_IntNotFound = 33,

    Err_Rate_Invalid = 80 //system
} ErrorCode;
  
//Arithmetic Operator
typedef uint8_t Op;
enum {
    EQ = 0,
    NEQ = 1,
    GT = 2,
    GE = 3,
    LT = 4,
    LE = 5
};

//logical operator
//Only consider AND now.

//aggregate operator
typedef uint8_t AggOp;
enum {
    NO = 0,
    AVG = 1,
    MIN = 2,
    MAX = 3,
    SUM = 4,
    DELTA = 5,
    TREND = 6 //for later use?
};

//query types
//type 1 query means query over data
//type 2 query means query over query
enum {
    //type 1
    CT_QUERY = 0, //continous query or persistent query
    OT_QUERY = 1,  //one time query
    //type 2
    Q_QUERY = 2
};
enum {
    //for type 1 query
    QOP_SELECT = 0,
    QOP_INSERT = 1,
    QOP_DELETE = 2,
    QOP_JOIN = 3,
    QOP_UPDATE = 4,
    //for type 2 query
    QOP2_ESTIMATE_OVERLAP = 5,
    QOP2_ADD_QUERY = 6,
    QOP2_DELETE_QUERY = 7,
    QOP2_UPDATE_EPOCH = 8,
    QOP2_UPDATE_QOR = 9,
    QOP2_ADD_TREND_QUERY = 10,
    QOP2_STOP_TREND_QUERY = 11
};

//Data and Metadata attributes
typedef uint8_t Attrib;
enum {
    //mote id
    NID = 0,
    LOCATION_X = 1,
    LOCATION_Y = 2,
    TIMESTAMP_attr = 3,
    //sensor data
    TEMP = 4,
    LIGHT = 5,
	MAG = 6
};

typedef struct Tuple {
    uint16_t nid;
    uint16_t loc_x;
    uint16_t loc_y;
    uint16_t time_stamp;
    uint16_t temp;
    uint16_t light;
} Tuple, *TuplePtr;

//simple condition, no aggregate
typedef struct {
    Attrib attr;
    Op op;
    int16_t val;
} Condition, *ConditionPtr;

//the number of nodes used for a query determines the quality of result
typedef uint8_t QOR;
enum {
    STOPPED = 0, //reserved for later used
    LOW = 1,
    MEDIAN = 2,
    HIGH = 3,
    UNSPECIFIED = 4,
    TRIGGER = 5,
    TRIGGERED = 6
};

enum {
    BLACK = 0,
    RED = 1
};

typedef struct IntervalStat {
    int16_t lb; //left bound  (e.g., 32)
    int16_t rb; //right bound (e.g., 1023)
    //    int16_t hits; //number of sample readings falling within this range
    int16_t max; //max value of this sub rooted at this node


    uint8_t color; //red-black tree
  uint8_t left;   // left child index
  uint8_t right; // right child index
  uint8_t parent;  // parent index

  uint8_t qid;    // query id (seq no)
  uint8_t query_info_index; // pointer(index) of query buffer 
} IntNode, *IntNodePtr;

//do binary search to locate the subband into which a sample falls
typedef struct HistNode {
    int16_t key;
    uint8_t left;
    uint8_t right;
    uint16_t hits;
} HistNode;

typedef struct QueueNode {
    uint8_t key;
    uint8_t node;
    uint8_t qid;
    uint8_t next;
} QueueNode;

typedef struct CurvSegment {
    uint8_t start;
    uint8_t end;
    float slope;
} CurvSegment;
#define NUM_CURVSEGS 3
typedef struct QoRCurv {
    CurvSegment curvs[NUM_CURVSEGS];
} QoRCurv;

#define NUM_QOR_CURVS 4

typedef struct QueryStatics{
    uint16_t num_match;
    uint16_t num_exclusive_match;
} QueryStatistics, *QueryStatisticsPtr;

typedef uint8_t IntervalNodePtr;


/* ------------------------------------------------------ */
//Node topology
typedef uint8_t Role;
enum {
    SUPER_COOR = 0,
    COOR = 1,
    MEMBER = 2
};

/* ------------------------------------------------------ */
// Network
enum {
    AM_QUERYMESSAGE = 110,
    AM_PARSEDQUERY = 111,
    AM_QUERYRESPONSE = 113,
    AM_PARSEDQUERY2 = 115,
    AM_QUERYRESPONSE2 = 116,  

    AM_DBCOMMANDMSG = 121,
    AM_DBCOMMANDRSP = 122,

    AM_SDBMONITORMSG = 131,
    AM_SDBMONITORRESETMSG = 132,

    //communication with PC
    AM_QUERYMESSAGEFROMPC = 110,
    AM_PARSEDQUERYTOPC = 111,
    AM_QUERYRESPONSETOPC = 113,
    AM_PARSEDQUERY2TOPC = 115,
    AM_QUERYRESPONSE2TOPC = 116,

    AM_LOCATIONINFO = 131,
    AM_DBCOMMANDMSGFROMPC = 121
};

/* ------------------------------------------------------ */
//Command
enum {
    CmdTest = 0,
    CmdMeasureTime = 1,
    CmdReadLog = 2,
    CmdSenseTemp = 3,

    CmdRadioLouder = 11,
    CmdRadioQuieter = 12
};

enum {
    Test_SearchIndexTree = 0,
    Test_BuildIndexTree = 1
};

typedef struct {
    uint16_t destaddr;
    uint8_t test_id;
    uint8_t dummy;
    uint16_t test_counts;
} cmd_measure_time_args;

typedef struct {
    uint16_t destaddr;
    uint16_t freq;
} cmd_sense_temp_args;

typedef struct {
    uint16_t destaddr;
    uint16_t line_num;
} cmd_read_log_args;

typedef struct {
    uint16_t destaddr;
} cmd_radio_louder_args;

typedef struct {
    uint16_t destaddr;
} cmd_radio_quieter_args;

typedef struct DBCommandMsg {
    int8_t seqno;
    int8_t action;
    uint16_t srcaddr;
    uint8_t hop_count;
    uint8_t dummy;
    union {
	cmd_measure_time_args mt_args;
	cmd_read_log_args rlog_args;
	cmd_radio_louder_args rl_args;
	cmd_radio_quieter_args rq_args;
	cmd_sense_temp_args st_args;
	uint8_t untyped_args[0];
    } args;
} DBCommandMsg, *DBCommandMsgPtr;


typedef struct QueryMessage {
    uint8_t qtype;//1
    uint8_t qid; //2
    uint8_t qop;//3
    uint8_t epoch;//4
    uint8_t qor;//5
    uint8_t qorCurv;//6
    uint8_t attrib;//7
    uint8_t aggOp;//8
    uint8_t numConds;//9
    //    uint8_t untyped_args[1];//10 for byte padding
    Condition conds[4];//25
} __attribute__((packed)) QueryMessage, *QueryMessagePtr;


typedef struct DBCommandMsgFromPC {
    int8_t seqno;
    int8_t action;
    uint16_t srcaddr;
    uint8_t hop_count;
    uint8_t dummy;
    union {
	cmd_measure_time_args mt_args;
	cmd_read_log_args rlog_args;
	cmd_radio_louder_args rl_args;
	cmd_radio_quieter_args rq_args;
	cmd_sense_temp_args st_args;
	uint8_t untyped_args[0];
    } args;
    uint16_t origin;
    uint16_t sequence;
} DBCommandMsgFromPC;

typedef struct QueryMessageFromPC {
    uint8_t qtype;//1
    uint8_t qid; //2
    uint8_t qop;//3
    uint8_t epoch;//4
    uint8_t qor;//5
    uint8_t qorCurv;//6
    uint8_t attrib;//7
    uint8_t aggOp;//8
    uint8_t numConds;//9
    //uint8_t untyped_args[1];//10 for byte padding
    Condition conds[4];//25
    uint16_t origin;
    uint16_t sequence;
}   __attribute__((packed)) QueryMessageFromPC;

#define BUFFER_SIZE 4
typedef struct SDBMonitorMsg {
    uint16_t sourceMoteID;
    uint16_t lastSampleNumber;
    uint16_t channel;
    uint16_t data[BUFFER_SIZE];
}  SDBMonitorMsg;

typedef struct SDBMonitorResetMsg {
}  SDBMonitorResetMsg;

//type 1 query
typedef struct ParsedQuery {
    uint8_t qtype;//1
    uint8_t qid; //2
    uint8_t qop;//3
    uint8_t epoch;//4
    uint8_t qor;//5
    uint8_t qor_curv;//6
    uint8_t attrib;//7
    uint8_t aggOp;//8
    uint8_t numConds;//9
    Condition conds[2];//18 get rid of location conds
} __attribute__((packed)) ParsedQuery, *ParsedQueryPtr;

//type 2 query
typedef struct ParsedQuery2 {
    uint8_t qtype;//1
    uint8_t qid;//2
    uint8_t qop; //3
    uint8_t qqid; //4 the query this type2 query is operating on
    uint8_t new_epoch;//5
    uint8_t new_qor;//6
    uint8_t new_qor_curv;//7
    uint8_t new_aggOp;//8
} __attribute__((packed)) ParsedQuery2, *ParsedQuery2Ptr;
//typedef QueryMessagePtr ParsedQueryPtr;


//type 1 query response
typedef struct QueryResponse {
    uint16_t node;
    uint16_t seqno;
    int16_t data;
    int8_t detect;
    uint8_t numMatch;
    uint8_t qid[15];
} __attribute__((packed)) QueryResponse, *QueryResponsePtr;

typedef struct QueryResponse2 {
    uint16_t node;
    uint16_t seqno; //seq no
    uint8_t qid;
    uint8_t qqid;
    uint16_t overlap;
    uint16_t nonoverlap;
    uint16_t total_match;
} __attribute__((packed)) QueryResponse2, *QueryResponse2Ptr;


//in order to let pc extract origin and seq conveniently
//we include origin and seq in the structs on which java classes are generated

typedef struct ParsedQueryToPC {
    uint8_t qtype;//1
    uint8_t qid; //2
    uint8_t qop;//3
    uint8_t epoch;//4
    uint8_t qor;//5
    uint8_t qor_curv;//6
    uint8_t attrib;//7
    uint8_t aggOp;//8
    uint8_t numConds;//9
    Condition conds[2];//17 get rid of location conds
    uint16_t origin; //19
    uint16_t sequence; //21
    uint16_t dest; //23
} __attribute__((packed)) ParsedQueryToPC;

//type 2 query
typedef struct ParsedQuery2ToPC {
    uint8_t qtype;//1
    uint8_t qid;//2
    uint8_t qop; //3
    uint8_t qqid; //4 the query this type2 query is operating on
    uint8_t new_epoch;//5
    uint8_t new_qor;//6
    uint8_t new_qor_curv;//7
    uint8_t new_aggOp;//8
    uint16_t origin; //9
    uint16_t sequence; //10
    uint16_t dest;
} __attribute__((packed)) ParsedQuery2ToPC;
//typedef QueryMessagePtr ParsedQueryPtr;


//type 1 query response
typedef struct QueryResponseToPC {
    uint16_t node;
    uint16_t seqno;
    int16_t data;
    int8_t detect;
    uint8_t numMatch;
    uint8_t qid[15];
    uint16_t origin;
    uint16_t sequence;
    uint16_t dest;
} __attribute__((packed)) QueryResponseToPC;

typedef struct QueryResponse2ToPC {
    uint16_t node; //2
    uint16_t seqno; //seq no//4
    uint8_t qid; //5
    uint8_t qqid;//6
    uint16_t overlap; //8
    uint16_t nonoverlap; //10
    uint16_t total_match; //12
    uint16_t origin; //14
    uint16_t sequence; //16
    uint16_t dest;
} __attribute__((packed)) QueryResponse2ToPC;

enum {
    APPROACH = 0,
    LEAVE = 1
};
typedef struct LocationInfo {
    uint16_t cluster_id;
    uint16_t node;
    uint16_t next_cluster;
    uint8_t direction; //0:approach; 1:leave
    uint8_t qid;
    uint16_t origin;
    uint16_t sequence;
    uint16_t dest;    
} __attribute__((packed)) LocationInfo, *LocationInfoPtr;

//NodeState
enum {
    //SUPER COOR
    SUPER_IDLE = 1,
    //COOR
    COOR_IDLE = 11,
    COOR_PROCESS_QUERY1 = 12,
    COOR_SEND_FOR_ESTIMATE = 13,
    COOR_WAIT_FOR_ESTIMATE = 14,
    COOR_ALLOC_QUERY = 15,
    COOR_UPDATE_EPOCH = 16,
    COOR_POST_PROCESSQUERY1 = 17,
    COOR_SEEK_TREND = 18,
    COOR_STOP_TREND = 19,
    //MEMBER
    MEMBER_IDLE = 21,
    MEMBER_PROCESS_QUERY1 = 22,
    MEMBER_QESTIMATE_READY = 23,
    MEMBER_PROCESS_QUERY2 = 24,
    MEMBER_PROCESS_TUPLE = 25
    
};

//monitor state

enum {
    NORMAL = 1,
    AGILE = 2,
    DETECTING = 3
};

#ifdef PRI_SCHED
typedef struct ProcessCMDMsgTaskContext {
    TOS_Msg cmdMsg;
} ProcessCMDMsgTaskContext, *ProcessCMDMsgTaskContextPtr;

typedef struct ProcessQueryMsgTaskContext {
    TOS_Msg queryMsg;
} ProcessQueryMsgTaskContext, *ProcessQueryMsgTaskContextPtr;

typedef struct ProcessDataTaskContext {
    Tuple data;
} ProcessDataTaskContext, *ProcessDataTaskContextPtr;

#define CMDMSG_BUFFER_SIZE 2
#define QUERYMSG_BUFFER_SIZE 2
#define DATA_BUFFER_SIZE 4
#endif


#ifdef PC
#include <assert.h>
#define ASSERT(x) assert(x)
#else
#define ASSERT(x) \
  do { \
    if(!(x)) \
      call Leds.redOn(); \
  } while(0)
#endif
