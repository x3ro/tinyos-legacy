using System;
using System.Data;

namespace TASKView.lib
{
	/**
	 *  A custom NodeList component for use by TASKView. 
	 * 
	 * @author      Martin Turon
	 * @version     2004/4/12    mturon      Initial version
	 * 
	 * $Id: classNodeList.cs,v 1.6 2004/04/28 23:37:45 mturon Exp $
	 */
	public class NodeList : AxCTLISTLib.AxctList
	{
		// ==================== INSTANCE DATA ========================

		// ======================= METHODS ===========================

		/** Constructor */
		public NodeList() {
			// Add an event handler for whenever a node check box is clicked.
			this.CheckClick += new AxCTLISTLib._DctListEvents_CheckClickEventHandler(NodeList_CheckClick);
		}

		/** 
		 * Fill NodeList with values from MoteTable.
		 * 
		 *  @version    2004/4/13    mturon      Initial version
		 */
		public void Initialize() 
		{
			MoteTable moteTable = theMoteTable.Instance;
			moteTable.Load();

			ClearList();
			foreach (MoteInfo moteInfo in moteTable.Values)
			{
				AddItem(";" + moteInfo.m_nodeid + ";" + moteInfo.m_name);
			}
		}
	
		/** 
		 * Intercept the CheckClick event, and save the plot bit into
		 * the MoteTable whenever a user toggles the checkbox associated
		 * with a node.
		 * 
		 * @author		Martin Turon 
		 * @version     2004/4/21    mturon      Initial version
		 */
		private void NodeList_CheckClick(object sender, AxCTLISTLib._DctListEvents_CheckClickEvent e)
		{
			MoteInfo moteInfo =							// grab clicked node
				(MoteInfo)theMoteTable.Instance.GetByIndex(e.nIndex);

			if (e.nValue == 1)							// if box checked
			{	
				moteInfo.m_flags |=  MoteFlags.MF_PLOT;	// set plot bit 
			} 
			else			
			{
				moteInfo.m_flags &= ~MoteFlags.MF_PLOT;	// clear plot bit
			}
		}
	}
}
