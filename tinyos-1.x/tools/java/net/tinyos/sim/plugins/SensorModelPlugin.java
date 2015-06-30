// $Id: SensorModelPlugin.java,v 1.1 2004/04/14 18:24:30 mikedemmer Exp $

/*									tab:2
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
 * DASENSORES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DASENSORE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Michael Demmer
 * Date:        March 4 2004
 * Desc:        plugin to model sensor values
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim.plugins;

import java.util.*;
import java.io.*;

import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

/**
 * Keep track of sensor values on registered sensory fields in the
 * presence of mote and other object movement.
 */
public class SensorModelPlugin extends Plugin implements SimConst {
  private static SimDebug debug = SimDebug.get("sensor");

  private Hashtable fields;
  private Hashtable models;
  
  public Enumeration getModels() {
    return models.elements();
  }

  public void addModel(String name, SensorModel model) {
    models.put(name, model);
  }

  public SensorModel getModel(String name) {
    return (SensorModel)models.get(name);
  }

  public SensorField getField(String field) {
    return (SensorField)fields.get(field);
  }

  public void addField(String fieldName, short adcPort, String modelName) {
    SensorModel model = (SensorModel)models.get(modelName);
    if (model == null) {
      throw new RuntimeException("no sensor model " + modelName);
    }

    SensorField field = new SensorField(fieldName, adcPort, model);
    fields.put(fieldName, field);

    Iterator it = state.getSimObjects().iterator();
    while (it.hasNext()) {
      SimObject obj = (SimObject)it.next();
      if (obj.getAttribute(fieldName) != null) {
        field.addSensableObject(obj);
      }
    }

    field.updateValues();
  }

  public void removeField(String fieldName) {
    fields.remove(fieldName);
  }

  public void handleEvent(SimEvent event) {
    if (event instanceof SimObjectEvent) {
      SimObjectEvent simObjectEvent = (SimObjectEvent)event;
      SimObject simObject = simObjectEvent.getSimObject();
      switch (simObjectEvent.getType()) {
        case SimObjectEvent.OBJECT_ADDED:
          // don't do anything on addition, we check for attribute
          // changes below.
          break;
          
        case SimObjectEvent.OBJECT_REMOVED:
          debug.err.println("SENSOR: sim object removed, updating values");

          Enumeration en = fields.elements();
          while (en.hasMoreElements()) {
            SensorField field = (SensorField)en.nextElement();
            field.removeSensableObject(simObject);
            field.updateValues();
          }
	  break;
      }
    }
    
    else if (event instanceof AttributeEvent) {
      AttributeEvent attrEvent = (AttributeEvent)event;
      SimObject obj = (SimObject)attrEvent.getOwner();
      
      switch (attrEvent.getType()) {
      case ATTRIBUTE_CHANGED:
	if (attrEvent.getAttribute() instanceof SensorAttribute) {
          
          // If a sensor attribute changed, update the corresponding field
          SensorAttribute attribute = (SensorAttribute)attrEvent.getAttribute();
          String fieldName = attribute.getField();
          debug.err.println("SENSOR: sensor "+fieldName+" changed, updating values");

          SensorField field = (SensorField)fields.get(fieldName);
          if (field == null) break;

          field.addSensableObject(obj);
          field.updateValues();
          break;
          
        } else if (attrEvent.getAttribute() instanceof CoordinateAttribute) {
          Enumeration en = fields.keys();
          while (en.hasMoreElements()) {
            String fieldName = (String)en.nextElement();
            SensorField field = (SensorField)fields.get(fieldName);
            if (field == null) continue;

            // If an object that has a corresponding sensor attributes
            // moved, need to update all the motes in the field
            
            if (obj.getAttribute(fieldName) != null) {
              debug.err.println("SENSOR: sensable object in field "+fieldName+
                                " moved, updating all values");
              field.updateValues();
            }
            
            // Otherwise if it's a mote that moved, update it
            else if (obj instanceof MoteSimObject) {
              MoteSimObject mote = (MoteSimObject)obj;
              debug.err.println("SENSOR: mote "+mote+
                                " moved, updating value in field"+fieldName);
              field.updateValue(mote);
            }
          }
        }
        break;
      }
    }
  }

  public void register() {
    debug.out.println("SENSOR: registering sensor plugin");

    models = new Hashtable();
    fields = new Hashtable();
    
    LinearSensorModel lm;
    lm = new LinearSensorModel(2.0, 10.0);
    models.put("linear10", lm);
    lm = new LinearSensorModel(2.0, 50.0);
    models.put("linear50", lm);
    lm = new LinearSensorModel(2.0, 100.0);
    models.put("linear100", lm);
    
    DiscSensorModel dm;
    dm = new DiscSensorModel(10.0);
    models.put("disc10", dm);
    dm = new DiscSensorModel(50.0);
    models.put("disc50", dm);
    dm = new DiscSensorModel(100.0);
    models.put("disc100", dm);
  }

  public void deregister() {}
  
  public String toString() {
    return "SensorPlugin";
  }

  /**
   * A particular field of sensor reading (i.e. light, magnetism, etc)
   * is managed by a SensorField instance. It keeps track of SimObject
   * instances that have an attribute corresponding to the sensory
   * field name and calls into the sensor model to calculate the new
   * value.
   */
  class SensorField {
    private String fieldName;
    private short adcPort;
    private SensorModel model;
    private HashSet sensableObjects;

    public SensorField(String fieldName, short adcPort, SensorModel model) {
      this.fieldName = fieldName;
      this.adcPort = adcPort;
      this.model = model;

      this.sensableObjects = new HashSet();
    }

    public void addSensableObject(SimObject obj) {
      sensableObjects.add(obj);
    }      
      
    public void removeSensableObject(SimObject obj) {
      sensableObjects.remove(obj);
    }      
    
    public void updateValue(MoteSimObject mote) {
      int value = model.getValue(mote, fieldName, sensableObjects);
      int moteID = mote.getID();
      
      debug.err.println("SENSOR ("+fieldName+"): mote["+moteID+"] value "+value);
      
      try {
        simComm.sendCommand(new SetADCPortValueCommand((short)moteID, 0L, adcPort, value));
      } catch (IOException e) {
        System.err.println("SENSOR: Cannot send command: "+e);
      }
    }
    
    // Loop through all the motes and recalculate the sensor values
    public void updateValues() {
      Iterator it = state.getMoteSimObjects().iterator();
      while (it.hasNext()) {
        updateValue((MoteSimObject)it.next());
      }
    }
  }
}
