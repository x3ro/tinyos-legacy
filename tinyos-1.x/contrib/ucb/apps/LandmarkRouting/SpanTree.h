
#ifndef _H_SpanTree_h
#define _H_SpanTree_h

typedef struct
{
  uint8_t build;
  uint8_t route;
  uint8_t surge;
} SpanTreeRetries_t;

typedef struct
{
  uint8_t hopCount;
  uint16_t parent;
  uint16_t signalStrength;
} SpanTreeRoute_t;

// crumb routing:
// FIXME: watch wrapping on crumbseqno
typedef struct
{
  uint16_t crumbseqno;
  uint16_t parent;
} SpanTreeCrumb_t;

typedef struct
{
  SpanTreeRoute_t Route1;
  SpanTreeRoute_t Route2;
  uint16_t BCastSeqNo;
  SpanTreeCrumb_t Crumb1;
  SpanTreeCrumb_t Crumb2;
  uint16_t numPacketReceived;
} SpanTreeStatus_t;

typedef struct
{
  SpanTreeRoute_t Route1; // 5 bytes
  uint16_t BCastSeqNo;    // 2 bytes
  SpanTreeCrumb_t Crumb1; // 4 bytes
  SpanTreeCrumb_t Crumb2; // 4 bytes
  uint16_t numPacketReceived; // 2 bytes = 17 bytes
} SpanTreeStatusConcise_t;

#endif//_H_SpanTree_h

