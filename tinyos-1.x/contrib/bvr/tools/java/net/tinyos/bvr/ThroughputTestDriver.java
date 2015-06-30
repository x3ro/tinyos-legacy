/* ex: set tabstop=4 shiftwidth=4 expandtab:*/ 
/* $Id: ThroughputTestDriver.java,v 1.1.1.1 2005/06/19 04:34:38 rfonseca76 Exp $ */


package net.tinyos.bvr;

import java.io.*;
import java.util.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

import net.tinyos.testbed.*;

public class ThroughputTestDriver {
 
   public static final byte COMPONENTS = 3;

   //private static final int[] REPS =      {450, 900 , 1800,3600,7200,14200};
   //private static final int[] REPS =      {10 , 20,40,80,160,320 };
   //private static final int[] REPS =      {4500,500,1000,2000,4000};
   //private static final int[] INTERVALS = {1000,500,250,125,62};
      
   //Mica2 1:30h
   //private static final int[] REPS =      {2400,1000,2000,5000};
   //private static final int[] INTERVALS = {1000,500,250,100};
   //private static final int INITIAL_INTERVAL = 600000;

   private static final int[] REPS =      {25000,1000,2000,5000};
   private static final int[] INTERVALS = {1000,500,250,100};
   
   //private static final int INITIAL_INTERVAL = 3600000;
   private static final int INITIAL_INTERVAL = 300000;
    
   
   
   private Vector motes;
   private int step = 0;
   private int reps = 0;
   private int delay = 0;

   public ThroughputTestDriver(TestBedConfig tbConfig, String host, int basePort) {
      motes = new Vector();

      Iterator motesIt = tbConfig.getMotesIterator();
      TestBedConfig.TestBedConfigMote configMote;
      while (motesIt.hasNext()) {
         configMote = (TestBedConfig.TestBedConfigMote) motesIt.next(); 
         motes.addElement(new BVRTestBedMote(configMote.getId(), host, basePort));
      }
      Iterator tbMotesIt;
    
      step = 0; 
      reps = REPS[step];
      delay = INTERVALS[step];
     
      //Initial delay
      System.out.println("Starting Throughput test. Sleeping for " + (INITIAL_INTERVAL / 60000) + "minutes");
      try {
         Thread.sleep(INITIAL_INTERVAL);
      } catch (Exception e) {e.printStackTrace(System.err); System.exit(0);}
   
      int shuffle[] = new int[motes.size()];
      while (true) {
        BVRTestBedMote source = null;
        BVRTestBedMote dest = null;
        tbMotesIt = motes.iterator();
        int i,j,aux,t_source;
        for (i = 0; i < motes.size(); i++) {
            shuffle[i] = i;
        }
        //shuffle the motes
        //System.out.print("Before:");
        //for (i = 0; i < shuffle.length; i++) {
        //    System.out.print(shuffle[i] + " ");
        //}
        //System.out.println();

        for (i = motes.size(); --i > 0;) {
           j = (int)(Math.random()*(i+1));
           if (j != i) {
                aux = shuffle[i];
                shuffle[i] = shuffle[j];         
                shuffle[j] = aux;
            } 
        }

        //System.out.print("After:");
        //for (i = 0; i < shuffle.length; i++) {
        //    System.out.print(shuffle[i] + " ");
        //}
        //System.out.println();


        //now, choose the destination
        
        for (i = 0; i < shuffle.length; i++) {
            if (((BVRTestBedMote)motes.elementAt(shuffle[i])).countValid() > COMPONENTS) {
                dest = (BVRTestBedMote)motes.elementAt(shuffle[i]);
                break;
            } 
        }
        if (dest != null && shuffle.length > 1) {
            //choose source
            for (j = 1; j < shuffle.length; j++) {
                t_source = (i+j) % shuffle.length;
                source = (BVRTestBedMote)motes.elementAt(shuffle[t_source]);
                if (source.countValid() > COMPONENTS)
                    break;
            }
            if (j != shuffle.length) {
                //route from source to dest
                //System.out.println("Routing from " + source.getId() + " to " + dest.getId());
                source.sendRouteCommand(dest);
            }
        }
        //now choose the amount of sleep
        if (reps-- == 0) {
            if (++step == INTERVALS.length) {
                System.exit(0);
            }
            delay = INTERVALS[step];
            reps = REPS[step];
            System.out.println("***** Starting now with interval: " + delay);
        } 
        try {
            //System.out.println("Sleeping for "+delay+" ( step "+step + " reps " + reps + ")" );
            Thread.sleep(delay);
        } catch (Exception e) {e.printStackTrace(System.err); System.exit(0);}
      }
   }

   private static void printUsage() {
      System.err.println("usage: ThroughputTestDriver <configuration file> <host> <baseport>");
   }

   public static void main(String[] args) throws IOException {
      TestBedConfig tbConfig;
      String host;
      int baseport;
      if (args.length == 3) {
        try {
           tbConfig = new TestBedConfig(args[0]); 
           host = args[1];
           try { 
              baseport = Integer.parseInt(args[2]);
              if (baseport < 1024) baseport = 9100;
           } catch(NumberFormatException e) {
              baseport = 9100;
           }
           System.out.println("Read " + tbConfig.getNumberOfMotes() + " motes from " + args[0]);
           ThroughputTestDriver pl = new ThroughputTestDriver(tbConfig, host, baseport);
        } catch(FileNotFoundException e) {
           System.err.println(e);
           System.exit(-1);
        }
      } else {
        printUsage();
        System.exit(-1);
      }
   }
}

