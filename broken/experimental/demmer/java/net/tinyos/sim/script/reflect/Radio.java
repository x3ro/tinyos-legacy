
package net.tinyos.sim.script.reflect;

import net.tinyos.sim.SimDriver;
import net.tinyos.sim.SimState;
import net.tinyos.sim.script.ScriptInterpreter;
import net.tinyos.sim.plugins.RadioModelPlugin;

import org.python.core.*;

public class Radio extends SimReflect {
  protected RadioModelPlugin radioModel;
  protected SimState state;
  
  public Radio(ScriptInterpreter interp, SimDriver driver) {
    super(interp, driver);
    this.radioModel = driver.getRadioModel();
    this.state = driver.getSimState();
  }

  public String getCurModel() {
    return radioModel.getCurModel().toString();
  }

  public void setCurModel(String modelname) {
    radioModel.setCurModel(modelname);
  }

  public void setScalingFactor(double scalingFactor) {
    radioModel.setScalingFactor(scalingFactor);
  }

  public double getLossRate(int senderID, int receiverID) {
    try {
      return radioModel.getLossRate(senderID, receiverID);
    } catch (ArrayIndexOutOfBoundsException e) {
      throw Py.IndexError(e.getMessage());
    }
  }

  public void setLossRate(int senderID, int receiverID, double prob) {
    radioModel.setLossRate(senderID, receiverID, prob);
  }
  
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

  public void setAutoPublish(boolean autoPublish) {
    radioModel.setAutoPublish(autoPublish);
  }
  
  public void updateModel() {
    radioModel.updateModel();
  }

  public void publishModel() {
    radioModel.publishModel();
  }
}
  
