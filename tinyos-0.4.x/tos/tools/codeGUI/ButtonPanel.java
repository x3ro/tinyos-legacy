/*									tab:2
 *
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
 * Authors:		Phil Levis
 *
 *
 */

package codeGUI;

import java.awt.*;
import java.awt.event.*;
import java.io.*;

import javax.swing.*;

public class ButtonPanel extends JPanel {
    private MotePanel motes;
    private LogPanel log;
    private CodeInjector injector;
    
    private JButton queryButton;
    private JButton uploadButton;
    private JButton checkButton;
    private JButton startButton;
    private JButton fileButton;
    private JButton newButton;
    private JButton onButton;
    private JButton offButton;
    
    public ButtonPanel(MotePanel motes, LogPanel log, CodeInjector injector) {
		super();
		
		this.motes = motes;
		this.log = log;
		this.injector = injector;
		
		BoxLayout box = new BoxLayout(this, BoxLayout.X_AXIS);
		
		queryButton = new JButton("Query");
		uploadButton = new JButton("Upload");
		checkButton = new JButton("Check");
		startButton = new JButton("Start");
		newButton = new JButton("New");
		fileButton = new JButton("File");
		onButton = new JButton("On");
		offButton = new JButton("Off");
		
		queryButton.addActionListener(new QueryListener(motes));
		fileButton.addActionListener(new FileListener(motes));
		startButton.addActionListener(new StartListener(motes, injector));
		newButton.addActionListener(new ClearListener(motes, injector));
		checkButton.addActionListener(new CheckListener(motes, injector));
		uploadButton.addActionListener(new UploadListener(motes, injector));

		onButton.addActionListener(new OnListener(motes, injector));
		offButton.addActionListener(new OffListener(motes, injector));
		
		this.add(queryButton);
		this.add(uploadButton);
		this.add(checkButton);
		this.add(startButton);
		this.add(fileButton);
		this.add(newButton);
		this.add(onButton);
		this.add(offButton);
	
		this.setVisible(true);
		
		Font f = getFont();
		setFont(f.deriveFont((float)6.0));
    }
	
    public short getSelectedMote() {
		short id = motes.getSelectedMote();
		System.out.println(id);
		return id;
    }

    public CodeInjector getInjector() {
		return injector;
    }
	
    public class UploadListener implements ActionListener {
		private MotePanel motes;
		private CodeInjector injector;
		
		public UploadListener(MotePanel motes, CodeInjector injector) {
			this.motes = motes;
			this.injector = injector;
		}
		
		public void actionPerformed(ActionEvent e) {
			File file = motes.getSelectedFile();
			short id = motes.getSelectedMote();

			System.out.println("Uploading... to mote " + (int)(id & 0xff));
			
			if (file != null) {
				injector.readCode(file.getAbsolutePath());
				
				try {injector.download(id);}
				catch (IOException exception) {
					System.err.println(exception);
				}
			}
		}
    }
    
    public class QueryListener implements ActionListener {
		private MotePanel motes;
		
		public QueryListener(MotePanel motes) {
			this.motes = motes;
		}
		
		public void actionPerformed(ActionEvent e) {
			short id = motes.getSelectedMote();
			System.out.println("Querying mote " + (int)(id & 0xffff));
			try {
				injector.id(id);
			}
			catch (IOException exception) {
				System.err.println(exception);
			}
		}
    }
	
    public class FileListener implements ActionListener {
		private MotePanel motes;
		private JFileChooser chooser;
		
		public FileListener(MotePanel motes) {
			this.motes = motes;
			
			chooser = new JFileChooser();
			TOSFileFilter filter = new TOSFileFilter();
			filter.addExtension("srec");
			filter.setDescription("TOS images");
			chooser.setFileFilter(filter);
		}
	
		public void actionPerformed(ActionEvent e) {
			int returnVal = chooser.showOpenDialog(motes);
			if (returnVal == JFileChooser.APPROVE_OPTION) {
				File file = chooser.getSelectedFile();
				System.err.println(file);
				motes.addFile(file);
			}
		}
    }

    public class ClearListener implements ActionListener {
		private MotePanel motes;
		private CodeInjector injector;
		
		public ClearListener(MotePanel motes, CodeInjector injector) {
			this.motes = motes;
			this.injector = injector;
		}
		
		public void actionPerformed(ActionEvent e) {
			try {
				injector.newProgram(motes.getSelectedMote());
			}
			catch (IOException exception) {
				System.err.println(exception);
			}
		}
	}
	
    public class CheckListener implements ActionListener {
		private MotePanel motes;
		private CodeInjector injector;

		public CheckListener(MotePanel motes, CodeInjector injector) {
			this.motes = motes;
			this.injector = injector;
		}
		
		public void actionPerformed(ActionEvent e) {
			try {
				injector.check(motes.getSelectedMote());
			}
			catch (IOException exception) {
				System.err.println(exception);
			}
		}
    }

    public class StartListener implements ActionListener {
	private MotePanel motes;
	private CodeInjector injector;
	
	public StartListener(MotePanel motes, CodeInjector injector) {
	    this.motes = motes;
	    this.injector = injector;
	}
	
	public void actionPerformed(ActionEvent e) {
	    try {
		injector.startProgram(motes.getSelectedMote());
	    }
	    catch (IOException exception) {
		System.err.println(exception);
	    }
	}
    }

    public class OnListener implements ActionListener {
	private MotePanel motes;
	private CodeInjector injector;
	
	public OnListener(MotePanel motes, CodeInjector injector) {
	    this.motes = motes;
	    this.injector = injector;
	}
	
	public void actionPerformed(ActionEvent e) {
	    try {
		injector.turnOn(motes.getSelectedMote());
	    }
	    catch (IOException exception) {
		System.err.println(exception);
	    }
	}
    }

    public class OffListener implements ActionListener {
	private MotePanel motes;
	private CodeInjector injector;
	
	public OffListener(MotePanel motes, CodeInjector injector) {
	    this.motes = motes;
	    this.injector = injector;
	}
	
	public void actionPerformed(ActionEvent e) {
	    try {
		injector.turnOff(motes.getSelectedMote());
	    }
	    catch (IOException exception) {
		System.err.println(exception);
	    }
	}
    }
}

