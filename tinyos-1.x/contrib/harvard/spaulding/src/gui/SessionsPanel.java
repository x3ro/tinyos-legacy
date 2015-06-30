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
import javax.swing.table.AbstractTableModel;
import java.awt.Component;

import javax.swing.JTable;
import java.awt.Color;
import java.awt.Component;

/**
 * @author Konrad Lorincz
 * @version 1.0, June 21, 2005
 */

class SessionsJTable extends JTable
{
    private SpauldingApp spauldingApp;
    private JPopupMenu popupMenu;
    private SessionsTableModel model;

    SessionsJTable(SpauldingApp spauldingGUI)
    {
        this.spauldingApp = spauldingGUI;
        this.model = new SessionsTableModel(spauldingGUI, this);
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

    private List<Session> getSelectedSessions()
    {
        List<Session> selectedSessions = new Vector<Session>();
        SessionsTableModel myTableModel = (SessionsTableModel) getModel();

        ListSelectionModel lsm = getSelectionModel();
        int minIndex = lsm.getMinSelectionIndex();
        int maxIndex = lsm.getMaxSelectionIndex();

        for (int i = minIndex; i <= maxIndex; i++) {
            if (lsm.isSelectedIndex(i)) {
                //System.out.println("row " + i + " is selected");
                Session currSession = myTableModel.getSession(i);
                if (currSession != null)
                    selectedSessions.add(currSession);
            }
        }

        Collections.sort(selectedSessions);
        return selectedSessions;
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
        menuItem = new JMenuItem("Download");
        menuItem.addMouseListener(new MouseAdapter() {
            public void mouseReleased(MouseEvent e) {
                System.out.println("Download clicked");
                ListSelectionModel rowSM = getSelectionModel();
                if (!rowSM.isSelectionEmpty()) {
                    // Find out which indexes are selected.
                    List<Session> selectedSessions = getSelectedSessions();
                    Object[] options = {"Yes", "No"};
                    int n = JOptionPane.showOptionDialog(null,
                                                         "Are you sure you want to download all " + selectedSessions.size() + " sessions?",
                                                         "Confirm Download",
                                                         JOptionPane.YES_NO_OPTION,
                                                         JOptionPane.QUESTION_MESSAGE,
                                                         null,
                                                         options,
                                                         options[1]);
                    if (n == JOptionPane.YES_OPTION) {
                        for (Session session: selectedSessions) {
                            System.out.println("SessionPanel - scheduling Download for session= " + session.getDate());
                            session.download();
                        }
                    }
                }
            }
        });
        popupMenu.add(menuItem);

        // add separator
        popupMenu.addSeparator();

        menuItem = new JMenuItem("Remove");
        menuItem.addMouseListener(new MouseAdapter() {
            public void mouseReleased(MouseEvent e) {
                System.out.println("Remove clicked");
                ListSelectionModel rowSM = getSelectionModel();
                if (!rowSM.isSelectionEmpty()) {
                    // Find out which indexes are selected.
                    List<Session> selectedSessions = getSelectedSessions();
                    Object[] options = {"Yes", "No"};
                    int n = JOptionPane.showOptionDialog(null,
                                                         "Are you sure you want to REMOVE all " + selectedSessions.size() + " sessions?",
                                                         "Confirm Removal",
                                                         JOptionPane.YES_NO_OPTION,
                                                         JOptionPane.QUESTION_MESSAGE,
                                                         null,
                                                         options,
                                                         options[1]);

                    if (n == JOptionPane.YES_OPTION) {
                        spauldingApp.removeSessions(selectedSessions);
                        //System.out.println("YES");
                    }
                    else {
                        //System.out.println("NO");
                    }
                }
            }
        });
        popupMenu.add(menuItem);

        // add separator
        //popupMenu.addSeparator();

    }

}


class SessionsTableModel extends AbstractTableModel implements SessionListener
{
    private JTable table;
    private SpauldingApp spauldingApp;

    private Vector<Session> sessions;

    private String[] columnNames = {"Date",
                                   "Name",
                                   "Subject ID",
                                   "Duration (sec)",
                                   "Downloaded (%)",
    };

/*    private void initColumnWidths(final JTable table)
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
    }*/


    SessionsTableModel(SpauldingApp spauldingGUI, JTable table)
    {
        assert (spauldingGUI != null && table != null);
        this.table = table;
        this.spauldingApp = spauldingGUI;

        updateSessions();

    }

    private void updateSessions()
    {
        sessions = spauldingApp.getSessionsSorted();
    }

    public Session getSession(int row)   {return sessions.get(row);}
    public int getColumnCount()          {return columnNames.length;}
    public int getRowCount()             {return sessions.size();}
    public String getColumnName(int col) {return columnNames[col];}

    synchronized public Object getValueAt(int row, int col) {
        Session session = sessions.get(row);

        switch (col) {
            case 0:
                return SpauldingApp.dateToString(session.getDate(), false);
            case 1:
                return session.getSessionName();
            case 2:
                return session.getSubjectID();
            case 3:
                return session.getDuration()/1000;
            case 4:
                return Math.round(session.getPercentDownloaded()) + "%";
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


    public synchronized void updateAll()
    {
        updateSessions();
        fireTableDataChanged();
    }

    // ----------- SessionListener Interfaces ---------
    public void stateChanged(Session.State state)            {updateAll();};
    public void statePercentCompletedChanged(double percent) {updateAll();};
    public void stateElapsedTimeChanged(long timeMS)         {updateAll();};
}

