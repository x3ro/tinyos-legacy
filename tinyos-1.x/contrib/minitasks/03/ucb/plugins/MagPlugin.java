/* "Copyright (c) 2000-2002 The Regents of the University of California.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 */

// Authors: Cory Sharp
// $Id: MagPlugin.java,v 1.3 2003/06/11 02:06:18 cssharp Exp $

import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

public class MagPlugin extends Plugin implements SimConst
{
  private static final int BROADCAST_ADDR = 0xffff;
  private static final String MagReadADCMsg = "(MAG READ ADC)";
  private static final String MagSetBiasMsg = "(MAG SET BIAS)";
  private static final short PORT_MAGX = 120;
  private static final short PORT_MAGY = 121;
  private static final short PORT_MAGZ = 122;
  MagneticEnvironment m_magEnv;
  IntVector m_biasX;
  IntVector m_biasY;
  IntVector m_biasZ;
  JTextArea m_ta;
  TextField m_tf[];

  public MagneticEnvironment getMagneticEnvironment()
  {
    return m_magEnv;
  }

  void motetf( MoteSimObject mote, Triple position, Triple mag )
  {
    int id = mote.getID();
    if( id < m_tf.length )
    {
      m_tf[id].setText( id + ": mx=" + mag.x + ", my=" + mag.y + ", mz=" + mag.z + ", x=" + position.x + ", y=" + position.y + ", z=" + position.z );
    }
  }

  public void handleEvent( SimEvent event )
  {
    if( event instanceof DebugMsgEvent )
    {
      try
      {
	DebugMsgEvent dme = (DebugMsgEvent)event;
	String msg = dme.getMessage();
	int id = dme.getMoteID();
	double time = dme.getTime() / 4e6;
	MoteSimObject mote = state.getMoteSimObject(id);

	if( msg.indexOf(MagReadADCMsg) != -1 )
	{
	  if( mote != null )
	  {
	    MoteCoordinateAttribute motepos = mote.getCoordinate();
	    Triple position = new Triple( motepos.getX(), motepos.getY(), 0 );
	    Triple mag = m_magEnv.measure( time, position );
	    m_ta.setText( "Time = " + time );
	    motetf( mote, position, mag );

	    if( msg.indexOf("[x]") != -1 )
	    {
	      int x = convertMagToADC( mag.x, m_biasX.get(id) );
	      simComm.sendCommand( new SetADCPortValueCommand( (short)id, (long)0, PORT_MAGX, x ) );
	    }

	    if( msg.indexOf("[y]") != -1 )
	    {
	      int y = convertMagToADC( mag.y, m_biasY.get(id) );
	      simComm.sendCommand( new SetADCPortValueCommand( (short)id, (long)0, PORT_MAGY, y ) );
	    }

	    if( msg.indexOf("[z]") != -1 )
	    {
	      int z = convertMagToADC( mag.z, m_biasZ.get(id) );
	      simComm.sendCommand( new SetADCPortValueCommand( (short)id, 0, PORT_MAGZ, z ) );
	    }
	  }
	}
	else if( msg.indexOf(MagSetBiasMsg) != -1 )
	{
	  int n;

	  if( (n = msg.indexOf("[x=")) != -1 )
	    m_biasX.set( id, parseIntTerm( msg, n+3, "]" ) );

	  if( (n = msg.indexOf("[y=")) != -1 )
	    m_biasY.set( id, parseIntTerm( msg, n+3, "]" ) );

	  if( (n = msg.indexOf("[z=")) != -1 )
	    m_biasZ.set( id, parseIntTerm( msg, n+3, "]" ) );
	}
      }
      catch( Exception e )
      {
	System.err.println( "ERROR in MagReadADCPlugin.handleEvent: " + e );
      }
    }
  }


  private int parseIntTerm( String str, int nBegin, String strEnd )
  {
    int nEnd = str.indexOf( strEnd, nBegin+1 );
    return ( nEnd != -1 )
         ? Integer.parseInt( str.substring( nBegin, nEnd ) )
         : Integer.parseInt( str.substring( nBegin ) );
  }


  static private int convertMagToADC( double magGauss, int bias )
  {
    // circuit constants
    double MagPower = 3.3; // volts
    double MagSensitivity = 0.001; // V/V/gauss
    double RBiasTop = 270e3; // ohms
    double RBiasPot = 100e3; // ohms
    double RBiasBot = 270e3; // ohms
    double RGA = 3300; // ohms
    double RGB = 330; // ohms
    double nADCOutMax = 1023; // digital value

    // circuit properties
    double OpAmpMin = 0.7; // volts
    double OpAmpMax = MagPower - 0.7; // Volts
    double GA = 5.0 + 80e3 / RGA; // gain stage A
    double GB = 5.0 + 80e3 / RGB; // gain stage B
    double RPot = RBiasPot * ((double)bias) / 255.0; // pot value

    // circuit voltages
    double VBias = MagPower * (RPot + RBiasBot) / (RBiasTop + RPot + RBiasBot); // volts
    double Vmag = MagSensitivity * MagPower * magGauss; // volts
    double VA = Vmag * GA + MagPower/2; // volts output stage A
    double VAClip = (VA<OpAmpMin) ? OpAmpMin : (VA>OpAmpMax) ? OpAmpMax : VA;
    double VB = (VAClip - VBias) * GB + MagPower/2; // volts output stage B
    double VBClip = (VB<OpAmpMin) ? OpAmpMin : (VB>OpAmpMax) ? OpAmpMax : VB;

    // ADC result
    double nADC = nADCOutMax * VBClip / MagPower; // digital value
    return (int)( nADC + 0.5 );
  }

  void registerMagneticDisturbances()
  {
    Plugin pp[] = tv.getPluginPanel().plugins();
    int n = 0;
    for( int i=0; i<pp.length; i++ )
    {
      if( pp[i] instanceof MagneticDisturbance )
      {
	m_magEnv.addDisturbance( (MagneticDisturbance)pp[i] );
	n++;
      }
    }
  }

  public void register()
  {
    m_ta = new JTextArea(3,40);
    m_ta.setFont(tv.defaultFont);
    m_ta.setEditable(false);
    m_ta.setBackground(Color.lightGray);
    m_ta.setLineWrap(true);
    m_ta.setText( "MagPlugin uses MagneticEnvironment to accumulate MagneticDisturbance's." );
    pluginPanel.add(m_ta);

    m_tf = new TextField[2];
    m_tf[0] = new TextField(60);
    m_tf[1] = new TextField(60);
    pluginPanel.add(m_tf[0]);
    pluginPanel.add(m_tf[1]);

    m_magEnv = new MagneticEnvironment();
    m_biasX = new IntVector();
    m_biasY = new IntVector();
    m_biasZ = new IntVector();
  }

  public void deregister()
  {
  }

  public void reset()
  {
    motePanel.refresh();
  }

  public void draw( Graphics g )
  {
  }

  public String toString()
  {
    return "Magnetic Environment";
  }
}

