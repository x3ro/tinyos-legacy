#ifndef __TINYDB__
#define __TINYDB__

#include "TinyDBError.h"
#include "util.h"

/* Tuples are always full, but with null compression
   Fields in the tuple are defined on a per query basis,
   with mappings defined by the appropriate query
   data structure.  
   If a field is null (e.g. not defined on the local sensor), its
   notNull bit is set to 0.

   Tuples should be accesses exclusively through TUPLE.comp
*/
typedef struct {
  char qid;
  char numFields;
  long notNull;  //bitmap defining the fields that are null or not null
  //bit i corresponds to ith entry in ParsedQuery.queryToSchemaFieldMap

  byte fields[1]; //Access only through TUPLE.comp!
} Tuple;

//high bit of query field indicates field is null
#define QUERY_FIELD_IS_NULL(c) (((c) & 0x80) > 0)
#define NULL_QUERY_FIELD 0x80

//accessor macros for Parsed Query data structure
//q is of type (ParsedQuery *)
#define PQ_GET_EXPR(q,n) (*(Expr *)(&((char *)(q))[sizeof(ParsedQuery) + ((q)->numFields - 1) * sizeof(char) + (n) * sizeof(Expr)]))
#define PQ_GET_FIELD_ID(q,n) ((q)->queryToSchemaFieldMap[n]) //note:  may be NULL_QUERY_FIELD
#define PQ_SET_EXPR(q,n,e) (PQ_GET_EXPR(q,n) = (e))
#define PQ_GET_TUPLE_PTR(q) ((Tuple *)(&((char *)(q))[sizeof(ParsedQuery) + ((q)->numFields - 1) * sizeof(char) + ((q)->numExprs) * sizeof(Expr)]))

/* Query consists of a list of fields followed by a list of expressions.  Fields are
   a mapping from query fields to local schema fields.  Fields that are in the query
   but not the local schema are defined to be NULL.

   Access variable size parts of this data structure via PQ_ methods defined above
*/
typedef struct {
  char qid;
  char numFields;
  char numExprs;
  short epochDuration; //in millisecs
  short clocksPerSample, clockCount;
  short currentEpoch;
  
  //mapping from query field to local schema field id 
  char queryToSchemaFieldMap[1]; //access via PQ_GET_FIELD_ID, test for NULL with QUERY_FIELD_IS_NULL
  //offset: sizeof(Query) + (numFields - 1) * sizeof(char) 
  //Expr exprs[1];  -- access via PQ_GET/SET_EXPR
  //Tuple t;  -- allocate one tuple per query -- access via PQ_GET_TUPLE
} ParsedQuery;

//size of PQ without tuple...
#define BASE_PQ_SIZE(q) (sizeof(ParsedQuery) +  (sizeof(char) * ((q)->numFields - 1))  +  (sizeof(Expr) * ((q)->numExprs)))

#define QUERY_FIELD_SIZE 8

//q is of type (Query *) in all of the below
#define QUERY_SIZE(q)(sizeof(Query) + ((q)->numFields-1)*sizeof(Field) + (q)->numExprs * sizeof(Expr))
#define GET_FIELD(q,idx)((q)->fields[idx])
#define SET_FIELD(q,idx,f)((q)->fields[idx]=f)
#define GET_EXPR(q,idx)(*(Expr *)((char *)((q) + sizeof(Query) + ((q)->numFields-1)*sizeof(Field) + (idx) * sizeof(Expr))))
#define SET_EXPR(q,idx,e)(GET_EXPR(q,idx) = e)

#define MAX_FIELDS 16
#define MAX_EXPRS 16

#define FIELDS_COMPLETE(q) (((q).knownFields & 0xFFFF) == 0xFFFF)
#define EXPRS_COMPLETE(q) (((q).knownExprs & 0xFFFF) == 0xFFFF)

typedef struct {
  char name[QUERY_FIELD_SIZE];
} Field;

/* Query gets translated into parsed query by mapping field names into
   local field ids
   
   Access via GET_, SET_ methods described above
   Note that SET_ methods don't set knownFields or knownExprs bitmaps
*/
typedef struct {
  char qid;
  char numFields;
  char numExprs;
  short epochDuration; //in millisecs
  short knownFields; //bitmask indicating what fields we've seen
  short knownExprs; //bitmask indicating what exprs we've seen
  Field fields[1]; //access via GET_FIELD, SET_FIELD
  //Expr exprs[1] //access vis GET_EXPR, SET_EXPR
} Query;


/* Dont use enums -- not at all clear what their size is! */
typedef char Op;


#define EQ 0
#define	NEQ 1
#define GT 2
#define GE 3
#define LT 4
#define LE 5


typedef char Agg;
#define SUM 0
#define MIN 1
#define MAX 2
#define COUNT 3
#define AVERAGE 4
#define MIN3 5
	    
//expressions are either aggregates or selections
//for now we support the simplest imagineable types (e.g.
//no nested expressions, joins, or modifiers on fields)
typedef struct {
    short field;
    Op op;
    short value;
} OpValExpr;

typedef struct {
  short field;
  short groupingField;  //field to group on
  char attenuation;
  Agg op;
} AggregateExpression;

#define kNO_GROUPING_FIELD 0xFFFF


//operator state represents the per operator
//query state stored in the tuple router and
//sent to the operators on invocation
typedef char** OperatorStateHandle;

typedef struct {
  char isAgg;
  bool success; //boolean indicating if this query was successfully applied
  char idx; //index of this expression in the query
  union {
    OpValExpr opval;
    AggregateExpression agg;
  } ex;
  OperatorStateHandle opState;
} Expr;


#define kFIRST_RESULT 0xFF

//for now, a query result is really just a tuple
typedef struct {
    char qid;
    char result_idx;
    short epoch;
    
    union {
	Tuple t;
	char data[DATA_LENGTH]; //maximum size of a message
    } d;
} QueryResult;


//header information that MUST be in every message
//if it is to be send via TINYDB_NETWORK -- we require
//so that TINYDB_NETWORK doesn't have to copy messages
typedef struct {
    short senderid; //id of the sender
    short parentid; //id of senders parent
    byte level; //level of the sender
    unsigned char xmitSlots; //number of transmission slots?
    unsigned char timeRemaining; //number of clock cyles til end of epoch
    short idx; //message index
} DbMsgHdr;




#endif //__TINYDB__

