package net.tinyos.sim.plugins;

import net.tinyos.sim.*;
import net.tinyos.sim.event.SimEvent;

import javax.swing.*;
import javax.swing.table.AbstractTableModel;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.io.*;
import java.lang.reflect.InvocationTargetException;
import java.net.Socket;
import java.util.Collections;
import java.util.Vector;

public class TDBPlugin extends GuiPlugin implements SimConst {
//    private JButton connectButton;
    private boolean connected = false;
    private Socket debugSocket = null;
    private JTextArea messageArea;
    private SocketThread sockThread = null;
    private boolean shouldRun = false;
    private InputStream inStream = null;
    private OutputStream outStream = null;
    private BufferedReader inReader = null;
    private OutputStreamWriter outWriter = null;
    private JTextField inputField;
    private JButton sendButton;
    private JButton clearButton;
    private Vector varsVector = null;
    private Vector sourcesVector = null;
    private SocketState currState = null;
    private JComboBox globalsCombo;
    private JSpinner globalsSpinner;
    private JButton retrieveGlobalButton;
    private JButton watchGlobalButton;
    private JComboBox sourcesCombo;
    private JTextField sourceLineField;
    private JButton breakpointButton;
    private JCheckBox continueCheckbox;
    private JButton continueButton;
    private JButton stepButton;
    private JButton listButton;
    private JButton saveButton;
    private JTextField breakpointMoteField;
    private JButton toggleBreakpointButton;
    private JButton deleteBreakpointButton;
    private JComboBox watchGlobalsCombo;
    private JSpinner watchSpinner;
    private JTable watchpointTable;
    private JTable breakpointTable;
    private JButton toggleWatchpointButton;
    private JButton deleteWatchpointButton;
    private int maxMote;

    private Vector breakpointVector;
    private Vector watchpointVector;

    // Draws onto the main canvas
    public void draw(Graphics graphics) {
        graphics.setFont(TinyViz.smallFont);
        graphics.setColor(Color.blue);
        int[] drawn = new int[state.numMoteSimObjects()];
        for (int i = 0; i < drawn.length; i++) {
            drawn[i] = 0;
        }
        for (int i = 0; i < watchpointVector.size(); i++) {
            StopPointInfo point = (StopPointInfo) watchpointVector.elementAt(i);
            MoteSimObject mote = state.getMoteSimObject(point.moteNumber);
            CoordinateAttribute coordinate = mote.getCoordinate();
            int x = (int) cT.simXToGUIX(coordinate.getX()) + (int) cT.simXToGUIX(mote.getObjectSize());
            int y = (int) cT.simYToGUIY(coordinate.getY());
            y += 10 * (drawn[point.moteNumber]++);
            if (point.value != null)
                graphics.drawString(point.location + ": " + point.value, x, y);
        }
    }

    public void handleEvent(SimEvent event) {
        //To change body of implemented methods use File | Settings | File Templates.
    }

    public void register() {
        currState = new SocketState();
        maxMote = state.numMoteSimObjects()-1;
        if (maxMote < 0) maxMote = 999;
        breakpointVector = new Vector();
        watchpointVector = new Vector();
        setupGUI();
        setupConnection();

    }

    private void setupGUI() {
        GridBagLayout gridBag = new GridBagLayout();
        pluginPanel.setLayout(gridBag);
        GridBagConstraints c;


        setupTabPanels();

        c = new GridBagConstraints();
        c.gridwidth = 1;
        c.gridx = 0;
        c.gridy = 1;
        c.weighty = 0.0;
        c.fill = GridBagConstraints.NONE;
        c.anchor = GridBagConstraints.WEST;
        JLabel messagesLabel = new JLabel("Messages");
        gridBag.setConstraints(messagesLabel, c);
        pluginPanel.add(messagesLabel);

        c.gridy = 2;
        c.gridwidth = 5;
        c.fill = GridBagConstraints.BOTH;
        c.anchor = GridBagConstraints.CENTER;
        c.weightx = 1.0;
        c.weighty = 1.0;
        messageArea = new JTextArea();
        messageArea.setEditable(false);
        JScrollPane pane = new JScrollPane(messageArea);
        gridBag.setConstraints(pane, c);
        pluginPanel.add(pane);

        c.gridy = 3;
        c.fill = GridBagConstraints.HORIZONTAL;
        c.weighty = 0;
        c.anchor = GridBagConstraints.WEST;
        continueCheckbox = new JCheckBox("Continue when watchpoint is hit");
        gridBag.setConstraints(continueCheckbox, c);
        pluginPanel.add(continueCheckbox);


        setupBottomButtons();

        setupListeners();
    }

    private void setupBottomButtons() {
        GridBagConstraints c = new GridBagConstraints();
        c.gridy = 4;
        c.fill = GridBagConstraints.NONE;
        c.weightx = 0.0;
        c.gridx = 0;
        c.gridwidth = 1;
        clearButton = new JButton("Clear");
        pluginPanel.add(clearButton, c);

        c.gridx = 1;
        continueButton = new JButton("Continue");
        pluginPanel.add(continueButton, c);

        c.gridx = 2;
        stepButton = new JButton("Step");
        pluginPanel.add(stepButton, c);

        c.gridx = 3;
        listButton = new JButton("List Lines");
        pluginPanel.add(listButton, c);

        c.gridx = 4;
        saveButton = new JButton("Save Log");
        pluginPanel.add(saveButton, c);
    }

    private void setupTabPanels() {
        GridBagConstraints c;
        JTabbedPane tabPane = new JTabbedPane();

        setupCommandPanel(tabPane);
        setupBreakpointPanel(tabPane);
        setupWatchpointPanel(tabPane);

        c = new GridBagConstraints();
        c.gridx = 0;
        c.gridy = 0;
        c.gridwidth = 5;
        c.fill = GridBagConstraints.BOTH;
        c.anchor = GridBagConstraints.NORTH;
        c.weightx = 1.0;
        c.weighty = 0.5;
        pluginPanel.add(tabPane,c );
    }

    private void setupWatchpointPanel(JTabbedPane tabPane) {
        GridBagConstraints c;
        c = new GridBagConstraints();
        JPanel watchpointPanel = new JPanel();
        GridBagLayout watchpointLayout = new GridBagLayout();
        watchpointPanel.setLayout(watchpointLayout);

        c.gridx = 0;
        c.gridy = 0;
        c.anchor = GridBagConstraints.WEST;
        watchpointPanel.add(new JLabel("Variables"), c);

        c.gridx = 1;
        watchpointPanel.add(new JLabel("Mote Number"), c);

        c.gridy = 1;
        c.gridx = 0;
        c.fill = GridBagConstraints.HORIZONTAL;
        c.weightx = 1.0;
        watchGlobalsCombo = new JComboBox();
        watchpointPanel.add(watchGlobalsCombo, c);

        c.gridx = 1;
        c.weightx = 0.0;
        watchSpinner = new JSpinner(new SpinnerNumberModel(0, 0, maxMote, 1));
        watchpointPanel.add(watchSpinner, c);

        c.gridx = 2;
        c.anchor = GridBagConstraints.EAST;
        watchGlobalButton = new JButton("Set Watchpoint");
        watchpointPanel.add(watchGlobalButton, c);

        c.gridy = 3;
        c.gridx = 0;
        c.anchor = GridBagConstraints.WEST;
        watchpointPanel.add(new JLabel("Current Watchpoints"), c);

        c.gridx = 0;
        c.gridy = 4;
        c.anchor = GridBagConstraints.CENTER;
        c.fill = GridBagConstraints.BOTH;
        c.weightx = 1.0;
        c.weighty = 1.0;
        c.gridwidth = 3;
        watchpointTable = new JTable(new WatchpointTableModel());
        watchpointPanel.add(new JScrollPane(watchpointTable), c);

        c.gridx = 0;
        c.gridy = 5;
        c.anchor = GridBagConstraints.WEST;
        c.fill = GridBagConstraints.NONE;
        c.weightx = 0.0;
        c.weighty = 0.0;
        c.gridwidth = 1;
        toggleWatchpointButton = new JButton("Toggle Active");
        watchpointPanel.add(toggleWatchpointButton, c);

        c.gridx = 2;
        c.anchor = GridBagConstraints.EAST;
        deleteWatchpointButton = new JButton("Delete Watchpoint");
        watchpointPanel.add(deleteWatchpointButton, c);

        tabPane.add("Watchpoints", watchpointPanel);
    }

    private void setupBreakpointPanel(JTabbedPane tabPane) {
        GridBagConstraints c;
        JLabel moteLabel;

        GridBagLayout breakpointLayout = new GridBagLayout();
        JPanel breakpointPanel = new JPanel();
        breakpointPanel.setLayout(breakpointLayout);

        c = new GridBagConstraints();
        c.gridx = 0;
        c.gridy = 0;
        c.anchor = GridBagConstraints.WEST;
        JLabel sourcefilesLabel = new JLabel("Source Files");
        breakpointPanel.add(sourcefilesLabel, c);

        c.gridx = 2;
        JLabel lineLabel = new JLabel("Line");
        breakpointPanel.add(lineLabel, c);

        c.gridx = 3;
        moteLabel = new JLabel("Mote");
        breakpointPanel.add(moteLabel, c);

        c.gridx = 0;
        c.gridy = 1;
        c.gridwidth = 2;
        c.fill = GridBagConstraints.HORIZONTAL;
        c.weightx = 0.8;
        sourcesCombo = new JComboBox();
        breakpointPanel.add(sourcesCombo, c);

        c.gridx = 2;
        c.gridwidth = 1;
        c.fill = GridBagConstraints.HORIZONTAL;
        c.weightx = 0.1;
        sourceLineField = new JTextField();
        breakpointPanel.add(sourceLineField, c);

        c.gridx = 3;
        breakpointMoteField = new JTextField();
        breakpointPanel.add(breakpointMoteField, c);

        c.gridx = 4;
        c.anchor = GridBagConstraints.EAST;
        c.weightx = 0.0;
        breakpointButton = new JButton("Set Breakpoint");
        breakpointPanel.add(breakpointButton, c);

        c.gridx = 0;
        c.gridy = 2;
        c.anchor = GridBagConstraints.WEST;
        breakpointPanel.add(new JLabel("Current Breakpoints"), c);

        c.gridy = 3;
        c.weighty = 1.0;
        c.fill = GridBagConstraints.BOTH;
        c.gridwidth = 5;
        breakpointTable = new JTable(new BreakpointTableModel());
        breakpointPanel.add(new JScrollPane(breakpointTable), c);

        c.gridy = 4;
        c.weighty = 0.0;
        c.fill = GridBagConstraints.NONE;
        c.gridwidth = 1;
        toggleBreakpointButton = new JButton("Toggle Active");
        breakpointPanel.add(toggleBreakpointButton, c);

        c.gridx = 4;
        c.anchor = GridBagConstraints.EAST;
        deleteBreakpointButton = new JButton("Delete Breakpoint");
        breakpointPanel.add(deleteBreakpointButton, c);
        tabPane.add("Breakpoints", breakpointPanel);
	sourcesCombo.setMaximumSize(sourcesCombo.getSize());
    }

    private class BreakpointTableModel extends AbstractTableModel {
        protected String columnNames[];
        protected Vector dataVector;

        public BreakpointTableModel() {
            BreakpointTableModel.this.dataVector = breakpointVector;
            columnNames = new String[]{"Location", "Is Active", "Mote"};
        }

        public boolean isCellEditable(int rowIndex, int columnIndex) {
            return false;
        }

        public String getColumnName(int column) {
            return columnNames[column];
        }

        public int getRowCount() {
            return dataVector.size();
        }

        public int getColumnCount() {
            return 3;
        }

        public Object getValueAt(int rowIndex, int columnIndex) {
            StopPointInfo breakpoint = (StopPointInfo) dataVector.elementAt(rowIndex);
            if (breakpoint == null) return null;
            switch(columnIndex) {
                case 0:
                    return breakpoint.location;
                case 1:
                    return breakpoint.enabled ? "Yes" : "No";
                case 2:
                    return (breakpoint.moteNumber == -1) ? "N/A" : String.valueOf(breakpoint.moteNumber);
                case 3:
                    return (breakpoint.value == null) ? "" : breakpoint.value;
                default:
                    return null;
            }
        }
    }

    private class WatchpointTableModel extends BreakpointTableModel {
        public WatchpointTableModel() {
            dataVector = watchpointVector;
            columnNames = new String[]{"Variable", "Is Active", "Mote", "Value"};
        }

        public int getColumnCount() {
            return 4;
        }
    }

    private void setupCommandPanel(JTabbedPane tabPane) {
        GridBagConstraints c;
        JPanel commandPanel = new JPanel();
        GridBagLayout commandLayout = new GridBagLayout();
        commandPanel.setLayout(commandLayout);
        c = new GridBagConstraints();
        JLabel commandLabel = new JLabel("Command");
        c.gridx = 0;
        c.gridy = 0;
        c.anchor = GridBagConstraints.NORTHWEST;
        commandLayout.setConstraints(commandLabel, c);
        commandPanel.add(commandLabel);

        inputField = new JTextField();
        c.gridy++;
        c.gridwidth = 3;
        c.weightx = 1.0;
        c.fill = GridBagConstraints.HORIZONTAL;
        commandLayout.setConstraints(inputField, c);
        commandPanel.add(inputField);

        c.gridx = 3;
        c.gridwidth = 1;
        c.weightx = 0.0;
        c.fill = GridBagConstraints.NONE;
        c.anchor = GridBagConstraints.NORTHEAST;
        sendButton = new JButton("Send");
        commandLayout.setConstraints(sendButton, c);
        commandPanel.add(sendButton);

        c.anchor = GridBagConstraints.WEST;
        c.gridy++;
        c.gridx = 0;
        c.fill = GridBagConstraints.HORIZONTAL;
        c.weightx = 1.0;
        globalsCombo = new JComboBox();
        commandLayout.setConstraints(globalsCombo, c);
        commandPanel.add(globalsCombo);

        c.gridx = 1;
        c.fill = GridBagConstraints.NONE;
        c.weightx = 0.0;
        JLabel moteLabel = new JLabel("Mote");
        commandLayout.setConstraints(moteLabel, c);
        commandPanel.add(moteLabel);

        c.gridx = 2;

        globalsSpinner = new JSpinner(new SpinnerNumberModel(0, 0, maxMote, 1));
        commandLayout.setConstraints(globalsSpinner, c);
        commandPanel.add(globalsSpinner);

        c.gridx = 3;
        retrieveGlobalButton = new JButton("Retrieve");
        c.anchor = GridBagConstraints.NORTHEAST;
        commandLayout.setConstraints(retrieveGlobalButton, c);
        commandPanel.add(retrieveGlobalButton);

        tabPane.add("Commands", commandPanel);
    }

    private void setupListeners() {
        // command panel
        inputField.addKeyListener(new KeyListener() {
            public void keyTyped(KeyEvent e) {
            }

            public void keyPressed(KeyEvent e) {
                if (e.getKeyCode() == KeyEvent.VK_ENTER) {
                    sendButton.doClick();
                }
            }

            public void keyReleased(KeyEvent e) {
            }

        });
        sendButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                sendCommand();
            }
        } );
        retrieveGlobalButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                retrieveGlobal();
            }
        });


//        connectButton.addActionListener(new ActionListener() {
//            public void actionPerformed(ActionEvent e) {
//                if (!connected) {
//                    setupConnection();
//                } else {
//                    closeConnection();
//                }
//            }
//        });

        //breakpoints
        breakpointButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                setBreakpoint();
            }
        });
        deleteBreakpointButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                deleteSelectedBreakpoint();
            }
        });
        toggleBreakpointButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                toggleSelectedBreakpoint();
            }
        });

        //watchpoints
        watchGlobalButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                watchGlobal();
            }
        });
        deleteWatchpointButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                deleteSelectedWatchpoint();
            }
        });
        toggleWatchpointButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                toggleSelectedWatchpoint();
            }
        });

        // main view
        clearButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                messageArea.setText("");
            }
        });
        continueCheckbox.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                sendThroughSocket("togglecontinue\n");
            }
        });
        continueButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                sendThroughSocket("continue\n");
            }
        });
        stepButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                sendThroughSocket("next\n");
            }
        });
        listButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                sendThroughSocket("list\n");
            }
        });

    }

    private void toggleSelectedWatchpoint() {
        int selected = watchpointTable.getSelectedRow();
        if (selected >= 0 && selected < watchpointVector.size()) {
            StopPointInfo wp = (StopPointInfo) watchpointVector.get(selected);
            if (wp.enabled) {
                sendThroughSocket("SENDLIT disable " + String.valueOf(wp.stopPointId) + "\ninfo breakpoints\ninfo breakpoints\n");
                wp.enabled = false;
            } else {
                sendThroughSocket("SENDLIT enable " + String.valueOf(wp.stopPointId) + "\ninfo breakpoints\ninfo breakpoints\n");
                wp.enabled = true;
            }
            watchpointTable.updateUI();
        }
    }

    private void deleteSelectedWatchpoint() {
        int selected = watchpointTable.getSelectedRow();
        if (selected >= 0 && selected < watchpointVector.size()) {
            StopPointInfo wp = (StopPointInfo) watchpointVector.get(selected);
            sendThroughSocket("delete " + String.valueOf(wp.stopPointId) + "\ninfo breakpoints\n");
            watchpointVector.remove(selected);
            watchpointTable.updateUI();
        }
    }

    private void toggleSelectedBreakpoint() {
        int selected = breakpointTable.getSelectedRow();
        if (selected >= 0 && selected < breakpointVector.size()) {
            StopPointInfo bp = (StopPointInfo) breakpointVector.get(selected);
            if (bp.enabled) {
                sendThroughSocket("SENDLIT disable " + String.valueOf(bp.stopPointId) + "\ninfo breakpoints\ninfo breakpoints\n");
                bp.enabled = false;
            } else {
                sendThroughSocket("SENDLIT enable " + String.valueOf(bp.stopPointId) + "\ninfo breakpoints\ninfo breakpoints\n");
//                bp.enabled = true;
            }
            breakpointTable.updateUI();
        }
    }

    private void deleteSelectedBreakpoint() {
        int selected = breakpointTable.getSelectedRow();
        if (selected >= 0 && selected < breakpointVector.size()) {
            StopPointInfo breakpointInfo = (StopPointInfo)(breakpointVector.get(selected));
            sendThroughSocket("delete " + String.valueOf(breakpointInfo.stopPointId) + "\ninfo breakpoints\n");
            breakpointVector.remove(selected);
            breakpointTable.updateUI();
        }
    }

    private void setBreakpoint() {
        try {
            int moteNum = Integer.parseInt(breakpointMoteField.getText());
            sendThroughSocket("MOTE " + String.valueOf(moteNum) + "\n");
        } catch (NumberFormatException e) {
        }
        sendThroughSocket("break " + sourcesCombo.getSelectedItem() + ":" + sourceLineField.getText() + "\n");
    }

    private void watchGlobal() {
        sendThroughSocket("watch " + watchGlobalsCombo.getSelectedItem() + "[" + watchSpinner.getValue() + "]\n");
    }

    private void retrieveGlobal() {
        sendThroughSocket("print " + globalsCombo.getSelectedItem() + "[" + globalsSpinner.getValue() + "]\n");
    }

    private void sendCommand() {
        if (connected) {
            sendThroughSocket("SENDLIT " + inputField.getText() + "\n");
            inputField.setText("");
        }
    }

    private void closeConnection() {
        if (debugSocket != null) {
            try {
                debugSocket.close();
            } catch (IOException e) {
            }
        }

        debugSocket = null;
        shouldRun = false;
//        connectButton.setText("Connect");
        connected = false;
    }

    private void setupConnection() {
        try {
            debugSocket = new Socket("127.0.0.1", 7834);
            inStream = debugSocket.getInputStream();
            outStream = debugSocket.getOutputStream();
            inReader = new BufferedReader(new InputStreamReader(inStream));
            outWriter = new OutputStreamWriter(outStream);
        } catch (IOException e) {
            addListElement("Unable to connect: " + e.toString());
            return;
        }


        connected = true;
        addListElement("Connected!");

        shouldRun = true;
        sockThread = new SocketThread();
        sockThread.start();

        //if successful, change button to say "Disconnect"
//        connectButton.setText("Disconnect");

        sendThroughSocket("vars\n");
        sendThroughSocket("info sources\n");                     
    }

    private void sendThroughSocket(String command) {
        try {
            outWriter.write(command);
            outWriter.flush();
        } catch (IOException e) {
        }
    }

    private void addListElement(String element) {
        //synchronized(listModel) {
//            listModel.addElement(element);
//            messageList.updateUI();
        //}
        messageArea.append(element+"\n");
    }

    public String toString() {
        return "TDB (Debugger)";
    }

    private class SocketThread extends Thread {
        public SocketThread() {
            super("TDBPlugin::SocketThread");
//            setPriority(Thread.MIN_PRIORITY);
        }

        public void run() {
            while (shouldRun) {
                try {
                    if (debugSocket.isClosed()) {
                        SwingUtilities.invokeLater(new Runnable() {
                            public void run() {
                                closeConnection();
                            }
                        });
                    }

                    final String line = inReader.readLine();
                    if (line != null) handleInput(line);
                } catch (IOException e) {
                    e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
                }
            }
        }

        private void handleInput(final String line) {
            if (line == null) return;
            currState.handleLine(line);
        }
    }

    private StopPointInfo getWatchPoint(int pointNumber) {
        for (int i = 0; i < watchpointVector.size(); i++) {
            StopPointInfo stopPointInfo = (StopPointInfo) watchpointVector.elementAt(i);
            if (stopPointInfo.stopPointId == pointNumber) return stopPointInfo;
        }
        return null;
    }

    private class SocketState {
        public void handleLine(final String line) {
            if ("SENDING VARS".equals(line)) {
                currState = new ReceiveGlobalVarsState();
            } else if ("SENDING SOURCES".equals(line)) {
                currState = new ReceiveSourcesState();
            } else if ("SENDING BREAKPOINTS".equals(line)) {
                currState = new ReceiveBreakpointsState();
            } else if (line.charAt(0) == '$' && line.indexOf(" = ") > 0) {
                int index = line.indexOf('=');
                addElementAndWait(line.substring(index + 2));
            } else if ("CONTMODE".equals(line)) {
                continueCheckbox.setSelected(true);
            } else if ("STOPMODE".equals(line)) {
                continueCheckbox.setSelected(false);
            } else if (line.indexOf("Hardware watchpoint") > -1) {
                int pointNumber = Integer.parseInt(line.substring(20, line.indexOf(":")));
                String newValue = line.substring(line.indexOf(", now ") + 6);
                StopPointInfo stopPoint = getWatchPoint(pointNumber);
                if (stopPoint != null) stopPoint.value = newValue;
                watchpointTable.updateUI();
                tv.getMotePanel().refresh();
                addElementAndWait(line);
            } else {
                addElementAndWait(line);
            }
        }



        protected void addElementAndWait(final String line) {
            try {
                SwingUtilities.invokeAndWait(new Runnable() {
                    public void run() {
                        addListElement(line);
                    }
                });
            } catch (InterruptedException e) {
                e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.;
            } catch (InvocationTargetException e) {
                e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.;
            }
        }
    }

    private class ReceiveGlobalVarsState extends SocketState {
        public ReceiveGlobalVarsState() {
            if (varsVector == null) {
                varsVector = new Vector();
            }
        }

        public void handleLine(String line) {
            if (".".equals(line)) {
                Collections.sort(varsVector, String.CASE_INSENSITIVE_ORDER);
                globalsCombo.setModel(new DefaultComboBoxModel(varsVector));
                watchGlobalsCombo.setModel(new DefaultComboBoxModel(varsVector));

                currState = new SocketState();
            } else {
                varsVector.add(line);
            }
        }
    }

    private class ReceiveSourcesState extends SocketState {

        public ReceiveSourcesState() {
            if (sourcesVector == null) {
                sourcesVector = new Vector();
            }
        }

        public void handleLine(String line) {
            if (".".equals(line)) {
                Collections.sort(sourcesVector, String.CASE_INSENSITIVE_ORDER);
                sourcesCombo.setModel(new DefaultComboBoxModel(sourcesVector));

                currState = new SocketState();
            } else {
		int slashIndex = line.lastIndexOf('/');
		if (slashIndex > -1)
		line = line.substring(slashIndex + 1);
                sourcesVector.add(line);
            }
        }
    }

    private class ReceiveBreakpointsState extends SocketState {
        private StopPointInfo newPoint;

        public ReceiveBreakpointsState() {
            // clear out the two JTables
            breakpointVector.clear();
//            watchpointVector.clear();
            for (int i = 0; i < watchpointVector.size(); i++) {
                StopPointInfo stopPointInfo = (StopPointInfo) watchpointVector.elementAt(i);
                stopPointInfo.scanned = false;
            }
        }

        public void handleLine(String line) {
            if (".".equals(line)) {
                for (int i = 0; i < watchpointVector.size(); i++) {
                    StopPointInfo stopPointInfo = (StopPointInfo) watchpointVector.elementAt(i);
                    if (!stopPointInfo.scanned) {
                        watchpointVector.remove(i);
                        i--;
                    }
                }

                currState = new SocketState();
                ((BreakpointTableModel)breakpointTable.getModel()).fireTableDataChanged();
                watchpointTable.updateUI();
            } else {
                if ("MOTE".equals(line.substring(0, 4) )) {
                    newPoint.moteNumber = Integer.parseInt(line.substring(5));
                    return;
                }

                newPoint = new StopPointInfo();
                newPoint.stopPointId = Integer.parseInt(line.substring(0, line.indexOf(' ')));
                newPoint.enabled = (line.charAt(24) == 'y');

                if ("breakpoint".equals(line.substring(4, 14))) {
                    breakpointVector.add(newPoint);
                    newPoint.location = line.substring(39);
                    newPoint.moteNumber = -1;
                }  else { // watchpoint
                    int bracketIndex = line.indexOf('[');
                    newPoint.location = line.substring(39, bracketIndex);
                    newPoint.moteNumber = Integer.parseInt(line.substring(bracketIndex + 1, line.indexOf(']')));
                    StopPointInfo oldWatchPoint = getWatchPoint(newPoint.stopPointId);
                    if (oldWatchPoint != null) {
                        oldWatchPoint.location = newPoint.location;
                        oldWatchPoint.moteNumber = newPoint.moteNumber;
                        oldWatchPoint.enabled = newPoint.enabled;
                        oldWatchPoint.scanned = true;
                    } else {
                        newPoint.scanned = true;
                        watchpointVector.add(newPoint);
                    }
                }
            }
        }
    }

    private class StopPointInfo {
        public int stopPointId;
        public int moteNumber;
        public boolean enabled;
        public String location;
        public String value;
        public boolean scanned;
    }
}
