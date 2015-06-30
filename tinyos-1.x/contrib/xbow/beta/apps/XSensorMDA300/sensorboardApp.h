/* sensorboard.h - hardware specific definitions for the MDA300 
*/

typedef struct XDataMsg {
  uint8_t  board_id;
  uint8_t  packet_id;
  uint8_t  node_id;
  uint8_t  parent;       // 4
  uint16_t seq_no;
  uint16_t adc0;  
  uint16_t adc1;
  uint16_t adc2;
  uint16_t vref;
  uint16_t humid;
  uint16_t humtemp;
} __attribute__ ((packed)) XDataMsg;


enum {
    XSENSORMSG_ID = 50,
    XMULTIHOPMSG_ID = 51         // xsensor multihop 
};
