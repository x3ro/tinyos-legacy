// $Id: DriveTest.java,v 1.1 2006/12/01 00:57:00 binetude Exp $

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

/**
 * File: DriveTest.java
 *
 * @author <a href="mailto:binetude@cs.berkeley.edu">Sukun Kim</a>
 */

package net.tinyos.sentri;
import java.util.*;

class DriveTest {

  DataCenter dc = new DataCenter();

  private int easyWait(long dur) {
    synchronized (this) {
      try {
        wait(dur);
      } catch (InterruptedException e) {
        System.out.println("EXCEPTION: DataCenter.easyWait");
      }
    }
    return 0;
  }



  private int ledOff() {
    String[] inputArgs;
    inputArgs = new String[1];
    inputArgs[0] = "ledOff";
    //inputArgs[1] = "-verbose";
    return dc.execute(inputArgs);
  }

  private int eraseFlash() {
    String[] inputArgs;
    inputArgs = new String[1];
    inputArgs[0] = "eraseFlash";
    //inputArgs[1] = "-verbose";
    return dc.execute(inputArgs);
  }

  private int startSensing() {
    String[] inputArgs;
    inputArgs = new String[7];
    inputArgs[0] = "startSensing";
    inputArgs[1] = "48000";
    inputArgs[2] = "1000";
    inputArgs[3] = "-chnlSelect";
    inputArgs[4] = "31";
    inputArgs[5] = "-samplesToAvg";
    inputArgs[6] = "5";
    //inputArgs[7] = "-verbose";
    return dc.execute(inputArgs);
  }
  
  private int readData(int dest) {
    String[] inputArgs;
    inputArgs = new String[3];
    inputArgs[0] = "readData";
    inputArgs[1] = "-dest";
    inputArgs[2] = "" + dest;
    //inputArgs[3] = "-verbose";
    return dc.execute(inputArgs);
  }

  private int networkInfo(int dest) {
    String[] inputArgs;
    inputArgs = new String[2];
    inputArgs[0] = "networkInfo";
    inputArgs[1] = "" + dest;
    //inputArgs[2] = "-verbose";
    return dc.execute(inputArgs);
  }

  private int fixRoute() {
    String[] inputArgs;
    inputArgs = new String[1];
    inputArgs[0] = "fixRoute";
    //inputArgs[1] = "-verbose";
    return dc.execute(inputArgs);
  }

  private int releaseRoute() {
    String[] inputArgs;
    inputArgs = new String[1];
    inputArgs[0] = "releaseRoute";
    //inputArgs[1] = "-verbose";
    return dc.execute(inputArgs);
  }



  private int probing() {
    easyWait(10000);
    ledOff();
    easyWait(10000);
    return 0;
  }
  
  private int stressTest() {
    releaseRoute();
    easyWait(1000);
    eraseFlash();
    
    for (int i = 0; i < 6; i++) {
      probing();
    }
    for (int i = 1; i <= 6; i++) {
      if (networkInfo(i) != 0) {
        easyWait(10000);
      }
      easyWait(1000);
    }
    easyWait(120000);
    fixRoute();

    easyWait(60000);
    startSensing();
    easyWait(1000);
/*    for (int i = 1; i <= 6; i++) {
      readData(i);
      easyWait(1000);
    }

    releaseRoute();
*/
    return 0;
  }

  private int batteryTest() {
    for (int i = 14; i <= 15; i++) {
      if (networkInfo(i) != 0) {
        easyWait(10000);
      }
      easyWait(1000);
    }

    return 0;
  }

  public int drive(String[] args) {
    for (int i = 0; i < 1; i++) {
//      System.out.println("################  run " + i);
//      Date currentDate = new Date();
//      System.out.println(currentDate);
      stressTest();
//      batteryTest();
    }

    return 0;
  }

  public static void main(String[] args) {
    DriveTest dt = new DriveTest();
    System.exit(dt.drive(args));
  }

}

