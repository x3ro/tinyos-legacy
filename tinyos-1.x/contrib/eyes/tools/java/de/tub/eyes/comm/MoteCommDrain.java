/*
 * RecvDrain.java
 *
 * Created on 25. August 2005, 15:48
 */

package de.tub.eyes.comm;

import net.tinyos.drain.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

import java.util.*;

import de.tub.eyes.apps.demonstrator.Snapshot;
import de.tub.eyes.apps.demonstrator.Demonstrator;

/**
 *
 * @author Till Wimmer
 */
public class MoteCommDrain implements MessageListener, MoteComm {      
    // initial beacon frequency (before any notifications have been received)
    private static int DRAIN_INIT_BEACON_FREQUENCY;
    
    // beacon frequency (one or more notifications have been received, e.g. decrease the frequency)   
    private static int DRAIN_DEFAULT_BEACON_FREQUENCY;
    
    private static Drain drain=null;
    private static MoteIF moteIF=null;
    private static String hostName=null;
    private static int port=-1;
    private static int subscriberID=-1;    
    private static Vector listeners = new Vector();
    private final static int MAX_RETRY = 5;
    private static int retry_cnt = 0;
    private final static int RETRY_SLEEP = 5000; //ms
    private static Properties props = null;
    
    /** Creates a new instance of RecvDrain */
    public MoteCommDrain(int subscriberID) {
        this.subscriberID = subscriberID;
        
        if (props == null) {
            props = Demonstrator.getProps();
            DRAIN_INIT_BEACON_FREQUENCY = Integer.parseInt(props.getProperty("drainInitBeaconFrequency", "3"));
            DRAIN_DEFAULT_BEACON_FREQUENCY = Integer.parseInt(props.getProperty("drainDefaultBeaconFrequency", "10"));
        }
        
        if (moteIF == null) {
            moteIF = DrainLib.startMoteIF();            
            moteIF.registerListener(new DrainMsg(), this);                        
        }
        
        if (drain == null)
            createDrain();
    }
    
    public MoteCommDrain(String hostName, int port, int subscriberID) {
        this.hostName = hostName;
        this.port = port;
        this.subscriberID = subscriberID;

        if (props == null) {
            props = Demonstrator.getProps();
            DRAIN_INIT_BEACON_FREQUENCY = Integer.parseInt(props.getProperty("drainInitBeaconFrequency", "3"));
            DRAIN_DEFAULT_BEACON_FREQUENCY = Integer.parseInt(props.getProperty("drainDefaultBeaconFrequency", "10"));
        }
        
        if (moteIF == null) {
            createComm();
            moteIF.registerListener(new DrainMsg(), this);
        }
        
        if (drain == null)
            createDrain();
    }
    
    public void retry() {
        createComm();
        moteIF.registerListener(new DrainMsg(), this);           
    }

    /**
     * Creates a new MoteIF Object. In here the fixation at SerialForwarder@localhost:9001 is made.
     * Maybe this should be externalized to a properties file.
     *
     */
    private void createComm() {


        PhoenixSource source = BuildSource.makePhoenix(
                BuildSource.makeSF(hostName, port), 
                net.tinyos.util.PrintStreamMessenger.err
                );
        
        source.setPacketErrorHandler(new PhoenixError ( ) {
                    public void error(java.io.IOException e) {
                        if (retry_cnt > MAX_RETRY) {
                            System.err.println("PhoenixError! - Store Snapshot and exit!");
                            Snapshot.fireSnapshot(Snapshot.SNAPSHOT_EMERGENCY);
                            System.exit(2);
                        }
                        else
                        {
                            retry_cnt++;
                            try { 
                                Thread.sleep(RETRY_SLEEP); 
                            } catch (Exception interrupt) {
                                Snapshot.fireSnapshot(Snapshot.SNAPSHOT_EMERGENCY);
                                System.exit(2);                                
                            }
                            retry();
                                
                        }
                    };
                });
                
            try {

                moteIF = new MoteIF(source);
                moteIF.start();

            } catch (Exception e) {
                System.err.println("createComm: ");
                e.printStackTrace();
            }
    }
    
    private void createDrain() {            
        drain = new Drain(subscriberID, moteIF);
        drain.forever = true;
        System.out.println("DRAIN_INIT_BEACON_FREQUENCY=" + DRAIN_INIT_BEACON_FREQUENCY);
        drain.buildTree(DRAIN_INIT_BEACON_FREQUENCY);
        drain.maintainTree();        
    }
    
    public void messageReceived(int to, Message m) {
        if (drain == null)
            return;
        System.out.println("DRAIN_DEFAULT_BEACON_FREQUENCY=" + DRAIN_DEFAULT_BEACON_FREQUENCY);                
        drain.delay = DRAIN_DEFAULT_BEACON_FREQUENCY;

        for (Iterator it=listeners.iterator(); it.hasNext(); ) {
            ((MessageReceiver)it.next()).receiveMessage(m);
        }
    }
    
    public void addListener(MessageReceiver listener) {
        listeners.addElement(listener);
    }
    
    public void send(Message m, int to) {
        try {        
            moteIF.send(to, m);           
        } catch (java.io.IOException e) {        
            e.printStackTrace();
        }        
    }
    
    public MoteIF getMoteIF() {
        return moteIF;
    }    
}
