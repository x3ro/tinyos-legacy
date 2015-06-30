#ifndef NETWORK_CONTROL_MESSAGES_H
#define NETWORK_CONTROL_MESSAGES_H

// #define MSG_CONTROL 252
#define NC_DISABLE_UPPER_PORTION 1
#define NC_ENABLE_UPPER_PORTION 2
#define NC_DISABLE4 4

/* Format of the control packet (starting from TOS_Msg.data)*/
  typedef struct 
  {
    uint16_t nOp, nLength;
    uint16_t maSender;
    uint16_t maStart1, maEnd1, 
      maStart2, maEnd2, 
      maStart3, maEnd3,
      maStart4, maEnd4;
  } ControlPkt;
       
#endif
