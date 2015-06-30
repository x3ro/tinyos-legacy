using System;
using System.Data;

namespace TASKView.lib
{
	/**
	 *  A custom DataGrid component for use by TASKView. 
	 * 
	 * @author      Martin Turon
	 * @version     2004/4/12    mturon      Initial version
	 * 
	 * $Id: classDataGrid.cs,v 1.4 2004/04/15 04:34:46 mturon Exp $
	 */
	public class DataGrid : System.Windows.Forms.DataGrid
	{
		// ==================== INSTANCE DATA ========================

		// ======================= METHODS ===========================

		/** Constructor */
		public DataGrid() {}

		/** Refresh this DataGrid from the current database. */
		public void Initialize() 
		{
			OdbcManager db = theOdbcManager.Instance;
			db.Connect();

			DataSet dSet;					// dSet.ReadXml("test.xml");
			//dSet = db.CreateXmlTransformedDataSet();
			//dSet = db.CreateMoteInfoDataSet(db.GetMoteInfoCommand());	
			dSet = db.CreateResultDataSet(db.GetLastResultCommand());	
			db.Disconnect();

			if (null == dSet) return;
			this.DataSource = dSet.Tables[0].DefaultView;
		}
	}
}
