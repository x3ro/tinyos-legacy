/* "Copyright (c) 2001 and The Regents of the University
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
* Authors:   Kamin Whitehouse <kamin@cs.berkeley.edu>
* History:   created 7/22/2001
*/

//*********************************************************
//*********************************************************
//The code in this class has never been tested or run.
//This class is a base class for HistoryRecievers in general.
//It has two main roles
//1.  Listen to some other recievers, hear their packets and store them
//2.  Replay the store of packets that has been heard
//The serialize class should allow us to save and replay a series of
//Packets at a later date.  This is useful so that we don't actually
//have to re-run experiments over and over again, and also so we can
//test the same exact data with different algorithms for comparison.
//This class can either be subclassed into things like a
//SerialPortHistoryPacketReciever or one can put a menu item up
//to let people register it and de-register it with different
//packet recievers.
//*********************************************************
//*********************************************************

package net.tinyos.moteview.PacketRecievers;

import net.tinyos.moteview.*;
import net.tinyos.moteview.event.*;
import net.tinyos.moteview.util.*;
import java.util.*;
import javax.swing.*;
import java.awt.event.*;
import java.awt.*;
import java.io.*;
import java.util.zip.*;

              //this class listens to all packets and stores them when asked
              //it also plays the history back when asked, possible at the same
              //time as it is recording the history
              //The menu manager could be adjusted to look at the list of
              //packet recievers and make a CheckBoxMenuItem for each one,
              //allowing us to choose which packets we want to store
              //(we could then instantiate multiple history recievers)
public class HistoryPacketReciever extends net.tinyos.moteview.PacketRecievers.PacketReciever implements PacketEventListener
{
	protected Vector history;//a list of all the packets recieved
	protected Date recordingStartTime;//the time the HistoryReciever starting listening and storing a history
	protected Thread thread;
	protected MenuManager menuManager;

	public HistoryPacketReciever()
	{
		     //register to contribute a panel to the SurgeOptions panel
        MainClass.AddOptionsPanelContributor(this);

		history = new Vector();//define a vector to hold all the packets events I hears
		menuManager = new MenuManager();
	}

	public void PacketRecieved(PacketEvent e)
	{
		e.SetRecordingTime(recordingStartTime);
		history.add(e);
	}

			  //------------------------------------------------------------------------
		      //RUN
		      //this is the function that is run in the background as a thread
		      //IT basically hears all packets and stores them in a history
	public void run()
	{
		Date replayStartTime = Calendar.getInstance().getTime();//the time the history started playing again
		Date currentTime, packetTime, recordingTime;
		PacketEvent event;
		Vector tempHistory = (Vector)history.clone();
		try
		{
			while(true)
			{
				currentTime = Calendar.getInstance().getTime();
				for(Enumeration e = tempHistory.elements(); e.hasMoreElements();)
				{
					  event =  (PacketEvent)e.nextElement();
					  packetTime = event.GetTime();
					  recordingTime = event.GetRecordingTime();
					  if( (packetTime.getTime()-recordingTime.getTime()) < (currentTime.getTime()-replayStartTime.getTime()))
					  {
						TriggerPacketEvent(new PacketEvent(this, event.GetPacket(), currentTime));
						System.out.println(Hex.toHex(event.GetPacket().GetData()));
						tempHistory.removeElement(event);
						break;
					  }
				}
				if(tempHistory.size() == 0)
				{
					break;
				}
				sleep(100);
			}
			menuManager.historyReplayingCheckBox.setSelected(false);
		}
		catch(Exception e){e.printStackTrace();}
	}
		      //RUN
			  //------------------------------------------------------------------------

              //------------------------------------------------------------------------
	          //*****---Thread commands---******//
	          //you might want to add these thread commands
    public void start(){ try{ thread=new Thread(this);thread.start();} catch(Exception e){e.printStackTrace();}}
    public void stop(){ try{ thread.stop();} catch(Exception e){e.printStackTrace();}}
    public void sleep(long p){ try{ thread.sleep(p);} catch(Exception e){e.printStackTrace();}}
    public void setPriority(int p) { try{thread.setPriority(p);} catch(Exception e){e.printStackTrace();}}
			//*****---Thread commands---******//
              //------------------------------------------------------------------------



	        //*********************************************************
	        //*********************************************************
	        //*********************************************************
              //MENU MANAGER
              //This class creates and holds the menu that controls this
              //PacketAnalyzer.  It returns the menu to whoever wants
              //to display it and it also handles all events on the menu
	protected class MenuManager implements /*Serializable,*/ ActionListener, ItemListener
	{
			//{{DECLARE_CONTROLS
		JMenu mainMenu = new JMenu();
		JCheckBoxMenuItem historyGatheringCheckBox = new JCheckBoxMenuItem();
		public JCheckBoxMenuItem historyReplayingCheckBox = new JCheckBoxMenuItem();
		JSeparator separator1 = new JSeparator();
		JMenuItem propertiesItem = new JMenuItem();
		JSeparator separator2 = new JSeparator();
		JMenuItem clearHistoryItem = new JMenuItem();
		JSeparator separator3 = new JSeparator();
		JMenu serializeMenu = new JMenu();
		JMenuItem saveHistoryItem = new JMenuItem();
		JMenuItem loadHistoryItem = new JMenuItem();
		//}}

		public MenuManager()
		{
			//{{INIT_CONTROLS
			mainMenu.setText("Packet History");
			mainMenu.setActionCommand("Packet History");
			historyGatheringCheckBox.setSelected(false);
			historyGatheringCheckBox.setText("Gather History");
			historyGatheringCheckBox.setActionCommand("Gather History");
			mainMenu.add(historyGatheringCheckBox);
			historyReplayingCheckBox.setSelected(false);
			historyReplayingCheckBox.setText("Replay History");
			historyReplayingCheckBox.setActionCommand("Replay History");
			mainMenu.add(historyReplayingCheckBox);
			mainMenu.add(separator1);
			propertiesItem.setText("Options");
			propertiesItem.setActionCommand("Options");
			mainMenu.add(propertiesItem);
			mainMenu.add(separator2);
			clearHistoryItem.setText("Clear History");
			clearHistoryItem.setActionCommand("Clear History");
			mainMenu.add(clearHistoryItem);
			mainMenu.add(separator3);
			serializeMenu.setText("Serialize");
			serializeMenu.setActionCommand("Serialize");
			saveHistoryItem.setText("Save History");
			saveHistoryItem.setActionCommand("Save History");
			serializeMenu.add(saveHistoryItem);
			loadHistoryItem.setText("Load History");
			loadHistoryItem.setActionCommand("Load History");
			serializeMenu.add(loadHistoryItem);
			mainMenu.add(serializeMenu);
			MainClass.mainFrame.PacketReadersMenu.add(mainMenu);//this last command adds this entire menu to the main PacketAnalyzers menu
			//}}

			//{{REGISTER_LISTENERS
			historyGatheringCheckBox.addItemListener(this);
			historyReplayingCheckBox.addItemListener(this);
			propertiesItem.addActionListener(this);
			clearHistoryItem.addActionListener(this);
			saveHistoryItem.addActionListener(this);
			loadHistoryItem.addActionListener(this);
			//}}
		}

		      //----------------------------------------------------------------------
		      //EVENT HANDLERS
		      //The following two functions handle menu events
		      //The functions following this are the event handling functions
		public void actionPerformed(ActionEvent e)
		{
			Object object = e.getSource();
			if (object == saveHistoryItem)
				SaveHistory();
			else if (object == loadHistoryItem)
				LoadHistory();
//			else if (object == propertiesItem)
//				ShowOptionsDialog();
			else if (object == clearHistoryItem)
				history.removeAllElements();
		}

		public void itemStateChanged(ItemEvent e)
		{
			Object object = e.getSource();
			if (object == historyGatheringCheckBox)
				ToggleHistoryGathering();
			else if (object == historyReplayingCheckBox)
				ToggleHistoryReplaying();
		}
		      //EVENT HANDLERS
		      //----------------------------------------------------------------------

	        	//------------------------------------------------------------------------
	        	//****---SAVE HISTORY---****
	        	//takes the node hashtable and saves it to a file
		public void SaveHistory()
		{
			FileDialog dialog = new FileDialog(MainClass.mainFrame, "Save History", FileDialog.SAVE);
			dialog.show();
			String filename = dialog.getFile();
			if( (filename != null) && (history!=null))
			{
				try
				{
					FileOutputStream fos = new FileOutputStream(filename);
					GZIPOutputStream gos = new GZIPOutputStream(fos);
					ObjectOutputStream out = new ObjectOutputStream(gos);
					out.writeObject(history);
					out.flush();
					out.close();
				}
				catch(Exception e){e.printStackTrace();}
			}
		}
	        	//****---SAVE HISTORY---****
	        	//------------------------------------------------------------------------


	        	//------------------------------------------------------------------------
	        	//****---LOAD HISTORY---****
	        	//takes a file and loads the nodes into proprietaryNodeInfo hashtable
		public void LoadHistory()
		{        //in the future, it should prompt the user for which node should be kept
			FileDialog dialog = new FileDialog(MainClass.mainFrame, "Load History", FileDialog.LOAD);
			dialog.show();
			String filename = dialog.getFile();
			if(filename != null)
			{
				Vector newEvents;
				try
				{
					FileInputStream fis = new FileInputStream(filename);
					GZIPInputStream gis = new GZIPInputStream(fis);
					ObjectInputStream in = new ObjectInputStream(gis);
					newEvents = (Vector)in.readObject();
					in.close();
				}
				catch(Exception e){e.printStackTrace(); return;}

				if((history == null) || (history.isEmpty()))//if there are no nodes yet, just assign the new nodes to the entire vector
				{
					history = newEvents;
				}
				else//otherwise take the new nodes and add them to the vector (first eliminating repeat nodes)  ...in the future, we should ask the user which node to keep, in the case of repeat nodes
				{
					for(Enumeration e = newEvents.elements();e.hasMoreElements();)
					{
						history.add(e.nextElement());
					}
				}
			}
		}
	        	//****---LOAD HISTORY---****
	        	//------------------------------------------------------------------------


		      //------------------------------------------------------------------------
		      //****---TOGGLE HISTORY GATHERING
		      //This function will either register or de-register this PacketAnalyzer
		      //as a PacketEventListener.
		public void ToggleHistoryGathering()
		{
			if(historyGatheringCheckBox.isSelected())
			{ //Note:  the following syntax "PacketAnalyzerTemplate.this" allows an inner class to refer to its enclosing class
				recordingStartTime = Calendar.getInstance().getTime();
				MainClass.AddPacketEventListener(HistoryPacketReciever.this);//start the background thread of the enclosing packetAnalyzer
			}
			else
			{
				MainClass.RemovePacketEventListener(HistoryPacketReciever.this);//start the background thread of the enclosing packetAnalyzer
			}
		}
		      //****---TOGGLE HISTORY GATHERING
		      //------------------------------------------------------------------------

		      //------------------------------------------------------------------------
		      //****---TOGGLE HISTORY REPLAYING
		public void ToggleHistoryReplaying()
		{
			if(historyReplayingCheckBox.isSelected())
			{
				start();
			}
			else
			{
				stop();//stop the background thread of the enclosing packetAnalyzer
			}
		}
		      //****---TOGGLE BACKGROUND PROCESSING
		      //------------------------------------------------------------------------



	}
              //MENU MANAGER
	        //*********************************************************
	        //*********************************************************
	        //*********************************************************

}