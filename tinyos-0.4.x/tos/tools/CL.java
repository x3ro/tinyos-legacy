/*									tab:4
 * CL.java
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:  Solomon Bien
 *
 * Command line tool that makes use of most of the expInf package.
 *
 */


import expInf.*;

public class CL {
    public static void main(String [] args) {
	AMInterface aif = new AMInterface("COM1",false);
	try {
	    aif.open();
	} catch(Exception exp){
	    exp.printStackTrace();
	}
	Experiment e = new Experiment(aif);
	MoteMode m = new MoteMode(aif);
	PotKnob p = new PotKnob(aif);
	LogQuery l = new LogQuery(aif);

	try {
	    switch(args.length) {
	    case 0:
		usage();
		break;
	    case 1:
		if(args[0].equals("-h")) {  // help
		    usage();
	    }

	    //	    if(args[0].equals("-b")) {   // begin experiment
	    //e.startExperiment((byte) 0,AMInterface.TOS_BCAST_ADDR);
	    //}

	    //	    if(args[0].equals("-e")) {   // end experiment
	    //	e.stopExperiment((byte) 0,AMInterface.TOS_BCAST_ADDR);
	    //}

	    //if(args[0].equals("-d")) {   // discover nodes
	    //e.discover(AMInterface.TOS_BCAST_ADDR);
	    //}

	    //if(args[0].equals("-cb")) {   // start connectivity
	    //	e.startConnectivity(AMInterface.TOS_BCAST_ADDR);
	    //}

	    //if(args[0].equals("-ce")) {   // stop connectivity
	    //	e.stopConnectivity(AMInterface.TOS_BCAST_ADDR);
	    //}

	    break;

	case 2:
	    //    if(args[0].equals("-b")) {   // begin experiment
	    //	e.startExperiment((byte) 0,Short.parseShort(args[1]));
	    //}

	    //   if(args[0].equals("-e")) {   // end experiment
	    //	e.stopExperiment((byte) 0,Short.parseShort(args[1]));
	    //}

	    if(args[0].equals("-d")) {   // discover nodes
		e.discover(Short.parseShort(args[1]));
	    }

	    //if(args[0].equals("-g")) {   // set group ID
	    //	e.setExpID(Byte.parseByte(args[1]),AMInterface.TOS_BCAST_ADDR);
	    //}

	    if(args[0].equals("-cb")) {   // start connectivity
		e.startConnectivity(Short.parseShort(args[1]));
	    }

	    if(args[0].equals("-ce")) {   // stop connectivity
		e.stopConnectivity(Short.parseShort(args[1]));
	    }

	    //	    if(args[0].equals("-m")) {    // set mote mode
	    //	if(args[1].equals("e")) {
	    //	    m.setMode(MoteMode.EXPERIMENT_MODE,AMInterface.TOS_BCAST_ADDR);
	    //	}
	    //	if(args[1].equals("m")) {
	    //	    m.setMode(MoteMode.MONITOR_MODE,AMInterface.TOS_BCAST_ADDR);
	    //	}
	    //}

	    break;

	case 3:
	    if(args[0].equals("-g")) {   // set group ID
		e.setExpID(Byte.parseByte(args[1]),Short.parseShort(args[2]));
	    }

	    //if(args[0].equals("-b")) {   // begin experiment
	    //	e.startExperiment(Byte.parseByte(args[2]),Short.parseShort(args[1]));
	    //}

	    if(args[0].equals("-e")) {   // end experiment
		e.stopExperiment(Byte.parseByte(args[2]),Short.parseShort(args[1]));
	    }

	    if(args[0].equals("-m")) {    // set mote mode
		if(args[1].equals("e")) {
		    m.setMode(MoteMode.EXPERIMENT_MODE,Short.parseShort(args[2]));
		}
		if(args[1].equals("m")) {
		    m.setMode(MoteMode.MONITOR_MODE,Short.parseShort(args[2]));
		}
	    }

	    if(args[0].equals("-pi")) {   // increase POT
		p.increasePot(Short.parseShort(args[1]),Byte.parseByte(args[2]));
	    }

	    if(args[0].equals("-pd")) {   // decrease POT
		p.decreasePot(Short.parseShort(args[1]),Byte.parseByte(args[2]));
	    }

	    if(args[0].equals("-ps")) {   // set POT
		p.setPotValue(Short.parseShort(args[1]),Byte.parseByte(args[2]));
	    }

	    break;
	    
	case 4:

	    if(args[0].equals("-b")) {   // begin experiment
		e.startExperiment(Byte.parseByte(args[2]),Byte.parseByte(args[3]),Short.parseShort(args[1]));
	    }
	    
	    break;

	default:
	    System.out.println("Invalid Command");
	    usage();
	    break;
	}
	} catch (Exception ex) {
	    ex.printStackTrace();
	}
	System.exit(1);
    }
    
    private static void usage() {
	System.out.println("Usage: java CL <option> [parameters]");
	System.out.println("Options:");
	System.out.println("\t-h Display this usage description");
	System.out.println("\t-b [ADDR] [DELAY] [DURATION] Start experiment in DELAY clock ticks on");
System.out.println("\t\t\t\t   node ADDR and run for DURATION clock ticks");
	System.out.println("\t-cb [ADDR] Start topology query on node ADDR");
	System.out.println("\t-ce [ADDR] Stop topology query on node ADDR");
	System.out.println("\t-g [EXP_ID] [ADDR] Change the experimental ID on node ADDR to EXP_ID");
	System.out.println("\t-e [ADDR] [DELAY] End experiment in DELAY clock ticks on node ADDR");
	System.out.println("\t-m [MODE] [ADDR] Set the role of node ADDR to MODE");
	System.out.println("\t\t values of MODE:");
	System.out.println("\t\t\t e - EXPERIMENTAL");
	System.out.println("\t\t\t m - MONITOR");
	System.out.println("\t-pi [ADDR] [CHANGE] Increase the POT setting of node ADDR by CHANGE"); 
	System.out.println("\t-pd [ADDR] [CHANGE] Decrease the POT setting of node ADDR by CHANGE"); 
	System.out.println("\t-ps [ADDR] [SETTING] Set the POT of node ADDR to SETTING");
	System.out.println("");
	System.out.println("Note: specifying and address of 0 will cause a message to be broadcasted to the");
	System.out.println("      whole network");
    }
}
