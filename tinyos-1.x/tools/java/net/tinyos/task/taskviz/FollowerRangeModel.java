/*
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
package net.tinyos.task.taskviz;

/*
 * 1.1+Swing version.
 */

import javax.swing.*;
import javax.swing.event.*;

public class FollowerRangeModel extends DefaultBoundedRangeModel implements javax.swing.event.ChangeListener {
  DefaultBoundedRangeModel dataModel;
  TASKConfiguration config;

  public FollowerRangeModel(DefaultBoundedRangeModel dataModel, TASKConfiguration config) {
    this.dataModel = dataModel;
    this.config = config;
    dataModel.addChangeListener(this);
  }

  public void stateChanged(ChangeEvent e) {
    fireStateChanged();
  }

  public void setValue(int newValue) {
    int x = config.getTimeToLive((int)newValue);
    dataModel.setValue(x);
//    dataModel.setValue(newValue / 2); // * multiplier / dataModel.getMultiplier());
  }

  public int getValue() {
//	int x = config.getSamplePeriod(dataModel.getValue());
//	return x;

	int x = super.getValue();
System.out.println("sp: "+x+", ttl: "+dataModel.getValue());
	int v = config.getTimeToLive(x);
System.out.println("new ttl: "+(v+1));
	if ((v+1) != dataModel.getValue()) {
      x = config.getSamplePeriod((dataModel.getValue()));
//      System.out.println("getting "+x);
      super.setValue(x);
	}
System.out.println("new sp: "+	x);
    return x;
//    return dataModel.getValue()* 2; // dataModel.getMultiplier() / multiplier;
  }
}
