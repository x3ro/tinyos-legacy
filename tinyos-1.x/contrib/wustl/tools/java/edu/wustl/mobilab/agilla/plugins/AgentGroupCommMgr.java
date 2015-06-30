package edu.wustl.mobilab.agilla.plugins;

import java.util.*;
import java.io.*;
import edu.wustl.mobilab.agilla.*;
import edu.wustl.mobilab.agilla.variables.*;

public class AgentGroupCommMgr extends Plugin implements ReactionListener, AgillaConstants {
	private String leader_file
		= "C:\\Program Files\\cygwin\\opt\\tinyos-1.x\\contrib\\wustl\\apps\\AgillaAgents\\GroupComm\\chat\\Leader.ma";
	
	AgentInjector injector;
	TupleSpace ts;
	Hashtable<AgillaString, AgillaLocation> leaderTable = 
		new Hashtable<AgillaString, AgillaLocation>();
	String leaderString = "";
	
	public AgentGroupCommMgr(AgentInjector injector) {
		this(injector, new String[]{});
	}
	
	public AgentGroupCommMgr(AgentInjector injector, String [] args) {
		this.injector = injector;
		this.ts = injector.getTS();
	
		try {
			for (int i = 0; i < args.length; i++) {
				if (args[i].equals("-leader")) {
					this.leader_file = args[++i];
				}
				else throw new Exception("Unknown parameter: " + args[i]);
			}
		} catch(Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
		
		// read in the leader agent
		try {
			File f = new File(leader_file);
			BufferedReader reader = new BufferedReader(new FileReader(f));
			String nxtLine = reader.readLine();
			while (nxtLine != null) {
				leaderString += nxtLine + "\n";
				nxtLine = reader.readLine();
			}
		} catch(Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
				
		// create a template for join group tuples
		Tuple t = new Tuple();
		t.addField(new AgillaString("req"));
		t.addField(new AgillaType(AGILLA_TYPE_STRING));	 	// Name of group
		t.addField(new AgillaType(AGILLA_TYPE_LOCATION));	// Location of the agent that wants to join
			
		// register a reaction sensitive to join group tuples
		ts.registerReaction(new Reaction(new AgillaAgentID(), 0, t), this);
		log("Initialized.");
	}
	
	public void reactionFired(Tuple t) {
		AgillaString name = (AgillaString)t.getField(1);
		AgillaLocation loc = (AgillaLocation)t.getField(2);
		
		log("Received a join message for group " + name + " from " + loc);
		
		if (!leaderTable.containsKey(name)) {
			leaderTable.put(name, loc);
			injector.inject(new Agent(leaderString), loc.getAddr());
			log("Injected new leader for group " + name + " to " + loc);
		}
		
		AgillaLocation leaderLoc = leaderTable.get(name);
		Tuple reply = new Tuple();
		reply.addField(new AgillaString("grl"));
		reply.addField(leaderLoc);
		
//		try {
//			log("Sleeping to ensure agent is injected");
//			Thread.sleep(10000);
//		} catch (InterruptedException e) {
//			e.printStackTrace();
//		}
		
		
		log("Sending reply " + leaderLoc + " to " + loc + ".");
		ts.rout(reply, loc.getAddr());
	}
	
	private void log(String msg) {
		Debugger.dbgErr("AgentGroupCommMgr", msg);
	}

	@Override
	public void reset() {
		leaderTable.clear();		
	}
}
