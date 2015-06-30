typedef struct {
  float x;
  float y;
} point;

typedef struct LocationMsg {
  uint16_t sourceaddr;
  point location;
} LocationMsg;

enum {
  AM_LOCATIONMSG = 176
};
