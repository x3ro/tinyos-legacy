enum {
    MAX_PEOPLE = 64
};

struct RegisterMsg
{
  uint16_t localId;
};

struct ReqDataMsg {
  uint32_t currentTime; /* At the base */
  uint32_t lastDataTime;
};

struct DataMsg {
  uint16_t moteId;
  uint8_t seqno;
  uint8_t messageno;
  char data[0];
};

/* A social packet looks like this */
struct SocialPacket {
  uint8_t protocol;
  uint32_t timeInfoStarts;
  uint32_t timeInfoEnds;
  uint16_t timeTogether[MAX_PEOPLE];
};

enum {
  AM_REGISTERMSG = 20,
  AM_IDENTMSG = 21,
  AM_REQDATAMSG = 22,
  AM_DATAMSG = 23
};
