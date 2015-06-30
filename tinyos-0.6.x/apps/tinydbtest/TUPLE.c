#include "TUPLE.h"
#include <string.h>

/* Routines to manage a tuple */
short typeToSize(TOSType type);

//return the size of a tuple for a given query
short TOS_COMMAND(TUPLE_SIZE)(ParsedQuery *q) {
  short i;
  short size = sizeof(Tuple) - sizeof(byte);
  for (i = 0 ; i < q->numFields; i++) {
    size += TOS_CALL_COMMAND(TUPLE_FIELD_SIZE)(q, i);

  }
  return size;
}

//return the size of a field for a given query
short TOS_COMMAND(TUPLE_FIELD_SIZE)(ParsedQuery *q, char fieldNo) {
  if (!QUERY_FIELD_IS_NULL(q->queryToSchemaFieldMap[(short)fieldNo])) {
    return typeToSize(TOS_CALL_COMMAND(TUPLE_GET_ATTR)(q->queryToSchemaFieldMap[(short)fieldNo])->type);
  } else
    return 0;
}

//get the value of the specified field in the specified tuple
//of the specified query
//fieldIdx begins at 0
char *TOS_COMMAND(TUPLE_GET_FIELD)(ParsedQuery *q, Tuple *t, char fieldIdx) {
  if ((t->notNull & (1 << fieldIdx)) == 0 ) return NULL;
  return TOS_COMMAND(TUPLE_GET_FIELD_PTR)(q, t, fieldIdx);
}

char *TOS_COMMAND(TUPLE_GET_FIELD_PTR)(ParsedQuery *q, Tuple *t, char fieldIdx) {
  short i;
  short offset = 0;

  for (i = 0; i < fieldIdx; i++) {
    offset += TOS_CALL_COMMAND(TUPLE_FIELD_SIZE)(q, i);
  }
  return (char *)(&t->fields[offset]);
}

void TOS_COMMAND(SET_TUPLE_FIELD)(ParsedQuery *q, Tuple *t, char fieldIdx, char *data) 
{
	char *dest = TOS_COMMAND(TUPLE_GET_FIELD_PTR)(q, t, fieldIdx);
	if (dest != data)
		memcpy(dest, data, TOS_CALL_COMMAND(TUPLE_FIELD_SIZE)(q, fieldIdx));
	t->notNull |= (1 << fieldIdx);
}

void TOS_COMMAND(TUPLE_INIT)(ParsedQuery *q, Tuple *t) {
  t->notNull = 0; //all fields null
  t->qid = q->qid;
  t->numFields = q->numFields;
}

//return true iff the query is complete (e.g. all fields that are not supposed to be null are non-null)
bool TOS_COMMAND(IS_TUPLE_COMPLETE)(ParsedQuery *q, Tuple *t) {
  short i;
  
  for (i = 0; i < q->numFields; i++) {
    if (!QUERY_FIELD_IS_NULL(q->queryToSchemaFieldMap[i])) { //if field is not supposed to be null
      if ((t->notNull & (1 << i)) == 0) return FALSE; //but it is, return false
    }
  }
  return TRUE;  //all fields that are not supposed to be null are non-null
}


//scan the tuple, looking for null fields that shouldn't be null
//(e.g. fields that need to be filled in)
AttrDescPtr TOS_COMMAND(GET_NEXT_QUERY_FIELD)(ParsedQuery *q, Tuple *t) {
  short i;

  for (i = 0; i < q->numFields; i++) {
    if (!QUERY_FIELD_IS_NULL(q->queryToSchemaFieldMap[i]) && //shouldn't be null
	(t->notNull & (1 << i)) == 0 ) { //but is
      printf("getting field : %d\n", i); //fflush(stdout);
      return TOS_CALL_COMMAND(TUPLE_GET_ATTR)(q->queryToSchemaFieldMap[i]);
    }
  }
  return NULL;
}


short typeToSize(TOSType type) {
	return SIZEOF(type);
}
