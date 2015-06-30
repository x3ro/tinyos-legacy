// $Id: Nido.nc,v 1.3 2004/04/29 17:45:43 shnayder Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Philip Levis, Nelson Lee
 * Date last modified:  9/08/02
 *
 */

/**
 * @author Philip Levis
 * @author Nelson Lee
 */


includes nido;

module Nido {
  // Interface to inject messages into GenericComm
  provides interface ReceiveMsg as RadioReceiveMsg;
  provides interface BareSendMsg as RadioSendMsg;
  provides interface ReceiveMsg as UARTReceiveMsg;
  uses {
    interface StdControl;
    interface Pot;
    interface PowerState;
  }
}
implementation
{
  // Declared as a component variable because one must be able
  // to modify it externally
  
  
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
    fprintf(stderr, "Usage: %s [-h|--help] [options] num_nodes_total\n", progname);
    exit(-1);
  }
  
  void help(char* progname) {
    fprintf(stderr, "Usage: %s [options] num_nodes\n", progname);
    fprintf(stderr, "  [options] are:\n");
    fprintf(stderr, "  -h, --help        Display this message.\n");
    fprintf(stderr, "  -gui              pauses simulation waiting for GUI to connect\n");
    fprintf(stderr, "  -nodbgout	 only send dbg messages to GUI, not to stdout\n");
    fprintf(stderr, "  -a=<model>        specifies ADC model (generic is default)\n");
    fprintf(stderr, "                    options: generic random\n");
    fprintf(stderr, "  -b=<sec>          motes boot over first <sec> seconds (default 10)\n");
    fprintf(stderr, "  -e=<file>         use <file> for eeprom; otherwise anonymous file is used\n");
    fprintf(stderr, "  -l=<scale>        run sim at <scale> times real time (fp constant)\n");
    fprintf(stderr, "  -r=<model>        specifies a radio model (simple is default)\n");
    fprintf(stderr, "                    options: simple lossy\n");
    fprintf(stderr, "  -rf=<file>        specifies file for lossy mode (lossy.nss is default)\n");
    fprintf(stderr, "                    implicitly selects lossy model\n");
    fprintf(stderr, "  -s=<num>          only boot <num> of nodes\n");
    fprintf(stderr, "  -t=<sec>          run simulation for <sec> virtual seconds\n");
    fprintf(stderr, "  -p                do power profiling\n");
    fprintf(stderr, "  num_nodes         number of nodes to simulate\n");
    
    fprintf(stderr, "\n");
    dbg_help();
    fprintf(stderr, "\n");
    exit(-1);
  }

  void event_boot_handle(event_t* fevent,
			 struct TOS_state* fstate) __attribute__ ((C, spontaneous)) {
    char timeVal[128];
    printTime(timeVal, 128);

    // don't boot if a command came in that turned off the mote
    if (! tos_state.cancelBoot[NODE_NUM]) {
      dbg(DBG_BOOT, "BOOT: Mote booting at time %s.\n", timeVal);
      nido_start_mote((uint16_t)NODE_NUM);
    } else {
      dbg(DBG_BOOT, "BOOT: Boot cancelled at time %s since mote turned off.\n",
          timeVal);
    }
  }

  int main(int argc, char **argv) __attribute__ ((C, spontaneous)) {
    long long i;
    long long last_power_time = 0;
    
    int power_profiling = 0;
    int cpu_profiling = 0;
    int num_nodes_total;
    int num_nodes_start = -1;
    
    unsigned long long max_run_time = 0;
    
    char* adc_model_name = NULL;
    char* model_name = NULL;
    char* eeprom_name = NULL;
    
    int start_time = 0;
    int pause_time = 0;
    int start_interval = 10; // by default, motes boot over 10 sec
    char* rate_constant = "1000.0";
    char* lossy_file = NULL;
    
    int radio_kb_rate = 40;  // FIXME: wrong for mica2
    
    int currentArg;
    
    if (argc == 2 && ((strcmp(argv[1], "-h") == 0) ||
		      (strcmp(argv[1], "--help") == 0))) {
      help(argv[0]);
    }

    if (argc < 2) {usage(argv[0]);}
    
    dbg_init();
    
    for (currentArg = 1; currentArg < argc - 1; currentArg++) {
      char* arg = argv[currentArg];
      if ((strcmp(arg, "-h") == 0) ||
	  (strcmp(arg, "--help") == 0)) {
	help(argv[0]);
      }
      else if (strcmp(argv[currentArg], "--help") == 0) {
	help(argv[0]);
      }
      else if (strcmp(arg, "-gui") == 0) {
	GUI_enabled = 1;
      }
      else if (strcmp(arg, "-nodbgout") == 0) {
	dbg_suppress_stdout = 1;
      }
      else if (strncmp(arg, "-a=", 3) == 0) {
	arg += 3;
	adc_model_name = arg;
      }
      else if (strncmp(arg, "-b=", 3) == 0) {
	arg += 3;
	start_interval = atoi(arg);
        if (start_interval < 0) {
          fprintf(stderr, "SIM: boot time value must be a positive integer, not %s\n", arg);
          exit(-1);
        }
      }
      else if (strncmp(arg, "-ef=", 3) == 0) {
	arg += 4;
	eeprom_name = arg;
      }
      else if (strncmp(arg, "-l=", 3) == 0) {
	arg += 3;
	rate_constant = arg;
      }
      else if (strncmp(arg, "-r=", 3) == 0) {
	arg += 3;
	model_name = arg;
      }
      else if (strncmp(arg, "-rf=", 4) == 0) {
	arg += 4;
	model_name = "lossy";
	lossy_file = arg;
      }
      else if (strncmp(arg, "-s=",3) == 0) {
	arg += 3;
	num_nodes_start = atoi(arg);
      }
      else if (strncmp(arg, "-t=", 3) == 0) {
	arg += 3;
	max_run_time = (unsigned long long)atoi(arg);
	max_run_time *= 4000000;
      }
      else if (strcmp(arg, "-p") == 0) {
	   power_profiling = 1;
      }
      else if (strcmp(arg, "-cpuprof") == 0) {
	   cpu_profiling = 1;
      }
      else {
	usage(argv[0]);
      }
    }

    set_rate_value(atof(rate_constant));
    if (get_rate_value() <= 0.0) {
      fprintf(stderr, "SIM: Invalid rate constant: %s.\n", rate_constant);
      exit(-1);
    }
    
    num_nodes_total = atoi(argv[argc - 1]);
    if (num_nodes_total <= 0) {usage(argv[0]);}
    
    if ((num_nodes_start < 0) || (num_nodes_start > num_nodes_total)) {
      num_nodes_start = num_nodes_total;
    }
    
    // finished parsing command line

    call PowerState.init(power_profiling, cpu_profiling);  

    
    if (num_nodes_total > TOSNODES) {
      fprintf(stderr, "Nido: I am compiled for maximum of %d nodes and you have specified %d nodes.\n", TOSNODES, num_nodes_total);
      fprintf(stderr, "Nido: Exiting...\n");
      exit(-1);
    }

    init_signals();
    initializeSockets();
    tos_state.num_nodes = num_nodes_total;
    
    // RFM model initialized
    
    if (model_name == NULL || strcmp(model_name, "simple") == 0) {
      tos_state.rfm = create_simple_model();
      tos_state.radioModel = TOSSIM_RADIO_MODEL_SIMPLE;
    }
    else if (strcmp(model_name, "lossy") == 0) {
      tos_state.rfm = create_lossy_model(lossy_file);
      tos_state.radioModel = TOSSIM_RADIO_MODEL_LOSSY;
    }
    else {
      fprintf(stderr, "SIM: Don't recognize RFM model type %s.\n", model_name);
      exit(-1);
    }

    // ADC model initialized 
    
    if (adc_model_name == NULL || strcmp(adc_model_name, "generic") == 0) {
      tos_state.adc = create_generic_adc_model();
    }
    else if (strcmp(adc_model_name, "random") == 0) {
      tos_state.adc = create_random_adc_model();
    }
    else {
      fprintf(stderr, "SIM: Bad ADC model name: %s\n", adc_model_name);
      exit(-1);
    }
    if (eeprom_name != NULL) {
      namedEEPROM(eeprom_name, num_nodes_total, DEFAULT_EEPROM_SIZE);
    }
    else {
      anonymousEEPROM(num_nodes_total, DEFAULT_EEPROM_SIZE);
    }
    dbg_clear(DBG_SIM|DBG_BOOT, "SIM: EEPROM system initialized.\n");
    
    tos_state.space = create_simple_spatial_model();
    
    tos_state.radio_kb_rate = radio_kb_rate;
    tos_state_model_init();
    packet_sim_init();
    
    init_hardware();
    
    queue_init(&(tos_state.queue), pause_time);
    dbg_clear(DBG_SIM, "SIM: event queue initialized.\n");

    if (GUI_enabled) {
      waitForGuiConnection();
    }
    
    for (i = 0; i < num_nodes_start; i++) { /* initialize machine state */
      /* Start time is slightly randomized, to prevent bit synchronization */
      int rval = rand();
      if (start_interval > 0) {
	rval %= (4000000 * start_interval); // One second FIXME: use CPUFREQ
        start_time = rval + i;
      } else if (start_interval == 0) {
        start_time = i;
      }
      
      tos_state.node_state[i].time = start_time;
      dbg_clear(DBG_SIM|DBG_USR3, "SIM: Time for mote %lli initialized to %lli.\n",
                i, tos_state.node_state[i].time);
    }

    for (i = 0; i < num_nodes_start; i++) { /* initialize applications */
      char timeVal[128];
      event_t* fevent = (event_t*)malloc(sizeof(event_t));
      fevent->mote = i;
      fevent->time = tos_state.node_state[i].time;
      fevent->handle = event_boot_handle;
      fevent->cleanup = event_default_cleanup;
      fevent->pause = 0;
      fevent->force = 1;
      TOS_queue_insert_event(fevent);
      printOtherTime(timeVal, 128, tos_state.node_state[i].time);
      dbg(DBG_BOOT, "BOOT: Scheduling for boot at %s.\n", timeVal);
    }
    
    rate_checkpoint();
    
    for (;;) {
      if ((max_run_time > 0) && (tos_state.tos_time >= max_run_time)) {
	break;
      }
      /* Check if we need to pause */
      pthread_mutex_lock(&(tos_state.pause_lock));
      if (tos_state.paused == TRUE) {
	pthread_cond_signal(&(tos_state.pause_ack_cond));
	pthread_cond_wait(&(tos_state.pause_cond), &(tos_state.pause_lock));
      }
      pthread_mutex_unlock(&(tos_state.pause_lock));
      
      while(TOSH_run_next_task()) {}
      if (!queue_is_empty(&(tos_state.queue))) {
	tos_state.tos_time = queue_peek_event_time(&(tos_state.queue));
	queue_handle_next_event(&(tos_state.queue));
	// Sleep appropriately, but only if we need to sleep for
	// more than 10ms (the 10000 constant below)
	// implemented in tos.c
	rate_based_wait(); 
      }
      if(cpu_profiling) {
	   /* Don't want to send too many messages-lets make it 10 per
	     virtual second */
	   
	   if(tos_state.tos_time - last_power_time > (long long)CPU_FREQ/10)
	   {
		call PowerState.CPUCycleCheckpoint();
		last_power_time = tos_state.tos_time;
	   }
      }
    }
    if(power_profiling || cpu_profiling) {
	 call PowerState.stop();
    }
    
    printf("Simulation of %i motes completed.\n", num_nodes_total);
    return 0;
  }
  
  void nido_start_mote(uint16_t moteID) __attribute__ ((C, spontaneous)) {
    if ((!tos_state.moteOn[moteID]) && (moteID < tos_state.num_nodes)) {
      __nesc_nido_initialise(moteID);
      tos_state.moteOn[moteID] = 1;
      tos_state.current_node = moteID;
      atomic TOS_LOCAL_ADDRESS = tos_state.current_node;
      tos_state.node_state[moteID].time = tos_state.tos_time;
      call StdControl.init();
      call StdControl.start();
      tos_state.node_state[moteID].pot_setting = 73;
      while(TOSH_run_next_task()) {} // Clear out tasks posted by StdControl
    }
  }
  

  void nido_stop_mote(uint16_t moteID) __attribute__ ((C, spontaneous)) {
    // if the mote was scheduled to boot, make sure it doesn't
    tos_state.cancelBoot[moteID] = 1;
    
    if ((tos_state.moteOn[moteID]) && (moteID < tos_state.num_nodes)) {
      tos_state.moteOn[moteID] = 0;
      tos_state.current_node = moteID;
      atomic TOS_LOCAL_ADDRESS = tos_state.current_node;
      tos_state.node_state[moteID].time = tos_state.tos_time;
      call StdControl.stop();
    }
  }

  // Handle the event of the reception of an incoming message
  TOS_MsgPtr NIDO_received_radio(TOS_MsgPtr packet)  __attribute__ ((C, spontaneous)) {
    packet->crc = 1;
    return signal RadioReceiveMsg.receive(packet);
  }

  // default do-nothing message receive handler
  default event TOS_MsgPtr RadioReceiveMsg.receive(TOS_MsgPtr msg) {
    return msg;
  }

  TOS_MsgPtr NIDO_received_uart(TOS_MsgPtr packet) __attribute__ ((C, spontaneous)) {
    packet->crc = 1;
    return signal UARTReceiveMsg.receive(packet);
  }

  // default do-nothing message receive handler
  default event TOS_MsgPtr UARTReceiveMsg.receive(TOS_MsgPtr msg) {
    return msg;
  }


  command result_t RadioSendMsg.send(TOS_MsgPtr msg) {
    dbg(DBG_AM,"TossimPacketM: Send.send() called\n");
    return packet_sim_transmit(msg);
  }

  default event result_t RadioSendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    return FAIL;
  }
  
  void packet_sim_transmit_done(TOS_MsgPtr msg) __attribute__ ((C, spontaneous)) {
    dbg(DBG_PACKET, "TossimPacketMica2M: Send done.\n");
    signal RadioSendMsg.sendDone(msg, SUCCESS);
  }

  void packet_sim_receive_msg(TOS_MsgPtr msg)  __attribute__ ((C, spontaneous)) {
    msg = signal RadioReceiveMsg.receive(msg);
  }
  
  void set_sim_rate(uint32_t rate)  __attribute__ ((C, spontaneous)) {
    double realRate = (double)rate;
    realRate /= 1000.0;
    dbg_clear(DBG_SIM, "SIM: Setting rate to %lf\n", realRate);
    set_rate_value(realRate);
    rate_checkpoint();
  }

  uint32_t get_sim_rate() __attribute__ ((C, spontaneous)) {
    return (uint32_t)(1000.0 * get_rate_value()); 
  }
  
}
