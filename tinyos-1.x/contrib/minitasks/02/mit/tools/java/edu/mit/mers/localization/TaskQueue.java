package	edu.mit.mers.localization;

import java.util.*;

/**
 * This class implements a task queue that tracks the things that we still need to do,
 *  and does them when the time comes.  The implementation model is not listener based;
 *  rather, explicit calls are assumed.  This means tighter coupling with application
 *  data strewn about in here.  This is not a generic component.
 *
 * The user of this class is assumed to:
 *  - Call our processQueueTick() function once a second.
 *  - Call us to schedule tasks to be executed.
 *  - Call us to let us know when tasks succeeded, so we should stop repeating 
 *     the (repeatable) tasks over and over.
 */

public class TaskQueue 
{
    // -----------------
    //   Inner Classes
    // -----------------    

    public class TaskQueueItem
    {
	private final static int DEFAULT_NUMBER_OF_TRIES = 3;

	protected int numberOfTries;
	protected int triedSoFar;

	public TaskQueueItem()
	{
	    triedSoFar = 0;
	    
	    numberOfTries = DEFAULT_NUMBER_OF_TRIES;
	}	

	public TaskQueueItem(int numberOfTries)
	{
	    triedSoFar = 0;

	    this.numberOfTries = numberOfTries;
	}
	
	/** Returns the expected latency of the operation in seconds.
	 *  (The number of seconds before the next task queue item
	 *  should be launched)
	 */
	public int getLatency()
	{
	    // By default, everything should take one second.
	    return 3;
	}
	
	public int getNumberOfTriesRemaining()
	{
	    return numberOfTries;
	}

	public void invoke()
	{
	    triedSoFar++;
	    if(numberOfTries > 0)
		numberOfTries--;
	}
    }

    public class CalibrateNodeTask extends TaskQueueItem
    {
	private int nodeId;
	private int hash;

	public CalibrateNodeTask(int nodeId)
	{
	    super(1);

	    this.nodeId = nodeId;
	    
	    hash = (new Integer(nodeId)).hashCode();
	}

	public int getLatency()
	{
	    return 40;
	}

	public boolean equals(Object o)
	{
	    if(!(o instanceof CalibrateNodeTask))
		return false;
	    
	    CalibrateNodeTask task = (CalibrateNodeTask)o;

	    return(task.nodeId == nodeId);
	}

	public int hashCode()
	{
	    return hash;
	}

	public String toString()
	{
	    return "Calibrate node " + nodeId + " (Try #" + triedSoFar + ")";
	}

	public void invoke()
	{
	    super.invoke();

	    // Calibrate...
	    core.testRadio(nodeId);

	    // Assume we succeeeded.  Just queue up a calibration followup task.
	    CalibrationFollowupTask task = new CalibrationFollowupTask(nodeId);

	    //core.logTask("Adding: " + task);

	    if(queue.indexOf(task) == -1)
		queue.add(task);
	}
    }

    public class CalibrationFollowupTask extends TaskQueueItem
    {
	private int nodeId;
	private int hash;

	public CalibrationFollowupTask(int nodeId)
	{
	    super();

	    this.nodeId = nodeId;
	    
	    hash = (new Integer(nodeId)).hashCode();
	}

	public boolean equals(Object o)
	{
	    if(!(o instanceof CalibrationFollowupTask))
		return false;
	    
	    CalibrationFollowupTask task = (CalibrationFollowupTask)o;

	    return(task.nodeId == nodeId);
	}

	public int hashCode()
	{
	    return hash;
	}

	public String toString()
	{
	    return "Get calibration results for node " + nodeId + " (Try #" + triedSoFar + ")";
	}

	public void invoke()
	{
	    super.invoke();

	    core.statRadio(nodeId);
	}
    }

    public class GetDistanceTask extends TaskQueueItem
    {
	private int nodeId;
	private int anchorId;
	private int hash;

	public GetDistanceTask(int nodeId, int anchorId)
	{
	    super();

	    this.nodeId = nodeId;
	    this.anchorId = anchorId;

	    hash = (new Integer(nodeId)).hashCode() * 31 +
		   (new Integer(anchorId)).hashCode();
	}

	public boolean equals(Object o)
	{
	    if(!(o instanceof GetDistanceTask))
		return false;
	    
	    GetDistanceTask task = (GetDistanceTask)o;

	    return((task.nodeId == nodeId) &&
		   (task.anchorId == anchorId));
	}

	public int hashCode()
	{
	    return hash;
	}

	public void invoke()
	{
	    super.invoke();

	    core.getDistance(nodeId, anchorId);
	}

	public String toString()
	{
	    return "Get distance from node " + nodeId + " to anchor " + anchorId + " (Try #" + triedSoFar + ")";
	}
    }

    public class SetRadioTask extends TaskQueueItem
    {
	private int nodeId;
	private int potValue;
	private int hash;

	public SetRadioTask(int nodeId, int potValue)
	{
	    super();

	    this.nodeId   = nodeId;
	    this.potValue = potValue;

	    hash = (new Integer(nodeId)).hashCode() * 31 +
		   (new Integer(potValue)).hashCode();
	}

	public boolean equals(Object o)
	{
	    if(!(o instanceof SetRadioTask))
		return false;
	    
	    SetRadioTask task = (SetRadioTask)o;

	    return((task.nodeId == nodeId) &&
		   (task.potValue == potValue));
	}

	/** Returns the expected latency of the operation in seconds.
	 *  (The number of seconds before the next task queue item
	 *  should be launched)
	 */
	public int getLatency()
	{
	    return 2;
	}
	
	public int hashCode()
	{
	    return hash;
	}

	public void invoke()
	{
	    super.invoke();

	    core.setPot(nodeId, potValue);
	}

	public String toString()
	{
	    return "Set radio for node " + nodeId + " to " + potValue + " (Try #" + triedSoFar + ")";
	}
    }

    public class SetPotMapTask extends TaskQueueItem
    {
	private int nodeId;
	private int potMap[];
	private int hash;

	public SetPotMapTask(int nodeId, int potMap[])
	{
	    super();

	    this.nodeId  = nodeId;
	    this.potMap  = potMap;

	    hash = (new Integer(nodeId)).hashCode();
	}

	public boolean equals(Object o)
	{
	    if(!(o instanceof SetPotMapTask))
		return false;
	    
	    SetPotMapTask task = (SetPotMapTask)o;

	    return((task.nodeId == nodeId));
	}

	/** Returns the expected latency of the operation in seconds.
	 *  (The number of seconds before the next task queue item
	 *  should be launched)
	 */
	public int getLatency()
	{
	    return 2;
	}
	
	public int hashCode()
	{
	    return hash;
	}

	public void invoke()
	{
	    super.invoke();

	    core.setPotMap(nodeId, potMap);
	}

	public String toString()
	{
	    return "Set potMap for node " + nodeId + " (Try #" + triedSoFar + ")";
	}
    }

    // ----------------------------------------------------------
    private List queue = null;
    private int nextUsableTick = 0;
    private LocationCore core = null;

    public TaskQueue(LocationCore core)
    {
	// Initialize our Queue structure
	queue = new ArrayList();

	this.core = core;
    }

    /** Takes a collection of nodes and queues them all for potMap setting.
     */
    public void setPotMaps(Collection nodes, int potMap[])
    {
	Iterator iNodes = nodes.iterator();
	while(iNodes.hasNext())
	{
	    Node node = (Node)iNodes.next();

	    setPotMap(node, potMap);
	}
    }    

    public void setPotMap(Node node, int potMap[])
    {
	SetPotMapTask task = new SetPotMapTask(node.getID(), potMap);

	//core.logTask("Adding: " + task);
	
	if(queue.indexOf(task) == -1)
	    queue.add(task);
    }

    /** Call this method when a setNodeRadio ack has been received. 
     */
    public void setPotMapReceived(Node node, int potMap[])
    {
	// If we got a reply, we should remove setPotMap task

	SetPotMapTask task = new SetPotMapTask(node.getID(), potMap);

	queue.remove(task);
    }

    /** Takes a collection of nodes and queues them all for radio setting.
     */
    public void setNodeRadios(Collection nodes)
    {
	Iterator iNodes = nodes.iterator();
	while(iNodes.hasNext())
	{
	    Node node = (Node)iNodes.next();

	    setNodeRadio(node);
	}
    }    

    public void setNodeRadio(Node node)
    {
	SetRadioTask task = new SetRadioTask(node.getID(), node.getPotValue());

	//core.logTask("Adding: " + task);
	
	if(queue.indexOf(task) == -1)
	    queue.add(task);
    }

    /** Call this method when a setNodeRadio ack has been received. 
     */
    public void setNodeRadioReceived(Node node, int potValue)
    {
	// If we got valid set pot result, we should remove setPot task

	SetRadioTask task = new SetRadioTask(node.getID(), potValue);

	queue.remove(task);
    }

    /** Takes a collection of nodes and queues them all for calibration.
     */
    public void calibrateNodes(Collection nodes)
    {
	Iterator iNodes = nodes.iterator();
	while(iNodes.hasNext())
	{
	    Node node = (Node)iNodes.next();

	    calibrateNode(node);
	}
    }    

    public void calibrateNode(Node node)
    {
	CalibrateNodeTask task = new CalibrateNodeTask(node.getID());

	//core.logTask("Adding: " + task);
	
	if(queue.indexOf(task) == -1)
	    queue.add(task);

	// Remove any outstanding calibration followups
	CalibrationFollowupTask task2 = new CalibrationFollowupTask(node.getID());
	queue.remove(task2);
    }

    /** Call this method when a node's calibration results have
     *   been received. 
     */
    public void nodeCalibrationResultsReceived(Node node)
    {
	// If we got valid calibration results, we should make sure that neither
	//  a followup request or a calibration initiation occurs.

	CalibrateNodeTask       task1 = new CalibrateNodeTask(node.getID());
	CalibrationFollowupTask task2 = new CalibrationFollowupTask(node.getID());

	queue.remove(task1);
	queue.remove(task2);
    }

    /**
     * This method should ordinarily not need to be called by user-classes; the
     *  calibration task will automatically queue a calibration followup task.
     *
     * You would only use this if your calibration results task died after 
     *  multiple tries and you wanted to try more.
     */
    public void getNodeCalibrationResults(Node node)
    {
	CalibrationFollowupTask task = new CalibrationFollowupTask(node.getID());

	//core.logTask("Adding: " + task);

	if(queue.indexOf(task) == -1)
	    queue.add(task);
    }

    /** 
     * Schedules all of the given nodes for distance retrieval for the given anchors.
     */
    public void getDistances(Collection nodes, Collection anchors)
    {
	Iterator iNodes = nodes.iterator();
	while(iNodes.hasNext())
	{
	    Node node = (Node)iNodes.next();

	    getDistances(node, anchors);
	}
    }

    /**
     * Schedules distance retrievals for the given node for the given anchors.
     */
    public void getDistances(Node node, Collection anchors)
    {
	Iterator iAnchors = anchors.iterator();
	while(iAnchors.hasNext())
	{
	    Node anchor = (Node)iAnchors.next();

	    GetDistanceTask task = new GetDistanceTask(node.getID(), anchor.getID());

	    //core.logTask("Adding: " + task);

	    // Only add the task to the queue if it's not already there.
	    if(queue.indexOf(task) == -1)
		queue.add(task);
	}   
    }

    /**
     * Indicates that we've received a distance estimate from the node to the anchor
     *  (sent to us by the node).  Kills the associated task.
     */
    public void gotDistance(Node node, Node anchor)
    {
	// This is what the task we want to remove should look like...
	GetDistanceTask task = new GetDistanceTask(node.getID(), anchor.getID());

	// So remove it if it exists
	queue.remove(task);
    }

    public void gotDistance(int nodeId, int anchorId)
    {
	// This is what the task we want to remove should look like...
	GetDistanceTask task = new GetDistanceTask(nodeId, anchorId);

	// So remove it if it exists
	queue.remove(task);
    }

    /**
     * Exposes the queue.  This should only be used for GUI purposes, and should not
     *  be manipulated.  Because I trust you I'm not doing a shallow clone or 
     *  providing you with a decorator that makes the access read-only.  So don't
     *  do anything stupid.
     */
    public List getQueue()
    {
	return queue;
    }

    /** This method should be called once a second in order to drive us.
     *
     */
    public void processQueueTick()
    {
	if(nextUsableTick > 0)
	    nextUsableTick--;

	if((nextUsableTick <= 0) && !queue.isEmpty())
	{
	    // Pop an item from the front of the queue.
	    TaskQueueItem task = (TaskQueueItem)queue.get(0);
	    queue.remove(0);

	    // Process the task.
	    task.invoke();

	    // If it has more tries yet, queue it up again.
	    if(task.getNumberOfTriesRemaining() > 0)
	    {
		queue.add(task);

		core.logTask("Task Performed and Rescheduled: " + task.toString());
	    }
	    else
	    {
		// If we wanted to let someone know this task is 'dying', we would do it here.
		core.logTask("Task Performed (Last Time): " + task.toString());
	    }    
	    
	    // How long till the next time?
	    nextUsableTick = task.getLatency();
	}    
    }
}
