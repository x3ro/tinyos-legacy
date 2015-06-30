/**
 * Handles parsing of parameter config packets.
 *
 * @file      xpacket.c
 * @author    Martin Turon
 * @version   2004/3/10    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xpacket.c,v 1.5 2004/12/08 01:55:19 husq Exp $
 */

#include "xpacket.h"
#include "config.h"

static unsigned g_datastart = XPACKET_DATASTART;

/**
 * Returns a pointer into the packet to the data payload.
 * Also performs any required packetizer conversions if this
 * packet came from over the wireless via TOSBase. 
 * 
 * @author    Martin Turon
 * @version   2004/4/07       mturon      Intial version
 */
XbowParamDataPacket *xpacket_get_sensor_data(unsigned char *tos_packet)
{
    return (XbowParamDataPacket *)(tos_packet + XPACKET_DATASTART);
}


/**
 * Converts escape sequences from a packetized TOSMsg to normal bytes.
 * 
 * @author    Martin Turon
 * @version   2004/4/07       mturon      Intial version
 */
int xpacket_unframe(unsigned char *tos_packet, int len)
{
    int i = 0, o = 2;    // index and offset
    len -=2; //SYN + ACK 

    while(i < len) {
	// Handle escape characters
	if (tos_packet[o] == XPACKET_ESC) {
	    tos_packet[i++] = tos_packet[++o] ^ 0x20;
	    ++o;
	    len--;
	} else {
	    tos_packet[i++] = tos_packet[o++];
	}
	}
	len -=2; // CRC part;
	return len;
}

/**
 * Detects if incoming packet is UART framed and unframes if needed.
 * 
 * @author    Martin Turon
 * @version   2004/8/05       mturon      Intial version
 */
int xpacket_decode(unsigned char *tos_packet, int len, int mode)
{
	int newlen;
    if (len < 2) return;

	switch (mode) {
		case 0:
			// Automatic detection of framing
			switch (tos_packet[1]) {
				// case AMTYPE_XUART:  // temp hack for FEATURE_UART_DEBUG 
				case XPACKET_ACK:
				case XPACKET_W_ACK:
				case XPACKET_NO_ACK:
					newlen = xpacket_unframe(tos_packet, len);
					break;
			}
			break;
		
		case 1:
			// Framed packet
			newlen = xpacket_unframe(tos_packet, len);
			break;

		default:
			// Unframed packet
			newlen = len;
			break;
    }
    return newlen;
    
}


int xpacket_frame(char *framed, char *unframed, int len_unframed)
{
	int len =0;    
	framed[len++] = XPACKET_SYNC;
    framed[len++] = XPACKET_NO_ACK;    

    int i;    
    for(i=0; i < len_unframed; i++){  	

		char b = unframed[i];
 	 
 		if (b == XPACKET_SYNC || b == XPACKET_ESC)
    	{
      		framed[len++] = XPACKET_ESC;
      		framed[len++] = b ^ 0x20;
    	}
 		else
    		framed[len++] = b;
    }
    
    len +=2; // two bytes' CRC
    xcrc_set(framed, len);
    framed[len++] = XPACKET_SYNC;
    return len;
}



void xpacket_print_raw(unsigned char *packet, int len)
{
    int i; 
    for (i=0; i<len; i++) {
        printf("%02x", packet[i]);
    }
    printf("\n");
}




void specific_cook(XbowParamDataPacket *pPacket)
{

	switch(pPacket->App_id) {
			case TOS_INVALID_APPLICATION:
			    printf("Invalid Application ID. \n\n");
		    	return;
			case TOS_SYSTEM:
		    	switch(pPacket->Param_id){
		    		case TOS_MOTE_ID:
		    			printf("TOS_MOTE_ID = %i\n", pPacket->args.nodeid);
		    			break;
		    		case TOS_MOTE_GROUP:
		    			printf("TOS_MOTE_GROUP = %i\n", pPacket->args.groupid);
		    			break;
		    		default:
		    			break;
		    		}
		    	return;
			case TOS_CROSSBOW:
            	//xbow_cook(packet);
		    	return;
			case TOS_CC1000:
			  
			  switch(pPacket->Param_id){
			  case TOS_CC1000_TUNE_HZ:
		    		//memcpy(&myfreq,packet->data,4);
		    		printf("TOS_CC1000_TUNE_HZ = %i\n", pPacket->args.rf_freq);
		    		break;
			  case TOS_CC1000_RF_POWER:
		    		printf("TOS_CC1000_RF_POWER = %i\n", pPacket->args.rf_power);
		    		break;
		      case TOS_CC1000_RF_CHANNEL:
		    		printf("TOS_CC1000_RF_CHANNEL = %i\n", pPacket->args.rf_channel);
		    		break;

		    		default:
		    		break;
		    		}
		    	return;
			case TOS_CC2420:
			  printf("CC2420 radio parameters: \n\n");
		    	return;
			case TOS_TEST_APPLICATION:
				printf("Test application parameters: \n\n");
		    	return;
			case TOS_NO_APPLICATION:
				printf("No application parameters: \n\n");
				return;
			default:
		    	printf("The Application ID unrecognized.\n\n");
		    	return;    
		    }
	
}


void xpacket_print_cooked(unsigned char *tos_packet, int len)
{
    XbowParamDataPacket *packet = xpacket_get_sensor_data(tos_packet);
	switch(packet->msg_type) {
		case XEE_MSG_UNKNOWN_ERROR:   // other error	:
			printf("param not existed in eeprom.\n");
			break;
		case XEE_MSG_UNKNOWN_PARAM:
			printf("unknown Paramid.\n");
			break;
		case XEE_MSG_UNKNOWN_APP:
			printf("unknown Appid.\n");
			break;			
		case XEE_MSG_UNKNOWN_CMD:
			printf("unknown command.\n");
			break;
		case XEE_MSG_OK:
			specific_cook(packet);
			
			break;
			
		default:
			printf("Unknown data packet type! \n\n");
			break;		    
    
    
    
	}
}

