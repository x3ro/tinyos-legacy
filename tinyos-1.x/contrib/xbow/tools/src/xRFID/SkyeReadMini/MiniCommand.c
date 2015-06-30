/**
 * Sends commands to Skyetek Mini. 
 *
 * @file      MiniCommand.c
 * @author    Michael Li
 *
 * @version   2004/9/24    mli      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: MiniCommand.c,v 1.1 2005/03/31 07:51:06 husq Exp $
 */


#include "AM.h"
#include "MiniCommand.h"

static TagCommand mini_cmd;
static uint16_t mini_cmd_len;


typedef struct cmd_type
{
    char flag[2];
    char request[2];
    char misc[4];  // depending on command, could mean different things
	               // for example system read command (to read firmware version)
    uint8_t len;
} cmd_type_t;

// contains required command (flags and cmd type)
static cmd_type_t mini_cmd_type[] = 
{
    {{'0', '0'}, {'1', '4'}, {'0', '0', '0', '0'}, TID_REQUEST_SIZE},    // CMD_TAG_TYPE
    {{'4', '0'}, {'2', '4'}, {'0', '0', '0', '0'}, TREAD_REQUEST_SIZE},  // CMD_RDM_TYPE
    {{'4', '0'}, {'4', '4'}, {'0', '0', '0', '0'}, TWRITE_REQUEST_SIZE}, // CMD_WRM_TYPE
    {{'0', '0'}, {'2', '2'}, {'0', '1', '0', '1'}, FMW_REQUEST_SIZE}     // CMD_FMW_TYPE
};



uint16_t crcByte(uint16_t crc, uint8_t b)
{
    int i;

    crc = crc ^ b << 8;
    i = 8;
    do
      if (crc & 0x8000)
        crc = crc << 1 ^ 0x1021;
      else
        crc = crc << 1;
    while (--i);

    return crc;
}



int skyeread_mini_set_command (uint8_t type, uint8_t *buf, uint16_t len)
{
    uint8_t i;
    mini_cmd_len = 0;

    // checks
    switch (type)
    {
        case CMD_RAW_TYPE:
        case CMD_TAG_TYPE:
        case CMD_RDM_TYPE:
        case CMD_WRM_TYPE: 
		case CMD_FMW_TYPE: break;
        
        default: return -1;             
    }
    
    if ((buf == NULL) && ((type != CMD_TAG_TYPE) && (type != CMD_FMW_TYPE)))
        return -2;

    if (len > sizeof(TagCommand))
        return -3;


    // clear cmd buffer
    memset ((char *) &mini_cmd, '0', sizeof(TagCommand));

    // predefined commands
    if (type != CMD_RAW_TYPE)
    {
        mini_cmd.flag[0]    = mini_cmd_type[type].flag[0];
        mini_cmd.flag[1]    = mini_cmd_type[type].flag[1];
        mini_cmd.request[0] = mini_cmd_type[type].request[0];
        mini_cmd.request[1] = mini_cmd_type[type].request[1];

        if (type == CMD_FMW_TYPE)
		     memcpy ((char *) mini_cmd.type, mini_cmd_type[type].misc, 4); 

        // set length
        mini_cmd_len = mini_cmd_type[type].len;
        i = 0;
    }

    // user defined command 
    else
    {
        mini_cmd.flag[0]    = buf[0];
        mini_cmd.flag[1]    = buf[1];
        mini_cmd.request[0] = buf[2];
        mini_cmd.request[1] = buf[3];

        // set length
        mini_cmd_len = len;

        i = 4;
    }

    // set data
    if ((type != CMD_TAG_TYPE) && (type!= CMD_FMW_TYPE))
        memcpy (mini_cmd.type, &buf[i], len);


    return 0;
}



void skyeread_mini_send_command (int g_stream, uint8_t group)
{
    TOS_Msg cmdbuf;
    TOS_MsgPtr cmdPtr;
    Payload *p;
    uint8_t *ptr;
    uint8_t i=0, numpkts=1, pidx=0, datalen, mini_cmd_idx=0;
    uint16_t crc; 

    // how many packets do we need to send command?
    if (mini_cmd_len > MSG_PAYLOAD)
    {
        numpkts = mini_cmd_len / MSG_PAYLOAD;
        if (mini_cmd_len % MSG_PAYLOAD)
             numpkts++; 
    }

    cmdPtr = &cmdbuf;

    // TOS packet struct
    cmdPtr->addr   = TOS_BCAST_ADDR;
    cmdPtr->type   = AMTYPE_RFID;
    cmdPtr->group  = group;

    // packetize command to send
    for (pidx=0; pidx<numpkts; pidx++)
    {
        if (pidx == numpkts-1)
            datalen = mini_cmd_len - mini_cmd_idx;
        else
            datalen = MSG_PAYLOAD;

        cmdPtr->length = datalen + PAYLOAD_DATA_INDEX;

        // Skyetek mini packet struct
        p = (Payload *) cmdPtr->data;
        p->num  = numpkts;
        p->pidx = pidx;
        p->RID  = 0x1234;
        p->SG   = 0x0022;

        ptr = ((uint8_t *) &mini_cmd) + mini_cmd_idx;

        for (i=0; i<datalen; i++)
             p->data[i] = ptr[i];

        ptr = (uint8_t *) cmdPtr;

        // calculate CRC for packet
        crc = 0;
        crc = crcByte (crc, PROTO_PACKET_NOACK);
        for (i=0; i < (5+cmdPtr->length); i++)
            crc = crcByte (crc, ptr[i]);

        // append CRC
        p->data[datalen]   = 0;
        p->data[datalen]  |= (uint8_t) crc;
        p->data[datalen+1] = (uint8_t) (crc >> 8);

        xserial_port_write_packet(g_stream, (uint8_t *)cmdPtr, 7 + cmdPtr->length);

        mini_cmd_idx += datalen;
       
	    // need a delay between sending out packets, too fast for UART->RADIO (TOSBase program)
		usleep (DELAY_BETWEEN_PACKETS);
//printf( "numpkts: %i pidx: %i  pkt_len: %i  left: %i\n", numpkts, pidx, datalen, mini_cmd_len-mini_cmd_idx);
    }
}

