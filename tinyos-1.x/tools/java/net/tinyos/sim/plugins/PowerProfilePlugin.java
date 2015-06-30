/*
 * For PowerTOSSIM project, Harvard University
 * Authors:	Bor-rong Chen
 * Date:        Mar 23 2004
 * Desc:        Power Profiling Plugin for PowerTOSSIM
 *
 */

/**
 * @author Bor-rong Chen
 */

//TODO: the simulation time shown on the top bar is actually wrong after
//we switched to 7.37Mhz  clock, fix this?

package net.tinyos.sim.plugins;

import java.util.*;
import java.text.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;


import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

/* All plugins must extend the 'Plugin' class. 'SimConst' provides
 * some useful constants.
 */
public class PowerProfilePlugin extends GuiPlugin implements SimConst {

/*
 *  power states to track:
 *
 *  ADC:
 *  LED:
 *  RADIO_STATE: TX, RX, ON, OFF, SetRFPower FF
 *  CPU_STATE: IDLE, ADC_NOISE_REDUCTION, POWER_DOWN, POWER_SAVE, RESERVED, STANDBY, EXTENDED_STANDBY
 *  EEPROM:
 */


  JTable table;
  JScrollPane scrollpane;
  String[][] tableData;

  // Begin Energy Model
  final double VOLTAGE=  3.0;

  // CPU numbers:
  // Idle mode is what the CPU is in when not actively executing, but
  // no special action is taken.  The per-active-cycle numbers are added
  // on top of that
  final double CPU_ACTIVE=                      8.0;
  //final double CPU_IDLE=                        3.2;
  final double CPU_IDLE=                        4.13;
  final double CPU_ADC_NOISE_REDUCTION=         1.0;
  final double CPU_POWER_DOWN=                  0.103;
  final double CPU_POWER_SAVE=                  0.110;
  final double CPU_STANDBY=                     0.216;
  final double CPU_EXTENDED_STANDBY=            0.223;

  // The startup mode for the cpu
  final double CPU_INIT=                        3.2;
  final double CPU_FREQ=        7370000;

  // Radio numbers
  final double RADIO_RX=        7.96;
  final double RADIO_TX_00=     4.65;
  final double RADIO_TX_01=     6.14;
  final double RADIO_TX_03=     6.3;
  final double RADIO_TX_06=     7.4;
  final double RADIO_TX_09=     7.98;
  final double RADIO_TX_0F=     9.4;
  final double RADIO_TX_60=     12.5;
  final double RADIO_TX_80=     14.7;
  final double RADIO_TX_C0=     18.3;
  final double RADIO_TX_FF=     22.41;
  final double RADIO_OFF=       0;

  // The default power mode
  final double RADIO_DEFAULT_POWER=  0x0F;

  // LED
  final double LED=             2.2;
  final double LED_INIT=        0;

  // EEPROM - FIXME
  final double EEPROM_READ=     6.241;
  final double EEPROM_WRITE=    18.401;
  final double EEPROM_INIT=     0;

  //ADC
  final double ADC=     0.9;
  final double ADC_INIT=  0;

  // If the sensor board is plugged in, it draws this much current at all times
  //final double SENSOR_BOARD=    1.6;
  final double SENSOR_BOARD=    0.69;

  // Sensors
  final double SENSOR_PHOTO=    0;

  //FIXME.......
  final double SENSOR_TEMP=     0; 
  //end Energy Model

  //max number of motes allowed
  final int MAX_MOTE = 1000;
  
  //column assignment for different component
  final int COL_MOTEID = 0;
  final int COL_RADIO = 1;
  final int COL_CPU = 2;
  final int COL_LED = 3;
  //final int COL_ADC = 4;
  final int COL_EEPROM = 4;
  final int COL_TOTAL = 5;
  
  //this tells us how many nodes in the simulation
  int max_moteid_seen = 0;
  
  double e_radio[] = new double[MAX_MOTE];
  double e_cpu[] = new double[MAX_MOTE];
  double e_led[] = new double[MAX_MOTE];
  double e_adc[] = new double[MAX_MOTE];
  double e_eeprom[] = new double[MAX_MOTE];
  double e_total[] = new double[MAX_MOTE];
  
  double radio_tx = RADIO_TX_0F; //default radio tx power level
  
  //current draw for each component at certain state
  double current_radio[] = new double[MAX_MOTE];
  double current_cpu[] = new double[MAX_MOTE];
  double current_led_r[] = new double[MAX_MOTE];
  double current_led_g[] = new double[MAX_MOTE];
  double current_led_y[] = new double[MAX_MOTE];    
  double current_adc[] = new double[MAX_MOTE];
  double current_eeprom[] = new double[MAX_MOTE];

  final double INVALID_POWER = -1.0;

  //variables for setting next state
  //must set back to INVALID_POWER after state switching is done
  double next_radio = INVALID_POWER;
  double next_cpu = INVALID_POWER;  
  double next_led_r = INVALID_POWER;
  double next_led_g = INVALID_POWER;
  double next_led_y = INVALID_POWER;    
  double next_adc = INVALID_POWER;    
  double next_eeprom = INVALID_POWER;
  
  //last time update this mote
  int last_time[] = new int[MAX_MOTE];
  int current_time;
  
  private void update_table(int moteid) {
           
           int duration;
           
           //for the first time
  	   if(last_time[moteid]==0) {
  	   	last_time[moteid] = current_time;
  	   	
  	   	//set the default states here
  	   	current_radio[moteid] = RADIO_OFF;
  	   	current_cpu[moteid] = CPU_INIT;
  	   	current_led_r[moteid] = LED_INIT;
  	   	current_led_g[moteid] = LED_INIT;
  	   	current_led_y[moteid] = LED_INIT;  	   	
  	   	current_adc[moteid] = ADC_INIT;
  	   	current_eeprom[moteid] = EEPROM_INIT;  	   	  	   	
  	   	
  	   	//end default states
  	   	return;
  	   }
  	   
  	   duration = current_time - last_time[moteid];
  	   
  	   e_radio[moteid] += current_radio[moteid] * VOLTAGE * duration / CPU_FREQ;
  	   e_cpu[moteid] += current_cpu[moteid] * VOLTAGE * duration / CPU_FREQ;
  	   e_led[moteid] += current_led_r[moteid] * VOLTAGE * duration / CPU_FREQ;
  	   e_led[moteid] += current_led_g[moteid] * VOLTAGE * duration / CPU_FREQ;
  	   e_led[moteid] += current_led_y[moteid] * VOLTAGE * duration / CPU_FREQ;  	   
           //e_adc[moteid] += current_adc[moteid] * VOLTAGE * duration / CPU_FREQ;
  	   e_eeprom[moteid] += current_eeprom[moteid] * VOLTAGE * duration / CPU_FREQ;
  	   //e_total[moteid] = e_radio[moteid] + e_cpu[moteid] + e_led[moteid] + e_adc[moteid] + e_eeprom[moteid];
  	   e_total[moteid] = e_radio[moteid] + e_cpu[moteid] + e_led[moteid] + e_eeprom[moteid];
  	   
  	   //change update time
  	   last_time[moteid] = current_time;
  	   
           //switching states
  	   if(next_radio != INVALID_POWER)
  	   {
  	   	current_radio[moteid] = next_radio;
  	   	next_radio = INVALID_POWER;
  	   }
  	   if(next_cpu != INVALID_POWER)
  	   {
  	   	current_cpu[moteid] = next_cpu;
  	   	next_cpu = INVALID_POWER;
  	   }
  	   if(next_led_r != INVALID_POWER)
  	   {
  	   	current_led_r[moteid] = next_led_r;
  	   	next_led_r = INVALID_POWER;
  	   }
  	   if(next_led_g != INVALID_POWER)
  	   {
  	   	current_led_g[moteid] = next_led_g;
  	   	next_led_g = INVALID_POWER;
  	   }
  	   if(next_led_y != INVALID_POWER)
  	   {
  	   	current_led_y[moteid] = next_led_y;
  	   	next_led_y = INVALID_POWER;
  	   }
  	   if(next_adc != INVALID_POWER)
  	   {
  	   	current_adc[moteid] = next_adc;
  	   	next_adc = INVALID_POWER;
  	   }
  	   if(next_eeprom != INVALID_POWER)
  	   {
  	   	current_eeprom[moteid] = next_eeprom;
  	   	next_eeprom = INVALID_POWER;
  	   }
  	   
  	   //update the energy number

  	   DecimalFormat format = new DecimalFormat("0.00");
  	   FieldPosition f = new FieldPosition(0);
  	   StringBuffer s;

  	   s = new StringBuffer();
  	   table.setValueAt(String.valueOf(moteid), moteid, COL_MOTEID);
  	   format.format(e_radio[moteid], s, f);
  	   table.setValueAt(s.toString(), moteid, COL_RADIO);

  	   s = new StringBuffer();  	   
  	   format.format(e_cpu[moteid], s, f);
  	   table.setValueAt(s.toString(), moteid, COL_CPU);

  	   s = new StringBuffer();
  	   format.format(e_eeprom[moteid], s, f);
  	   table.setValueAt(s.toString(), moteid, COL_EEPROM);

  	   s = new StringBuffer();
  	   format.format(e_led[moteid], s, f);
  	   table.setValueAt(s.toString(), moteid, COL_LED);

  	   s = new StringBuffer();
  	   format.format(e_total[moteid], s, f);
  	   table.setValueAt(s.toString(), moteid, COL_TOTAL);


  	   /* taken out after we added number formatting above
  	   table.setValueAt(String.valueOf(moteid), moteid, COL_MOTEID);
  	   table.setValueAt(String.valueOf(e_radio[moteid]), moteid, COL_RADIO);
  	   table.setValueAt(String.valueOf(e_cpu[moteid]), moteid, COL_CPU);
  	   table.setValueAt(String.valueOf(e_led[moteid]), moteid, COL_LED);
  	   //table.setValueAt(String.valueOf(e_adc[moteid]), moteid, COL_ADC);
  	   table.setValueAt(String.valueOf(e_eeprom[moteid]), moteid, COL_EEPROM);
  	   table.setValueAt(String.valueOf(e_total[moteid]), moteid, COL_TOTAL);
  	   */

  }

  /* The main event-handling function. Every event handled by TinyViz
   * will be delivered to each plugin through this method. There are
   * a few types of events that can be received - see the 'event' 
   * subdirectory. 
   */
  public void handleEvent(SimEvent event) {
  
      String match;
      int index_match, index_2;
  
      if (event instanceof DebugMsgEvent) {
         DebugMsgEvent dmEvent = (DebugMsgEvent)event;
         Integer mote = new Integer(dmEvent.getMoteID());
         //Integer time = new Integer();
         String msg = dmEvent.getMessage();
         
         //Currently we only support up to MAX_MOTE moteid power profiling
         
         if(mote.intValue() < MAX_MOTE) {
           
           if(mote.intValue() > max_moteid_seen)
               max_moteid_seen = mote.intValue();
         	
           //table.setValueAt(mote.toString(), mote.intValue(), COL_MOTEID);

         //Check if it is a RADIO_STATE message         
	   match = new String("POWER:");
	   
	   if ((index_match = msg.indexOf(match)) != -1) {

             //get current time
	     match = new String(" at");
	     if ((index_match = msg.indexOf(match)) != -1) {
               String strLen = msg.substring(index_match);
               String strParsed[] = strLen.split(" ");
               //table.setValueAt(strParsed[2], mote.intValue(), COL_TOTAL);
               //set current time
               current_time = Integer.valueOf(strParsed[2]).intValue();
               update_table(mote.intValue());
             }

	 	
             match = new String("RADIO_STATE");
             if ((index_match = msg.indexOf(match)) != -1) {
               String strLen = msg.substring(index_match);
               String strParsed[] = strLen.split(" ");
               
               //find state
               if((index_2 = strParsed[1].indexOf(new String("TX"))) != -1)  { next_radio = radio_tx; }
               if((index_2 = strParsed[1].indexOf(new String("RX"))) != -1)  { next_radio = RADIO_RX; }
               if((index_2 = strParsed[1].indexOf(new String("ON"))) != -1)  { next_radio = RADIO_RX; }
               if((index_2 = strParsed[1].indexOf(new String("OFF"))) != -1)  { next_radio = RADIO_OFF; }
               if((index_2 = strParsed[1].indexOf(new String("SetRFPower"))) != -1)  { radio_tx = RADIO_TX_0F; } //FIXME: implement SetRFPower
               update_table(mote.intValue());
             }
             
             match = new String("CPU_STATE");
             if ((index_match = msg.indexOf(match)) != -1) {
               String strLen = msg.substring(index_match);
               String strParsed[] = strLen.split(" ");
               //table.setValueAt(strParsed[1], mote.intValue(), COL_CPU);

               //find state
               if((index_2 = strParsed[1].indexOf(new String("IDLE"))) != -1)  { next_cpu = CPU_IDLE; }
               if((index_2 = strParsed[1].indexOf(new String("ADC_NOISE_REDUCTION"))) != -1)  { next_cpu = CPU_ADC_NOISE_REDUCTION; }
               if((index_2 = strParsed[1].indexOf(new String("POWER_DOWN"))) != -1)  { next_cpu = CPU_POWER_DOWN; }
               if((index_2 = strParsed[1].indexOf(new String("POWER_SAVE"))) != -1)  { next_cpu = CPU_POWER_SAVE; }
               if((index_2 = strParsed[1].indexOf(new String("STANDBY"))) != -1)  { next_cpu = CPU_STANDBY; }
               if((index_2 = strParsed[1].indexOf(new String("EXTENDED_STANDBY"))) != -1)  { next_cpu = CPU_EXTENDED_STANDBY; }
               update_table(mote.intValue());
             }

             match = new String("LED_STATE");
             if ((index_match = msg.indexOf(match)) != -1) {
               String strLen = msg.substring(index_match);
               String strParsed[] = strLen.split(" ");

               //find state
               if((index_2 = strParsed[1].indexOf(new String("RED_ON"))) != -1)  { next_led_r = LED; }
               if((index_2 = strParsed[1].indexOf(new String("RED_OFF"))) != -1)  { next_led_r = LED_INIT; }
               if((index_2 = strParsed[1].indexOf(new String("GREEN_ON"))) != -1)  { next_led_g = LED; }
               if((index_2 = strParsed[1].indexOf(new String("GREEN_OFF"))) != -1)  { next_led_g = LED_INIT; }
               if((index_2 = strParsed[1].indexOf(new String("YELLOW_ON"))) != -1)  { next_led_y = LED; }
               if((index_2 = strParsed[1].indexOf(new String("YELLOW_OFF"))) != -1)  { next_led_y = LED_INIT; }

               //table.setValueAt(strParsed[1], mote.intValue(), COL_LED);
               update_table(mote.intValue());
             }

             match = new String("ADC");
             if ((index_match = msg.indexOf(match)) != -1) {
               String strLen = msg.substring(index_match);
               String strParsed[] = strLen.split(" ");

               //find state
               if((index_2 = strParsed[1].indexOf(new String("SAMPLE"))) != -1)  { next_adc = ADC; }
               if((index_2 = strParsed[1].indexOf(new String("DATA_READY"))) != -1)  { next_adc = ADC_INIT; }

               //table.setValueAt(strParsed[1], mote.intValue(), COL_ADC);
               //table.setValueAt(String.valueOf(current_adc[mote.intValue()]), mote.intValue(), COL_TOTAL);

               update_table(mote.intValue());
             }

             match = new String("EEPROM");
             if ((index_match = msg.indexOf(match)) != -1) {
               String strLen = msg.substring(index_match);
               String strParsed[] = strLen.split(" ");

               //find state
               if((index_2 = strParsed[2].indexOf(new String("START"))) != -1) {
                  if((index_2 = strParsed[1].indexOf(new String("WRITE"))) != -1)  { next_eeprom = EEPROM_WRITE; }
                  if((index_2 = strParsed[1].indexOf(new String("READ"))) != -1)  { next_eeprom = EEPROM_READ; }
               }
                  
               if((index_2 = strParsed[2].indexOf(new String("STOP"))) != -1)  { next_eeprom = EEPROM_INIT; }

               //table.setValueAt(strParsed[1]+strParsed[2], mote.intValue(), COL_EEPROM);
               update_table(mote.intValue());
             }

             
           }
         }
     }
     motePanel.refresh();
  }

  /* This method is called when a plugin is "registered", ie., enabled
   * by the user from the plugins menu. Here we create the widgets to appear 
   * in the plugin control panel.
   */
  public void register() {
   
    String columnNames[] = { "moteid", "radio", "cpu", "led", "eeprom", "total"};
    tableData = new String[MAX_MOTE][6];
    table = new JTable(tableData, columnNames);
    scrollpane = new JScrollPane(table);
    pluginPanel.add(scrollpane);
  }

  /* This method is called when a plugin is disabled by the user - here
   * we do nothing.
   */
  public void deregister() {}

  /* This method is called when the simulation state is reset, which 
   * may happen when the simulation stops running, or in between 
   * simulations when using AutoRun files. Here we want to clear out our
   * internal state.
   */
  public void reset() {
    motePanel.refresh();
  }


//modified from ADCPlugin.java

  /* Called when it's time to redraw the mote panel. Here we just redraw
   * the arrows representing radio links.
   */
  public void draw(Graphics graphics) {
    
    //these values are just for fancy coloring of mote energy numbers
    //in motepanel
    double TOTAL_BATTERY_ENERGY = 200; //assume each mote has such amount of battery energy
    double LEVEL_3 = 0.5 * TOTAL_BATTERY_ENERGY;  // anything above it is good, green
    double LEVEL_2 = 0.2 * TOTAL_BATTERY_ENERGY;  // 
    double LEVEL_1 = 0.05 * TOTAL_BATTERY_ENERGY; // critical
    double LEVEL_0 = 0.01 * TOTAL_BATTERY_ENERGY; // mote with lower than this energy is dead
    
    double e_remaining;
    String strEnergy;
  	
    Iterator it = state.getMoteSimObjects().iterator();
    graphics.setFont(tv.smallFont);
    graphics.setColor(Color.green);
    while (it.hasNext()) {
      MoteSimObject mote = (MoteSimObject)it.next();
      if (!mote.isVisible()) {
	continue;
      }
    
        e_remaining = TOTAL_BATTERY_ENERGY - e_total[mote.getID()];
        
        //set the color according to energy spent
        if(e_remaining < LEVEL_0) {graphics.setColor(Color.black);}  //should turn off mote here, future work :)
        else if(e_remaining < LEVEL_1) {graphics.setColor(Color.red);}
        else if(e_remaining < LEVEL_2) {graphics.setColor(Color.orange);}
        else if(e_remaining < LEVEL_3) {graphics.setColor(Color.blue);}
        else {graphics.setColor(Color.green);}
        //
        
        DecimalFormat eFormat = new DecimalFormat("###.##");
        strEnergy = new String("E:" + eFormat.format(e_total[mote.getID()]));
      
	CoordinateAttribute coordinate = mote.getCoordinate();
	int x = (int)cT.simXToGUIX(coordinate.getX());
       	int y = (int)cT.simYToGUIY(coordinate.getY());
	graphics.drawString(strEnergy, x+10, y);
      }
   }

  
  /* The toString() method is important - it gives the plugin a name in
   * the plugins menu and panel. Use a *short* but descriptive name here.
   */
  public String toString() {
    return "Power Profiling";
  }
}
