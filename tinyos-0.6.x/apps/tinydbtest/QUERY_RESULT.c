#include "QUERY_RESULT.h"

/* Query result represents the outcome of a query
   This is not just a tuple since aggregation queries may
   
 */


#define FIRST_QR_BYTE sizeof(DbMsgHdr)

/* Fill out a query result with a single tuple's values 
 Don't just copy a reference to the tuple, since they user may want to
 generate query results from a specified tuple, and then reuse the tuple
 for other purposes
*/
TinyDBError TOS_COMMAND(QUERY_RESULT_FROM_TUPLE)(QueryResult *qr, ParsedQuery *pq, Tuple *t) {
  short size = TOS_CALL_COMMAND(QR_TUPLE_SIZE)(pq);
  char *p,*q;

  qr->qid = pq->qid;
  qr->result_idx = 0;
  p = (char *)t;
  q = (char *)&qr->d.t;
  while (size--)
    *q++ = *p++;
  return err_NoError;
}


/* Return a tuple from a query result.  Note that the resulting tuple may be a pointer
 into the query result data structure 
*/
TinyDBError TOS_COMMAND(QUERY_RESULT_TO_TUPLE_PTR)(QueryResult *qr, ParsedQuery *q, Tuple **t) {
  *t = &qr->d.t;
  return err_NoError;
}

/* Write the query result into the specified byte array.  The number of bytes written
   is guarantted not to exceed QUERY_RESULT_SIZE(qr,q)
*/
TinyDBError TOS_COMMAND(QUERY_RESULT_TO_BYTES)(QueryResult *qr, ParsedQuery *pq, char *bytes) {
  short size = sizeof(QueryResult); //TOS_CALL_COMMAND(QR_TUPLE_SIZE)(pq) + sizeof(*qr) - sizeof(qr->d);
  char *p,*q;

  q = (char *)&bytes[FIRST_QR_BYTE];
  p = (char *)qr;
  while (size--)
    *q++=*p++;
  return err_NoError;
}

/* Convert the specified set of bytes into a query result */
TinyDBError TOS_COMMAND(QUERY_RESULT_FROM_BYTES)(char *bytes, QueryResult *qr, ParsedQuery *pq) {
  short size = sizeof(QueryResult); //TOS_CALL_COMMAND(QR_TUPLE_SIZE)(pq) + (sizeof(*qr) - sizeof(qr->d));
  char *p,*q;
  q = (char *)qr;
  p = (char *)&bytes[FIRST_QR_BYTE];
  while (size--)
    *q++ = *p++;
  return err_NoError;
}

/* Return the query id corresponding to a stream of bytes representing a query result
   (So that callers can determine the value of q to pass into to QUERY_RESULT_FROM_BYTES
*/
short TOS_COMMAND(QUERY_RESULT_QUERY_ID)(char *bytes) {
  return bytes[FIRST_QR_BYTE];
}

/* Return the size required to store the specified query result in a byte
   stream, in bytes 
*/
short TOS_COMMAND(QUERY_RESULT_SIZE)(QueryResult *qr, ParsedQuery *q) {
  return TOS_CALL_COMMAND(QR_TUPLE_SIZE)(q) + sizeof(QueryResult) - sizeof(qr->d.data);
}
