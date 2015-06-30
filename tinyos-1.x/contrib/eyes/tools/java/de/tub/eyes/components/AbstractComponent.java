/*
 * Created on Sep 13, 2004 by jpraetorius
 * Project EYES Demonstrator
 *
 */
package de.tub.eyes.components;

import java.awt.Component;

import javax.swing.JToggleButton;

/**
 * <p>
 * This is the base Class of all Components that should be plugged into the
 * Demonstrator Class. The Demonstrator uses the two specified methods to get
 * the Components it needs to display the Component and to switch to it.
 * </p>
 * <p>
 * Sample implementations for this base Class can be found in the other classes
 * in this package.
 * </p>
 * 
 * @author Joachim Praetorius
 *  
 */
public abstract class AbstractComponent {
    /**
     * This method returns the Button which switches to the Component in the
     * view of the Demonstrator. The Button <b>must </b> have been given an
     * actionCommand via <code>setActionCommand(String)</code>, as the
     * Demonstrator relies on this String for bringing up the right Component,
     * when the button is clicked.
     * 
     * @return An instance of JToggleButton
     */
    public abstract JToggleButton getButton();

    /**
     * This method returns the {@link Component Component}that displays the
     * Components view. It is added to a card layout and shown when the
     * according button is clicked.
     * 
     * @return An instance of Component.
     */
    public abstract Component getUI();
}