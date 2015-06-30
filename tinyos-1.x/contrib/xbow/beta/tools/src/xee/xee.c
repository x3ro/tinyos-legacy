/**
 * Listens to the serial port, and outputs sensor data in human readable form.
 *
 * XEE is a C program that runs in a console application, like XListen. 
 * This program write and reads user values via the MIB510 programming board from the mote.
 *   - Read the .ini file (as defined by Mike Newman)
 *   - Xmit uart messages from the PC to the mote to program:
 *        	o	TOS_SYSTEM parameters
 *			o	TOS_CC_1000 parameters
 *			o	TOS_CROSSBOW parameters
 *   - Read back and display this parameters
 * 
 * UART Packet structure:
 *   Packet Identifier (1 = TOS_SYSTEM, 2 = TOS_CROSSBOW, 3 = TOS_CC_1000, ...)
 *   Sub Packet Identifier (0,1,2.) needed for TOS_CROSSBOW packets.
 *   Data - same sequence as listed in the EEPROM header table from the engineering spec.
 *
 * @file      xee.c
 * @author    Hu Siquan
 * @version   2004/6/1    husq      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: xee.c,v 1.5 2004/12/08 01:55:18 husq Exp $
 */
#include <string.h>
#include <errno.h>
#include <sys/time.h>
#include <signal.h>
#include <unistd.h>
#include "xee.h"
#include "xpacket.h"

typedef struct XeeCMD_Msg
{
  /* The following fields are transmitted/received on the radio. */
  TOSMsgHeader tos;
  XbowParamConfigPacket cmd;
} XeeCMD_Msg;


// queried parameter name, e.g. nodeid, groupid,...
char qParam[10];
char sParam[10];
char sParamValue[100];

const int X_TIME_OUT = 6;

/** A structure to store parsed parameter flags. */
typedef union {
    unsigned flat;
    
    struct {
        // output display options
        unsigned  display_raw    : 1;  //!< raw TOS packets
        unsigned  display_cooked : 1;  //!< convert to engineering units
        unsigned  reserved       :14;  //!< reserved bits for outputs
        // modes of operation
        unsigned  display_help   : 1;
        unsigned  display_baud   : 1;  //!< baud was set by user
        unsigned  mode_quiet     : 1;  //!< suppress headers
        unsigned  mode_debug     : 1;  //!< debug serial port
        unsigned  mode_write     : 1;  //!< write parameters into ini file
        unsigned  mode_set       : 2;  //!< no=0, one parameter=1
        unsigned  mode_query     : 2;  //!< no=0, one parameter=1
     } bits; 
    
    struct {
        unsigned short output;         //!< must have at least one output option
        unsigned short mode;
    } options;
} s_params;

/** A variable to store parsed parameter flags. */
s_params  g_params;


/**
 * print help message of Xee.
 *
 * @author    Hu Siquan
 *
 * @version   2004/11/15       husq      Intial version
 */
void printhelp(){
	    printf(
            "\nUsage: xee <-?|r|x|c|d|q> <-b=baud> <-s=device> <-g=parameter> <-w=parameter:value>"
            "\n   -? = display help [help]"
            "\n   -r = raw display of tos packets [raw]"
            "\n   -c = convert data to engineering units [cooked]"
            "\n   -d = debug serial port by dumping bytes [debug]"
            "\n   -b = set the baudrate [baud=#|mica2|mica2dot]"
            "\n   -s = set serial port device [device=com1]"
            "\n   -q = quiet mode (suppress headers)"
            "\n   -g = get parameter [parameter=nodeid]"
            "\n   -w = write parameter as value [nodeid:5]"
            "\n"
        );
        exit(0);
	
	}

/**
 * Extracts command line options and sets flags internally.
 * 
 * @param     argc            Argument count
 * @param     argv            Argument vector
 *
 * @author    Martin Turon
 *
 * @version   2004/3/10       mturon      Intial version
 * @n         2004/3/12       mturon      Added -b,-s,-q,-x
 * @n         2004/7/19       husq        Added -i,-o,
 * @n         2004/10/11      husq        Added -g,-w
 */
void parse_args(int argc, char **argv) 
{
    unsigned baudrate;
    g_params.flat = 0;   /* default to no params set */
    FILE *pFile;

    while (argc) {
        if ((argv[argc]) && (*argv[argc] == '-')) {
	  switch(argv[argc][1]) {
	  case '?':
	    g_params.bits.display_help = 1;
	    break;
	    
	  case 'q':
	    xserial_set_verbose(0);
	    g_params.bits.mode_quiet = 1;
	    break;
    
	  case 'r':
	    g_params.bits.display_raw = 1;
	    break;
	    
	  case 'c':
	    g_params.bits.display_cooked = 1;
	    break;
	    
	  case 'b':
	    if (argv[argc][2] == '=') {
	      baudrate = xserial_set_baud(argv[argc]+3);
	      g_params.bits.display_baud = 1;
	    }
	    break;
	    
	  case 's':
	    if (argv[argc][2] == '=') {
	      xserial_set_device(argv[argc]+3);
	    }
	    break;

	  case 'g':
	    if (argv[argc][2] == '='){
	      strcpy(qParam,argv[argc]+3);
	      g_params.bits.mode_query = 1;
	    }
	    else
	      if(argv[argc][2] == ' '){
		g_params.bits.mode_query = 2;
	      }
	    break;
	  case 'w':
	  	g_params.bits.mode_query = 0;
	    g_params.bits.mode_set = 1;

	    char *ptr;
	    ptr=strchr(argv[argc]+3,':');
	    int i=ptr-argv[argc]-3;
	    //printf("ptr: %i i:=%i\n", ptr,i);
	    strncpy(sParam,argv[argc]+3,i);
	    //printf("sParam: %s\n", sParam);
    	strcpy(sParamValue,ptr+1);
    	//printf("sparamvalue: %s\n", sParamValue);
	    break;
	       
	  case 'd':
	    g_params.bits.mode_debug = 1;
	    break;
	  }
        }
        argc--;
    }
    
    if (!g_params.bits.mode_quiet) {
      // Summarize parameter settings
     // printf("Xee: Using params: ");
     //   if (g_params.bits.display_help)   printf("[help] ");
     //   if (g_params.bits.display_baud)   printf("[baud=0x%04x] ", baudrate);
     //   if (g_params.bits.display_raw)    printf("[raw] ");
     //   if (g_params.bits.display_cooked) printf("[cooked] ");
          if (g_params.bits.mode_debug) {
            printf("[debug - serial dump!] \n");
            xserial_port_dump();
        }
//        printf("\n");
    }
        
    if (g_params.bits.display_help) {
    	printhelp();
    }

    /* Default to displaying packets as raw, parsed, and cooked. */
    if (g_params.options.output == 0) {
//	g_params.bits.display_raw = 1;
	g_params.bits.display_cooked = 1;
    }
}


static struct sigaction act1, oact1;

static void AlarmFunc (int signo)
{
	printf("No correct answer from the mote. \n"
  			"Check the firware is XEE-compatible. Or try again."
  	);
	exit(0);    
}

/**
 * The main entry point for the xee console application.
 * 
 * @param     argc            Argument count
 * @param     argv            Argument vector
 *
 * @author    Hu Siquan
 * @version   2004/6/2       husq      Intial version
 */
int main(int argc, char **argv) 
{

	int len = 0;
	int serline;
	
    unsigned char SendBuffer[255], ReceiveBuffer[255];
    

    XeeCMD_Msg cmdBuffer;        
    XbowParamConfigPacket *pParam;
    
    parse_args(argc, argv); 

    pParam = & (cmdBuffer.cmd);    
	bzero(pParam,sizeof(XbowParamConfigPacket));
  
    cmdBuffer.tos.addr = TOS_BCAST_ADDR;
    cmdBuffer.tos.type = AM_XEECMDMSG;
    cmdBuffer.tos.length = sizeof(XbowParamConfigPacket);
    cmdBuffer.tos.group = 0x00;           
    
    if(g_params.bits.mode_query ==1)
    {
      pParam->cmd_type = XEE_CMD_GET;

      if(!strcmp(qParam,"nodeid")){
	  pParam->App_id = TOS_SYSTEM;
	  pParam->Param_id = TOS_MOTE_ID;	    		
	}
	else if(!strcmp(qParam,"groupid"))
	  {
	    pParam->App_id = TOS_SYSTEM;
	    pParam->Param_id = TOS_MOTE_GROUP;	    			    
	  }
	else if(!strcmp(qParam,"rf_freq"))
	  {
	    pParam->App_id = TOS_CC1000;
	    pParam->Param_id = TOS_CC1000_TUNE_HZ;	    			    
	  }
	else if(!strcmp(qParam,"rf_channel"))
	  {
	    pParam->App_id = TOS_CC1000;
	    pParam->Param_id = TOS_CC1000_RF_CHANNEL;	    			    
	  }
	else if(!strcmp(qParam,"rf_power"))
	  {
	    pParam->App_id = TOS_CC1000;
	    pParam->Param_id = TOS_CC1000_RF_POWER;
	  }
    }   
    else if(g_params.bits.mode_set ==1)
      { 
      pParam->cmd_type = XEE_CMD_SET;
	if(!strcmp(sParam,"nodeid")){
	  pParam->App_id = TOS_SYSTEM;
	  pParam->Param_id = TOS_MOTE_ID;	  
	  pParam->args.nodeid = atoi(sParamValue);   		
	}
	else if(!strcmp(sParam,"groupid"))
	  {
	    pParam->App_id = TOS_SYSTEM;
	    pParam->Param_id = TOS_MOTE_GROUP;	 
	    pParam->args.groupid = atoi(sParamValue);
	  }
	else if(!strcmp(sParam,"rf_freq"))
	  {
	    pParam->App_id = TOS_CC1000;
	    pParam->Param_id = TOS_CC1000_TUNE_HZ;	 
	    pParam->args.rf_freq = atoi(sParamValue);
	  }
    	else if(!strcmp(sParam,"rf_power"))
	  {
	    pParam->App_id = TOS_CC1000;
	    pParam->Param_id = TOS_CC1000_RF_POWER;	  
	    pParam->args.rf_power = atoi(sParamValue);
	  }    	
	else if(!strcmp(sParam,"rf_channel"))
	  {
	    pParam->App_id = TOS_CC1000;
	    pParam->Param_id = TOS_CC1000_RF_CHANNEL;	 
	    pParam->args.rf_channel = atoi(sParamValue);
	  }

      }else
	{
	  printhelp();
	}
    
    serline = xserial_port_open();
    len = xpacket_frame(&SendBuffer, &cmdBuffer, sizeof(XeeCMD_Msg));   	
    	
    // send parameters packet to programme into eeprom
    if(g_params.bits.display_raw){
    printf("Writing to serial port...\n");
    xpacket_print_raw(SendBuffer, len);
    }
    xserial_port_write_packet(serline, SendBuffer, len);
    
    // read packets and parse it    
    if(g_params.bits.display_raw){
    	printf("Reading from serial port...\n");
    }
    
 
  int ret;
  struct timeval tv;
  tv.tv_sec=X_TIME_OUT;
  tv.tv_usec=0;
  
  fd_set rfds;
  FD_ZERO(&rfds); FD_SET(serline,&rfds);

  int tries = 5;
  while (1) {
    if ((ret=select(serline+1, &rfds, NULL, NULL, &tv))==-1) {
      printf("Select on %d returned retval:%d errno:%d\n",
           serline, ret, errno);
      if ((errno == EINTR) && tries) {
        tries--;
        continue;
      }
      printf("Select failed");
    }
    break;
  }
  if (ret==0)
  {
  	printf("No response from the mote. \n"
//  	       "Check the firware is XEE-compatible. Or try again."
  	       );
  	xserial_port_close(serline);
  	exit(0);
  }
  
  //int timeout=X_TIME_OUT;
    /* set up alarm */
  act1.sa_handler = AlarmFunc;
  sigemptyset(&act1.sa_mask);
  act1.sa_flags = 0;
#ifdef SA_INTERRUPT
  act1.sa_flags |= SA_INTERRUPT;
#endif
  if( sigaction(SIGALRM, &act1, &oact1) < 0 ){
    perror("sigaction");
    exit(1);
  }

  /* start alarm */
  alarm(X_TIME_OUT);
   
   while(1){
    		
    	bzero(ReceiveBuffer,255);

    	len = xserial_port_read_packet(serline, ReceiveBuffer);     	
    	if (g_params.bits.display_raw)    xpacket_print_raw(ReceiveBuffer, len);    	
    	len = xpacket_decode(ReceiveBuffer, len, 0);    
    	if(ReceiveBuffer[2]==AM_XEEDATAMSG){     		
//    		if (g_params.bits.display_raw)    xpacket_print_raw(ReceiveBuffer, len);    	    
    		if (g_params.bits.display_cooked) xpacket_print_cooked(ReceiveBuffer, len);
			break;
    	}
	}
	/* turn off alarm if it did not go off */
	alarm(0);
	xserial_port_close(serline);    	
	return 0;     	 
	    
}

/*


After sending the query or set command, xee will waiting for 6 seconds to get the answer back.
If no response at all, maybe mote is not plugged onto the MIB board or it is not power up or not XEE compatible.
If no correct answer gets back, User should check if the mote application is XEE compatible. 





*/
