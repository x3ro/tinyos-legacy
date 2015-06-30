/*
 * Created on Sep 27, 2004 by Joachim PRaetorius
 * Project EYES Demonstrator
 *
 */
package de.tub.eyes.components;

/**
 * The idea behind the FilterView is the different view on Nodes. E.g. one may
 * have a graphic display of a network topology. In this topology he may choose
 * to inspect some nodes further which is done in other views on the nodes data.
 * These other views can be told via this interface, which data is intersting to
 * the user.
 *
 * @author Joachim Praetorius
 *
 */
public interface FilterView {

    /**
     * Adds the given Node id to the Filter, which results in the messages of this node being displayed.
     * So <emph>filter</emph> does <emph>not</emph> mean filter <emph>out</emph>.
     * @param id the id of the node, of which to show the messages
     */
    public void addToFilter(int id);

    /**
     * Removes the given Node id from the filter, so the messages are not displayed further.
     * @param id The id to remove
     */
    public void removeFromFilter(int id);

}
