enum {
  AM_GROUPERCMDMSG = 4,
};

typedef struct GrouperCmdMsg {
  bool treeIDChanged:1;
  bool newGroupIDChanged:1;
  bool pad:6;

  uint16_t treeID;
  uint8_t  newGroupID;
} GrouperCmdMsg;
