// $Id: DisplayPropertiesPanel.java,v 1.1 2003/11/05 22:35:11 jlhill Exp $

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


    public class DisplayPropertiesPanel extends net.tinyos.surge.Dialog.ActivePanel
    {
	SensorAnalyzer analyzer;

	public DisplayPropertiesPanel(SensorAnalyzer pAnalyzer)
	{
	    analyzer = pAnalyzer;
	    tabTitle = "Light";//this will be the title of the tab
	    setLayout(null);
	    //			Insets ins = getInsets();
	    setSize(307,168);
	    JLabel3.setToolTipText("This text will appear with mouse hover over this component");
	    JLabel3.setText("Variable Name:");
	    add(JLabel3);
	    JLabel3.setBounds(12,36,108,24);
	    JLabel4.setToolTipText("This is the value of Variable Name");
	    JLabel4.setText("text");
	    add(JLabel4);
	    JLabel4.setBounds(12,60,108,24);
	}

	javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel4 = new javax.swing.JLabel();

	public void ApplyChanges()//this function will be called when the apply button is hit
	{
	    //			analyzer.SetVariableName(Integer.getInteger(JLabel4.getText()).intValue());
	}

	public void InitializeDisplayValues()//this function will be called when the panel is first shown
	{
	    //			JLabel4.setText(String.valueOf(analyzer.GetVariableName()));
	}
    }	          

