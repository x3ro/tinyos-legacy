// $Id: Sensor.java,v 1.1 2004/04/14 18:30:32 mikedemmer Exp $

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
 * Date:        March 8, 2004
 * Desc:        Reflected Sensor model object
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim.script.reflect;

import net.tinyos.sim.SimDriver;
import net.tinyos.sim.SimState;
import net.tinyos.sim.PluginManager;
import net.tinyos.sim.SensorModel;
import net.tinyos.sim.script.ScriptInterpreter;
import net.tinyos.sim.plugins.SensorModelPlugin;

import org.python.core.*;

/**
 * Interface class to the sensor model.<p>
 *
 * The class is bound into the simcore module as the <i>sensor</i>
 * global instance.
 */
public class Sensor extends SimReflect {
  protected SensorModelPlugin sensorModel;
  
  public Sensor(ScriptInterpreter interp, SimDriver driver) {
    super(interp, driver);
    this.sensorModel = null;
  }

  /**
   * Enable the sensor model. Note that this must be called before any
   * other operations as it is required to load the plugin into the
   * simulator.
   */
  protected void enable() {
    if (sensorModel != null)
      return;
    
    PluginManager pm = driver.getPluginManager();
    sensorModel = (SensorModelPlugin)pm.getPlugin("SensorModelPlugin");
    pm.register(sensorModel);
  }

  /**
   * Add a new sensor model to the set of options.
   *
   * @param name	the name of the sensor model
   * @param model	the model subclass to use
   */
  public void addModel(String name, SensorModel model) {
    enable();
    sensorModel.addModel(name, model);
  }

  /**
   * Add a new sensor field to the model.
   *
   * @param fieldName	sensor field name, e.g. "magnetism"
   * @param adcPort	ADC port value
   * @param modelName	name of the sensor model to use e.g. "linear10"
   */
  public void addField(String fieldName, short adcPort, String modelName) {
    enable();
    sensorModel.addField(fieldName, adcPort, modelName);
  }

  /**
   * Add a new sensor field to the model.
   *
   * @param fieldName	sensor field name
   */
  public void removeField(String fieldName) {
    enable();
    sensorModel.removeField(fieldName);
  }
}

  
