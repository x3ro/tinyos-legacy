typedef struct {
   uint8_t  id;        // id of client application
   uint8_t  indx;      // user's index for the alarm
   uint32_t wake_time; // in seconds;  ffffffff => inactive
   } sched_list;
// The following is the maximum number of wakeups scheduled
#define sched_list_size 20
// Change the followinging to 1000 for once-per-second Timer granularity 
// but please, INTER_RATE should evenly divide 1000 (see AlarmM.nc)  
#define INTER_RATE 2 
   
