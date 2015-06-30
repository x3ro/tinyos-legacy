/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/**
 * FILE NAME
 *
 *     MoteMessageMBean.java
 *
 * DESCRIPTION
 *
 * This is the management interface explicitly defined for the "MoteMessage" standard MBean.
 * The "MoteMessage" standard MBean implements this interface 
 * in order to be manageable through a JMX agent.
 *
 * The "MoteMessageMBean" interface expose for management:
 * - a read/write attribute (named "message") through its getter and setter methods,
 * - an operation named "printMoteMessage",
 * - an operation named "start",
 * - an operation named "stop",
 * - an operation named "run",
 *
 * Author :  Mark E. Miyashita  -  Kent State Univerisity
 *
 * Modification history:
 *
 * 04/18/2003 Mark E. Miyashita - Created the intial interface
 * 05/03/2003 Mark E. Miyashita - Added two new methods to handle socket
 *
 */
public interface MoteMessageMBean
{
 /** 
  * Setter: set the "message" attribute of the "MoteMessage" MBean.
  *
  * @param <VAR>s</VAR> the new value of the "message" attribute.
  */
  public void setMoteDisplayMessage( String message );
 /**
  * Getter: set the "message" attribute of the "MoteMessage" MBean.
  *
  * @return the current value of the "message" attribute.
  */
  public String getMoteDisplayMessage();
 /**
  * Operation: print the current values of "message" attributes of the 
  * "MoteMessage" MBean.
  */
  public void printMoteDisplayMessage();
 /**
  * Operation: read the mote message from the file 
  */
  public void start();
 /**
  * Operation: stop the thread 
  */
  public void stop();
 /**
  * Operation: run the thread 
  */
  public void run();
}

