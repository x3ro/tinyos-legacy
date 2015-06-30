package de.tub.eyes.comm;

import net.tinyos.message.Message;

/**
 * The {@link de.tub.eyes.Demonstrator Demonstrator} acts as connection Proxy to
 * TinyOS, so it receives Messages on behalf of Components that are plugged in
 * the Demonstrator. In order to receive Messages from the Demonstrator class,
 * the Components have to register themselves as <code>MessageListener</code>
 * at the Demonstrator via the
 * {@link de.tub.eyes.Demonstrator#addListener(String, MessageReceiver) addListener}
 * Method. So all components interested in interacting with the TinyOS network
 * have to implement this Interface. <br>
 * <b>Note:</b> The implementing components have to check the type of the incoming message,
 * as the Demonsrtator can not forward on specific Message subtypes, but forwards <i>all</i>
 * incoming messages to <i>all</i> registered Listeners, so a component might receive messages it
 * has not registered for.
 * 
 * @author Joachim Praetorius
 *  
 */
public interface MessageReceiver {
    
    /**
     * Notifies the Listener of a newly arrived Message.
     * @param m the new Message
     */
    public void receiveMessage(Message m);
}
