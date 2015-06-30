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
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Oct 7 2003
 * Desc:        Main window for VM builder
 *
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.awt.*;
import java.awt.event.*;
import java.awt.font.*;
import java.io.*;
import java.net.*;
import java.util.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.event.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.script.tree.*;
import net.tinyos.util.*;


public class FunctionInfoPanel extends JPanel {
    private JLabel nameLabel;
    private JLabel name;
    private JLabel descLabel;
    private JTextArea description;
    
    public FunctionInfoPanel() {
	GridBagLayout layout = new GridBagLayout();
	GridBagConstraints gridConsts = new GridBagConstraints();
	gridConsts.fill = GridBagConstraints.BOTH;
	gridConsts.anchor = GridBagConstraints.NORTHWEST;	

	nameLabel = new JLabel("Name: ");
	nameLabel.setFont(TinyLook.boldFont());
	gridConsts.gridwidth = GridBagConstraints.RELATIVE;
	layout.setConstraints(nameLabel, gridConsts);

	name = new JLabel("");
	name.setFont(TinyLook.defaultFont());
	gridConsts.gridwidth = GridBagConstraints.REMAINDER;
	gridConsts.weightx = 1.0;
	layout.setConstraints(name, gridConsts);
	    
	descLabel = new JLabel("Description");
	descLabel.setFont(TinyLook.boldFont());
	gridConsts.weightx = 0.0;
	gridConsts.anchor = GridBagConstraints.CENTER;
	gridConsts.gridwidth = GridBagConstraints.REMAINDER;
	layout.setConstraints(descLabel, gridConsts);
	
	description = new JTextArea();
	description.setRows(6);
	description.setEditable(false);
	description.setLineWrap(true);
	description.setWrapStyleWord(true);
	description.setFont(TinyLook.defaultFont());
	gridConsts.weightx = 1.0;
	gridConsts.weighty = 1.0;
	gridConsts.anchor = GridBagConstraints.NORTHWEST;
	layout.setConstraints(description, gridConsts);

	setLayout(layout);	    
	add(nameLabel);
	add(name);
	add(descLabel);
	add(description);
    }

    public void setFunction(Function f) {
	if (f == null) {
	    name.setText("");
	    description.setText("");
	}
	else {
	    name.setText((String)f.get("name"));
	    description.setText((String)f.get("desc"));
	}
    }
}


