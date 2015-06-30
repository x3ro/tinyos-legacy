includes AM;

interface AODVMsg {
   command uint8_t getSequenceNum(TOS_MsgPtr msg);
   command uint8_t getTTL(TOS_MsgPtr msg);
   command uint8_t getNext(TOS_MsgPtr msg);
}
