#ifndef __NEIGHBORHOOD_TABLE___
#define __NEIGHBORHOOD_TABLE___
typedef struct{
  unsigned short node;
  unsigned char mr_stable;
  char hop;
  char seqnum;
  unsigned char avg;
  char liveliness;
  unsigned char backward_estimate;
}neighborhood_t;

#define DEFAULT_LIVELINESS 30
#define TABLE_SIZE 6

#endif //__NEIGHBORHOOD_TABLE___
