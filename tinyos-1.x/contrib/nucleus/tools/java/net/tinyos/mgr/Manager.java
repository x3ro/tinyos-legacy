import java.awt.*;
import java.awt.event.*;
import java.awt.geom.*;
import javax.swing.*;

import java.io.*;

import net.tinyos.message.*;

public class Manager extends JFrame implements ActionListener {

  Network network;
  WatchableUserQuery userQuery;
  WatchableSchema watchableSchema;
  NodeBasicControl controller;
  EventListModel eventListModel;
  
  NetworkView networkView;
  WatchableTreeView watchableTreeView;
  JSplitPane watchableNetworkSplit;
  JList eventList;

  boolean isRamQuery;

  public Manager(String args[]) {

    super("SNMS Network Manager");
    setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    
    if (args.length > 0 && args[0].equals("--ramschema")) 
      isRamQuery = true;

    buildModel();

    buildUI();

    buildMenus();

    pack();
    setVisible(true);
  }

  private void buildModel() {
    
    String schemaFile = "snms_schema.txt";

    controller = new NodeBasicControl();
    
    network = new Network();
    network.testInit();

    watchableSchema = new WatchableSchema();
    try {
      if (isRamQuery) {
	watchableSchema.setRAMQuery();
	schemaFile = "snms_ram_schema.txt";
      }
      watchableSchema.loadSchema(schemaFile);
    } catch (IOException e) {
      System.err.println("Couldn't find schema file: " + schemaFile);
    }
    network.setWatchableSchema(watchableSchema);

    userQuery = new WatchableUserQuery(watchableSchema);
    userQuery.setNetwork(network);

    eventListModel = new EventListModel();
  }

  private void buildUI() {

    JPanel contentPane = new JPanel(new BorderLayout());
    contentPane.setOpaque(true);
    contentPane.setBackground(Color.WHITE);
    
    /*    
	  networkView = new TreeView(network);
	  network.setNetworkView(networkView);
	  networkView.setNetwork(network);
    JScrollPane networkViewScroll = new JScrollPane(networkView);
    */  

    networkView = new GridView(network);
    
    JPanel whitePane = new JPanel();
    whitePane.setBackground(Color.WHITE);
    
    JPanel innerPane = new JPanel();
    innerPane.setLayout(new BorderLayout());
    innerPane.add((JPanel)networkView, BorderLayout.NORTH);
    innerPane.add(whitePane, BorderLayout.CENTER);
    
    JScrollPane networkViewScroll = 
      new JScrollPane(innerPane,
		      JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED,
		      JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
    
    networkViewScroll.setBackground(Color.WHITE);
    contentPane.add(networkViewScroll);

    watchableTreeView = new WatchableTreeView(watchableSchema, userQuery);
    
    JScrollPane watchableTreeViewScroll = 
      new JScrollPane(watchableTreeView,
		      JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED,
		      JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);					      
    watchableNetworkSplit = 
      new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, 
		     watchableTreeViewScroll,
		     networkViewScroll);

    watchableNetworkSplit.setResizeWeight(0.0);
    watchableNetworkSplit.setContinuousLayout(false);

    watchableTreeView.setSplitPane(watchableNetworkSplit);

    contentPane.add(watchableNetworkSplit, BorderLayout.CENTER);

    eventList = new JList(eventListModel);
    eventList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    eventList.setVisibleRowCount(-1);
    JScrollPane listScroller = new JScrollPane(eventList);
    listScroller.setPreferredSize(new Dimension(800, 160));
    contentPane.add(listScroller, BorderLayout.SOUTH);

    setContentPane(contentPane);
  }

  private void buildMenus() {
    JMenuBar menuBar = new JMenuBar();
    JMenu menu;
    JMenuItem menuItem;

    menu = new JMenu("SNMS Network Manager");
    menuBar.add(menu);

    menuItem = new JMenuItem("Quit");
    menuItem.addActionListener(this);
    menu.add(menuItem);

    menu = new JMenu("Network");
    menuBar.add(menu);

    menuItem = new JMenuItem("Wake");
    menuItem.addActionListener(new NetworkMenu());
    menu.add(menuItem);

    menuItem = new JMenuItem("Sleep");
    menuItem.addActionListener(new NetworkMenu());
    menu.add(menuItem);

    menuItem = new JMenuItem("Reboot");
    menuItem.addActionListener(new NetworkMenu());
    menu.add(menuItem);

    menu = new JMenu("Node");
    menuBar.add(menu);

    menuItem = new JMenuItem("Wake");
    menuItem.addActionListener(this);
    menu.add(menuItem);

    menuItem = new JMenuItem("Sleep");
    menuItem.addActionListener(this);
    menu.add(menuItem);

    menuItem = new JMenuItem("Reboot");
    menuItem.addActionListener(this);
    menu.add(menuItem);

    setJMenuBar(menuBar);
  }

  public Dimension getPreferredSize() {
    return new Dimension(800,600);
  }

  public void actionPerformed(ActionEvent e) {
    
    if (e.getActionCommand().equals("Quit")) {
      System.exit(0);
    }
  }

  private class NetworkMenu implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      if (e.getActionCommand().equals("Wake")) {
	controller.wake(MoteIF.TOS_BCAST_ADDR, NodeBasicControl.MAX_TTL,
			1024);
      } else if (e.getActionCommand().equals("Sleep")) { 
	controller.sleep(MoteIF.TOS_BCAST_ADDR, NodeBasicControl.MAX_TTL,
			 4096);
      } else if (e.getActionCommand().equals("Reboot")) { 
	controller.reboot(MoteIF.TOS_BCAST_ADDR, NodeBasicControl.MAX_TTL,
			  4096);
      }
    }
  }

  public static void main(String args[]) {
      Manager mgr = new Manager(args);
  }

}
