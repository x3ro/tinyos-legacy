typedef enum {
  err_NoError = 1,
  err_UnknownError = 0,
  err_OutOfMemory = 2,
  err_UnknownAllocationState = 3,
  err_InvalidGetDataCommand = 4,
  err_InvalidAggregateRecord =5,
  err_NoMoreResults = 6,
  err_MessageBufferInUse = 7,
  err_MessageSendFailed = 8,
  err_RemoveFailedRouterBusy = 9,
  err_MessageBufferFull = 10
} TinyDBError;


//probably not supposed to do this in tinyos, but fuck it...
void signalError(TinyDBError err);
void statusMessage(char *m);
