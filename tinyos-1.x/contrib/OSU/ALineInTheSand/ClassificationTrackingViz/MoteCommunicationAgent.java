/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/*
*
*   FILE NAME
*
*        MoteCommunicationAgent.java
*
*   DESCRIPTION
*
*   This class implements the JMX server and agent.  Addes two MBeans, namely, Motelocation
*  and MoteMessage.  The first MBean, MoteLocation, will generate coordinates of all motes
*  in the simulation and pass the resulting vector to the GraphicsPanel for display.  The
*  second MBean, MoteMessage implemented as independent thread, will pass the information
*  regarding mote reading and target reading to the GraphicsPanel for display.  All 
*  notification methods are simple feedback of event of interest.  Each notifications are
*  registered with specific name and will be handled in the class file.  The notification will
*  be fired from the each individual MBean and handled in this class.
*
*  Author : Adnan Vora  -  Kent State University
*
*  Modification history
*
*  4/19/2003  Mark E. Miyashita - Created intial Java class
*  4/20/2003  Mark E. Miyashita - Updated message display format to use toString method of
*                                 object defined in both MoteReading and MoteProperty
*  4/20/2003  Mark E. Miyashita - Added new MBean and method FieldSize
*  4/22/2003  Mark E. Miyashita - Added new MBean and method LoadBaseStation
*  6/05/2003  Mark E. Miyashita - Added "readScale" notification handle
*
*/


// RI imports

import javax.management.*;

// Java imports

import java.util.*;

public class MoteCommunicationAgent implements NotificationListener
{
  private MBeanServer mbs = null;                  /* MBean server */
  private MoteLocation ML;                         /* Mote Location object */
  private MoteMessage MM;                          /* Mote Message object */
  private FieldSize MS;                            /* Mote Field object */
  private BaseStation BS;                          /* Base Station object */
  private ObjectName mbeanObjectName = null;
  private ObjectName mbeanObjectName1 = null;  
  private ObjectName mbeanObjectName2 = null; 
  private ObjectName mbeanObjectName3 = null;         
  private String domain = null;                    /* domain of running object */
  private String mbeanName = "MoteLocation";       /* Managed bean name */
  private String mbeanName1 = "MoteMessage";       /* Managed bean name */
  private String mbeanName2 = "MoteField";         /* Managed bean name */
  private String mbeanName3 = "BaseStationMote";   /* Managed bean name */
  private Vector vctMotes  = new Vector();         /* Vector of Motes */
  private Field vFieldSize;                        /* Field size of simulation */
  private Scale vScale;                            /* Scale information */
  private BaseStationMote vBaseStationMote;        /* Base Station mote information */
  protected DisplayPanel dpanel;                   /* Pointer to Display panel */
  protected GraphicsPanel gpanel;                  /* Graphics panel with Topology */
  protected String newline ="\n";                  /* constant denoting new line */
  private TargetProperty target;                   /* target property object */
  private MIRProperty mir; /* mir property object */
  private MoteReading reading;                     /* mote reading object */

  public MoteCommunicationAgent(DisplayPanel dp, GraphicsPanel gp)
  {
    // Create the MBeanServer
    dpanel = dp;
    gpanel = gp;
    mbs = MBeanServerFactory.createMBeanServer();
    ML = new MoteLocation();
    MM = new MoteMessage();
    MS = new FieldSize();
    BS = new BaseStation();
    domain = mbs.getDefaultDomain();
    LoadFieldSize();
    LoadBaseStation();
    LoadMoteLocation();
    RegisterMoteMessage();
  }

  public void handleNotification( Notification notif, Object handback )
  {
    dpanel.displayMsg( "Receiving notification... "  );
    if ( notif.getType() == "readMoteLocation" ) {
      dpanel.displayMsg( notif.getMessage() + newline );
      vctMotes = (Vector) notif.getUserData();
    }  else if ( notif.getType() == "readTargetMessage" ) {
        dpanel.displayMsg( notif.getMessage() + newline );
        target = (TargetProperty) notif.getUserData();
        gpanel.surf.CopyTargetProperty(target);
        dpanel.displayMsg("Target Message: " + target.toString() + newline );
    }  else if ( notif.getType() == "readMirMessage" ) {
        dpanel.displayMsg( notif.getMessage() + newline );
        mir = (MIRProperty) notif.getUserData();
        gpanel.surf.CopyMIRMessage(mir);
        System.out.println("Received MIR Message");
        dpanel.displayMsg("MIR Message: " + mir.toString() + newline );
    } else if ( notif.getType() == "readMoteMessage" ) {
        dpanel.displayMsg( notif.getMessage() + newline );
        reading = (MoteReading) notif.getUserData();
        gpanel.surf.CopyMoteReading(reading);
        dpanel.displayMsg("Mote Message: " + reading.toString() + newline );
    }  else if ( notif.getType() == "readFieldSize" ) {
        dpanel.displayMsg( notif.getMessage() + newline );
        vFieldSize = (Field) notif.getUserData();
        dpanel.displayMsg(vFieldSize.toString() + newline );
    }  else if ( notif.getType() == "readBaseStation" ) {
        dpanel.displayMsg( notif.getMessage() + newline );
        vBaseStationMote = (BaseStationMote) notif.getUserData();
        dpanel.displayMsg(vBaseStationMote.toString() + newline );
    }  else if ( notif.getType() == "readScale" ) {
        dpanel.displayMsg( notif.getMessage() + newline );
        vScale = (Scale) notif.getUserData();
        gpanel.surf.CopyScale(vScale);
        dpanel.displayMsg(vScale.toString() + newline );
    }  else 
        dpanel.displayMsg( notif.getMessage() + newline );
    
  }

  private void RegisterMoteMessage()
  {
    try
    {
      // build the MBean ObjectName
      mbeanObjectName1 = new ObjectName( domain + ":name=" + mbeanName1 );
      // register Mbean ObejctName
      mbs.registerMBean( MM, mbeanObjectName1 );
      // add notification Listener
      MM.addNotificationListener( this, null, null );
    String message = (String) mbs.getAttribute(mbeanObjectName1,"MoteDisplayMessage");
    dpanel.displayMsg( message + newline );
    }
    catch( Exception e )
    {
      e.printStackTrace();
    }
  }

  private void LoadFieldSize()
  {
    try
    {
      // build the MBean ObjectName
      mbeanObjectName2 = new ObjectName( domain + ":name=" + mbeanName2 );
      // register Mbean ObejctName
      mbs.registerMBean( MS, mbeanObjectName2 );
      // add notification Listener
      MS.addNotificationListener( this, null, null );
    }
    catch( Exception e )
    {
      e.printStackTrace();
    }

    try
    {
    String message = (String) mbs.getAttribute(mbeanObjectName2,"DisplayMessage");
    dpanel.displayMsg( message + newline );
    mbs.invoke(mbeanObjectName2,"LoadFieldSize",null,null);

    }
    catch ( Exception e )
    {
      e.printStackTrace();
    }

  }

  private void LoadMoteLocation()
  {
    try
    {
      // build the MBean ObjectName
      mbeanObjectName = new ObjectName( domain + ":name=" + mbeanName );
      // register Mbean ObejctName
      mbs.registerMBean( ML, mbeanObjectName );
      // add notification Listener
      ML.addNotificationListener( this, null, null );
    }
    catch( Exception e )
    {
      e.printStackTrace();
    }

    try
    {
    String message = (String) mbs.getAttribute(mbeanObjectName,"DisplayMessage");
    dpanel.displayMsg( message + newline );
    mbs.invoke(mbeanObjectName,"readMoteLocation",null,null);

    }
    catch ( Exception e )
    {
      e.printStackTrace();
    }

  }

  private void LoadBaseStation()
  {
    try
    {
      // build the MBean ObjectName
      mbeanObjectName3 = new ObjectName( domain + ":name=" + mbeanName3 );
      // register Mbean ObejctName
      mbs.registerMBean( BS, mbeanObjectName3 );
      // add notification Listener
      BS.addNotificationListener( this, null, null );
    }
    catch( Exception e )
    {
      e.printStackTrace();
    }

    try
    {
    String message = (String) mbs.getAttribute(mbeanObjectName3,"DisplayMessage");
    dpanel.displayMsg( message + newline );
    mbs.invoke(mbeanObjectName3,"readBaseStation",null,null);

    }
    catch ( Exception e )
    {
      e.printStackTrace();
    }

  }

  public void StartMoteMessageListener()
  {
    try
    {
     mbs.invoke(mbeanObjectName1,"start",null,null);
     Attribute messageAttribute = new Attribute("MoteDisplayMessage","MoteMessage thread started");
     mbs.setAttribute(mbeanObjectName1, messageAttribute);

    }
    catch ( Exception e )
    {
      e.printStackTrace();
    }

  }

  public void StopMoteMessageListener()
  {
    try
    {
     Attribute messageAttribute = new Attribute("MoteDisplayMessage","MoteMessage thread stopped");
     mbs.setAttribute(mbeanObjectName1, messageAttribute);
     mbs.invoke(mbeanObjectName1,"stop",null,null);
    }
    catch ( Exception e )
    {
      e.printStackTrace();
    }

  }

  public void ClearMoteLocation()
  {
    try
    {
     mbs.invoke(mbeanObjectName,"clearMoteLocation",null,null);
     vctMotes.removeAllElements();
    }
    catch ( Exception e )
    {
      e.printStackTrace();
    }

  }

  public Vector getMoteLocation()
  {
     return vctMotes;
  }

  public BaseStationMote getBaseStation()
  {
     return vBaseStationMote;
  }

  public Field getFieldSize()
  {
     return vFieldSize;
  }

}

