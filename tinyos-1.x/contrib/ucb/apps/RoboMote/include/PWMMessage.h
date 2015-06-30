// @author John Breneman <johnyb_4@berkeley.edu>
 
enum
{
 AM_PWMMSG = 4,
};
 
typedef struct PWMMsg
{
  uint16_t steer1;         // 0 - 255
  uint16_t steer2;         // 0 - 255
  uint16_t throttle1;      // 0 - 255
  uint16_t throttle2;      // 0 - 255
} PWMMsg_t;
