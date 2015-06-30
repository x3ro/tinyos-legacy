/*
 * MoteComm.java
 *
 * Created on 7. Februar 2005, 19:10
 */

package de.tub.eyes.comm;

import net.tinyos.message.*;

public interface MoteComm {
    public void send(Message m, int to);
    public void addListener(MessageReceiver receiver);
    public MoteIF getMoteIF();
    
}