/*
 * AbstractNetworkComponent.java
 *
 * Created on 15. Februar 2005, 16:21
 */

package de.tub.eyes.components;

/**
 *
 * @author develop
 */
public abstract class AbstractNetworkComponent extends AbstractComponent {
        
    public abstract void fireAddToFilter(int id); 
    public abstract void fireRemoveFromFilter(int id);     
    
}
