// $Id: Radio.java,v 1.5 2004/06/14 21:30:36 mikedemmer Exp $

/*
 *
 *
 * "Copyright (c) 2004 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Michael Demmer
 * Date:        January 9, 2004
 * Desc:        Reflected Radio model object
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim.script.reflect;

import net.tinyos.sim.SimDriver;
import net.tinyos.sim.SimState;
import net.tinyos.sim.script.ScriptInterpreter;
import net.tinyos.sim.plugins.RadioModelPlugin;

import org.python.core.*;

/**
 * Interface class to the radio model.<p>
 *
 * The class is bound into the simcore module as the <i>radio</i>
 * global instance.
 */
public class Radio extends SimReflect {
  protected RadioModelPlugin radioModel;
  protected SimState state;
  
  public Radio(ScriptInterpreter interp, SimDriver driver) {
    super(interp, driver);
    this.radioModel = driver.getRadioModel();
    this.state = driver.getSimState();
  }

  /**
   * Return the name of the current radio model.
   */
  public String getCurModel() {
    return radioModel.getCurModel().toString();
  }

  /**
   * Set the radio model.
   *
   * @param modelname	the name of the new model (e.g. "empirical")
   */
  public void setCurModel(String modelname) {
    radioModel.setCurModel(modelname);
    radioModel.updateGUI();
  }

  /**
   * Return the radio model scaling factor.
   *
   * @return	the current scaling factor
   */
  public double getScalingFactor() {
    return radioModel.getScalingFactor();
  }
  
  /**
   * Set the radio model scaling factor.
   *
   * @param scalingFactor	the new scaling factor
   */
  public void setScalingFactor(double scalingFactor) {
    radioModel.setScalingFactor(scalingFactor);
    radioModel.updateGUI();
  }

  /**
   * Get the packet loss rate between two motes.
   *
   * @param senderID	id of the sender mote
   * @param receiverID	id of the receiver mote
   */
  public double getLossRate(int senderID, int receiverID) {
    try {
      return radioModel.getLossRate(senderID, receiverID);
    } catch (ArrayIndexOutOfBoundsException e) {
      throw Py.IndexError(e.getMessage());
    }
  }

  /**
   * Set the packet loss rate between two motes.
   *
   * @param senderID	id of the sender mote
   * @param receiverID	id of the receiver mote
   * @param prob	new loss probability
   */
  public void setLossRate(int senderID, int receiverID, double prob) {
    radioModel.setLossRate(senderID, receiverID, prob);
  }
  
  /**
   * Dump the current loss rate table to the console.
   */
  public void printLossRates() {
    int nmotes = state.numMoteSimObjects();
    for (int i = 0; i < nmotes; ++i) {
      for (int j = 0; j < nmotes; ++j) {
        if (i == j) continue;
        // there must be a better way to do this
        interp.exec("print '["+i+" -> "+j+"] "+getLossRate(i, j) +"'");
      }
    }
  }

  /**
   * Convert a requested packet loss probability into a bit error
   * rate, according to the current radio model.
   *
   * @param packetLoss	requested packet loss probability
   */
  public double packetLossToBitError(double packetLoss) {
    return radioModel.getCurModel().getBitLossRate(packetLoss);
  }

  /**
   * Convert a requested packet loss probability into a bit error
   * rate, according to the specified radio model.
   *
   * @param packetLoss	requested packet loss probability
   * @param model	name of the radio model to use
   */
  public double packetLossToBitError(double packetLoss, String model) {
    return radioModel.getModel(model).getBitLossRate(packetLoss);
  }

  /**
   * Convert a distance into a packet loss probability according to
   * the current radio model.
   *
   * @param distance	the distance between two motes
   */
  public double distanceToPacketLoss(double distance) {
    return radioModel.getCurModel().getPacketLossRate(distance, 1.0);
  }

  /**
   * Convert a distance into a packet loss probability according to
   * the specified radio model.
   *
   * @param distance	the distance between two motes
   * @param model	name of the radio model to use
   */
  public double distanceToPacketLoss(double distance, String model) {
    return radioModel.getModel(model).getPacketLossRate(distance, 1.0);
  }

  /**
   * Set the auto publish flag in the radio model. With this flag
   * enabled, all changes, either due to mote movement or due to
   * programmatic settings, are propagated to the simulator. When auto
   * publish is turned off, the updateModel() function must be called
   * to propagate settings from the simdriver to the simulator.
   *
   * @param autoPublish	value of the autoPublish feature
   */
  public void setAutoPublish(boolean autoPublish) {
    radioModel.setAutoPublish(autoPublish);
    radioModel.updateGUI();
  }

  /**
   * Forces a recalculation of the radio loss model by iterating over
   * all pairs of motes.
   */
  public void updateModel() {
    radioModel.updateModel();
  }

  /**
   * Publishes all the current radio model values to the simulator.
   * See setAutoPublish() for more information.
   */
  public void publishModel() {
    radioModel.publishModel();
  }

  /**
   * Disables the radio model plugin altogether.
   */
  public void disable() {
    radioModel.disable();
  }

  /**
   * Re-enables the radio model plugin.
   */
  public void enable() {
    radioModel.enable();
  }

}

  
