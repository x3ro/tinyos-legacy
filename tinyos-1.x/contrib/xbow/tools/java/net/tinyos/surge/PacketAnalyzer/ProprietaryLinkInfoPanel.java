// $Id: ProprietaryLinkInfoPanel.java,v 1.3 2004/02/24 23:41:39 jlhill Exp $

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
 * @author Wei Hong
 */

package net.tinyos.surge.PacketAnalyzer;

import net.tinyos.surge.*;
import net.tinyos.surge.event.*;
import net.tinyos.message.*;
import net.tinyos.surge.util.*;
import java.util.*;
import java.lang.*;
import java.text.*;
import javax.swing.*;
import net.tinyos.surge.Dialog.*;
import java.awt.*;


public class ProprietaryLinkInfoPanel extends net.tinyos.surge.Dialog.ActivePanel
    {
	NodeInfo nodeInfo;

	public ProprietaryLinkInfoPanel(NodeInfo pNodeInfo)
	{
	    nodeInfo = pNodeInfo;
	    nodeInfo.link_panel = this;
	    tabTitle = "Link Information";
	    JPanel pan = new JPanel();
	    pan.setBounds(10, 0, 500, 105);
	    pan.setLayout(new GridLayout(7, 3));
	    pan.add(new JLabel("Souce Node ID: " + nodeInfo.nodeNumber));
	    pan.add(new JLabel(""));
	    pan.add(new JLabel(""));
	    pan.add(new JLabel("Node ID: "));
	    pan.add(new JLabel("Quality"));
	    pan.add(new JLabel("Hop Count"));
	    for(int i = 0; i < 5; i ++){
		pan.add(id[i] = new JLabel());
		pan.add(quality[i] = new JLabel());
		pan.add(hopcount[i] = new JLabel());
	    }
	    get_new_data();
	    add(pan);
	}

	public void panelClosing() {
	    System.err.println ("SensorAnalyzer: updating panel = null");
	    nodeInfo.SetPanel(null);
	}
      
	javax.swing.JLabel[] id = new javax.swing.JLabel[5];
	javax.swing.JLabel[] quality = new javax.swing.JLabel[5];
	javax.swing.JLabel[] hopcount = new javax.swing.JLabel[5];

	public void get_new_data()//this function will be called when the apply button is hit
	{
		for(int i = 0; i < 5; i ++){
			id[i].setText(nodeInfo.neighbors[i].id + "");
			quality[i].setText(nodeInfo.neighbors[i].link_quality/2.55 + "%");
			hopcount[i].setText(nodeInfo.neighbors[i].hopcount + "");
		}
	}

	public void InitializeDisplayValues()//this function will be called when the panel is first shown
	{
	}
    }


