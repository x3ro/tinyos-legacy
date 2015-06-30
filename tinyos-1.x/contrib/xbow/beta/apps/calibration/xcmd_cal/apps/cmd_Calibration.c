/**
 * Handles generating and sending commands to control an XSensor application.
 *
 * @file      cmd_Calibration.c
 * @author    PiPeng
 * @version   2004/10/5    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: cmd_Calibration.c,v 1.1 2005/01/05 03:28:17 pipeng Exp $
 */

#include "../xcommand.h"
#include "Calibration.h"

char        value[41];
const char*       name;
enum {

    CALIB_SETVALUE = 0x01,
    CALIB_SETBDINFO= 0x02,
    
    
} CalibSubcode;


CALIB_HANDLE*  g_calibtable[256];

typedef struct CalibOp {
    uint16_t     cmd;         // XCommandOpcode
    uint8_t     subcmd;         //SubCommand
    
    union {
        /** FOR XCOMMAND_CALIBRATION */
        struct {
            uint16_t infotype;  //!< The type of the config info,high byte is sensor board type,low byte is index of the info for the sensorboard
            uint16_t data;      //!< The value to be set into the sensor board
            uint8_t  valtype;   //!<0=BYTE;1=WORD
            uint8_t  offset;    //!<The offset value in the config struct
        }__attribute__ ((packed)) calibration;
          
    } param;
} __attribute__ ((packed)) CalibOp;


typedef struct CalibMsg {
    TOSMsgHeader tos;
    uint16_t     seq_no;        //!< Required by lib/Broadcast/Bcast
    uint16_t     dest;          //!< Destination nodeid (0xFFFF for all)
    CalibOp   inst[1]; 
} __attribute__ ((packed)) CalibMsg;


void calib_add_type(CALIB_HANDLE* handle)
{
    if (handle==NULL) return;
    g_calibtable[handle->type] = handle;
}

uint8_t get_board_type(char * buffer)
{
    uint16_t   type;
    char   namestr[20];
    if(!buffer)
        return 0;
    sprintf(namestr,"%s",buffer);
    for(type=0;type<256;type++)
    {
        if(g_calibtable[type]==NULL)
            continue;
    	if (!strcmp(g_calibtable[type]->name,namestr)) {
    	    return type;
    	}
    }
    return 0;
}

char* get_value_str(uint8_t type, char * buffer)
{
    CALIB_STRUCT* handle=NULL;

    char   namestr[20];
    if(!g_calibtable[type])
        return NULL;
    handle=g_calibtable[type]->calib_table;
    if(handle==NULL)
        return NULL;

    sprintf(namestr,"%s",buffer);
    while(handle->name)
    {
    	if (!strcmp(handle->name,namestr )) {
    	    return (char*)handle->valstr;
    	}
        handle++;
    }
    return NULL;
}

void calib_set_header(char * buffer) 
{
    // Fill in TOS_msg header.
    CalibMsg *msg = (CalibMsg *)buffer;
    msg->tos.addr    = g_dest;
    msg->tos.type    = AMTYPE_XCOMMAND;
    msg->tos.group   = g_group;
    msg->tos.length  = sizeof(CalibMsg) - sizeof(TOSMsgHeader);    
}

char*   GetDataChar(char* buf,int idx)
{

    uint16_t    i=0;
    uint16_t    j=0;
    uint16_t    count=0;
    if(idx>3)
        return 0;
    while(count<=idx)
    {
        if(buf[i]=='[' || buf[i]==']' || buf[i]==',' || buf[i]=='=')
        {
            count++;
            i++;
            continue;
        }
        if(count==idx)
        {
            if(buf[i]>='a' && buf[i]<='z')
                value[j]=(buf[i]+'A'-'a');
            else
                value[j]=buf[i];
            j++;
        }
        i++;
        if(i>40)
        {
            return 0;
        }
    }
    value[j]=0;
    return value;
}

uint16_t GetDataValue(char* buf,int idx)
{
    uint16_t    data;
    uint16_t    i=0;
    uint16_t    j=0;
    uint16_t    count=0;
    if(idx>3)
        return 0xffff;
    while(count<=idx)
    {
        if(idx==0)
        {
            if(buf[i]=='B' || buf[i]=='b')
            {
                return 0;   //BYTE type;
            }
            if(buf[i]=='W' || buf[i]=='w')
            {
                return 1;   //WORD type;
            }
            if(buf[i]=='T' || buf[i]=='t')
            {
                return 2;   //search table;
            }
        }
        if(count==idx)
        {
            value[j]=buf[i];
            j++;
        }
        if(buf[i]=='[' || buf[i]==']' || buf[i]==',' || buf[i]=='=')
            count++;
        i++;
        if(i>40)
            return 0xffff;
    }
    if(idx==0 && count>idx)
        return 0xffff;
    if(count>idx)
    {
        data=strtoul(value,NULL,16);
        return data;
    }
    return 0xffff;
}

int xcmd_set_calibration(char * buffer)
{
    uint16_t    data,idx;
    uint8_t     bdtype;

    CalibMsg *msg = (CalibMsg *)buffer;
    msg->seq_no      = g_seq_no;
    msg->dest        = 0xffff;//g_dest;
    msg->inst[0].cmd=XCOMMAND_CALIBRATION;
    msg->inst[0].subcmd=CALIB_SETVALUE;
    calib_set_header(buffer);
    if (g_argument)
    {
        idx=GetDataValue(g_argument,0);
        if(idx==0xffff)
        {
            printf("error: Value type is not right.\n");
            return 0;
        }
        switch(idx)
        {
        case 0:
        case 1:
            msg->inst[0].param.calibration.valtype=(uint8_t)(idx);
    
            data=GetDataValue(g_argument,1);
            if(data==0xffff)
            {
                printf("error: Info type is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.infotype=(uint16_t)(data);
    
            data=GetDataValue(g_argument,2);
            if(data==0xffff || data>255)
            {
                printf("error: Offset is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.offset=(uint8_t)(data);
    
            data=GetDataValue(g_argument,3);
            if(data==0xffff)
            {
                printf("error: Value is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.data=(uint16_t)(data);
            break;
        case 2:
            GetDataChar(g_argument,1);
            bdtype=get_board_type(value);
            if(bdtype==0)
            {
                printf("error: Board name is not right.\n");
                return 0;
            }
            data=GetDataValue(g_argument,3);
            if(data==0xffff)
            {
                printf("error: Value is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.data=(uint16_t)(data);
            GetDataChar(g_argument,2);
            name=get_value_str(bdtype,value);
            if(name==NULL)
            {
                printf("\n error: Could not find the name in the table.\n");
                return 0;
            }
            data=GetDataValue((char*)name,0);
            if(idx==0xffff)
            {
                printf("error: Value type is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.valtype=(uint8_t)(data);

            data=GetDataValue((char*)name,1);
            if(data==0xffff)
            {
                printf("error: Info type is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.infotype=(uint16_t)(data);
    
            data=GetDataValue((char*)name,2);
            if(data==0xffff || data>255)
            {
                printf("error: Offset is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.offset=(uint8_t)(data);
            break;
        default:
            break;
        }
    }
    else
    {
        printf("error: No right parameters found.\n");
        return 0;
    }
    return sizeof(CalibMsg);
}


int xcmd_set_bdinfo(char * buffer)
{
    uint16_t    data,idx;
    uint8_t     bdtype;
    CalibMsg *msg = (CalibMsg *)buffer;
    msg->seq_no      = g_seq_no;
    msg->dest        = 0xffff;//g_dest;
    msg->inst[0].cmd=XCOMMAND_CALIBRATION;
    msg->inst[0].subcmd=CALIB_SETBDINFO;
    calib_set_header(buffer);
    if (g_argument)
    {
        idx=GetDataValue(g_argument,0);
        if(idx==0xffff)
        {
            printf("error: Value type is not right.\n");
            return 0;
        }
        switch(idx)
        {
        case 0:
        case 1:
            msg->inst[0].param.calibration.valtype=(uint8_t)(idx);
    
            data=GetDataValue(g_argument,1);
            if(data==0xffff)
            {
                printf("error: Info type is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.infotype=(uint16_t)(data);
    
            data=GetDataValue(g_argument,2);
            if(data==0xffff || data>255)
            {
                printf("error: Offset is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.offset=(uint8_t)(data);
    
            data=GetDataValue(g_argument,3);
            if(data==0xffff)
            {
                printf("error: Value is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.data=(uint16_t)(data);
            break;
        case 2:
            GetDataChar(g_argument,1);
            bdtype=get_board_type(value);
            if(bdtype==0)
            {
                printf("error: Board name is not right.\n");
                return 0;
            }
            data=GetDataValue(g_argument,3);
            if(data==0xffff)
            {
                printf("error: Value is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.data=(uint16_t)(data);
            GetDataChar(g_argument,2);
            name=get_value_str(bdtype,value);
            if(name==NULL)
            {
                printf("\n error: Could not find the name in the table.\n");
                return 0;
            }
            data=GetDataValue((char*)name,0);
            if(idx==0xffff)
            {
                printf("error: Value type is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.valtype=(uint8_t)(data);

            data=GetDataValue((char*)name,1);
            if(data==0xffff)
            {
                printf("error: Info type is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.infotype=(uint16_t)(data);
    
            data=GetDataValue((char*)name,2);
            if(data==0xffff || data>255)
            {
                printf("error: Offset is not right.\n");
                return 0;
            }
            msg->inst[0].param.calibration.offset=(uint8_t)(data);
            break;
        default:
            break;
        }

    }
    else
    {
        printf("error: No right parameters found.\n");
        return 0;
    }
    return sizeof(CalibMsg);
}


/** List of commands handled by XSensor applications using XCommand. */
XCmdHandler calib_cmd_list[] = {
    // App Control
    {"set_cal",       xcmd_set_calibration},
    {"set_bdinfo",       xcmd_set_bdinfo},

    {NULL, NULL}
};

/** Valid reference names for XSensor/XCommand from the command line. */
char *calib_app_keywords[] = { 
    "calibration",
    NULL 
};

XAppHandler calib_app_desc = 
{
    AMTYPE_CALIBRATION,
    "$Id: cmd_Calibration.c,v 1.1 2005/01/05 03:28:17 pipeng Exp $",
    calib_cmd_list,
    calib_app_keywords
};

void initialize()
{
    mda300_initialize();
}

void initialize_Calibration() {
    initialize();
    xpacket_add_type(&calib_app_desc);
}

