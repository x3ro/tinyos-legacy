/*
 * Copyright (c) 2007
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

import java.util.*;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.table.AbstractTableModel;
import javax.swing.event.*;
import javax.swing.table.TableColumn;
import java.awt.SystemColor;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.awt.Component;

import javax.swing.BorderFactory;
import javax.swing.JLabel;
import javax.swing.JTable;
import javax.swing.border.Border;
import javax.swing.table.TableCellRenderer;
import java.awt.Color;
import java.awt.Component;

/**
 * This file contains the various views that a node may have.  Each view
 * extends from JPanel; this way it can be displayed in a GUI.
 *
 * @author Konrad Lorincz
 * @version 1.0, June 21, 2005
 */

class NodesStatusJTable extends JTable
{
    private SpauldingApp spauldingApp;
    private JPopupMenu popupMenu;
    private NodeStatusTableModel model;

    NodesStatusJTable(SpauldingApp spauldingGUI)
    {
        this.spauldingApp = spauldingGUI;
        this.model = new NodeStatusTableModel(spauldingGUI, this);
        this.setModel(model);

        this.setPreferredScrollableViewportSize(new Dimension(25, 25));
        this.setBackground(new Color(255, 251, 240));
        this.setForeground(new Color(0, 0, 150));
        getTableHeader().setForeground(new Color(150, 0, 0));

        createPopupMenu();
        registerEvents();
    }

    public void update()
    {
        model.updateAll();
    }

    private List<Node> getSelectedNodes()
    {
        List<Node> selectedNodes = new Vector<Node>();
        NodeStatusTableModel myTableModel = (NodeStatusTableModel) getModel();

        ListSelectionModel lsm = getSelectionModel();
        int minIndex = lsm.getMinSelectionIndex();
        int maxIndex = lsm.getMaxSelectionIndex();

        for (int i = minIndex; i <= maxIndex; i++) {
            if (lsm.isSelectedIndex(i)) {
                //System.out.println("row " + i + " is selected");
                Node currNode = myTableModel.getNode(i);
                if (currNode != null)
                    selectedNodes.add(currNode);
            }
        }

        return selectedNodes;
    }

    private void registerEvents()
    {
        this.addMouseListener(new MouseAdapter() {
            public void mouseClicked(MouseEvent e) {
                if ((e.getModifiers() & InputEvent.BUTTON3_MASK) == InputEvent.BUTTON3_MASK &&
                    !getSelectionModel().isSelectionEmpty()) {
                    popupMenu.show(e.getComponent(), e.getX(), e.getY());
                }
            }
        });
    }

    private void createPopupMenu()
    {
        JMenuItem menuItem;

        // Create the popup menu.
        popupMenu = new JPopupMenu();
        menuItem = new JMenuItem("Update");
        menuItem.addMouseListener(new MouseAdapter() {
            public void mouseReleased(MouseEvent e) {
                ListSelectionModel rowSM = getSelectionModel();
                if (!rowSM.isSelectionEmpty()) {
                    // Find out which indexes are selected.
                    for (Node node: getSelectedNodes()) {
                        System.out.println("NodeStatusPanel - scheduling Status Update for nodeID= " + node.getNodeID());
                        AckRequest ackRequest = new AckRequest(spauldingApp, node, DriverMsgs.REQUESTMSG_TYPE_STATUS);
                        spauldingApp.scheduleRequest(ackRequest);
                    }
                }
            }
        });
        popupMenu.add(menuItem);

        // add separator
        popupMenu.addSeparator();//JPopupMenu.Separator);


        menuItem = new JMenuItem("Start sampling");
        menuItem.addMouseListener(new MouseAdapter() {
            public void mouseReleased(MouseEvent e) {
                ListSelectionModel rowSM = getSelectionModel();
                if (!rowSM.isSelectionEmpty()) {
                    // Find out which indexes are selected.
                    for (Node node: getSelectedNodes()) {
                        System.out.println("NodeStatusPanel - scheduling Start Sampling for nodeID= " + node.getNodeID());
                        AckRequest ackRequest = new AckRequest(spauldingApp, node, DriverMsgs.REQUESTMSG_TYPE_STARTSAMPLING);
                        spauldingApp.scheduleRequest(ackRequest);
                    }
                }
            }
        });
        popupMenu.add(menuItem);

        menuItem = new JMenuItem("Stop sampling");
        menuItem.addMouseListener(new MouseAdapter() {
            public void mouseReleased(MouseEvent e) {
                ListSelectionModel rowSM = getSelectionModel();
                if (!rowSM.isSelectionEmpty()) {
                    // Find out which indexes are selected.
                    for (Node node: getSelectedNodes()) {
                        System.out.println("NodeStatusPanel - scheduling Stop Sampling for nodeID= " + node.getNodeID());
                        AckRequest ackRequest = new AckRequest(spauldingApp, node, DriverMsgs.REQUESTMSG_TYPE_STOPSAMPLING);
                        spauldingApp.scheduleRequest(ackRequest);
                    }
                }
            }
        });
        popupMenu.add(menuItem);

        // add separator
        popupMenu.addSeparator();


        menuItem = new JMenuItem("Download");
        menuItem.addMouseListener(new MouseAdapter() {
            public void mouseReleased(MouseEvent e) {
                ListSelectionModel rowSM = getSelectionModel();
                if (!rowSM.isSelectionEmpty()) {
                    String str = JOptionPane.showInputDialog("Number of blocks to download", "3");
                    int nbrBlockToDownload = 3;
                    if (str == null)
                        System.err.println("Invalid number of blocks, using default of " + nbrBlockToDownload + " blocks.");
                    try {
                        nbrBlockToDownload = Integer.parseInt(str);
                    } catch (Exception exp) {
                        System.err.println("Invalid number of blocks, using default of " + nbrBlockToDownload + " blocks.");
                    }

                    // Find out which indexes are selected.
                    for (Node node: getSelectedNodes()) {

                        System.out.println("NodeStatusPanel - scheduling Download Blocks for nodeID= " + node.getNodeID());
                        FetchLogger fetchLogger = new FetchLogger(spauldingApp, node, FetchLogger.MANUAL_FETCH, new Date(), null);
                        long startBlockID = node.getHeadBlockID() - nbrBlockToDownload;
                        FetchRequest fetchRequest = new FetchRequest(spauldingApp, node, startBlockID, nbrBlockToDownload, fetchLogger);
                        spauldingApp.scheduleRequest(fetchRequest);
                    }
                }

            }
        });
        popupMenu.add(menuItem);

        // add separator
        popupMenu.addSeparator();

        menuItem = new JMenuItem("Reset DataStore");
        menuItem.addMouseListener(new MouseAdapter() {
            public void mouseReleased(MouseEvent e) {
                ListSelectionModel rowSM = getSelectionModel();
                if (!rowSM.isSelectionEmpty()) {
                    Object[] options = {"Yes", "No"};
                    int n = JOptionPane.showOptionDialog(null,
                                                         "Are you sure you want to RESET the DataStore?  Note, This is irreversible!",
                                                         "Confirm RESET",
                                                         JOptionPane.YES_NO_OPTION,
                                                         JOptionPane.QUESTION_MESSAGE,
                                                         null,
                                                         options,
                                                         options[1]);
                    if (n == JOptionPane.YES_OPTION) {
                        // Find out which indexes are selected.
                        for (Node node: getSelectedNodes()) {
                            System.out.println("NodeStatusPanel - scheduling Reset DataStore for nodeID= " + node.getNodeID());
                            AckRequest ackRequest = new AckRequest(spauldingApp, node, DriverMsgs.REQUESTMSG_TYPE_RESETDATASTORE);
                            spauldingApp.scheduleRequest(ackRequest);
                        }
                    }
                }
            }
        });
        popupMenu.add(menuItem);


        // add separator
        popupMenu.addSeparator();//JPopupMenu.Separator);

    }
}


class NodeStatusTableModel extends AbstractTableModel implements NodeListener, RequestListener
{
    private JTable table;
    private SpauldingApp spauldingApp;
    // We want fast lookup by index (row) and by nodeID
    private Vector<Node> nodes;
    private Map<Integer, Integer> nodeIDToRow;  // Map<nodeID, rowIndex>
    private Map<Integer, Request> nodeIDToRequest = Collections.synchronizedMap(new HashMap<Integer, Request>());

    private String[] columnNames = {"NodeID",
                                   "State",
                                   "Tail",
                                   "Head",
                                   "Local time",
                                   "Global time",
                                   "Time synched",
                                   "Last request",
    };

    private void initColumnWidths(final JTable table)
    {
        javax.swing.SwingUtilities.invokeLater(new Runnable() {
            public void run() {
                table.getColumnModel().getColumn(0).setMaxWidth(100);
                table.getColumnModel().getColumn(1).setPreferredWidth(150);
//                table.getColumnModel().getColumn(2).setPreferredWidth(5);
//                table.getColumnModel().getColumn(3).setPreferredWidth(5);
//                table.getColumnModel().getColumn(4).setPreferredWidth(5);
//                table.getColumnModel().getColumn(5).setPreferredWidth(5);
                table.getColumnModel().getColumn(7).setPreferredWidth(175);
            }
        });
    }

    // ----------- Custom Renderers ----------------------------------------------------------------
    class LastRequestCellRendererClass {} // wrapper class
    class LastRequestCellRenderer extends JProgressBar implements TableCellRenderer
    {
        LastRequestCellRenderer()
        {
            super(0, 100);
            this.setBorderPainted(true);
            this.setStringPainted(true);
            //this.setForeground(new Color(0, 0, 150));
        }

        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus,
                                                       int row, int column)
        {
            if (isSelected)
                this.setBackground(table.getSelectionBackground());
            else
                this.setBackground(table.getBackground());

            Node node = nodes.get(row);
            Request request = nodeIDToRequest.get(node.getNodeID());
            if (request == null) {
                this.setString("NONE");
                this.setValue(0);
            }
            else {
                int percent = (int) Math.round(request.getPercentDone());
                this.setString(request.getType().toString() + "  " + percent + "%");
                this.setValue(percent);
            }
            return this;
        }
    }
    // ---------------------------------------------------------------------------------------------

    NodeStatusTableModel(SpauldingApp spauldingGUI, JTable table)
    {
        assert (spauldingGUI != null && table != null);
        this.table = table;
        this.spauldingApp = spauldingGUI;

        // set custom renderers
        table.setDefaultRenderer(new LastRequestCellRendererClass().getClass(),
                                 new LastRequestCellRenderer());

        this.initColumnWidths(table);
        updateNodes();

    }

    private void updateNodes()
    {
        nodes = spauldingApp.getNodesSorted();
        nodeIDToRow = Collections.synchronizedMap(new HashMap<Integer, Integer>());

        for (int r = 0; r < nodes.size(); ++r)
            nodeIDToRow.put(nodes.get(r).getNodeID(), r);
    }

    public Node getNode(int row)         {return nodes.get(row);}
    public int getColumnCount()          {return columnNames.length;}
    public int getRowCount()             {return nodes.size();}
    public String getColumnName(int col) {return columnNames[col];}

    synchronized public Object getValueAt(int row, int col) {
        Node node = nodes.get(row);

        switch (col) {
            case 0:
                return node.getNodeID();
            case 1:
                return node.getCurrState();
            case 2:
                return node.getTailBlockID();
            case 3:
                return node.getHeadBlockID();
            case 4:
                return node.getLocalTime();
            case 5:
                return node.getGlobalTime();
            case 6:
                return node.getIsTimeSynchronized();
            case 7:
                return new LastRequestCellRendererClass();
            default:
                return "UNKNOWN";
        }
    }

    /*
     * JTable uses this method to determine the default renderer/
     * editor for each cell.  If we didn't implement this method,
     * then the last column would contain text ("true"/"false"),
     * rather than a check box.
     */
    public Class getColumnClass(int c) {return getValueAt(0, c).getClass();}

    public void updateNodeID(int nodeID)
    {
        Integer rowIndex = nodeIDToRow.get(nodeID);
        if (rowIndex == null)
            updateAll();
        else
            fireTableRowsUpdated(rowIndex, rowIndex);
    }
    public synchronized void updateAll()
    {
        updateNodes();
        fireTableDataChanged();
    }

    // ----------- Listening Interfaces ---------
    public void newSamplingMsg(SamplingMsg samplingMsg)
    {  // Just ignore, we don't care about new samples
    }

    public void newReplyMsg(ReplyMsg replyMsg)
    {
        updateNodeID(replyMsg.get_srcAddr());
    }

    public void requestDone(Request request, boolean isSuccessful)
    {
    }

    public void percentCompletedChanged(Request request, double percentCompleted)
    {
        assert (request != null);
        this.nodeIDToRequest.put(request.getDestAddr(), request);
        updateNodeID(request.getDestAddr());
    }
}

