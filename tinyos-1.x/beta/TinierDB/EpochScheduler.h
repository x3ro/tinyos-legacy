typedef enum {
  ES_SUCCESS = 0,
  ES_FAIL = 1,
  ES_CANT_SCHEDULE = 2, //requested epoch dur / sample period cannot be satisfied
  ES_INVALID_SCHED = 3, //unknown schedule id
  ES_INVALID_TIME = 4, //epoch scheduler can't schedule the specified times

} ESResult;



