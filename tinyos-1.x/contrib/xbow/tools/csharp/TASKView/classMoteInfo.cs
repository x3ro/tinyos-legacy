using System;
using System.Data;
using System.Drawing;
using System.Collections;
using NationalInstruments.UI;

namespace TASKView.lib
{
	public enum MoteFlags 
	{
		MF_SAVED   = 0x01,		//!< bit to signify if node was autodiscovered
		MF_DIRTY   = 0x02,		//!< bit to signify node has been altered
		MF_PLOT    = 0x04,		//!< bit to enable plotting of node
	}

	#region MoteInfo class
	/**
	 *  The MoteInfo structure contains all meta data for a given node. 
	 * 
	 * @author      Martin Turon
	 * @version     2004/4/13    mturon      Initial version
	 * 
	 * $Id: classMoteInfo.cs,v 1.12 2004/05/04 03:32:30 mturon Exp $
	 */
	public class MoteInfo
	{
		// ===================== CLASS DATA ==========================
		public const ushort MF_NO_PARENT = 0xFFFF;
		
		// ==================== INSTANCE DATA ========================

		// The nodeid is actually the index for the Dictionary of motes
		public ushort			m_nodeid;

		// Core information updated from the database every refresh
		public ushort			m_parent;	//!< id of parent (0xffff = none) 
		public ushort			m_epoch;	//!< last epoch recorded
		public string			m_time;		//!< time of last result recorded

		// Static information stored in the task_mote_info table
		public int				m_x;
		public int				m_y;
		public int				m_z;
		public byte[]			m_calib;	//!< calibration words for mote

		// Client side annotations
		public string			m_name;		//!< full name of mote
	    public Color			m_color;	//!< charting color for this node
		public ScatterPlot[]	m_plot;		//!< number of plot, 0 if none
		public MoteFlags		m_flags;

		// ======================= METHODS ===========================
		public MoteInfo()
		{
			m_parent = MF_NO_PARENT;
			m_color  = Color.DarkGray;
			m_plot   = new ScatterPlot[3]{null, null, null};
		}
	} // class MoteInfo
	#endregion

	#region MoteTable class
	/**
	 *  A table to store static client information for all motes.
	 *  Note: Always index the MoteTable with nodeid as ushort type.
	 * 
	 * @author      Martin Turon
	 * @version     2004/4/13    mturon      Initial version
	 */
	public class MoteTable : SortedList 
	{
		// ===================== CLASS DATA ==========================
		private static Color[] m_colors;

		// ======================= METHODS ===========================
		public MoteTable() 
		{	
			// Assign the color table
			InitColors(
				0x7F0000FF, 0x7F00FF00, 0x7FFFFF00,
				0x7F00FFFF, 0x7FFF0000, 0x7FFF00FF,
                0x7FFF8080, 0x7F80FF80, 0x7F8080FF,
				0x7FFFFF80, 0x7F80FFFF, 0x7FFF80FF,
				0x7FCC4080, 0x7F40CC80, 0x7F4080CC,
				0x7FCCCC40, 0x7F40CCCC, 0x7FCC40CC);
			
			// Always initialize with a Gateway.
			MoteInfo gatewayInfo = new MoteInfo();
			gatewayInfo.m_nodeid = 0;
			gatewayInfo.m_parent = 0;
			gatewayInfo.m_name = "Gateway";
			Add(gatewayInfo.m_nodeid, gatewayInfo);
		}

		/** Assign the array of default mote plotting colors. */
		private void InitColors(params int[] colors) 
		{
			int i = 0;
			m_colors = new Color[colors.Length];
			foreach (int color in colors) 
			{
				m_colors[i++] = Color.FromArgb(color);
			}
		}

		/** Attach this DataGrid to the current database. */
		public void Load() 
		{
			OdbcManager db = theOdbcManager.Instance;
			db.Connect();
			DataSet dSet = db.CreateDataSet(db.GetMoteInfoCommand());	
			db.Disconnect();

			this.Clear();
			if (null == dSet) return;

			MoteInfo moteInfo;
			foreach (DataRow dRow in dSet.Tables[0].Rows)
			{
				ushort nodeid = Convert.ToUInt16(dRow["mote_id"].ToString());
				bool   exists = this.ContainsKey(nodeid);
				if (!exists) 
				{
					moteInfo = new MoteInfo();
					moteInfo.m_nodeid = nodeid;
					moteInfo.m_name = "[S]";
					byte[] nameBytes = (byte[])dRow["moteinfo"];
					for (int i = 0; i < nameBytes.Length; i++) 
					{
						char c = Convert.ToChar(nameBytes[i]);
						if (c == 0) break;
						moteInfo.m_name += c;
					}
				} 
				else 
				{
					moteInfo = (MoteInfo)this[nodeid];
					moteInfo.m_name = "[S]" + moteInfo.m_name;
				}
				
				moteInfo.m_x      = Convert.ToInt32(dRow["x_coord"].ToString());
				moteInfo.m_y      = Convert.ToInt32(dRow["y_coord"].ToString());
				moteInfo.m_z      = Convert.ToInt32(dRow["z_coord"].ToString());
				moteInfo.m_color  = m_colors[nodeid % m_colors.Length];
				moteInfo.m_flags  = MoteFlags.MF_SAVED;
				//moteInfo.m_calib  = (byte[])dRow["calib"];

				if (!exists) Add(nodeid, moteInfo);
			}

			Update();
		}		

		public void Update() 
		{
			OdbcManager db = theOdbcManager.Instance;
			db.Connect();
			DataSet dSet = db.CreateDataSet(db.GetLastResultCommand());	
			db.Disconnect();
			
			try 
			{
				foreach (DataRow dRow in dSet.Tables[0].Rows)
				{
					try 
					{
						string nodenum = dRow["nodeid"].ToString();
						if ("" == nodenum) continue;			// Ignore null nodes
						ushort nodeid = Convert.ToUInt16(nodenum);
						//if (0 == nodeid) continue;				// Ignore gateway

						MoteInfo moteInfo;
						if (this.ContainsKey(nodeid)) 
						{
							// Update the mote with latest parent, epoch, and result time
							moteInfo = (MoteInfo)this[nodeid];
							// Stuff name until casting of byte[] to string works.
							moteInfo.m_name = "[R]" + moteInfo.m_name;
						} 
						else 
						{
							// This mote is reporting data, but isn't saved yet.
							moteInfo = new MoteInfo();
							moteInfo.m_nodeid = nodeid;
							moteInfo.m_name   = "[N] Node " + nodeid;
							moteInfo.m_flags  = 0;

							/// TODO: testing only...
							theOdbcManager.Instance.ErrorLog("\nFixed position for node " + nodeid);
							moteInfo.m_x = 10;
							moteInfo.m_y = 10;

							Add(nodeid, moteInfo);
						}			
						// Common update for both new and existing nodes.
						moteInfo.m_parent = Convert.ToUInt16(dRow["parent"].ToString());
						moteInfo.m_epoch  = Convert.ToUInt16(dRow["epoch"].ToString());
						moteInfo.m_time   = dRow["result_time"].ToString();
					}
					catch (Exception ex) 
					{
						theOdbcManager.Instance.ErrorLog("\n" + ex.ToString());
					}
				}
			} 
			catch (Exception ex) 
			{
				theOdbcManager.Instance.ErrorLog("\n" + ex.ToString());
			}
		}
	} // class MoteTable
	#endregion

	#region theMoteTable singleton class
	/** 
	 * Singleton version of MoteTable 
	 * 
	 * @version    2004/4/13    mturon      Initial version
	 */
	public sealed class theMoteTable : MoteTable
	{
		/** The internal singular instance of the OdbcManager. */
		private static readonly theMoteTable instance = new theMoteTable();
		private theMoteTable() {}

		/** The read-only Instance property returns the one and only instance. */
		public static theMoteTable Instance
		{
			get { return instance; }
		}
	} // class theMoteTable
	#endregion

} // namespace TASKView.lib
