/* @(#)TinySecControl.h
 */

enum { 
  AM_TINYSEC_CONTROL = 251
};

typedef enum {
   TRANSMIT = 1,
   RECEIVE = 2 
} commandType;

typedef struct TinySec_Control_Msg {
  commandType commandSet;
  uint8_t commandMode;
} TinySec_Control_Msg;
