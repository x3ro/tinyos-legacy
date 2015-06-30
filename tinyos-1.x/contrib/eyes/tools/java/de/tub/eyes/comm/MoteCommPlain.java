/*
 * MoteCommPlain.java
 *
 * Created on 1. September 2005, 19:15
 */

package de.tub.eyes.comm;

import java.util.*;

import net.tinyos.message.*;
import net.tinyos.packet.BuildSource;

import de.tub.eyes.*;

/**
 *
 * @author Till Wimmer
 */
public class MoteCommPlain implements MessageListener, MoteComm {
 
    private static MoteIF moteIF = null;
    private Vector listeners = new Vector();
    private static String hostName;
    private static int port;
    private static String className;
    
    /** Creates a new instance of MoteComm */
    public MoteCommPlain(String hostName, int port, String className) {
        this.hostName = hostName;
        this.port = port;
        this.className = className;
        
        if (moteIF == null) {
            createComm();
            registerListener();
        }        
    }
    
    public void send(Message m, int to) {
        try {                
            moteIF.send(to, m);
        } catch (java.io.IOException e) {         
            e.printStackTrace();
        }
    }
 
    /**
     * Creates a new MoteIF Object. In here the fixation at SerialForwarder@localhost:9001 is made.
     * Maybe this should be externalized to a properties file.
     *
     */
    public void createComm() {

            try {
                moteIF = new MoteIF(BuildSource.makePhoenix(BuildSource.makeSF(
                        hostName, 
                        port),
                        net.tinyos.util.PrintStreamMessenger.err));
                moteIF.start();

            } catch (Exception e) {
                System.err.println("createComm: ");
                e.printStackTrace();
            }
    }
    
    private void registerListener() {
        Message msg = null;
        
        try {
            Class clazz = Class.forName(className);
            msg = (Message) clazz.newInstance();            
        } catch (Exception e) {
            e.printStackTrace();
            return;
        } 
        
        moteIF.registerListener(msg, this);
    }
    
    
    /**
     * Adds the given <code>MessageReceiver</code> as a receiver for the messages specified by
     * <code>messageClassName</code>. That means the Demonstrator registers for the given message
     * (identified by its FQCN) at the MoteIF (if it hasn't done before) and adds the MessageReceiver
     * to the List of message receivers. <br>
     * Important for this mechanism is that the messages passed in by their name need to have a no-argument
     * constructor, so Demonstrator can create an instance via Reflection.
     * @param messageClassName The fully qualified name of the Message class
     * @param receiver The class that should be informed of reveived messages.
     */
    public void addListener(MessageReceiver receiver) {
        listeners.addElement(receiver);
     
    } 
    
    public void messageReceived(int to, Message m) {


        for (Iterator it=listeners.iterator(); it.hasNext(); ) {
            ((MessageReceiver)it.next()).receiveMessage(m);
        }
    }    

    public MoteIF getMoteIF() {
        return moteIF;
    }
}
