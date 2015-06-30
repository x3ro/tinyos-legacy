#include "SELECT_OPERATOR.h"
#include <stdlib.h>
#include <string.h>

#define TOS_FRAME_TYPE AGG_OPERATOR_frame
TOS_FRAME_BEGIN(SELECT_OPERATOR_frame) {
  ParsedQuery *qs;
  Tuple *t;
  Expr *e;
}
TOS_FRAME_END(SELECT_OPERATOR_frame);
TOS_TASK(doFilter);


TinyDBError TOS_COMMAND(SELECT_OPERATOR_PROCESS_TUPLE)(ParsedQuery *qs, Tuple *t, Expr *e) {
  VAR(qs) = qs;
  VAR(t) = t;
  VAR(e) = e;

  TOS_POST_TASK(doFilter);
  return err_NoError;
}

TOS_TASK(doFilter) {
  ParsedQuery *qs = VAR(qs);
  Tuple *t = VAR(t);
  Expr *e = VAR(e);

  OpValExpr ex = e->ex.opval;
  short size = TOS_CALL_COMMAND(SEL_OP_GET_FIELD_SIZE)(qs, (char)ex.field);
  char *fieldBytes = TOS_CALL_COMMAND(SEL_OP_GET_FIELD_PTR)(qs, t, (char)ex.field);
  short fieldVal = 0;
  short i;
  bool result = FALSE;


  for (i = 0; i < size; i++) {
    unsigned char b = (*fieldBytes++);
    fieldVal += ((unsigned short)b)<<(i * 8);    
  }


  switch (ex.op) {
  case EQ:
    result = (fieldVal == ex.value);
    break;
  case NEQ:
    result = (fieldVal != ex.value);
    break;
  case GT:
    result = (fieldVal > ex.value);
    break;
  case GE:
    result = (fieldVal >= ex.value);
    break;
  case LT:
    result = (fieldVal < ex.value);
    { char str1[10];
    char str2[10];
    itoa(fieldVal, str1, 10);
    itoa(ex.value, str2, 10);
    strcat(str1, ",");
    strcat(str1, str2);

    statusMessage(str1);
    }
    break;
  case LE:
    result = (fieldVal <= ex.value);
    break;
  }
  
  printf ("DID SELECT, fieldVal = %d, ex.value = %d, result = %d\n", fieldVal, ex.value, result);

  TOS_SIGNAL_EVENT(SELECT_OPERATOR_PROCESSED_TUPLE)(t, qs, e, result);
}
