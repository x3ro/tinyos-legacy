package edu.wustl.mobilab.agilla.plugins;

import limone.*;
import edu.wustl.mobilab.agilla.*;
import edu.wustl.mobilab.agilla.variables.*;
//import edu.wustl.mobilab.agilla.mads.LocationManager;
import edu.wustl.mobilab.agimone.*;
import edu.wustl.mobilab.agimone.util.*;

/**
 * A plugin that launches the Agimone service.
 * 
 * @author liang
 */
public class AgimonePlugin extends Plugin {
	
	AgimoneAgent agimoneAgent;
	
	/**
	 * A constructor without any additional arguments
	 * 
	 * @param injector The AgentInjector
	 */
	public AgimonePlugin(AgentInjector injector) {
		this(injector, new String[0]);
	}
	
	/**
	 * A constructor with additional arguments.
	 * 
	 * @param injector
	 * @param args
	 */
	public AgimonePlugin(AgentInjector injector, String[] args) { 
		// Prevent creation of new AgentInjector and give AgentInjector reference
		// to agimone.
		edu.wustl.mobilab.agimone.util.InjectorFactory.setInjector(injector);  

		String limone_port = "2200"; // The TCP port used by Limone.  Limone uses this and the next port.
		boolean limone_debug = false;
		try {
			for (int i = 0; i < args.length; i++) {
				if (args[i].equals("-agimone.name")) {
					String nwName = args[++i];
					if (nwName.length() > 3)
						throw new Exception("Invalid network name, length must be 3.");
					AgillaProperties.setNetworkName(nwName);
				}
				//else if (args[i].equals("-agilla.showAgentInjector"))
					//InjectorFactory.setShowInjectorGUI(true);
				//else if (args[i].equals("-agilla.port"))
					//InjectorFactory.setPort(args[++i]);
				else if (args[i].equals("-limone.debug"))
					limone_debug = true;
				else if (args[i].equals("-limone.port"))
					limone_port = args[++i];
				else if (args[i].equals("-limone.name"))
					InjectorFactory.setAgentName(args[++i]); // "AgimoneAgent" default
				else throw new Exception("Unknown parameter: " + args[i]);
			}
		} catch(Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
		
		String[] limoneParams = null;
		if (limone_debug)
			limoneParams = new String[] {"-sPort", limone_port, "-debug"};
		else
			limoneParams = new String[] {"-sPort", limone_port};
		
		try {
			LimoneServer.getServer().parseArgs(limoneParams);
			LimoneServer.getServer().boot();
		
			agimoneAgent = (AgimoneAgent)LimoneServer.getServer()
				.loadAgent("edu.wustl.mobilab.agimone.AgimoneAgent", InjectorFactory.getAgentName());
			
			// The advertisement is an array of length 1 that contains a single AgillaString.
			agimoneAgent.advertise(new AgillaStackVariable [] { 
					new AgillaString(AgillaProperties.networkName()) });					
		} catch(Exception e) {
			e.printStackTrace();
		}
		
		// Pass a reference to the AgimoneAgent to the:
		//	 QueryAgentLocMsgHandler
		//   QueryNumAgentsMsgHandler
		//   QueryNearestAgentMsgHandler
//		injector.getLocMgr().setAgimoneAgent(agimoneAgent);
	}
	
	public void reset() {
		if (agimoneAgent != null)
			agimoneAgent.reset();
	}
	
	public String toString() {
		return "Agimone Plugin";
	}
}
