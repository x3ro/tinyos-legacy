// $Id: testReverseUART.java,v 1.1 2004/05/30 20:46:33 cssharp Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Send one or more a messages to the UART and wait for replies.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @since  0.1
 */

import net.tinyos.message.*;
import net.tinyos.util.*;

import java.io.*; 
import java.text.*;

public class testReverseUART implements MessageListener
{
  static final short TOS_UART_ADDR = 0x007e;
  private String m_strings[];
  private MoteIF m_moteif;
  private int m_nSend;

  testReverseUART( String[] args )
  {
    if( args.length <= 0 )
    {
      System.out.println("usage: testReverseUART [string]");
      System.exit(0);
    }

    try
    {
      m_moteif = new MoteIF((Messenger)null);
      m_moteif.registerListener(new ReverseUARTMsg(), this);
    }
    catch (Exception e)
    {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }

    m_strings = args;
    m_nSend = -1;
    m_moteif.start();

  }

  public synchronized void send( String str )
  {
    try
    {
      ReverseUARTMsg m = new ReverseUARTMsg();
      m.setString_str( str );
      m_moteif.send( MoteIF.TOS_BCAST_ADDR, m );
      System.out.println( "Send> " + m.getString_str() );
    }
    catch (IOException e)
    {
      e.printStackTrace();
      System.out.println("ERROR: Can't send message");
      System.exit(1);
    }
  }

  public boolean sendNextString()
  {
    if( ++m_nSend >= m_strings.length )
    {
      m_nSend = 0;
      return false;
    }

    send( m_strings[m_nSend] );
    return true;
  }

  synchronized public void messageReceived( int destAddr, Message m )
  {
    System.out.println( "Recv> " + ((ReverseUARTMsg)m).getString_str() );
    if( sendNextString() == false )
    {
      System.out.println("... done.");
      System.exit(0);
    }
  }

  public static void main(String[] args)
  {
    testReverseUART m = new testReverseUART( args );
    m.sendNextString();
  }
}

