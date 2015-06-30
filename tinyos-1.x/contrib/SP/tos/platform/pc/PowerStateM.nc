/**
 *
 * Author: Victor Shnayder, Bor-rong Chen
 */

includes powermod;
includes sensorboard;

module PowerStateM {
     provides interface PowerState;
}
implementation
{
     /*
      * Variable defs in powermod.h-that way they stay global instead of
      * being transformed to be per-mote
      */

     // prototypes
     int num_bbs();
     void dump_power_details();
     
     async command result_t PowerState.init(int prof, int cpu_prof) {
	  FILE* cycle_file;
	  char cycle_map[] = "bb_cycle_map";
	  int bb;
	  double bbcyc;
	  if(power_init == 1) {
	       fprintf(stderr,"PowerState.init() called twice...\n");
	       return SUCCESS;
	  }
	  power_init = 1;
	  prof_on = prof;
	  cpu_prof_on = cpu_prof;
	  
	  if(cpu_prof_on) {
	       cycle_file = fopen(cycle_map, "r");
	       if(!cycle_file) {
		    fprintf(stderr,"Couldn't open '%s', exiting\n", cycle_map);
		    exit(-1);
	       }
      
	       cycles = calloc(num_bbs(), sizeof(double));
      
	       while(EOF != fscanf(cycle_file, " %d %lf", &bb, &bbcyc)) {
		    cycles[bb] = bbcyc;
	       }
	       fclose(cycle_file);
	  }
	  return SUCCESS;
     }


     async command result_t PowerState.stop() {
	  if(cpu_prof_on)
	       dump_power_details();
	  return SUCCESS;
     }

/*************** STATE TRANSITION CODE ****************************/
     /******* ADC state functions ***/

     async command void PowerState.ADCon() {
	  if(!prof_on) return;
	  dbg(DBG_POWER, "POWER: Mote %d ADC ON at %lld \n", NODE_NUM,
	      tos_state.tos_time);
     }

     async command void PowerState.ADCoff() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d ADC OFF at %lld \n", NODE_NUM,
	      tos_state.tos_time);
     }

     async command void PowerState.ADCdataReady() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d ADC DATA_READY at %lld \n", NODE_NUM,
	      tos_state.tos_time);
     }
  
     async command void PowerState.ADCsample(uint8_t port) {
	  if(!prof_on) return;

	  dbg(DBG_POWER, "POWER: Mote %d ADC SAMPLE PORT %d at %lld \n", NODE_NUM, port,
		   tos_state.tos_time);
	  
/** It would be nice to know which port it is, but not portable.  So
 * instead just printing the port number
 */
/*  switch(port) {
	  case TOS_ADC_CC_RSSI_PORT:
	       dbg(DBG_POWER, "POWER: Mote %d ADC SAMPLE RSSI_PORT at %lld \n", NODE_NUM,
		   tos_state.tos_time);
	  case TOS_ADC_PHOTO_PORT:
	       dbg(DBG_POWER, "POWER: Mote %d ADC SAMPLE PHOTO_PORT at %lld \n", NODE_NUM,
		   tos_state.tos_time);
	       break;
	  case TOS_ADC_TEMP_PORT:
	       dbg(DBG_POWER, "POWER: Mote %d ADC SAMPLE TEMP_PORT at %lld \n", NODE_NUM,
		   tos_state.tos_time);
	       break;
	  case TOS_ADC_MIC_PORT:
	       dbg(DBG_POWER, "POWER: Mote %d ADC SAMPLE MIC_PORT at %lld \n", NODE_NUM,
		   tos_state.tos_time);
	       break;
	  case TOS_ADC_ACCEL_X_PORT:
	       dbg(DBG_POWER, "POWER: Mote %d ADC SAMPLE ACCEL_X_PORT at %lld \n", NODE_NUM,
		   tos_state.tos_time);
	       break;
	  case TOS_ADC_ACCEL_Y_PORT:
	       dbg(DBG_POWER, "POWER: Mote %d ADC SAMPLE ACCEL_Y_PORT at %lld \n", NODE_NUM,
		   tos_state.tos_time);
	       break;
	  case TOS_ADC_MAG_X_PORT:
	       dbg(DBG_POWER, "POWER: Mote %d ADC SAMPLE MAG_X_PORT at %lld \n", NODE_NUM,
		   tos_state.tos_time);
	       break;
	  case TOS_ADC_MAG_Y_PORT:
	       dbg(DBG_POWER, "POWER: Mote %d ADC SAMPLE MAG_Y_PORT at %lld \n", NODE_NUM,
		   tos_state.tos_time);
	       break;
	  default:
	       dbg(DBG_POWER, "POWER: Mote %d ADC SAMPLE unknown_port_%i at %lld \n", NODE_NUM,
		   port, tos_state.tos_time);
	  }
*/
     }

     /******* LED state functions ***/
     async command void PowerState.redOn() {
	  if(!prof_on) return;
	  dbg(DBG_POWER, "POWER: Mote %d LED_STATE RED_ON at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }
  
     async command void PowerState.redOff() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d LED_STATE RED_OFF at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }
  
     async command void PowerState.greenOn() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d LED_STATE GREEN_ON at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }
  
     async command void PowerState.greenOff() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d LED_STATE GREEN_OFF at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }
  
     async command void PowerState.yellowOn() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d LED_STATE YELLOW_ON at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }
  
     async command void PowerState.yellowOff() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d LED_STATE YELLOW_OFF at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }
  
     /******* RADIO state functions ***/
     async command void PowerState.radio(const char *state) {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d RADIO_STATE %s at %lld\n", NODE_NUM,
	      state, tos_state.tos_time);
     }

     async command void PowerState.radioTxMode() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d RADIO_STATE TX at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }

     async command void PowerState.radioRxMode() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d RADIO_STATE RX at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }

     async command void PowerState.radioRFPower(uint8_t power_level) {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d RADIO_STATE SetRFPower %X at %lld\n", NODE_NUM, power_level,
	      tos_state.tos_time);
     }

     async command void PowerState.radioStart() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d RADIO_STATE ON at %lld\n", NODE_NUM, 
	      tos_state.tos_time);
     }

     async command void PowerState.radioStop() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d RADIO_STATE OFF at %lld\n", NODE_NUM, 
	      tos_state.tos_time);
     }

     /************ CPU state funtions *******/
  
     async command void PowerState.cpuState(uint8_t sm) {

	  char cpu_power_state[8][20] = {"IDLE", \
					 "ADC_NOISE_REDUCTION", \
					 "POWER_DOWN", \
					 "POWER_SAVE", \
					 "RESERVED", \
					 "RESERVED", \
					 "STANDBY", \
					 "EXTENDED_STANDBY"};
       
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d CPU_STATE %s at %lld\n", NODE_NUM, cpu_power_state[sm],
	      tos_state.tos_time);

     }

     /************ SENSOR functions *********/
     async command void PowerState.sensorPhotoOn() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d SENSOR_STATE PHOTO ON at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }

     async command void PowerState.sensorPhotoOff() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d SENSOR_STATE PHOTO OFF at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }

     async command void PowerState.sensorTempOn() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d SENSOR_STATE TEMP ON at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }
                                                                                         
     async command void PowerState.sensorTempOff() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d SENSOR_STATE TEMP OFF at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }

     async command void PowerState.sensorAccelOn() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d SENSOR_STATE ACCEL ON at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }
                                                                                         
     async command void PowerState.sensorAccelOff() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d SENSOR_STATE ACCEL OFF at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }

     /************ EEPROM functions *********/
     async command void PowerState.eepromReadStart() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d EEPROM READ START at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }
  
     async command void PowerState.eepromReadStop() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d EEPROM READ STOP at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }

     async command void PowerState.eepromWriteStart() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d EEPROM WRITE START at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }
  
     async command void PowerState.eepromWriteStop() {
	  if(!prof_on) return; 
	  dbg(DBG_POWER, "POWER: Mote %d EEPROM WRITE STOP at %lld\n", NODE_NUM,
	      tos_state.tos_time);
     }
  
     /************ SNOOZE functions *********/

     async command void PowerState.snoozeStart() {
//       if(!prof_on) return; 
// dbg(DBG_POWER, "POWER: Mote %d SNOOZE START at %lld\n", NODE_NUM,
//           tos_state.tos_time);
     }

     async command void PowerState.snoozeWakeup() {
//       if(!prof_on) return; 
// dbg(DBG_POWER, "POWER: Mote %d SNOOZE END at %lld\n", NODE_NUM,
//           tos_state.tos_time);
     }

/********************** End State Transition Code  *******************/

     /****************************************************************
      * CPU Cycle Counting stuff: this needs a little explanation.
      *
      * This code will be run through the nesc compiler together with all
      * the other application components to generate a single app.c.  So
      * it needs to pass standard nesc.
      *
      * Then, it is run through CIL, which tags all the basic blocks.
      * Then it is run through a perl script to fix up some of the
      * references to # of basic blocks and to the actual exec counts for
      * each BB.  And then it's finally compiled.
      * 
      * Hence the nonsensical code in these next two functions: they need
      * to be valid C to pass the first (and second) preprocessor, and
      * will be made sensical by a later post-pre-processing step
      *****************************************************************/

     int num_bbs() {
	  // Preprocessor will add an '= #' to set it correctly
	  int POWERPROF_NUM_BBS;  
	  return POWERPROF_NUM_BBS;  
     }

     int bb_exec_count(int mote,int bb) {
	  int POWERPROF_BB_EXEC_COUNT;  // will be replaced with bb_count[mote][bb]
	  return POWERPROF_BB_EXEC_COUNT;
     }

     async command double PowerState.get_mote_cycles(int mote) {
	  int bb;
	  double total;
	  if(!cpu_prof_on) {
	       fprintf(stderr,"get_mote_cycles() called when cpu prof is off!  Shouldn't happen!\n");
	       exit(-1);
	  }

	  total = 0;
	  for(bb=1; bb < num_bbs(); bb++) {
	       total += bb_exec_count(mote,bb) * cycles[bb];
	  }
	  return total;
     }

  
     /* Print current totals to the debug stream */
     void print_power_info() {
	  int mote;
	  if(!cpu_prof_on) {
	       fprintf(stderr,"print_power_info() called when cpu prof is off!  Shouldn't happen!\n");
	       exit(-1);
	  }


	  if(!power_init) {
	       fprintf(stderr, "print_power_info() called before init_power_info()! Should never happen!\n");
	       exit(-1);
	  }
    
	  for(mote=0; mote < tos_state.num_nodes; mote++) {
	       //fprintf(stderr,"%d: CPU: %.1f\n", i, total);
	       dbg(DBG_POWER,"POWER: Mote %d CPU_CYCLES %.1lf at %lld\n", mote,
		     call PowerState.get_mote_cycles(mote),
		     tos_state.tos_time);
	  }
     }  

     /* Dump details to a file */
     void dump_power_details() {
	  char exec_cnts[] = "bb_exec_cnt";  // File to write to
	  FILE* f;
	  int mote,bb;

	  if(!cpu_prof_on) {
	       fprintf(stderr,"dump_power_details() called when cpu prof is off!  Shouldn't happen!\n");
	       exit(-1);
	  }

	  f = fopen(exec_cnts,"w");
	  if(!f) {
	       fprintf(stderr,"Couldn't open '%s', exiting\n", exec_cnts);
	       exit(-1);
	  }
	  for(mote=0; mote < tos_state.num_nodes; mote++) {
	       fprintf(f,"mote %d total cycles: %.1lf\n", mote, call PowerState.get_mote_cycles(mote));
	       dbg(DBG_POWER,"POWER: Mote %d CPU_CYCLES %.1lf at %lld\n", mote, call PowerState.get_mote_cycles(mote), tos_state.tos_time);
      
	       for(bb=1; bb < num_bbs(); bb++) {
		    fprintf(f, "%6d %6d %8d\n", mote, bb, bb_exec_count(mote,bb));
		    // dbg(DBG_POWER, "%6d %6d %8d\n", mote, bb, bb_exec_count(mote,bb));
	       }
	  }
	  fclose(f);
     }


     async command void PowerState.CPUCycleCheckpoint() {
	  if(!cpu_prof_on) {
	       fprintf(stderr,"CPUCycleCheckpoint() called when cpu prof is off!  Shouldn't happen!\n");
	       exit(-1);
	  }

	  /* FIXME: what's the right thing to do here? */
	  print_power_info();
     }

     /***********************  END CPU CYCLE COUNT CODE ***************/
}
