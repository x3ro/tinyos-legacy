/*
 * SubscriptionReceiver.java
 *
 * Created on 19. Februar 2005, 20:00
 */

package de.tub.eyes.comm;

/**
 *
 * @author develop
 */
public interface SubscriptionListener {
    public void subscribeSeq(int seqNo);
    public void unsubscribeSeq(int seqNo);
}
