// $Id: Counter.java,v 1.1 2006/12/01 00:57:00 binetude Exp $

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
 * File: Counter.java
 *
 * @author <a href="mailto:binetude@cs.berkeley.edu">Sukun Kim</a>
 */

package net.tinyos.sentri;

import java.io.*;

class Counter {

  private String nm;
  private int no;

  Counter(String aNm) {
    nm = aNm;
  }
  
  int get() {
    try {
      FileReader fr = new FileReader(nm);
      BufferedReader br = new BufferedReader(fr);

      no = Integer.parseInt(br.readLine());
      
      br.close();
      fr.close();
    } catch (IOException e) {
      no = 1;
    }
    return no;
  }
  
  int set(int newNo) {
    try {
      FileOutputStream fos = new FileOutputStream(nm);
      PrintWriter pr = new PrintWriter(fos);
 
      no = newNo;
      pr.println("" + no);
      
      pr.close();
      fos.close();
    } catch (IOException e) {
      System.out.println("Exception: Counter.set"
        + " - while storing number to " + nm);
      return 1;
    }
    return 0;
  }

  int incr() {
    ++no;
    return set(no);
  }

  int reset() {
    return set(1);
  }
  
};

