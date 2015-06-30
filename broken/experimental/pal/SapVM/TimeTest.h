typedef struct TimeTestMsg {
  uint32_t count;
  uint32_t ms;
  uint32_t ticks;
  uint32_t remaining;
  uint32_t offset;
  bool synchronized;
} TimeTestMsg;

enum {
  AM_TIMETESTMSG = 0x99,
};
