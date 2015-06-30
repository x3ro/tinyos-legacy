package com.shockfish.tinyos.apps.demo;

/**
 * @author Pierre Metrailler, Shockfish SA
 */

import javax.microedition.midlet.MIDlet;
import javax.microedition.midlet.MIDletStateChangeException;

public class MamaBoardDemo extends MIDlet {
    
    private static MamaBoardDemoManager mbdm;

    public MamaBoardDemo() { }

    public void startApp() throws MIDletStateChangeException {
        try {
            mbdm = new MamaBoardDemoManager();            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void pauseApp() { }

    public void destroyApp(boolean cond) {
        notifyDestroyed();
    }

}

