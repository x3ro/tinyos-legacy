#ifndef _SCPBASE_MSG_H_
#define _SCPBASE_MSG_H_

// Defines a TOS message encapsulated within an SCP packet

typedef ScpHeader SCPBaseHeader;

#define PAYLOAD_LEN (PHY_MAX_PKT_LEN - sizeof(SCPBaseHeader) - 2)

typedef struct {
    
    uint8_t type;
    uint16_t addr;
    int8_t  data[TOSH_DATA_LENGTH - 5];
    uint16_t crc;

} __attribute__ ((packed)) TOSNIC_Encap;

typedef struct {
    
    uint16_t addr;
    uint8_t type;
    uint8_t group;
    uint8_t length;
    int8_t data[TOSH_DATA_LENGTH];
    uint16_t crc;

} __attribute__ ((packed)) Mini_TOS_Msg;

typedef struct {

    SCPBaseHeader hdr;
    Mini_TOS_Msg tos_msg;
    int16_t crc;
    
} __attribute__ ((packed)) SCPBasePkt;


#endif
