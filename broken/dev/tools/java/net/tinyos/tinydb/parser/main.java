package net.tinyos.tinydb.parser;

import java_cup.runtime.Symbol;
import java.io.*;
import net.tinyos.tinydb.*;
import net.tinyos.amhandler.*;

public class main {

  static boolean run_query = true;

  static public void main(String[] args) throws java.io.IOException {

      //String query = "select avg(sensors.temp) cnt(sensors.temp) from sensors where sensors.light > 20 and sensors.temp < 58 group by sensors.light >> 2 epoch duration 128";
      //String query = "select avg(s.light) from sensors as s where sensors.light < 20 group by sensors.temp >> 2 epoch duration 1024";
      String query = "select avg(light/10) where temp > 200 group by temp";

      System.out.println("Translating query: "+ query);
      Catalog.curCatalog = new Catalog("catalog");
      TinyDBQuery tdb_query = null;
      try {
	  tdb_query = SensorQueryer.translateQuery(query, (byte) 1);
      } catch (ParseException pe) {
	    System.err.println(pe.getMessage());
	    pe.printStackTrace();
	    System.err.println(pe.getParseError());
	    return;
      }

      System.out.println(tdb_query);

//        if (run_query) {
//  	  AMInterface aif;
//  	  TinyDBNetwork nw;
	  
//  	  //open radio comm
//  	  try {
//  	      aif = new AMInterface("COM1", false);
//  	      aif.open();
	      
	      
//  	      for (int i = 0; i < 3; i++) {
//  		  aif.sendAM(CommandMsgs.resetCmd((short)-1), CommandMsgs.CMD_MSG_TYPE, (short)-1);
//  		  Thread.currentThread().sleep(200);
//  	      }
	      
//  	      nw = new TinyDBNetwork(aif);
//  	      nw.sendQuery(tdb_query);
//  	  } catch (Exception e) {
//  	      System.out.println("Open failed -- network won't work:" +e);
//  	      e.printStackTrace();
//  	  }
//        }
  }
} 

