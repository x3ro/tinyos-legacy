typedef struct {
   uint8_t  id;        // id of client application
   uint8_t  indx;      // user's index for the alarm
   uint32_t wake_time; // in seconds;  ffffffff => inactive
   } sched_list;
// The following is the maximum number of wakeups scheduled
#define sched_list_size 20
   
