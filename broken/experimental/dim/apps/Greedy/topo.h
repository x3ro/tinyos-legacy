#define MAXX 40
#define MAXY 40
#define MAX_NODE_NUM 5

typedef struct {
  uint16_t x;
  uint16_t y;
} Coord, *CoordPtr;

Coord Address[MAX_NODE_NUM] = {
  {10, 10},
  {5, 25},
  {5, 35},
  {15, 30},
  {30, 20},
};
