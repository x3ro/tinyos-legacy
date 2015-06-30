enum {
  MAXX = 40,
  MAXY = 40,
  
  MAX_SEND_QLEN = 8,
  MAX_RECV_QLEN = 4,
  MAX_QUERY_BUF_LEN = 26,
#if 0
  MAX_NODE_NUM = 2,
  MAX_LINK_NUM = 1,
#endif
  MAX_NODE_NUM = 5,
  MAX_LINK_NUM = 5,
  //MAX_NODE_NUM = 10,
  
  IDLE_PERIOD = 1000,

  BEACON = 0,
  GREEDY = 1,
  CONSOLE_QUERY = 2,
  CONSOLE_QUERY_REPLY = 3,
  CONSOLE_ZONE = 4,
  CONSOLE_ZONE_REPLY = 5,
  CONSOLE_CREATE = 6,
  CONSOLE_CREATE_REPLY = 7,
  CONSOLE_DROP = 8,
  CONSOLE_DROP_REPLY = 9,
  CONSOLE_START = 10,
  CONSOLE_STOP = 12,
};

#if 0
Coord Address[2] = {
  {10, 20},
  {30, 20},
};
#endif

Coord Address[MAX_NODE_NUM] = {
  {5, 5},
  {5, 25},
  {5, 35},
  {15, 30},
  {30, 30},
};

/*
Coord Address[MAX_NODE_NUM] = {
  {5, 10},
  {5, 35},
  {15, 5},
  {15, 15},
  {15, 30},
  {25, 5},
  {25, 15},
  {25, 30},
  {35, 10},
  {35, 35},
};*/

Coord NeighbHood[MAX_LINK_NUM] = {
  {0, 1},
  {1, 2},
  {1, 3},
  {2, 3},
  {3, 4},
};

#if 0
Coord NeighbHood[MAX_LINK_NUM] = {
  {0, 1},
};
#endif
