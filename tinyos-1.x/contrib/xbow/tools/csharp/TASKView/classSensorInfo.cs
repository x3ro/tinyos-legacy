using System;
using System.Data;
using System.Collections;

namespace TASKView.lib
{
	/**
	 *  The SensorInfo structure contains all meta data for a given sensor. 
	 * 
	 * @author      Martin Turon
	 * @version     2004/4/22    mturon      Initial version
	 * 
	 * $Id: classSensorInfo.cs,v 1.2 2004/04/28 23:37:45 mturon Exp $
	 */
	public class SensorInfo
	{
		public string		m_name;
		public string		m_description;

		/** Conctructor */
		public SensorInfo()	{}
	}

	#region SensorTable class
	/**
	 *  A table to store static client information for all sensors.
	 * 
	 * @author      Martin Turon
	 * @version     2004/4/22    mturon      Initial version
	 */
	public class SensorTable : Hashtable 
	{
		public SensorTable() {
			Load();
		}

		/** Load the list of sensors from the current database. */
		public void Load() 
		{
			OdbcManager db = theOdbcManager.Instance;
			db.Connect();
			DataSet dSet = db.CreateDataSet(db.GetSensorsCommand());	
			db.Disconnect();

			if (null == dSet) return;

			SensorInfo sensorInfo;
			foreach (DataRow dRow in dSet.Tables[0].Rows)
			{
				sensorInfo				 = new SensorInfo();
				sensorInfo.m_name		 = dRow["name"].ToString();
				sensorInfo.m_description = dRow["description"].ToString();;
				Add(sensorInfo.m_name, sensorInfo);
			}
		}		

	} // class SensorTable
	#endregion

	#region theSensorTable singleton class
	/** 
	 * Singleton version of SensorTable 
	 * 
	 * @version    2004/4/22    mturon      Initial version
	 */
	public sealed class theSensorTable : SensorTable
	{
		/** The internal singular instance of the OdbcManager. */
		private static readonly theSensorTable instance = new theSensorTable();
		private theSensorTable() {}

		/** The read-only Instance property returns the one and only instance. */
		public static theSensorTable Instance
		{
			get { return instance; }
		}
	} // class theSensorTable
	#endregion
}
