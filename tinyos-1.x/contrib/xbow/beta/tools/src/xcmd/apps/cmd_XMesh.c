/**
 * Handles generating and sending commands to control an XSensor application.
 *
 * @file      cmd_XSensor.c
 * @author    Martin Turon
 * @version   2004/10/5    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: cmd_XMesh.c,v 1.5 2004/10/21 22:10:36 jdprabhu Exp $
 */

#include "../xcommand.h"

typedef struct XMeshCmdMsg {
    TOSMsgHeader       tos;
    MultihopMsgHeader  multihop;
    uint8_t            command;    //!< time to light up path
    uint16_t           time;       //!< time to light up path
} __attribute__ ((packed)) XMeshCmdMsg;


void xmesh_cmd_set_header(char * buffer, uint8_t tos_type) 
{
    // Fill in TOS_msg header.
    XMeshCmdMsg *msg = (XMeshCmdMsg *)buffer;
    msg->tos.addr    = 0xFFFF;
    msg->tos.type    = tos_type;
    msg->tos.group   = g_group;
    msg->tos.length  = sizeof(XMeshCmdMsg) - sizeof(TOSMsgHeader);    
}

void xmesh_cmd_set_multihop(char * buffer) 
{
    // Fill in MultihopMsg header.
    XMeshCmdMsg *msg = (XMeshCmdMsg *)buffer;
    msg->multihop.sourceaddr = XPACKET_SYNC;   // Source from UART
    msg->multihop.originaddr = g_dest;         // destination nodeid
    msg->multihop.seqno      = g_seq_no;
    msg->multihop.hopcount   = 0;
}

int xmesh_cmd_light_path(char * buffer) 
{
    XMeshCmdMsg *msg = (XMeshCmdMsg *)buffer;
    xmesh_cmd_set_header(buffer, XPACKET_TEXT_MSG);
    xmesh_cmd_set_multihop(buffer);

    int path_time = 0x0A0A;
    if (g_argument) path_time = atoi(g_argument);

    // Data payload
    msg->command  = 1;
    msg->time     = path_time;
    return sizeof(XMeshCmdMsg);
}

int xmesh_cmd_ping_node(char * buffer) 
{
    XMeshCmdMsg *msg = (XMeshCmdMsg *)buffer;
    xmesh_cmd_set_header(buffer, AMTYPE_XMESH_PING);
    xmesh_cmd_set_multihop(buffer);

    int path_time = 0x0A0A;
    if (g_argument) path_time = atoi(g_argument);

    // Data payload
    msg->command  = 1;
    msg->time     = path_time;

    return sizeof(XMeshCmdMsg);
}


/** List of commands handled by XMesh networking layer. */
XCmdHandler xmesh_cmd_list[] = {
    {"light_path",    xmesh_cmd_light_path},
    {"ping_node",    xmesh_cmd_ping_node},
    {NULL, NULL}
};

/** Valid reference names for XMesh from the command line. */
char *xmesh_app_keywords[] = { "mesh", "xmesh", "XMesh", NULL };

XAppHandler xmesh_app_desc = 
{
    AMTYPE_XMESH_CMD,
    "$Id: cmd_XMesh.c,v 1.5 2004/10/21 22:10:36 jdprabhu Exp $",
    xmesh_cmd_list,
    xmesh_app_keywords
};

void initialize_XMesh() {
    xpacket_add_type(&xmesh_app_desc);
}








