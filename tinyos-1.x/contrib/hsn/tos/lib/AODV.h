typedef struct {
  wsnAddr   dest;
  wsnAddr   nextHop;
  uint16_t  destSeq;
  uint8_t   numHops;
} __attribute__ ((packed)) AODV_Route_Table;


typedef struct {
  wsnAddr   dest;
  wsnAddr   src;
  wsnAddr   nextHop;
  uint16_t  rreqID;
  uint16_t  destSeq;
  uint8_t   numHops;
} __attribute__ ((packed)) AODV_Route_Cache;



#define AODV_ROOT_NODE 0
