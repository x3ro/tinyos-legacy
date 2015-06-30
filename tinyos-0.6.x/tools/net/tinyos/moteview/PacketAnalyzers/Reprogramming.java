package net.tinyos.moteview.PacketAnalyzers;

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
* Authors:   Bret Hull
* History:   created 5/2002
*/

import net.tinyos.moteview.*;
import net.tinyos.moteview.event.*;
import java.util.*;
import java.lang.*;
import java.awt.event.*;
import javax.swing.*;
import net.tinyos.moteview.Dialog.*;
import net.tinyos.moteview.Packet.*;
import net.tinyos.moteview.util.*;
import javax.swing.border.*;
import java.awt.*;
import java.io.*;
import java.util.zip.*;

public class Reprogramming extends PacketAnalyzer
{
    public                  MoteViewInjector myCodeInjector;
    protected               Hashtable       proprietaryNodeInfo;
    protected final         int             MAX_WIDTH = 5;
    protected               Thread          thread;
    protected               ProgramReader   m_programReader = null;

    public Reprogramming ( )
    {
	MainClass.objectMaintainer.AddNodeEventListener(this);
	//register myself to be able to contribute to the node/edge properties panel
	MainClass.displayManager.AddNodeDialogContributor(this);
	//register myself to recieve NodeClickedEvents and EdgeClickedEvents
	MainClass.displayManager.AddNodeClickedEventListener(this);
	//register myself to paint nodes and edges and display info panels
	MainClass.displayManager.AddNodePainter(this);

	proprietaryNodeInfo     = new Hashtable();
	myCodeInjector          = new MoteViewInjector ( );
	Thread rt               = new Thread ( myCodeInjector );

	rt.start ();
	m_programReader = new ProgramReader ( MainClass.APP_PATH, myCodeInjector );

	System.out.println ("Reprogramming:: Initializing Reprogamming Packet Analyzer");
    }

    public synchronized void NodeCreated(NodeEvent e)
    {
    	Integer newNodeNumber = e.GetNodeNumber();//you probably want to create a new info pbject to track the data of this new node
    	if(!proprietaryNodeInfo.containsKey(newNodeNumber))//unless it already exists (it might exist if you don't delete it in NodeDeleted()
    	{
            proprietaryNodeInfo.put(newNodeNumber, new NodeInfo(newNodeNumber, 0, 0, m_programReader));
    	}
    	LocalizeNodes();
    }

    public synchronized void NodeDeleted(NodeEvent e)
    {
        Integer deletedNodeNumber = e.GetNodeNumber();//you probably want to delete the info pbject to track the data of this new node
	System.out.println ("REPROG: node deleted: " + deletedNodeNumber );
	proprietaryNodeInfo.remove(deletedNodeNumber);//but you might also want to leave it there but disable it, unless this node reappears and you want to use the same info

	LocalizeNodes();
    }

    public synchronized void PacketRecieved(PacketEvent e)
    {
    	Packet packet = e.GetPacket();
        if ( myCodeInjector.GetCurrentCommand() == myCodeInjector.NEXT_CMD_ID )
        {
            // we're reading in id packets
            NodeInfo currentNodeInfo = ExtractNodeInfo ( packet );
            MainClass.objectMaintainer.addNode( currentNodeInfo.GetNodeNumber () );

            if(!proprietaryNodeInfo.containsKey( currentNodeInfo.GetNodeNumber() ) )//unless it already exists (it might exist if you don't delete it in NodeDeleted()
            {
                proprietaryNodeInfo.put( currentNodeInfo.GetNodeNumber () , currentNodeInfo );
                currentNodeInfo.IncrementIDPackets();
            }
            else
            {
                NodeInfo storedNode = (NodeInfo) proprietaryNodeInfo.get ( currentNodeInfo.GetNodeNumber () );
                UpdateNode ( storedNode, currentNodeInfo );
            }
        }
        else
        {
            //we're doing something else, discard packets
            myCodeInjector.PacketRecieved( packet );
        }
    }


    public synchronized int SetID ( int nOld, int nNew )
    {
	myCodeInjector.setId( (short) nOld, (short) nNew );
	MainClass.objectMaintainer.DeleteNode( new Integer ( nOld) );
	try { Thread.currentThread().sleep ( 500 ); }
	catch ( Exception e ) { }

	//myCodeInjector.GetID((short) 0xFF);
	return nNew;
    }


    private NodeInfo ExtractNodeInfo ( Packet packet )
    {
	NodeInfo packetNode = new NodeInfo (new Integer ( packet.GetNodeID() ),
                                            packet.GetProgID ( ),
                                            packet.GetProgLength ( ),
                                            m_programReader );

	//System.out.println ( "ExtractNodeInfo: nodeNumber: " + packetNode.nodeNumber +
	//		     " program id: " + packetNode.m_nProgID +
	//		     " program length: " + packetNode.m_nProgLength );
	return packetNode;
    }

    private void UpdateNode ( NodeInfo stored, NodeInfo updated )
    {
	stored.SetProgramID ( updated.GetProgramID () );
	stored.SetProgramLength( updated.GetProgramLength () );
        stored.IncrementIDPackets();
    }

    public void SetSortBy ( int sortby)
    {
        NodeInfo node;
        for ( Enumeration e = proprietaryNodeInfo.elements(); e.hasMoreElements(); )
        {
            node = (NodeInfo) e.nextElement();
            node.SetSortBy( sortby );
        }

        LocalizeNodes ();
    }

    public void LocalizeNodes()
    {
	NodeInfo currentNodeInfo;

	int numNodes = proprietaryNodeInfo.size();
        Vector vctNodes = new Vector ( proprietaryNodeInfo.values() );
        Collections.sort( vctNodes );

        Enumeration nodes = vctNodes.elements();

        for(int r = 1; ; r++)
        {
            for(int c = 1; c < MAX_WIDTH; c++)
	    {
                if(nodes.hasMoreElements())
		{
		    currentNodeInfo = (NodeInfo)nodes.nextElement();
                    currentNodeInfo.SetX( c );
		    currentNodeInfo.SetY( r );
		    MainClass.displayManager.SetNodePosition ( currentNodeInfo.GetNodeNumber(), c, r );
                    System.out.println ("REPROG:Localize Nodes: X: " + (double) c +
                                       " Y: " + (double) r + " Node: " + currentNodeInfo.GetNodeNumber() );
                }
                else {
                     return;
                }

            }
        }
    }

    public void PaintNode(Integer pNodeNumber, int x1, int y1, int x2, int y2, Graphics g)
    {
        NodeInfo nodeInfo = (NodeInfo)proprietaryNodeInfo.get(pNodeNumber);
        String name = nodeInfo.GetProgramName();
        g.setColor(Color.black);
        g.drawString("Prog: " + name,  x1 + (x2 - x1)/4, (int) (y2+2.5*(y2-y1)/4) );
    }

    public ActivePanel GetProprietaryNodeInfoPanel(Integer pNodeNumber)
    {
            NodeInfo nodeInfo = (NodeInfo)proprietaryNodeInfo.get(pNodeNumber);
            if(nodeInfo==null)
                    return null;
            ProprietaryNodeInfoPanel panel = new ProprietaryNodeInfoPanel(nodeInfo);
            return (ActivePanel)panel;
    }

    public ActivePanel GetProprietaryNodeInfoPanel ( Vector nodes )
    {
        Vector myNodes = new Vector( );
        Integer nodeNumber;
        NodeInfo node;
        for ( Enumeration e = nodes.elements(); e.hasMoreElements(); )
        {
            nodeNumber = ((net.tinyos.moteview.util.NodeInfo) e.nextElement()).GetNodeNumber();
            node = (NodeInfo) proprietaryNodeInfo.get( nodeNumber );
            if ( node != null )
            {
                myNodes.add( node );
            }
        }

        ProprietaryNodeInfoPanel panel = new ProprietaryNodeInfoPanel( myNodes );
        return (ActivePanel) panel;
    }

    public synchronized void NodeDragged(NodeDraggedEvent e)
    {
    	/*Integer nodeDragged = e.GetNodeNumber();
		NodeInfo selectedNode = (NodeInfo)proprietaryNodeInfo.get(nodeDragged);

		if(selectedNode!=null)
		{     //this function acts on a custom mouse drag, and moves the node with the drag
			selectedNode.SetX(e.GetDraggedToX());
			selectedNode.SetY(e.GetDraggedToY());
			selectedNode.SetFixed(true);
			MainClass.displayManager.RefreshScreenNow();
		}
    	      //and maybe do some other processing*/
    }


    public class ProprietaryNodeInfoPanel extends net.tinyos.moteview.Dialog.ActivePanel
    {
        Vector             m_vctNodes       = new Vector ( );
        MoteViewInjector   codeInjector     = MainClass.reprogramming.myCodeInjector;

        boolean            bBusy            = false;
        boolean            bCheckCalled     = false;
	boolean            bWritten         = false;

        SymAction          lSymAction       = new SymAction();

	//DECLARE_CONTROLS
	JLabel             lblNodeID        = new JLabel();
        JLabel             lblProgID        = new JLabel();
        JLabel             lblProgLen       = new JLabel();
        JLabel             lblIDPackets     = new JLabel();
        JLabel             lblSource        = new JLabel();
        JLabel             lblCheck         = new JLabel();
        JLabel             lblBusy          = new JLabel();
	JLabel             lblSet1          = new JLabel();
	JLabel             lblSet2          = new JLabel();

	JTextField         fldNodeID        = new JTextField();
	JTextField         fldProgID        = new JTextField();
        JTextField         fldProgLen       = new JTextField();
        JTextField         fldSource        = new JTextField();

	JButton            bttnSetID        = new JButton ();
	JButton            bttnNewProg      = new JButton ();
        JButton            bttnSetSource    = new JButton ();
        JButton            bttnStart        = new JButton ();
        JButton            bttnWrite        = new JButton ();
        JButton            bttnCheck        = new JButton ();
        JButton            bttnMultiProg    = new JButton ();
        JButton            bttnStop         = new JButton ();

        JFileChooser       chooser          = new JFileChooser (MainClass.APP_PATH);
        JProgressBar       progress         = new JProgressBar ();
        File               source           = null;

        JPanel             pnlActions       = new JPanel ( );
        JPanel             pnlIndicators    = new JPanel ( );
        JTable             tblNodes         = null;
        JScrollPane        scrollPane       = null;
        JScrollPane        scrollPanePckts  = null;

        JList              lstMissPackets   = new JList ( );
	JComboBox          cmbNodes         = new JComboBox ( );

        public ProprietaryNodeInfoPanel ( Vector nodes )
        {
            m_vctNodes = nodes;
            InitPanel ( );
        }

	public ProprietaryNodeInfoPanel(NodeInfo pNodeInfo)
	{
            m_vctNodes = new Vector ( );
            m_vctNodes.add( pNodeInfo );
            InitPanel ( );
	}

        private void InitTable ( )
        {
            Vector columnNames = new Vector ( );
            Vector tableData   = new Vector ( );
            Vector rowData     = null;
            columnNames.addElement( new String ( "Node ID" ) );
            columnNames.addElement( new String ( "Prg ID" ) );
            columnNames.addElement( new String ( "Prg Size" ) );
            columnNames.addElement( new String ( "Pckt Rcvd" ) );

            NodeInfo node;
            for ( Enumeration nodes = m_vctNodes.elements(); nodes.hasMoreElements(); )
            {

                node = (NodeInfo) nodes.nextElement();

                rowData = new Vector ();
                rowData.add ( new String ("" + node.GetNodeNumber().toString() )  );
                rowData.add ( new String ( "" + node.GetProgramID() ) );
                rowData.add ( new String ( "" + node.GetProgramLength() ) );
                rowData.add ( new String ( "" + node.GetIDPacketsRecvd() ) );

                //tableData.add( rowData );
                tableData.addElement( rowData );
            }

            tblNodes = new JTable (   tableData, columnNames);

        }

        private void InitPanel ( )
        {
            MainClass.reprogramming.myCodeInjector.RegisterActionListener( this );
            tabTitle = "Reprogramming";

	    // Init Controls
	    setLayout(null);
	    //Insets ins = getInsets();
	    //setSize(400,168);

	    lblSet1.setText( "Set Node ID:");
	    lblSet1.setBounds( 5,1,65,18);
	    add ( lblSet1 );

	    cmbNodes.setBounds( 70,1,50,18 );
	    add (cmbNodes);

	    lblSet2.setText( " to " );
	    lblSet2.setBounds( 120,1,50,18);
	    add (lblSet2);

	    fldNodeID.setText ( "" );
            add ( fldNodeID );
            fldNodeID.setBounds ( 170, 1, 35, 18 );

	    bttnSetID.setText( "Set" );
            add ( bttnSetID );
            bttnSetID.setBounds( 205, 1, 75, 18 );
            bttnSetID.addActionListener(lSymAction);

	    AddSetSourceControls ( );
            AddTable ();
            AddActionButtons (  );
            AddIndicators ( );

	}

	private void AddSetSourceControls ( )
	{
	    Vector vctNodes = new Vector ( );
	    NodeInfo intNode;

	    for ( Enumeration nodes = m_vctNodes.elements(); nodes.hasMoreElements(); )
	    {
		intNode = (NodeInfo) nodes.nextElement();
		vctNodes.add( intNode.GetNodeNumber().toString() );
	    }

	    remove ( cmbNodes );
	    cmbNodes = new JComboBox ( vctNodes );
	    cmbNodes.setBounds( 55,1,50,18 );
	    cmbNodes.setSelectedIndex(0);
	    add ( cmbNodes );
	}

        private void AddTable ( )
        {
            InitTable ( );
            scrollPane = new JScrollPane( tblNodes );
            scrollPane.setBounds(100, 24, 400, 90);
            add(scrollPane);
            tblNodes.setPreferredScrollableViewportSize ( new Dimension(400, 90) );
        }

        private void InitPacketList ( JList newList )
        {
            pnlIndicators.remove( scrollPanePckts );
            scrollPanePckts = new JScrollPane ( newList );
            scrollPanePckts.setBounds( 5, 116, 150, 40 );
            pnlIndicators.add ( scrollPanePckts );
            lstMissPackets = newList;
            lstMissPackets.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
            lstMissPackets.setSelectedIndex(0);
        }

        private void AddActionButtons ( )
        {
            add ( pnlActions );
	    pnlActions.setLayout(null);
            pnlActions.setBounds( 10, 120, 125, 170 );
            pnlActions.setBorder(BorderFactory.createTitledBorder(
                                 "Actions"));

            bttnSetSource.setText( "Set Source" );
            pnlActions.add (bttnSetSource);
            bttnSetSource.setBounds(15, 20, 100, 18 );
	    bttnSetSource.addActionListener(lSymAction);

	    bttnNewProg.setText( "New" );
	    pnlActions.add ( bttnNewProg );
	    bttnNewProg.setBounds( 15, 44, 100, 18 );
	    bttnNewProg.addActionListener(lSymAction);

            bttnWrite.setText( "Write" );
	    pnlActions.add ( bttnWrite );
	    bttnWrite.setBounds( 15, 68, 100, 18 );
	    bttnWrite.addActionListener(lSymAction);
/*
            bttnMultiProg.setText ( "Multi Prog" );
	    pnlActions.add ( bttnMultiProg );
	    bttnMultiProg.setBounds( 15, 92, 100, 18 );
	    bttnMultiProg.addActionListener(lSymAction);*/

            bttnCheck.setText( "Check" );
	    pnlActions.add ( bttnCheck );
	    bttnCheck.setBounds( 15, 92, 100, 18 );
	    bttnCheck.addActionListener(lSymAction);

            bttnStart.setText( "Start" );
	    pnlActions.add ( bttnStart );
	    bttnStart.setBounds( 15, 116, 100, 18 );
	    bttnStart.addActionListener(lSymAction);
        }

        private void AddIndicators ( )
        {
            add ( pnlIndicators );
	    pnlIndicators.setLayout(null);
            pnlIndicators.setBounds( 140, 120, 190, 170 );
            pnlIndicators.setBorder(BorderFactory.createTitledBorder(
                                    "Status"));

            lblBusy.setText( "Busy: \\" );
            pnlIndicators.add( lblBusy );
            lblBusy.setBounds ( 5, 7, 84, 24 );

            pnlIndicators.add (progress );
            progress.setStringPainted(true);
            progress.setValue(0);
            progress.setMinimum(0);
            progress.setMaximum(100);
            progress.setBounds( 5, 31, 180, 18 );

            bttnStop.setText( "STOP" );
            pnlIndicators.add ( bttnStop );
            bttnStop.setBounds( 5, 54, 75, 18 );
            bttnStop.addActionListener(lSymAction);

            lblSource.setText( "Source: " );
            pnlIndicators.add (lblSource );
            lblSource.setBounds ( 5, 68,84, 24);

            pnlIndicators.add (fldSource );
            fldSource.setBounds( 5, 92, 180, 18);

            lstMissPackets.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
            scrollPanePckts = new JScrollPane ( lstMissPackets );
            scrollPanePckts.setBounds( 5, 116, 180, 40 );
            pnlIndicators.add ( scrollPanePckts );

        }

        public void ApplyChanges()
	{
            MainClass.reprogramming.myCodeInjector.UnregisterActionListener( this );
	}

        public void Cancel ( )
        {
           MainClass.reprogramming.myCodeInjector.UnregisterActionListener( this );
        }

        public void actionPerformed(ActionEvent e)
        {
	    switch ( e.getModifiers() )
            {
                case MoteViewInjector.CMD_CHECK_DONE:
                     Vector packets = MainClass.reprogramming.myCodeInjector.GetMissingPackets ( );
                     lstMissPackets.setListData( packets );
                     lstMissPackets.repaint();
		     progress.setValue( 100 );
                     break;

                case MoteViewInjector.CMD_WRITE_DONE:
                     InitializeDisplayValues ( );
                     lstMissPackets.setListData( new Vector ( ) );
                     lstMissPackets.repaint();
                     progress.setValue( 100 );
                     break;

		case MoteViewInjector.CMD_BUSY:
		     progress.setValue( e.getID() );
		     ToggleBusy ();
		     break;

		case MoteViewInjector.CMD_NEW_DONE:
		     progress.setValue( 100 );
                     lstMissPackets.setListData( new Vector ( ) );
                     InitializeDisplayValues ( );
                     break;

                case MoteViewInjector.CMD_START_DONE:
                     progress.setValue( 100 );
                     InitializeDisplayValues ( );
                     break;

                case MoteViewInjector.CMD_SETID_DONE:
		     progress.setValue( 100 );
		     InitializeDisplayValues ( );
                     break;

                default:
                    ToggleBusy();
		    InitializeDisplayValues ( );
                    break;
            }
        }


	public void InitializeDisplayValues()
	{
            this.remove( scrollPane );
            InitTable ( );
            scrollPane = new JScrollPane( tblNodes );
            scrollPane.setBounds(5, 24, 330, 90);
            add(scrollPane);
            tblNodes.setPreferredScrollableViewportSize ( new Dimension(290, 90) );
            if ( m_vctNodes.size() == 1 )
            {
                NodeInfo node = (NodeInfo) m_vctNodes.firstElement();
                source = node.GetSource();
                if ( source != null ) fldSource.setText( source.getAbsolutePath() );
            }
	}

	public void bttnSetID_actionPerformed ( ActionEvent event )
	{
	    System.out.println ("bttnSetID pressed");
	    String strNodeID = (String) cmbNodes.getSelectedItem();
            if ( strNodeID == null ) { return; }
            int nodeID = Integer.parseInt ( strNodeID );
            MainClass.reprogramming.SetID( nodeID, Integer.parseInt( fldNodeID.getText() ) );
	    lblNodeID.setText( "Node ID: " + nodeID );

            //super.CancelButton_actionPerformed ( new ActionEvent ( this, 0, "" ) );
	}

        public void bttnNewProg_actionPerformed ( ActionEvent event )
        {

            System.out.println ("bttnNewProg pressed");

            if ( source == null ) bttnSetSource_actionPerformed ( null );
            if ( source == null ) return;

            Vector nodes = ExtractNodeIDs ( );

            if ( m_vctNodes == null ) return;
	    codeInjector.CreateNewProgram( nodes, source.getAbsolutePath () );
        }

        private Vector ExtractNodeIDs ( )
        {
            if ( m_vctNodes == null ) return null;

            NodeInfo node;
            Vector   nodeIDs = new Vector( );
            for ( Enumeration nodes = m_vctNodes.elements(); nodes.hasMoreElements(); )
            {
                node = (NodeInfo) nodes.nextElement();
                nodeIDs.add( node.GetNodeNumber() );
            }
            return nodeIDs;
        }

        public void bttnSetSource_actionPerformed ( ActionEvent event )
        {
            System.out.println ("bttnSetSource pressed");
            chooser.showOpenDialog(this);
            source = chooser.getSelectedFile();
            if ( source != null )
            {
                fldSource.setText( source.getAbsolutePath() );
                codeInjector.SetFileSource( source.getAbsolutePath() );

                NodeInfo node;
                for ( Enumeration nodes = m_vctNodes.elements(); nodes.hasMoreElements();  )
                {
                    node = (NodeInfo) nodes.nextElement();
                    node.SetSource( source );
                }
            }
        }

        public void ToggleBusy ( )
        {
            if ( bBusy ) { lblBusy.setText( "Busy: \\\\" ); }
            else { lblBusy.setText( "Busy: //" ); }
            bBusy = !bBusy;
        }

       public void bttnStart_actionPerformed ( ActionEvent event )
        {
            System.out.println ("bttnStart pressed");
            if ( source == null ) return;
            codeInjector.StartProgram ( ExtractNodeIDs ( ), source.getAbsolutePath() );
        }

        public void bttnWrite_actionPerformed ( ActionEvent event )
        {
            System.out.println ("bttnWrite pressed");
            if ( source == null ) return;

	    if ( bWritten || bCheckCalled ) { codeInjector.FillProgram ( ExtractNodeIDs( ), source.getAbsolutePath() ); }
	    else
            {
                codeInjector.MultiProg ( ExtractNodeIDs ( ), source.getAbsolutePath() );
                bWritten = true;
	    }
        }

        public void bttnMultiProg_actionPerformed ( ActionEvent event )
        {
            if ( source == null ) return;
            codeInjector.MultiProg( ExtractNodeIDs( ), source.getAbsolutePath() );
        }

        public void bttnCheck_actionPerformed ( ActionEvent event )
        {
            if ( source == null ) return;
            codeInjector.CheckProgram ( ExtractNodeIDs ( ), source.getAbsolutePath() );
            bCheckCalled = true;
        }

        public void bttnStop_actionPerformed ( ActionEvent event ) { codeInjector.Stop ( ); }

	class SymAction implements java.awt.event.ActionListener
	{
	    public void actionPerformed(java.awt.event.ActionEvent event)
	    {
	        Object object = event.getSource();
		if (object == bttnSetID) { bttnSetID_actionPerformed(event); }
                else if ( object == bttnNewProg ) { bttnNewProg_actionPerformed (event); }
                else if ( object == bttnSetSource) { bttnSetSource_actionPerformed (event); }
                else if ( object == bttnStart) { bttnStart_actionPerformed (event); }
                else if ( object == bttnWrite) { bttnWrite_actionPerformed (event); }
                else if ( object == bttnCheck) { bttnCheck_actionPerformed (event); }
                else if ( object == bttnMultiProg) { bttnMultiProg_actionPerformed (event); }
                else if ( object == bttnStop) { bttnStop_actionPerformed (event); }
	    }
	}


    }


    public static class NodeInfo implements java.io.Serializable, Comparable
    {
	    protected static final int SORTBY_ID            = 0;
	    protected static final int SORTBY_PROGID        = 1;
	    protected static final int SORTBY_PROGLENGTH    = 2;

            protected double           x;
	    protected double           y;
	    protected Integer          nodeNumber;
	    protected boolean          fixed;
	    protected boolean          displayCoords;
	    protected int              m_nProgID                = 0;
	    protected int              m_nProgLength            = 0;
            protected int              m_nIDPacketsReceived     = 0;
            protected File             m_source                 = null;
            protected int              m_nSourceSize            = 0;
            protected int              m_nDownloaded            = 0;
            protected int              m_SortBy                 = SORTBY_ID;
            protected boolean          m_bReprogrammed          = false;
            protected ProgramReader    m_programReader          = null;

	    public NodeInfo(Integer pNodeNumber, int progID, int progLength, ProgramReader pr)
	    {
		    nodeNumber      = pNodeNumber;
		    x               = Math.random();
		    y               = Math.random();
		    fixed           = false;
		    displayCoords   = true;
                    m_programReader = pr;
                    m_nProgID       = progID;
                    m_nProgLength   = progLength;
	    }

            private void UpdateSource ( )
            {
                m_source = m_programReader.GetProgFile ( m_nProgID );
            }

	    public Integer GetNodeNumber(){return nodeNumber;}
	    public double GetX(){return x;}
	    public double GetY(){return y;}
	    public boolean GetFixed(){return fixed;}
	    public boolean GetDisplayCoords(){return displayCoords;}
	    public int GetProgramID ( ) { return m_nProgID; }
	    public int GetProgramLength ( ) { return m_nProgLength; }
            public String GetProgramName ( )
            {
                UpdateSource ( );
                if ( m_source == null ) { return ("" + m_nProgID); }
                return m_source.getName( );
            }

	    public void SetX(double pX){x=pX;}
	    public void SetY(double pY){y=pY;}
	    public void SetFixed(boolean pFixed){fixed = pFixed;}
	    public void SetDisplayCoords(boolean pDisplayCoords){displayCoords= pDisplayCoords;}
	    public void SetProgramID ( int id ) { m_nProgID = id; }
	    public void SetProgramLength ( int length ) { m_nProgLength = length; }

            public void IncrementIDPackets ( ) { m_nIDPacketsReceived++; }
            public int GetIDPacketsRecvd  ( ) { return m_nIDPacketsReceived; }
            public File GetSource ( )
            {
                /*if ( m_source == null )
                {
                    return "";
                }
                else
                {
                    return m_source.getAbsolutePath( );
                }*/
                UpdateSource ( );
                return m_source;
            }

            public void SetSource ( File file )
            {
                m_source = file;
                m_programReader.AddProgram ( file );
            }

            public int compareTo ( Object o )
            {
                NodeInfo node = (NodeInfo) o;

                switch ( m_SortBy )
                {
                    case SORTBY_ID:
                         return nodeNumber.compareTo( node.nodeNumber );

                    case SORTBY_PROGID:
                         if ( m_nProgID > node.m_nProgID ) { return 1; }
                         else if ( m_nProgID < node.m_nProgID ) { return -1; }
                         else { return 0; }

                    case SORTBY_PROGLENGTH:
                         if ( m_nProgLength > node.m_nProgLength ) { return 1; }
                         else if ( m_nProgLength < node.m_nProgLength ) { return -1; }
                         else { return 0; }
                }
                return 0;
            }

            public void SetSortBy ( int sortby ) { m_SortBy = sortby; }
            public void SetPacketsDownloaded ( int num ) { m_nDownloaded = num; }
            public int GetPacketsDownloaded () { return m_nDownloaded; }
            public void SetSourceSize ( int size ) { m_nSourceSize = size; }
            public int GetSourceSize ( int size ) { return m_nSourceSize; }
            public void SetReprogrammed ( boolean val ) { m_bReprogrammed = val; }
            public boolean GetReprogrammed ( ) { return m_bReprogrammed; }
    }

}