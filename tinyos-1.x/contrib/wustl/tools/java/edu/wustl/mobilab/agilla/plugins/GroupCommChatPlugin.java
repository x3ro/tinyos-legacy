package edu.wustl.mobilab.agilla.plugins;

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import edu.wustl.mobilab.agilla.*;
import edu.wustl.mobilab.agilla.variables.*;

import java.awt.event.*;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.*;

/**
 * A GUI displaying the messages exchanged with a particular agent.
 *
 * @author Chien-Liang Fok
 * @version 5/13/2003
 */
public class GroupCommChatPlugin extends Plugin
	implements java.io.Serializable, AgillaConstants {
	
	private String member_file
	= "C:\\Program Files\\cygwin\\opt\\tinyos-1.x\\contrib\\wustl\\apps\\AgillaAgents\\GroupComm\\chat\\Member.ma";
	
	public static final String FONT_NAMES[] = {
		"Arial", "Helvetica", "sans-serif",
			"Times New Roman", "Times", "serif",
			"Courier New", "Courier", "mono",
			"Georgia", "Verdana", "Geneva"
	};
	

	
	private AgentInjector injector;
	
	private Hashtable<AgillaAgentID, ChatGUI> memberGUITable = new Hashtable<AgillaAgentID, ChatGUI> ();
	
	/**
	 * The address of the mote that is attached to the base station.
	 */
	private int local_moteaddr = 0;
	
	/**
	 * Creates GroupCommChatPlugin with the default user name of
	 * "unk".
	 * 
	 * @param injector The AgentInjector.
	 */
	public GroupCommChatPlugin(AgentInjector injector) {
		this(injector, new String[]{"-name", "unk"});
	}
	
	/**
	 * Creates an Instant Messaging GUI.
	 *
	 * @param user the ChatUser running this instant messaging window.
	 * @param aID the destination agent's agent ID
	 */
	public GroupCommChatPlugin(AgentInjector injector, String[] args){
		String name = "unk";
		this.injector = injector;
		boolean injectMember = false;
		try {
			for (int i = 0; i < args.length; i++) {
				if (args[i].equals("-name")) {
					name = args[++i];
					if (name.length() > 3)
						throw new Exception("Invalid name, length must be 3.");
				}
				else if (args[i].equals("-member")) {
					this.member_file = args[++i];
				}
				else if (args[i].equals("-injectMember")) {
					injectMember = true;
				}
				else if (args[i].equals("-localAddr")){
					local_moteaddr = Integer.valueOf(args[++i]).intValue();
				}
				else throw new Exception("Unknown parameter: " + args[i]);
			}
		} catch(Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
		
		log("Registering reaction sensitive to chat messages...");
		Tuple chatMsgTemplate = new Tuple();
		chatMsgTemplate.addField(new AgillaString("lbm"));
		chatMsgTemplate.addField(new AgillaType(AGILLA_TYPE_AGENTID));
		chatMsgTemplate.addField(new AgillaType(AGILLA_TYPE_STRING));
		chatMsgTemplate.addField(new AgillaType(AGILLA_TYPE_STRING));
		
		Reaction chatMsgRxn = new Reaction(new AgillaAgentID(), 0, chatMsgTemplate);
		injector.getTS().registerReaction(chatMsgRxn, new ReactionListener() {
			public void reactionFired(Tuple t){
				AgillaAgentID aid = (AgillaAgentID)t.getField(1);
				AgillaString name = (AgillaString)t.getField(2);
				AgillaString msg = (AgillaString)t.getField(3);
				log("Reacted to a message!\n\tName: " + name + "\n\tMessage: " + msg);
				ChatGUI gui = memberGUITable.get(aid);
				if (gui != null) {
					gui.addText(name, msg);
				} else
					log("ERROR: received a member broadcast for an unknown member");
/*				if (name.toChars().equals(this.name))
					addMyText(msg.toChars());
				else
					addRecievedText(name.toChars(), msg.toChars());*/
			}
		});
		
//		try {
//			for (int i = 0; i < args.length; i++) {
//			
//				else throw new Exception("Unknown parameter: " + args[i]);
//			}
//		} catch(Exception e) {
//			e.printStackTrace();
//			System.exit(1);
//		}
		
		//log("member file = " + member_file);// read in the leader agent


		log("Registering reaction sensitive to create member chat GUI...");
		Tuple CreateGUITemplate = new Tuple();
		CreateGUITemplate.addField(new AgillaString("msc"));  // member start chatting
		CreateGUITemplate.addField(new AgillaType(AGILLA_TYPE_AGENTID));
		CreateGUITemplate.addField(new AgillaType(AGILLA_TYPE_STRING));
		
		Reaction CreateGUIRxn = new Reaction(new AgillaAgentID(), 0, CreateGUITemplate);
		injector.getTS().registerReaction(CreateGUIRxn, new ReactionListener() {
			public void reactionFired(Tuple t){
				AgillaAgentID agentID= (AgillaAgentID)t.getField(1);
				AgillaString screenName = (AgillaString)t.getField(2);
				
				log("Reacted to a create GUI message!\n\t Screen Name: " + screenName + "\n\t Agent ID: " + agentID);
				if(memberGUITable.containsKey(agentID))	
					log("Duplicate request, ignoring...");
				else {
					ChatGUI gui = new ChatGUI(agentID, screenName);
					memberGUITable.put(agentID, gui);
				}
			}
		});
		
		log("Registering reaction sensitive to dispose chat GUI...");
		Tuple killGUITemplate = new Tuple();
		killGUITemplate.addField(new AgillaString("msc"));  // member start chatting
		killGUITemplate.addField(new AgillaType(AGILLA_TYPE_AGENTID));
		Reaction killGUIreaction = new Reaction(new AgillaAgentID(), 0, killGUITemplate);
		injector.getTS().registerReaction(killGUIreaction, new ReactionListener() {
			public void reactionFired(Tuple t){
				AgillaAgentID agentID= (AgillaAgentID)t.getField(1);
				
				log("Reacted to a kill GUI message!\n\t Agent ID: " + agentID);
				if(memberGUITable.containsKey(agentID))	{
					//memberGUITable.get(agentID).close();
					memberGUITable.remove(agentID).close();
				} else
					log("ERROR: Request to kill non-existant gui, ignoring...");
			}
		});
		
		if (injectMember) {
			String memberString = "";
			try {
				File f = new File(member_file);
				BufferedReader reader = new BufferedReader(new FileReader(f));
				String nxtLine = reader.readLine();
				while (nxtLine != null) {
					memberString += nxtLine + "\n";
					nxtLine = reader.readLine();
				}
			} catch(Exception e) {
				e.printStackTrace();
				System.exit(1);
			}
			Agent member = new Agent (memberString);
			member.setHeap(0, new AgillaString(name));
			injector.inject(member, 0);
		}
		/*
		 * Modify code to inject member code to the attached mote
		 * need to find out the local address of the mote
		 * */
		
//		frame = new JFrame();
//		frame.setTitle("Chat - " + name);
//		
//		initGUI();
	}
	
//	public void reactionFired(Tuple t) {				
//
//	}
	
	/*public void agentArrived(){
		inTextString += "<i><font color=\"green\">[" +
			aID.getName() + " has re-engaged]</font></i><br>";
		setInText();
		otherPersonHere = true;
	}
	
	public void agentLeft(){
		inTextString += "<i><font color=\"green\">[" +
			aID.getName() + " has disengaged]</font></i><br>";
		setInText();
		otherPersonHere = false;
	}*/
	
//	/**
//	 * Returns true if the provided object is of type InstantMessagingGUI
//	 * and contains the same AgentID as this one.
//	 */
//	public boolean equals(Object o){
//		if (o instanceof GroupCommChatPlugin)
//			return ((GroupCommChatPlugin)o).getName().equals(name);
//		return false;
//	}
	
//	public String getName() {
//		return name;
//	}
	

	
	
	
	
	
	private void log(String str){
		System.out.println("GroupCommChatPlugin: " + str);
	}
	
	/**
	 * Implements the Plugin interface.
	 */
	public void reset() {
		
	}
	

	
	private class ChatGUI implements ActionListener
	{
		AgillaString sname; 
		AgillaAgentID aid;
		
		private JFrame frame;
		
		private JEditorPane inText, outText;
		private JScrollPane inTextScroller, outTextScroller;
		
		//private JButton send;
		private String	font;
		private String	fontSize;
		private String	inTextString = "";	
		
		public ChatGUI(AgillaAgentID aid, AgillaString sname)
		{
			this.sname=sname;
			this.aid=aid;
			
			frame = new JFrame();
			frame.setTitle("Chat - " + sname.toChars());
			initGUI();
		}
		
		private void initGUI(){
			frame.getContentPane().setLayout(new BorderLayout());
			
			inText = new JEditorPane();
			inText.setContentType("text/html");
			inText.setEditable(false);
			inTextScroller = new JScrollPane(inText);
			inTextScroller.setPreferredSize(new Dimension(320, 200));
			
			JPanel incommingMessages = new JPanel(new BorderLayout());
			incommingMessages.add("Center",inTextScroller);
			incommingMessages.add("North",new JLabel("Incomming Messages:"));
			
			outText = new JEditorPane();
			outText.setEditable(true);
			outTextScroller = new JScrollPane(outText);
			outTextScroller.setPreferredSize(new Dimension(320, 110));
			
			JPanel outgoingMessages = new JPanel(new BorderLayout());
			outgoingMessages.add("Center",outTextScroller);
			outgoingMessages.add("North",new JLabel("Outgoing Messages:"));
			
			JButton send = new JButton("Send");
			send.setActionCommand("Send Message");
			send.addActionListener(this);
			
			JButton move = new JButton("Move");
			move.setActionCommand("Move");
			move.addActionListener(this);
			
			JPanel buttonPanel = new JPanel();
			buttonPanel.setLayout(new FlowLayout(FlowLayout.RIGHT));
			buttonPanel.add(move);
			buttonPanel.add(send);
			
			// add Text listener to the input text field,
			// to send text when the enter key is hit
			outText.addKeyListener(new KeyListener(){
						public void keyPressed(KeyEvent e) {}
						
						public void keyReleased(KeyEvent e) {}
						
						public void keyTyped(KeyEvent e){
							if (e.getKeyChar() == KeyEvent.VK_ENTER){
								actionPerformed(new ActionEvent(this, 0, "Send Message"));
							}
						}
					});
			
			JSplitPane ioSplitPane = new JSplitPane(JSplitPane.VERTICAL_SPLIT,
													incommingMessages,outgoingMessages);
			ioSplitPane.setResizeWeight(0.75);
			
			frame.getContentPane().add("Center",ioSplitPane);
			frame.getContentPane().add("South",buttonPanel);
			createDropMenu();
			
			frame.setDefaultCloseOperation(WindowConstants.DISPOSE_ON_CLOSE);
			
			frame.pack();
			
			Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
			Dimension frameSize = frame.getSize();
			if (frameSize.height > screenSize.height)
				frameSize.height = screenSize.height;
			if (frameSize.width > screenSize.width)
				frameSize.width = screenSize.width;
			
			frame.setLocation((screenSize.width - frameSize.width) / 2, (screenSize.height - frameSize.height) / 2);
			
			//frame.show();
			frame.setVisible(true);
		}
		
		private void createDropMenu(){
			JMenuBar menuBar = new JMenuBar();
			frame.setJMenuBar(menuBar);
			
			// File menu
			JMenu fileMenu = new JMenu("File");
			fileMenu.setMnemonic(KeyEvent.VK_F);
			menuBar.add(fileMenu);
			
			JMenuItem closeMI = new JMenuItem("Exit", KeyEvent.VK_X);
			closeMI.setAccelerator(KeyStroke.getKeyStroke(
									   KeyEvent.VK_X,ActionEvent.CTRL_MASK));
			closeMI.addActionListener(this);
			closeMI.setActionCommand("Close");
			fileMenu.add(closeMI);
			
			// Options menu
			JMenu optionMenu = new JMenu("Options");
			optionMenu.setMnemonic(KeyEvent.VK_O);
			
			// add the font submenu
			JMenu fontMenu = new JMenu("Font");
			fontMenu.setMnemonic(KeyEvent.VK_F);
			
			ButtonGroup fontRadioGroup = new ButtonGroup();
			
			for (int i = 0; i < FONT_NAMES.length; i++){
				final String fontName = FONT_NAMES[i];
				
				JMenuItem fontMenuItem;
				if (fontName.equals("Arial"))
					fontMenuItem = new JRadioButtonMenuItem(fontName, true);
				else
					fontMenuItem = new JRadioButtonMenuItem(fontName, false);
				
				fontMenuItem.addActionListener(new ActionListener(){
							public void actionPerformed(ActionEvent ae){
								setFont(fontName);
							}
						});
				
				fontRadioGroup.add(fontMenuItem);
				fontMenu.add(fontMenuItem);
			}
			
			optionMenu.add(fontMenu);
			
			// add the font size submenu
			JMenu fontSizeMenu = new JMenu("Font Size");
			fontSizeMenu.setMnemonic(KeyEvent.VK_S);
			
			ButtonGroup fontSizeRadioGroup = new ButtonGroup();
			for (int i = -3; i <= 3; i++){
				final String value = String.valueOf(i);
				
				JMenuItem fontSizeMenuItem;
				if (i == 0)
					fontSizeMenuItem = new JRadioButtonMenuItem(value, true);
				else
					if (i > 0)
						fontSizeMenuItem = new JRadioButtonMenuItem("+" + value, false);
					else
						fontSizeMenuItem = new JRadioButtonMenuItem(value, false);
				
				fontSizeMenuItem.addActionListener(new ActionListener(){
							public void actionPerformed(ActionEvent ae){
								String fontSize;
								if (Integer.valueOf(value).intValue() >= 0)
									fontSize = "+" + value;
								else
									fontSize = value;
								setFontSize(fontSize);
							}
						});
				
				fontSizeRadioGroup.add(fontSizeMenuItem);
				fontSizeMenu.add(fontSizeMenuItem);
			}
			
			optionMenu.add(fontSizeMenu);
			
			optionMenu.addSeparator();
			
//			JMenuItem sendAgentIDMI = new JMenuItem("Send AgentID", KeyEvent.VK_A);
//			sendAgentIDMI.setAccelerator(KeyStroke.getKeyStroke(
//											 KeyEvent.VK_S,
//											 ActionEvent.ALT_MASK));
//			sendAgentIDMI.addActionListener(this);
//			sendAgentIDMI.setActionCommand("Send AgentID");
//			optionMenu.add(sendAgentIDMI);
			
			JMenuItem clearMessagesMI = new JMenuItem("Clear Incomming Messages",
													  KeyEvent.VK_C);
			clearMessagesMI.addActionListener(this);
			clearMessagesMI.setActionCommand("Clear Messages");
			optionMenu.add(clearMessagesMI);
			
			menuBar.add(optionMenu);
			
			// Help menu
			/*
			 JMenu helpMenu = new JMenu("Help");
			 helpMenu.setMnemonic(KeyEvent.VK_H);
			 
			 JMenuItem helpMenuItem = new JMenuItem("About Instant Messaging", KeyEvent.VK_A);
			 helpMenuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_A, ActionEvent.ALT_MASK));
			 helpMenuItem.addActionListener(this);
			 helpMenuItem.setActionCommand("Display About");
			 helpMenu.add(helpMenuItem);
			 
			 
			 menuBar.add(helpMenu);
			 */
		}
		
		private void setInText(){
			inText.setText("<font face=\"" + font + "\" size=\"" + fontSize + "\">" + inTextString + "</font>");
			JScrollBar scrollBar = inTextScroller.getVerticalScrollBar();
			scrollBar.setValue(scrollBar.getMaximum());
		}
		
		public void addText(AgillaString userName, AgillaString text) {
			if (userName.equals(sname))
				addMyText(text.toChars());
			else
				addReceivedText(userName.toChars(), text.toChars());
		}
		
		private void addReceivedText(String userName, String text) {		
			inTextString += "<b><font color=\"red\">" + userName + ":</font></b> " + text + "<br>";
			setInText();
		}
		
		private void addMyText(String text) {
			inTextString += "<b><font color=\"blue\">" + sname.toChars() + ":</font></b> "+ text + "<br>";
			setInText();
		}
		
		private void setFont(String font){
			this.font = font;
			setInText();
		}
		
		private void setFontSize(String size){
			this.fontSize = size;
			setInText();
		}
		
		private void clearMessages(){
			int answer = JOptionPane.showConfirmDialog(
				null,
				"Are you sure you want to clear the icomming messages?",
				"Confirmation",
				JOptionPane.YES_NO_OPTION,
				JOptionPane.QUESTION_MESSAGE);
			if (answer == JOptionPane.YES_OPTION){
				inTextString = "";
				inText.setText(inTextString);
			}
		}
		
		public void refreshGUI(){
			SwingUtilities.updateComponentTreeUI(frame);
			frame.pack();
		}
		
		public void actionPerformed(ActionEvent ae){
			if(ae.getActionCommand().equals("Send Message")){
				if (outText.getText() != null && !outText.getText().equals("\n") && !outText.getText().equals("")) {
					String outMessage = outText.getText();
					
					// remove trailing newlines
					if (outMessage.endsWith("\n")) {
						outMessage = outMessage.substring(0,outMessage.length()-2);
					}
					if (outMessage.length() > 3) {
						 JOptionPane.showMessageDialog(frame, "Message must be 3 characters", "Error", JOptionPane.ERROR_MESSAGE);
						 return;
					}
					Tuple chatMsg = new Tuple();
					chatMsg.addField(new AgillaString("snd"));
					chatMsg.addField(aid);
					chatMsg.addField(sname);
					chatMsg.addField(new AgillaString(outMessage));
					
					log("Sending a chat message to : " + local_moteaddr + " message = " + chatMsg);				
					injector.getTS().rout(chatMsg, local_moteaddr);
					
					outText.setText("");

					/*if (otherPersonHere){
						String outMessage = outText.getText();
						addMyText(outMessage);
						user.sendIM(aID, outMessage);
					}
					else{
						addMyText(outText.getText());
						inTextString += "<i><font color=\"green\">[" + aID.getName()
							+ " has disengaged and will not recieve the previous message]"
							+ "</font></i><br>";
						setInText();
					}*/
				}
				else
					outText.setText("");
				return;
			}
			
			if(ae.getActionCommand().equals("Close")){
				frame.dispatchEvent(new WindowEvent(frame, WindowEvent.WINDOW_CLOSING));
				frame.setVisible(false);
				frame.dispose();
				return;
			}
			
			/*if (ae.getActionCommand().equals("Send AgentID")){
				addMyText(user.sendIMAgentID(aID).toString());
				return;
			}*/
			
			if (ae.getActionCommand().equals("Clear Messages")){
				clearMessages();
				return;
			}
			
			if (ae.getActionCommand().equals("Move")) {
				String locStr = JOptionPane.showInputDialog("Please enter a destination");
				int x = 0, y = 0;
				try {
					System.out.println("locStr = " + locStr + " index of , = " + locStr.indexOf(","));
					x = Integer.valueOf(locStr.substring(0, locStr.indexOf(",")));
					y = Integer.valueOf(locStr.substring(locStr.indexOf(",")+1, locStr.length()));
				} catch(Exception e) {
					e.printStackTrace();
					return;
				}
				Tuple moveMsg = new Tuple();
				moveMsg.addField(new AgillaString("abc"));
				moveMsg.addField(aid);
				moveMsg.addField(new AgillaLocation(x, y));
				
				System.out.println("movemsg = " + moveMsg);
				log("Sending a move (" + x + ", " + y + ") to " + local_moteaddr);				
				injector.getTS().rout(moveMsg, local_moteaddr);
			}
		}
		
		/**
		 * Closes the window.
		 */
		public void close() {
			frame.dispose();
		}
		
		public String toString(){
			return "An chat GUI for: " + sname;
		}
	}
}
