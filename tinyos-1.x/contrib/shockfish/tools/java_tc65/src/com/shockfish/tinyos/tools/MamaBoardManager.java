package com.shockfish.tinyos.tools;
import com.shockfish.tinyos.packet.CldcPacketizer;
import com.shockfish.tinyos.bridge.CldcBridgeThread;
import com.shockfish.tinyos.bridge.CldcBridgeMasterThread;
import com.shockfish.tinyos.util.ToolBox;
import com.shockfish.tinyos.packet.Tc65SerialByteSource;

public abstract class MamaBoardManager extends Tc65Manager {

	// MamaBoard-specific code (LEDs, reset)
	public static final int MAMABOARD_GPIO_LED = 0;

	public static final int MAMABOARD_GPIO_NRESET = 3;

	
	public static CldcPacketizer serialAsc0Packetizer;
    public static Tc65SerialByteSource serialAsc0ByteSource;
    
    
	public abstract void enterBridgeMode();
    public abstract void leaveBridgeMode();
	
    private CldcBridgeMasterThread bridge;
    
	public MamaBoardManager() {
		super();
		initGpio();
        initSerialAsc0Packetizer();
	}

	private void initGpio() {

		// open driver
		sendAT("at^spio=1", "OK");
		sendAT("at^scpin=1," + MAMABOARD_GPIO_LED + ",1,0", "OK");
		sendAT("at^scpin=1," + MAMABOARD_GPIO_NRESET + ",1,0", "OK");
		// turn the led off
		setPinOut(MAMABOARD_GPIO_LED, 0);
		blinkLed(3, 200);
		// dont close, for now
	}

	private void setPinOut(int pin, int value) {
		sendAT("at^ssio=" + pin + "," + value, "OK");
	}

	public void blinkLed(int repeats, int duration) {
		for (int i = 0; i < repeats; i++) {
			setPinOut(MAMABOARD_GPIO_LED, 0);
			try {
				Thread.sleep(duration);
			} catch (InterruptedException ie) {
			}
			setPinOut(MAMABOARD_GPIO_LED, 1);
			try {
				Thread.sleep(duration);
			} catch (InterruptedException ie) {
			}
		}
		setPinOut(MAMABOARD_GPIO_LED, 0);
	}

	public void resetTinyNode() {
		setPinOut(MAMABOARD_GPIO_NRESET, 0);
        try {
            Thread.sleep(400);
        } catch (InterruptedException ie) {}
        setPinOut(MAMABOARD_GPIO_NRESET, 1);
	}

    private void initSerialAsc0Packetizer() {
        this.serialAsc0ByteSource = new Tc65SerialByteSource("SERIAL", 0);
        this.serialAsc0Packetizer = new CldcPacketizer("SERIAL",this.serialAsc0ByteSource, 0); // 0 is tinynode
    }
    
	protected void defaultCommandHandler(String command, String args) {
		if (command.startsWith("SET")) {
			String prop = command.substring(3);
			setProp(prop, args);
			return;
		}
		
		if (command.equals("RESETMODULE")) {
			resetModule();
			return;
		}
        
        if (command.equals("RESETBASESTATION")) {
            resetTinyNode();
            return;
        }
        
		if (command.equals("STARTBRIDGE")) {
            int port;
            String[] hostport = ToolBox.split(args,';');
            if (hostport == null) { 
                return;
            }
            try {
                port = Integer.parseInt(hostport[1]);
            } catch (NumberFormatException nfe) {
                return;
            }
            startBridge(hostport[0], port);
			return;
		}	
        
        if (command.equals("STOPBRIDGE")) {
            stopBridge();
            return;
        }
        
		if (command.equals("SENDSTATUSSMS")) {
			sendSms(args, getTc65Status());
			return;
		}
	}
	
	public void startBridge(String host, int port) {
		// beware : the node needs to be restarted after this operation.
        
        // if the bridge object exists, check if it is running!
        // TODO
        
		enterBridgeMode();
		bridge = new CldcBridgeMasterThread(this, host, port);
		bridge.start();
	}
    
    public void stopBridge() {
        if (bridge == null)
            return;
        bridge.requestStop();
    }
	
}
