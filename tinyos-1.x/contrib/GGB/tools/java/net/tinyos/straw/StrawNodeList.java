// $Id: StrawNodeList.java,v 1.1 2006/12/01 05:34:56 binetude Exp $

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
 * File: StrawNodeList.java
 *
 * @author <a href="mailto:binetude@cs.berkeley.edu">Sukun Kim</a>
 */

package net.tinyos.straw;

import java.io.*;
//import net.tinyos.util.*;
//import net.tinyos.message.*;

class StrawNodeList {

  String nm;
  //TreeSet nodeSet;
  static final int MAX_NO_OF_NODE = 100;
  int[] nodeNo = new int[MAX_NO_OF_NODE];
  boolean[] nodeVld = new boolean[MAX_NO_OF_NODE];
    { for (int i = 0; i < MAX_NO_OF_NODE; i++) {
      nodeNo[i] = 0;
      nodeVld[i] = false;
    } }
  short noOfNode = 0;

  StrawNodeList(String aNm) {
    nm = aNm;
  }

  void loadNodeList() {
    try {
      FileReader fr = new FileReader(nm);
      BufferedReader br = new BufferedReader(fr);
      noOfNode = Short.parseShort(br.readLine());
      for (int i = 0; i < noOfNode; i++) {
        nodeNo[i] = Integer.parseInt(br.readLine());
        nodeVld[i] = true;
      }
      br.close();
      fr.close();
    } catch (IOException e) {
      for (int i = 0; i < MAX_NO_OF_NODE; i++) {
        nodeNo[i] = 0;
        nodeVld[i] = false;
      }
      noOfNode = 0;
    }
  }
  void saveNodeList() {
    compactNodeList();
    try {
      FileOutputStream fos = new FileOutputStream(nm);
      PrintWriter pr = new PrintWriter(fos);
      pr.println("" + noOfNode);
      for (int i = 0; i < noOfNode; i++)
        pr.println("" + nodeNo[i]);
      pr.close();
      fos.close();
    } catch (IOException e) {
      System.out.println("EXCEPTION while storing node list" + e);
      e.printStackTrace();
    }
  }

  void compactNodeList() {
    short nodeIndex = 0;
    for (int i = 0; i < noOfNode; i++) {
      if (nodeVld[i]) {
        nodeNo[nodeIndex] = nodeNo[i];
        nodeVld[nodeIndex] = true;
        ++nodeIndex;
      }
    }
    noOfNode = nodeIndex;
    for (int i = noOfNode; i < MAX_NO_OF_NODE; i++) {
      nodeNo[i] = 0;
      nodeVld[i] = false;
    }
  }

  void dumpLodeList() {
    int nodeIndex = 0;
    System.out.println("****  NodeList - " + nm);
    for (int i = 0; i < noOfNode; i++)
      if (nodeVld[i]) ++nodeIndex;
    System.out.println("actual noOfNode = " + nodeIndex);
    System.out.println("noOfNode = " + noOfNode);
    for (int i = 0; i < noOfNode; i++)
      System.out.println("nodeNo[" + i + "] = " + nodeNo[i]
        + ", nodeVld[" + i + "] = " + nodeVld[i]);
  }

};
 
