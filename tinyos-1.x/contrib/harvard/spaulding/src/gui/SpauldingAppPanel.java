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

import javax.swing.*;
import java.awt.*;
import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;

/**
 * <p>SpauldingAppPanel - This is the main panel for the Spaulding App </p>
 * @author Konrad Lorincz
 * @version 1.0
 */
public class SpauldingAppPanel extends JPanel
{
    // =========================== Data Members ================================
    SpauldingApp spauldingApp;

    private CommandPanel commandPanel;
    private NodesStatusJTable nodesStatusPanel;
    private SessionsJTable sessionsPanel;
    private JTabbedPane realTimeSamplesTabbedPane;


    // =========================== Methods ================================
    public SpauldingAppPanel(SpauldingApp spauldingApp)
    {
        assert (spauldingApp != null);
        this.spauldingApp = spauldingApp;

        this.setPreferredSize(new Dimension(800,600));

        // (1) - The individual pannels
        // the Command panel
        commandPanel = new CommandPanel(spauldingApp);

        // the Nodes Status JTable
        nodesStatusPanel = new NodesStatusJTable(spauldingApp);
        nodesStatusPanel.setPreferredScrollableViewportSize(new Dimension(50, 50));
        JScrollPane nodesStatusScrollPane = new JScrollPane(nodesStatusPanel, JScrollPane.VERTICAL_SCROLLBAR_ALWAYS, JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);

        // the Sessions JTable
        sessionsPanel = new SessionsJTable(spauldingApp);
        sessionsPanel.setPreferredScrollableViewportSize(new Dimension(50, 50));
        JScrollPane sessionsScrollPane = new JScrollPane(sessionsPanel, JScrollPane.VERTICAL_SCROLLBAR_ALWAYS, JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);

        // the TabbedPane for RealTimeSamplesPanels
        realTimeSamplesTabbedPane = new JTabbedPane(JTabbedPane.TOP, JTabbedPane.SCROLL_TAB_LAYOUT);
        realTimeSamplesTabbedPane.setBorder(BorderFactory.createTitledBorder("Real Time Samples (downsampled)"));

        // the TabbedPane for Nodes & Sessions
        JTabbedPane nodesSessionsTabbedPane = new JTabbedPane(JTabbedPane.TOP, JTabbedPane.SCROLL_TAB_LAYOUT);
        //nodesSessionsTabbedPane.setBorder(BorderFactory.createTitledBorder("Nodes & Sessions"));
        nodesSessionsTabbedPane.add(nodesStatusScrollPane, "Nodes", 0);
        nodesSessionsTabbedPane.add(sessionsScrollPane, "Sessions", 1);


        // (2) - Composing the panels
        JSplitPane splitPane = new JSplitPane(JSplitPane.VERTICAL_SPLIT, nodesSessionsTabbedPane, realTimeSamplesTabbedPane);
        splitPane.setOneTouchExpandable(true);
        splitPane.setDividerLocation(0.3);

        // splitsplit
        JSplitPane split2Pane = new JSplitPane(JSplitPane.VERTICAL_SPLIT, commandPanel, splitPane);
        split2Pane.setOneTouchExpandable(true);
        split2Pane.setDividerLocation(0.3);


        // Do the Layout
        this.setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
        this.add(split2Pane);
    }

    public void updatePanels()
    {
        nodesStatusPanel.update();
        sessionsPanel.update();
    }

    public void addNewNode(Node newNode)
    {
        assert (newNode != null);
        RealTimeSamplesPanel rtsPanel = new RealTimeSamplesPanel(newNode);

        // Insert the tab sorted
        String tabTitle = "NodeID= " + newNode.getNodeID();
        int i = 0;
        while (i < realTimeSamplesTabbedPane.getTabCount() &&
               tabTitle.compareTo(realTimeSamplesTabbedPane.getTitleAt(i)) > 0)
            i++;
        realTimeSamplesTabbedPane.add(rtsPanel, tabTitle, i);

        // Register NodeListeners
        //newNode.registerNodeListener(rtsPanel);
        newNode.registerNodeListener((NodeStatusTableModel)nodesStatusPanel.getModel());
    }

    public void addNewSession(Session newSession)
    {
        assert (newSession != null);

        // Register sessionListeners
        newSession.registerListener((SessionsTableModel)sessionsPanel.getModel());
        sessionsPanel.update();
        newSession.registerListener(commandPanel);
    }

    public void newRequest(Request request)
    {
        request.registerListener((NodeStatusTableModel)nodesStatusPanel.getModel());
    }

    /**
     * Create a menu bar for this instance of MapGUI.
     */
    public static JMenuBar createMenuBar()
    {
        JMenuBar menuBar = new JMenuBar();

        JMenu fileMenu = new JMenu("File");
        fileMenu.setMnemonic(KeyEvent.VK_F);
        menuBar.add(fileMenu);
        JMenu helpMenu = new JMenu("Help");
        helpMenu.setMnemonic(KeyEvent.VK_H);
        menuBar.add(helpMenu);

        // Exit
        JMenuItem newMenuItem = fileMenu.add(new AbstractAction("Exit") {
            public void actionPerformed(ActionEvent evt) {
                System.exit(0);
            }
        });
        // About
        newMenuItem = helpMenu.add(new AbstractAction("About") {
            public void actionPerformed(ActionEvent evt) {
                JOptionPane.showMessageDialog(null,
                                              "Spaulding SamplingApp - Harvard University\n\n" +
                                              "GUI developed by: Konrad Lorincz",
                                              "About", JOptionPane.INFORMATION_MESSAGE);
            }
        });

        return menuBar;
    }
}
