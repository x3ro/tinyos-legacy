package net.tinyos.moteview.PacketAnalyzers;

import net.tinyos.moteview.*;
import net.tinyos.moteview.event.*;
import net.tinyos.moteview.util.*;
import net.tinyos.moteview.Dialog.*;
import net.tinyos.moteview.Packet.*;
import net.tinyos.moteview.PacketSenders.*;

import java.util.*;
import java.io.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.event.*;

public class MoteViewInjector extends CodeInjector
{
    //COMMANDS
    public static final int NEXT_CMD_ID         = 1;
    public static final int NEXT_CMD_SETID      = 2;
    public static final int NEXT_CMD_NEW        = 3;
    public static final int NEXT_CMD_START      = 4;
    public static final int NEXT_CMD_WRITE      = 5;
    public static final int NEXT_CMD_CHECK      = 6;
    public static final int NEXT_CMD_MULTIPROG  = 7;
    public static final int NEXT_CMD_FILL       = 8;

    public static final int DOWNLOAD_REPEATS    = 1;
    public static final int MAX_RETRIES         = 10;

    //ACTION EVENT IDS
    public static final int CMD_BUSY            = 0;
    public static final int CMD_CHECK_DONE      = 1;
    public static final int CMD_WRITE_DONE      = 2;
    public static final int CMD_NEW_DONE        = 3;
    public static final int CMD_ID_DONE         = 4;
    public static final int CMD_FILL_DONE       = 5;
    public static final int CMD_SETID_DONE      = 6;
    public static final int CMD_START_DONE      = 7;

    // THREAD STATE
    private Vector       m_commands             = new Vector ( );
    private Vector       m_vctActionListeners   = new Vector ( );
    private Thread       ciThread               = null;

    // CODE INJECTOR STATE
    private Vector       m_vctDestNodes         = new Vector ( );
    private Vector       m_vctMissingPackets    = new Vector ( );

    //private JProgressBar m_progress             = null;
    private int          m_progress_offset      = 0;
    private int          m_progress_max         = 100;
    private int          m_currentCommand       = NEXT_CMD_ID;
    private int          m_nMissingPackets      = 0;
    private String       m_strFile              = "";
    private boolean      m_bContinue            = true;
    private int          m_nPercentComplete     = 0;

    public MoteViewInjector()
    {
        Reset( );
	System.out.println ("CI:  Initializing Code Injector");
    }

    private void Reset ( )
    {
        for (int i = 0; i < MAX_CAPSULES; i++) {
	    packets_received[i] = true;
	}
	flash = new byte[MAX_CODE_SIZE];
	for (int i=0; i < MAX_CODE_SIZE; i++) {
	    flash[i] = (byte) 0xff;
	}
	reliableRequest = 0;
	requestID = -1;
	acked = 0;

        m_vctMissingPackets.clear();
        m_progress_offset = 0;
        m_nPercentComplete = 0;
        m_progress_max = 0;
    }

    public void run() {
	System.out.println ( "CI: Code Injector is running");
        ciThread = Thread.currentThread();
	try {
            CICommand ciCommand = new CICommand ( null, null, -1, -1 );;

	    while (true)
	    {
                m_bContinue = true;
                if ( m_commands.size() != 0 )
                {
		    ciCommand = (CICommand) m_commands.lastElement();
                    m_currentCommand = ciCommand.m_cmd;
                    m_commands.remove ( ciCommand );
                }
                else { m_currentCommand = NEXT_CMD_ID; }

                switch (m_currentCommand)
		{
		    case NEXT_CMD_ID:
			 id ( (short) -1 );
                         MainClass.objectMaintainer.SetPruneNodes( true );
			 break;

		    case NEXT_CMD_SETID:
                         m_vctDestNodes = ciCommand.m_vctNodes;
                         HandleCommandSetID ( ciCommand.m_arg );
                         FireActionEvent ( CMD_SETID_DONE );
			 break;

		    case NEXT_CMD_NEW:
                         MainClass.objectMaintainer.SetPruneNodes( false );
                         m_vctDestNodes = ciCommand.m_vctNodes;
			 m_strFile = ciCommand.m_strFile;
			 HandleCommandNew ( );
                         id ( (short) -1 );
		         Thread.currentThread().sleep ( 500 );
                         FireActionEvent ( CMD_NEW_DONE );
			 break;

                    case NEXT_CMD_START:
                         m_vctDestNodes = ciCommand.m_vctNodes;
                         HandleCommandStart ( );
                         FireActionEvent ( CMD_START_DONE );
			 break;

                    case NEXT_CMD_WRITE:
                         /*MainClass.objectMaintainer.SetPruneNodes( false );
                         m_vctDestNodes = ciCommand.m_vctNodes;
                         m_strFile      = ciCommand.m_strFile;
			 HandleCommandWrite ( );
                         id ( (short) -1 );
		         Thread.currentThread().sleep ( 500 );
                         FireActionEvent ( CMD_WRITE_DONE );*/
			 break;

                    case NEXT_CMD_CHECK:
                         MainClass.objectMaintainer.SetPruneNodes( false );
                         m_vctDestNodes = ciCommand.m_vctNodes;
                         HandleCommandCheck ( ciCommand.m_strFile );
                         FireActionEvent ( CMD_CHECK_DONE );
			 break;

                    case NEXT_CMD_MULTIPROG:
                         MainClass.objectMaintainer.SetPruneNodes( false );
                         m_vctDestNodes = ciCommand.m_vctNodes;
                         m_strFile      = ciCommand.m_strFile;
			 HandleCommandMultiProg (  );
                         id ( (short) -1 );
		         Thread.currentThread().sleep ( 500 );
                         FireActionEvent ( CMD_WRITE_DONE );
			 break;

		    case NEXT_CMD_FILL:
			 MainClass.objectMaintainer.SetPruneNodes( false );
			 HandleCommandFill ( );
                         FireActionEvent ( CMD_FILL_DONE );
			 FireActionEvent ( CMD_CHECK_DONE );
			 break;
		}
		Thread.currentThread().sleep ( 1000 );
	    }
	}
	catch (Exception e) {
	    System.err.println("CI: Reading ERROR");
	    System.err.println(e);
	    e.printStackTrace();
	}
	System.err.print("error");
    }

    private void HandleCommandSetID ( int newID )
    {
        if ( m_vctDestNodes == null ) return;
        Reset( );
        int oldID = ((Integer) m_vctDestNodes.firstElement()).intValue();

        UpdateProgress ( 0 );
        setId ( (short) oldID, (short) newID );
        UpdateProgress ( 100 );
    }

    private void HandleCommandNew ( )
    {
        if ( m_vctDestNodes == null ) return;
        Reset( );

        Integer nodeID;
        int progress = 0;

        readCode ( m_strFile );

	m_progress_max = m_vctDestNodes.size();
	m_nPercentComplete = progress;
	m_progress_offset  = 0;

        for ( Enumeration nodes = m_vctDestNodes.elements(); nodes.hasMoreElements(); )
        {
           nodeID = (Integer) nodes.nextElement();
           newProgram ( (short) nodeID.intValue() );

           try { Thread.currentThread().sleep ( 500 ); }
           catch ( Exception e) {};

           progress++;
           //m_progress.setValue( progress );
	   UpdateProgress ( progress );
        }
    }

    private void HandleCommandWrite ( )
    {
        if ( m_vctDestNodes == null ) return;
        Reset ( );

        Integer nodeID;
        int count = 0;

        readCode ( m_strFile );

        //m_progress.setMaximum( m_vctDestNodes.size() * ((length+15) & 0xfff0) );
	m_progress_max = m_vctDestNodes.size() * ((length+15) & 0xfff0);
        m_progress_offset = 0;
	m_nPercentComplete = 0;
        //m_progress.setValue( 0 );

        for ( Enumeration nodes = m_vctDestNodes.elements(); nodes.hasMoreElements(); )
        {
           nodeID = (Integer) nodes.nextElement();
           download( (short) nodeID.intValue() );

           try { Thread.currentThread().sleep ( 500 ); }
           catch ( Exception e) {};

           count++;
           m_progress_offset = count * length;
        }
    }

    private void HandleCommandMultiProg ( )
    {
        if ( m_vctDestNodes == null ) return;
	Reset ( );

        int count = 0;
        int node;

        if ( m_vctDestNodes.size() == 1 )
        {
            node = ((Integer) m_vctDestNodes.firstElement()).intValue();
        } else { node = -1; }

        readCode ( m_strFile );
	m_progress_max    = ((length+15) & 0xfff0) * DOWNLOAD_REPEATS;
	m_progress_offset = 0;
	UpdateProgress ( 0 );

        for ( int i = 0; i < DOWNLOAD_REPEATS; i++ )
        {
            download((short) node);
            m_progress_offset = i * ((length+15) & 0xfff0);
        }
    }

    private void HandleCommandCheck ( String file )
    {
        if ( m_vctDestNodes == null ) return;
        Reset ( );
        int node;

        if ( m_vctDestNodes.size() == 1 )
        {
            node = ((Integer) m_vctDestNodes.firstElement()).intValue();
        } else { node = -1; }

        readCode ( file );

	m_progress_max    = (MAX_CAPSULES/(8));
        m_progress_offset = 0;
        UpdateProgress ( 0 );

        FindMissingPackets ( (short) node );
    }

    private void HandleCommandFill (  )
    {
        if ( m_vctDestNodes == null ) return;

        int node;
        int count = 0;

        if ( m_vctDestNodes.size() == 1 )
        {
            node = ((Integer) m_vctDestNodes.firstElement()).intValue();
        } else { node = -1; }

	m_progress_max = m_nMissingPackets + (MAX_CAPSULES/(8));
        m_progress_offset = 0;
        UpdateProgress( 0 );

	FillMissingPackets ( (short) node );
    }

    private void HandleCommandStart ( )
    {
        if ( m_vctDestNodes == null ) return;

        Integer nodeID;
        int     progress = 0;

	m_progress_max      = m_vctDestNodes.size();
	m_progress_offset   = 0;
        UpdateProgress ( progress );

        for ( Enumeration nodes = m_vctDestNodes.elements(); nodes.hasMoreElements(); )
        {
           nodeID = (Integer) nodes.nextElement();
           startProgram ( (short) nodeID.intValue() );

           try { Thread.currentThread().sleep ( 500 ); }
           catch ( Exception e) {};

           progress++;
	   UpdateProgress ( progress );
        }
    }

    public int GetProgID ( File file )
    {
        readCode ( file.getAbsolutePath() );
        return prog_id;
    }

    public synchronized void PacketRecieved( net.tinyos.moteview.Packet.Packet packet)
    {
        System.out.println ("CodeInjector: PacketReceived");

    	//Packet packet = e.GetPacket();
        byte[] readings = packet.GetData();
	if (readings[2] == MSG_WRITE) {
	    updatePacketsReceived(readings);
	}
	acked = ((readings[4] &0xff) << 8) + (readings[5] &0xff) +16;
	notify();
    }

    private synchronized void FillMissingPackets (short node)
    {
	for (int i =0; i < ((length+15)>>4) && m_bContinue; i++)
        {
            UpdateProgress ( i+1 );
	    if (!packets_received[i])
            {
                System.out.print(i+" ");
		sendCapsule(node, i * 16);
		try {
		    Thread.currentThread().sleep(200);
		} catch (Exception e){}
	    }
	}
	int capsule = MAX_CODE_SIZE +(MAX_CAPSULES/8);
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_WRITE;
	packet[3] = group_id;
	packet[5] = (byte) ((prog_id >> 8) & 0xff);
	packet[4] = (byte) (prog_id & 0xff);
	packet[7] = (byte) ((capsule >> 8) & 0xff);
	packet[6] = (byte) (capsule & 0xff);
	preparePacket(packet);

	IPPortPacketSender.sendPackettoAll ( packet );
    }

    private synchronized void FindMissingPackets  (short node)
    {
	for (int i = 0; i < (MAX_CAPSULES/8) && m_bContinue; i+=16)
        {
	    awaitingResponse = 1;
            int retries = 0;
	    while (awaitingResponse > 0 && retries < MAX_RETRIES )
            {
                FireActionEvent ( CMD_BUSY );
                readCapsule(node, MAX_CODE_SIZE+i);
		try { wait(250); }
                catch (InterruptedException e) { return; }
                retries++;
	    }
	    UpdateProgress ( i + 16 );
	}

	if (debug >0)
	    System.out.print("\nMissing packets:");

        m_nMissingPackets = 0;

	for (int i =0; i < ((length+15)>>4); i++)
        {
	    if (!packets_received[i])
            {
                m_vctMissingPackets.add( "" + i );
                System.out.print(i+" ");
                m_nMissingPackets++;
	    }
	}

	int capsule = MAX_CODE_SIZE +(MAX_CAPSULES/8);
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_WRITE;
	packet[3] = group_id;
	packet[5] = (byte) ((prog_id >> 8) & 0xff);
	packet[4] = (byte) (prog_id & 0xff);
	packet[7] = (byte) ((capsule >> 8) & 0xff);
	packet[6] = (byte) (capsule & 0xff);
	preparePacket(packet);
	IPPortPacketSender.sendPackettoAll ( packet );
    }

    public void sendCapsule(short node, int capsule) {
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_WRITE;
	packet[3] = group_id;
	packet[5] = (byte) ((prog_id >> 8) & 0xff);
	packet[4] = (byte) (prog_id & 0xff);
	packet[7] = (byte) ((capsule >> 8) & 0xff);
	packet[6] = (byte) (capsule & 0xff);
	System.arraycopy(flash, capsule, packet, 8, 16);
	preparePacket(packet);
	//serialStub.Write(packet);
	IPPortPacketSender.sendPackettoAll ( packet );
        FireActionEvent ( CMD_BUSY );
    }

    public void download(short node)  {
	for (int i = 0; i < ((length+15) & 0xfff0) && m_bContinue; i += 16) {
	    if (debug > 0) {
		System.out.print("+");
		System.out.flush();
		if (i % 1280 == 0) {
		    System.out.println();
		}
	    }
	    sendCapsule(node, i);
	    UpdateProgress ( i+16 );

	    try
            {
		//Thread.currentThread().yield();
		if (((i>>4) & 127) == 1) {
		    System.out.print("!");
		    Thread.currentThread().sleep(longDelay);
		} else {
		    Thread.currentThread().sleep(shortDelay);
		}
	    }
	    catch (Exception e) {}

	}
	int capsule = MAX_CODE_SIZE +(MAX_CAPSULES/8);
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_WRITE;
	packet[3] = group_id;
	packet[5] = (byte) ((prog_id >> 8) & 0xff);
	packet[4] = (byte) (prog_id & 0xff);
	packet[7] = (byte) ((capsule >> 8) & 0xff);
	packet[6] = (byte) (capsule & 0xff);
	preparePacket(packet);
	//serialStub.Write(packet);
	IPPortPacketSender.sendPackettoAll ( packet );
    }


    public synchronized void check(short node)
    {
	for (int i = 0; i < (MAX_CAPSULES/8); i+=16) {
	    awaitingResponse = 1;
	    while (awaitingResponse > 0) {
		if (debug > 0)
		    System.out.print("+");
		readCapsule(node, MAX_CODE_SIZE+i);
		try {
		    wait(250);
		} catch (InterruptedException e) {
		    System.err.println("Interrupted wait:"+e);
		    e.printStackTrace();
		}
	    }
	}

	if (debug >0)
	    System.out.print("\nMissing packets:");
	for (int i =0; i < ((length+15)>>4); i++)
        {
	    UpdateProgress ( i+1 );
	    if (!packets_received[i]) {
		if (debug >0)
		    System.out.print(i+" ");
		sendCapsule(node, i * 16);
		try {
		    Thread.currentThread().sleep(100);
		} catch (Exception e){}
	    }
	}

	int capsule = MAX_CODE_SIZE +(MAX_CAPSULES/8);
	byte [] packet = new byte[MSG_LENGTH];
	packet[0] = (byte) (node & 0xff);
	packet[1] = (byte) ((node >> 8) & 0xff);
	packet[2] = MSG_WRITE;
	packet[3] = group_id;
	packet[5] = (byte) ((prog_id >> 8) & 0xff);
	packet[4] = (byte) (prog_id & 0xff);
	packet[7] = (byte) ((capsule >> 8) & 0xff);
	packet[6] = (byte) (capsule & 0xff);
	preparePacket(packet);
	IPPortPacketSender.sendPackettoAll ( packet );
	//serialStub.Write(packet);
    }

    public void fillBitmap(short node) {
	byte bitmap[] = new byte[MAX_CAPSULES/8];
	for (int i = 0; i < (MAX_CAPSULES/8); i++) {
	    bitmap[i] = (byte)0xff;
	}
	for (int i =0; i < ((length+15)>>4); i++) {
	    bitmap[(i >> 3) & ((MAX_CAPSULES/8) -1)] &= (byte)(~(1 << (i & 0x7)));
	}
	for (int i = 0; i < (MAX_CAPSULES/8); i++) {
	    System.out.print(Integer.toHexString(bitmap[i] & 0xff) + " ");
	}
	System.out.println();
	for (int i = 0; i < (MAX_CAPSULES / 128); i++) {
	    byte [] packet = new byte[MSG_LENGTH];
	    int capsule = MAX_CODE_SIZE + (i * 16);
	    packet[0] = (byte) (node & 0xff);
	    packet[1] = (byte) ((node >> 8) & 0xff);
	    packet[2] = MSG_WRITE;
	    packet[3] = group_id;
	    packet[5] = (byte) ((prog_id >> 8) & 0xff);
	    packet[4] = (byte) (prog_id & 0xff);
	    packet[7] = (byte) ((capsule >> 8) & 0xff);
	    packet[6] = (byte) (capsule & 0xff);
	    System.arraycopy(bitmap, i*16, packet, 8, 16);
	    int any = 0;
	    for (int j = 0; j < 16; j++) {
		any |= packet[7+j];
	    }
	    if (any != 0) {
		if (debug > 0)
		    System.out.print("+");
		preparePacket(packet);
		//serialStub.Write(packet);
                IPPortPacketSender.sendPackettoAll ( packet );
                FireActionEvent ( CMD_BUSY );
		try {
		    Thread.currentThread().sleep(300);
		} catch (Exception e) {}
	    } else {
		if (debug > 0)
		    System.out.print("?");
	    }
	}
    }

    public void SetID ( Vector nodes, int newNode )
    {
        m_commands.add( new CICommand ( nodes, null, NEXT_CMD_SETID, newNode ) );
    }

    public void CreateNewProgram ( Vector nodes, String file )
    {
        m_commands.add ( new CICommand ( nodes, file, NEXT_CMD_NEW, -1) );
    }

    public void StartProgram ( Vector nodes, String file )
    {
        m_commands.add ( new CICommand ( nodes, file, NEXT_CMD_START, -1 ) );
    }

    public void WriteProgram ( Vector nodes, String file )
    {
        m_commands.add ( new CICommand ( nodes, file, NEXT_CMD_WRITE, -1 ) );
    }

    public void MultiProg ( Vector nodes, String file )
    {
        m_commands.add ( new CICommand ( nodes, file, NEXT_CMD_MULTIPROG, -1 ) );
    }

    public void CheckProgram ( Vector nodes, String file )
    {
        m_commands.add ( new CICommand ( nodes, file, NEXT_CMD_CHECK, -1 ) );
    }

    public void FillProgram ( Vector nodes, String file )
    {
	m_commands.add( new CICommand ( nodes, file, NEXT_CMD_FILL, -1 ) );
    }

    public int GetCurrentCommand ( ) { return m_currentCommand; }

    public Vector GetMissingPackets ( ) { return m_vctMissingPackets; }

    public void SetFileSource (String source) { m_strFile = source; }

    public void Stop ( )
    {
        if ( ciThread == null ) return;
        m_bContinue = false;
        try { ciThread.interrupt(); }
        catch ( Exception e ) { }
    }

    public void RegisterActionListener ( ActionListener listener ) { m_vctActionListeners.add ( listener ); }

    public void UnregisterActionListener ( ActionListener listener ) { m_vctActionListeners.remove ( listener ); }

    public void UpdateProgress ( int value )
    {
	m_nPercentComplete =  (int) Math.floor(100 * (double) ( value + m_progress_offset ) / m_progress_max );
	FireActionEvent ( CMD_BUSY );
    }

    public void FireActionEvent ( int cmd )
    {
        ActionListener listener;
        for ( Enumeration listeners = m_vctActionListeners.elements(); listeners.hasMoreElements(); )
        {
            listener = (ActionListener) listeners.nextElement();
            listener.actionPerformed( new ActionEvent (this, m_nPercentComplete, "codeinjector", cmd ) );
        }
    }

    public int ProgramLength ( String file )
    {
        readCode(file);
        return (length+15)>>4;
    }

    public int PacketsReceived ( )
    {
        int count = 0;
        for (int i =0; i < ((length+15)>>4); i++)
        {
	    if (packets_received[i]) { count++; }
        }

        return count;
    }

    public static class CICommand
    {
        public int          m_arg             = -1;
        public int          m_cmd           = NEXT_CMD_ID;
        public Vector       m_vctNodes      = new Vector ( );
        public String       m_strFile       = "";

        public CICommand ( Vector nodes, String file, int cmd, int arg )
        {
            m_arg       = arg;
            m_strFile   = file;
            m_vctNodes  = nodes;
            m_cmd       = cmd;
        }
    }
}