/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Jason Hill, David Gay, Philip Levis, Nelson Lee
 * Date last modified:  8/01/02
 *



 */


module Nido {
  // Interface to inject messages into GenericComm
  provides interface ReceiveMsg as InjectMsg;

  uses {
    interface StdControl;
    interface Interrupt;
    interface Pot;
  }
}
implementation
{
    
  /* grody stuff to set mote address into code image */
  //short TOS_LOCAL_ADDRESS = 160;
  //unsigned char LOCAL_GROUP = DEFAULT_LOCAL_GROUP;
  
  /**************************************************************
   *  Generic main routine.  Issues an init command to subordinate
   *  modules and then a start command.  These propagate down the
   *  tree as required.  The application component sits below main
   *  and above various levels of hardware support components
   *************************************************************/
  
    void usage(char *progname) {
    fprintf(stderr, "Usage: %s [-h|--help] [options] num_nodes\n", progname);
    exit(-1);
  }
  
  void help(char* progname) {
    fprintf(stderr, "Usage: %s [options] num_nodes\n", progname);
    fprintf(stderr, "  [options] are:\n");
    fprintf(stderr, "  -h, --help        Display this message.\n");
    fprintf(stderr, "  -r <model>        specifies a radio model (simple is default)\n");
    fprintf(stderr, "  -e <file>         use <file> for eeprom; otherwise anonymous file is used\n");
    fprintf(stderr, "  -p <sec>          pause <sec> seconds on each system clock interrupt\n");
    fprintf(stderr, "  -l                invocation logging: will block for connect on port 10583\n");
    fprintf(stderr, "  num_nodes         number of nodes to simulate\n\n");
    fprintf(stderr, "  -ri[=portnumber] pauses simulation waiting for incoming packet connection;\n  default portnumber is 10576\n");
    fprintf(stderr, "  -ro[=portnumber] pauses simulation watiing for outgoing packet connection;\n  default portnumber is 10577\n");
    fprintf(stderr, "\n");
    dbg_help();
    fprintf(stderr, "\n");
    exit(-1);
  }
  
  int main(int argc, char **argv) __attribute__ ((C, spontaneous)) {
    long long i;

    int num_nodes;
    
    char* model_name = NULL;
    char* eeprom_name = NULL;
      
    int radio_in_port = -1;
    int radio_out_port = -1;
    char radio_in_use = 0;
    char radio_out_use = 0;
      
	
    int start_time = 0;
    int pause_time = 0;
    
    
    int loggingOn = 0;
    int radio_kb_rate = 40;
    

    
    int currentArg;
    
    if (argc == 2 && ((strcmp(argv[1], "-h") == 0) ||
		      (strcmp(argv[1], "--help") == 0))) {
      help(argv[0]);
    }
    
    dbg_init();

    
    for (currentArg = 1; currentArg < argc - 1; currentArg++) {
      if (strcmp(argv[currentArg], "-p") == 0) {
	currentArg++;
	pause_time = atoi(argv[currentArg]);
      }
      else if (strncmp(argv[currentArg], "-ri", 3) == 0) {
	currentArg++;
	if (argv[currentArg][0] == '=') {
	  radio_in_port = atoi((argv[currentArg])+1);
	}
	else 
	  currentArg--;
	
	radio_in_use = 1;
	
      }
      else if (strncmp(argv[currentArg], "-ro", 3) == 0) {
	currentArg++;
	if (argv[currentArg][0] == '=') {
	  radio_out_port = atoi((argv[currentArg])+1);
	}
	else
	  currentArg--;
	
	radio_out_use = 1;
	
      }
      else if (strcmp(argv[currentArg], "-r") == 0) {
	currentArg++;
	model_name = argv[currentArg];
      }
      else if (strcmp(argv[currentArg], "-h") == 0) {
	help(argv[0]);
      }
      else if (strcmp(argv[currentArg], "--help") == 0) {
	help(argv[0]);
      }
      else if (strcmp(argv[currentArg], "-l") == 0) {
	loggingOn = 1;
      }
            else if (strcmp(argv[currentArg], "-e") == 0) {
	currentArg++;
	eeprom_name = argv[currentArg];
      }
      else {
	usage(argv[0]);
      }
    }
    
    // finished parsing command line
    if (radio_in_use)
      initializeIncomingRadio(radio_in_port);
    
    if (radio_out_use)
      initializeOutgoingRadio(radio_out_port);
        
    num_nodes = atoi(argv[argc - 1]);
    if (num_nodes <= 0) {usage(argv[0]);}
      
      
    
    if (num_nodes > TOSNODES) {
      fprintf(stderr, "compiled for maximum of %d nodes\n", TOSNODES);
      fprintf(stderr, "Exiting...\n");
      exit(-1);
    }
    

    init_signals();
    
    tos_state.num_nodes = num_nodes;
    
    
    

    
    // RFM model initialized (only one model for now)
    
    if (model_name == NULL || strcmp(model_name, "simple") == 0) {
      tos_state.rfm = create_simple_model();
    }
    else if (strcmp(model_name, "static") == 0) {
      tos_state.rfm = create_static_model();
    }
    else if (strcmp(model_name, "space") == 0) {
      tos_state.rfm = create_space_model();
    }
    else {
      dbg_clear(DBG_ERROR, "SIM: Don't recognize RFM model type: %s\n", model_name);
      tos_state.rfm = create_simple_model();
    }

    
    if (eeprom_name != NULL) {
      namedEEPROM(eeprom_name, num_nodes, DEFAULT_EEPROM_SIZE);
    }
    else {
      anonymousEEPROM(num_nodes, DEFAULT_EEPROM_SIZE);
    }
    dbg_clear(DBG_SIM|DBG_BOOT, "SIM: EEPROM system initialized.\n");
    
    
    tos_state.adc = create_simple_adc_model();
    tos_state.space = create_simple_spatial_model();
    
    dbg_clear(DBG_SIM|DBG_BOOT, "SIM: spatial model initialized.\n");
    tos_state.space->init();

    
    dbg_clear(DBG_SIM|DBG_BOOT, "SIM: RFM model initialized at %i kbit/sec.\n", radio_kb_rate);
    tos_state.radio_kb_rate = radio_kb_rate;
    tos_state.rfm->init();
    

    dbg_clear(DBG_SIM|DBG_BOOT, "SIM: ADC model initialized.\n");
    tos_state.adc->init();
    
    init_hardware();
    
    queue_init(&(tos_state.queue), pause_time);
    dbg_clear(DBG_SIM, "SIM: event queue initialized.\n");
    
    
    initializeSockets();
    
    /*
      if (loggingOn) {
      initializeInvocationLogging();
      //setLoggingPause(frequentPause);
      }
    */
    
    
    for (i = 0; i < num_nodes; i++) { /* initialize machine state */
      /* Start time is slightly randomized, to prevent bit synchronization */
      int rval = rand() % 10000;
      start_time += (rval) + 23741;
      dbg_clear(DBG_SIM, "SIM: Time for mote %lli initialized to %i from %i.\n", i, start_time, rval);
      tos_state.node_state[i].time = start_time;
    }
    
    for (i = 0; i < num_nodes; i++) { /* initialize applications */
      tos_state.current_node = i;
      TOS_LOCAL_ADDRESS = tos_state.current_node;
      tos_state.tos_time = tos_state.node_state[i].time;
      call StdControl.init();
      call StdControl.start();
      tos_state.node_state[i].pot_setting = 73;
    }
    
    for (;;) {
      while(TOSH_run_next_task()) {}
      if (!queue_is_empty(&(tos_state.queue))) {
	tos_state.tos_time = queue_peek_event_time(&(tos_state.queue));
	queue_handle_next_event(&(tos_state.queue));
      }
    }
    
    printf("Simulation completed.\n");
    return 0;
  }

  // Handle the event of the reception of an incoming message
  TOS_MsgPtr NIDO_received(TOS_MsgPtr packet)  __attribute__ ((C, spontaneous)) {
    return signal InjectMsg.receive(packet);
  }

  // default do-nothing message receive handler
  default event TOS_MsgPtr InjectMsg.receive(TOS_MsgPtr msg) {
    return msg;
  }
}


