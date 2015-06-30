using System;
using System.Data;
using System.Data.Odbc;
using System.Data.Common;
using System.Xml;
using System.Xml.Xsl;
using System.Windows.Forms;
using TASKView.app;

namespace TASKView.lib
{
	/**
	 *  A general class for managing access to a database through ODBC. 
	 * 
	 * @author      Martin Turon
	 * @version     2004/4/9    mturon      Initial version
	 * 
	 * $Id: classOdbcManager.cs,v 1.11 2004/05/04 03:32:30 mturon Exp $
	 */
	public class OdbcManager 
	{
		#region // ==================== INSTANCE DATA ========================
		private OdbcConnection	m_Connection;	//!< db connection object

		public string			m_Driver;		//!< database driver
		public string			m_Server;		//!< database ip or host
		public string			m_Port;			//!< database port
		public string			m_User;			//!< database username 
		public string			m_Password;		//!< database password
		public string			m_Database;		//!< database to use
		public string			m_Table;		//!< query table to use
		public string			m_Client;		//!< client name to use
		#endregion

		#region // ===================== PROPERTIES ==========================

		/** Allows public access to the database server reconnecting if needed. */
		public string Server
		{
			get { return m_Server; }
			set { m_Server = value; }
		}

		/** Allows public access to the database selection refreshing if needed. */
		public string Database
		{
			get { return m_Database; }
			set { m_Database = value; }
		}

		#endregion		// PROPERTIES

		// ======================= METHODS ===========================

		/** 
		 * Initializes a new database manager object.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/9    mturon      Initial version
		 */
		public OdbcManager() 
		{
			// Set default database settings.
			m_Driver   = "{PostgreSQL}";
			m_Server   = "localhost";
			m_Port     = "5432";
			m_User     = "tele";
			m_Password = "tiny";
			m_Database = "labapp_task"; 
			m_Table    = "labapp923_sensor";
			m_Client   = "TASKView";
		}

		public void ErrorLog(string errMsg) 
		{
			//MessageBox.Show(errMsg);
			FormMain theForm = TASKView.app.theMainForm.Instance;
			if (null != theForm) theForm.OutputLog.AppendText(errMsg);
		}

		/** 
		 * Opens a new connection to the database.
		 * 
		 *  @return     System.Data.IDbConnection object.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/9    mturon      Initial version
		 */
		public IDbConnection Connect() 
		{ 
			string connectionString = 
				"DRIVER=" + m_Driver +
				";UID=" + m_User + ";PWD=" + m_Password +
				";SERVER=" + m_Server + ";PORT=" + m_Port + 
				";DATABASE=" + m_Database;
			m_Connection = new OdbcConnection(connectionString);

			try 
			{
				m_Connection.Open();
			}
			catch (Exception ex) 
			{ 
				ErrorLog("\nError: Opening database connection\n" + ex.Message);
			}

			return m_Connection;
		}

		/** 
		 * Closes the existing connection to the database.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/12    mturon      Initial version
		 */
		public void Disconnect() 
		{ 
			try 
			{
				m_Connection.Close();
			}
			catch (Exception ex) 
			{ 
				ErrorLog("\nError: Closing database\n" + ex.Message);
			}
		}

		/** 
		 * Creates a command to get the last result for the current query table.
		 * 
		 *  @return     System.Data.IDbCommand object.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/9    mturon      Initial version
		 */
		public IDbCommand GetLastResultCommand() 
		{ 
			return new OdbcCommand( 
				"SELECT DISTINCT ON (nodeid) * FROM " + m_Table + 
				" ORDER BY nodeid, result_time DESC", m_Connection);
		}

		/** 
		 * Creates a command to get the mote information.
		 * 
		 *  @return     System.Data.IDbCommand object.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/12    mturon      Initial version
		 */
		public IDbCommand GetMoteInfoCommand() 
		{ 
			return new OdbcCommand( 
				"SELECT * FROM task_mote_info " +
				"WHERE clientinfo_name = '" + m_Client + 
				"' ORDER BY mote_id", m_Connection);
		}

		/** 
		 * Command to find all the sensors from the task_attributes table. 
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/22    mturon      Initial version
		 */
		public IDbCommand GetSensorsCommand()
		{
			return new OdbcCommand(
				"SELECT name, description FROM task_attributes",
				m_Connection);
		}

		/** 
		 * Returns command to get a list of databases from the server.
		 * 
		 *  @return     System.Data.IDbCommand object.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/28    mturon      Initial version
		 */
		public IDbCommand GetDatabasesCommand() 
		{ 
			return new OdbcCommand("SELECT datname FROM pg_database", m_Connection);
		}

		/** 
		 * Returns command to get a list of query result tables from the server.
		 * 
		 *  @return     System.Data.IDbCommand object.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/28    mturon      Initial version
		 */
		public IDbCommand GetTablesCommand() 
		{ 
			return new OdbcCommand(
				"SELECT table_name, query_text " + 
				"FROM task_query_log " +
                "WHERE query_type='sensor'", 
				m_Connection);
		}

		/** 
		 * Command to grab all plot data for a given node/sensor pair. 
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/22    mturon      Initial version
		 */
		public IDbCommand GetNodeDataCommand(ushort nodeid, string sensor) 
		{
			return new OdbcCommand(
				"SELECT result_time, " + sensor + 
                " FROM " + m_Table + 
                " WHERE nodeid = " + nodeid, 
				m_Connection);
		}

		/** 
		 * Creates a DataTable object for the specified command.
		 * 
		 *  @param  command     The System.Data.IDbCommand object.
		 *  @return A reference to the System.Data.DataTable object.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/9    mturon      Initial version
		 */
		public DataTable CreateDataTable(IDbCommand command) 
		{
			DataTable dataTable = new DataTable();
			DbDataAdapter dataAdapter;
			dataAdapter = new OdbcDataAdapter((OdbcCommand)command);
			dataAdapter.Fill(dataTable);
			return dataTable;
		}


		/** 
		 * Creates a DataSet object for the specified adapter.
		 * 
		 *  @param  adapter     System.Data.DBDataAdapter object.
		 *  @param  dset        System.Data.DataSet object to fill.
		 *  @return A reference to the System.Data.DataSet object.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/13    mturon      Initial version
		 */
		public DataSet FillDataSet(DbDataAdapter dataAdapter, DataSet ds) 
		{
			if (null == ds) 
			{
				ds = new DataSet();
			}
			
			try 
			{
				dataAdapter.Fill(ds, m_Table);
			} 
			catch (Exception ex)
			{
				ErrorLog("\nError: DataSet fill\n"	+ ex.Message);
				ds = null;
			}

			return ds;
		}

		/** 
		 * Creates a DataSet object for the specified command.
		 * 
		 *  @param  command     The System.Data.IDbCommand object.
		 *  @return A reference to the System.Data.DataSet object.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/9    mturon      Initial version
		 */
		public DataSet CreateDataSet(IDbCommand command) 
		{
			DbDataAdapter dataAdapter; 
			dataAdapter = new OdbcDataAdapter((OdbcCommand)command);
			DataSet ds = new DataSet();		// fill data into this object
			return FillDataSet(dataAdapter, ds);
		}

		/** 
		 * Creates a DataSet object for the specified command.
		 * 
		 *  @param  command     The System.Data.IDbCommand object.
		 *  @return A reference to the System.Data.DataSet object.
		 * 
		 *  @author     Martin Turon
		 *  @version    204/4/12    mturon      Initial version
		 */
		public DataSet CreateXmlTransformedDataSet() 
		{
			DataSet dset = CreateDataSet(GetLastResultCommand());
			//dset.ReadXmlSchema("..//..//xschemaResults.xml");

			XmlDataDocument xmlDoc = new XmlDataDocument(dset); 
			//System.Xml.XPath.XPathDocument xd = new System.Xml.XPath.XPathDocument("../../rss.xml");
			
			XslTransform xslt = new XslTransform();
			xslt.Load("..//..//xviewResults.xslt");

			System.IO.Stream strmTemp = 
				new System.IO.FileStream("out.xml", System.IO.FileMode.Create, 
				System.IO.FileAccess.ReadWrite); 
			xslt.Transform(xmlDoc, null, strmTemp, null); 
			strmTemp.Close();

			DataSet ds = new DataSet();
			ds.ReadXml("..//..//out.xml");

			return ds;
		}

		/** 
		 * Creates a DataSet object specifically mapped to view mote
		 * information in a DataGrid.
		 * 
		 *  @param  adapter     The System.Data.DbDataAdapter object.
		 *  @return A newly allocated System.Data.DataSet object.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/13    mturon      Initial version
		 */
		public DataSet MapMoteInfoDataSet(DbDataAdapter dataAdapter) 
		{
			// Add mapping to given adapter
			DataTableMapping dtblmap;
			dtblmap = dataAdapter.TableMappings.Add(m_Table, "Mote Info");
			dtblmap.ColumnMappings.Add("mote_id", "Id");
			dtblmap.ColumnMappings.Add("moteinfo", "Name");
			dtblmap.ColumnMappings.Add("calib", "Calibration");
			
			// Create new DataSet with matching result columns
			DataSet   dset = new DataSet();
			DataTable dtbl = dset.Tables.Add("Mote Info");
			dtbl.Columns.Add("Id", Type.GetType("System.Int32"));
			//dtbl.Columns.Add("Name", Type.GetType("System.String"));
			//dtbl.Columns.Add("Calibration", Type.GetType("System.String"));
			dataAdapter.MissingSchemaAction = MissingSchemaAction.Ignore;

			return dset;
		}

		/** 
		 * Creates a DataSet object specifically mapped to view results
		 * information in a DataGrid.
		 * 
		 *  @param  adapter     The System.Data.DbDataAdapter object.
		 *  @return A newly allocated System.Data.DataSet object.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/13    mturon      Initial version
		 */
		public DataSet MapResultsDataSet(DbDataAdapter dataAdapter) 
		{
			// Add mapping to given adapter
			DataTableMapping dtblmap;
			dtblmap = dataAdapter.TableMappings.Add(m_Table, "Results");
			dtblmap.ColumnMappings.Add("nodeid", "Id");
			dtblmap.ColumnMappings.Add("parent", "Parent");
			dtblmap.ColumnMappings.Add("epoch", "Sample #");
			dtblmap.ColumnMappings.Add("result_time", "Time");
			
			// Create new DataSet with matching result columns
			DataSet   dset = new DataSet();
			DataTable dtbl = dset.Tables.Add("Results");
			dtbl.Columns.Add("Id", Type.GetType("System.Int32"));
			dtbl.Columns.Add("Parent", Type.GetType("System.Int32"));
			dtbl.Columns.Add("Sample #", Type.GetType("System.Int32"));
			dtbl.Columns.Add("Time", Type.GetType("System.String"));
			//dataAdapter.MissingSchemaAction = MissingSchemaAction.Ignore

			return dset;
		}

		/** 
		 * Creates a DataSet object for the specified command.
		 * 
		 *  @param  command     The System.Data.IDbCommand object.
		 *  @return A reference to the System.Data.DataSet object.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/9    mturon      Initial version
		 */
		public DataSet CreateResultDataSet(IDbCommand command) 
		{
			DbDataAdapter dataAdapter; 
			dataAdapter = new OdbcDataAdapter((OdbcCommand)command);
			DataSet dset = MapResultsDataSet(dataAdapter);
			return FillDataSet(dataAdapter, dset);
		}

		/** 
		 * Creates a DataSet object for the specified command.
		 * 
		 *  @param  command     The System.Data.IDbCommand object.
		 *  @return A reference to the System.Data.DataSet object.
		 * 
		 *  @author     Martin Turon
		 *  @version    2004/4/9    mturon      Initial version
		 */
		public DataSet CreateMoteInfoDataSet(IDbCommand command) 
		{
			DbDataAdapter dataAdapter; 
			dataAdapter = new OdbcDataAdapter((OdbcCommand)command);
			DataSet dset = MapMoteInfoDataSet(dataAdapter);
			return FillDataSet(dataAdapter, dset);
		}

		/** 
		 * Creates a new client in the task_client_info database 
		 * @version      2004/3/25    mturon      Initial version
		 */
		public void SaveClientNew() 
		{
			string sqlInsert = "INSERT INTO task_client_info " +
                "(name, type, clientinfo) " +
                "VALUES ('" + m_Client + "', 'CONFIGURATION', '')";

			OdbcCommand command = new OdbcCommand(sqlInsert, m_Connection);
			try 
			{
				command.ExecuteNonQuery();
			} 
			catch (Exception ex) 
			{
				ErrorLog("\nError: creating new client\n" + ex.Message);
			}			

		}

		/** 
		 * Creates a new mote in the task_mote_info database 
		 * @version      2004/3/25    mturon      Initial version
		 */
		public void SaveMoteNew(MoteInfo moteInfo) 
		{
			string sqlInsert = "INSERT INTO task_mote_info (mote_id, " +
                "x_coord, y_coord, z_coord, calib, " +
                "moteinfo, clientinfo_name) " +
                "VALUES ( " +
                moteInfo.m_nodeid + ", " +
                moteInfo.m_x + ", " +
				moteInfo.m_y + ", " +
                moteInfo.m_z + ", '' , '" +
                moteInfo.m_name + "', '" + m_Client + "')";

			OdbcCommand command = new OdbcCommand(sqlInsert, m_Connection);
			try 
			{
				command.ExecuteNonQuery();
			} 
			catch (Exception ex) 
			{
				ErrorLog("\nError: adding new mote to database\n" + ex.Message);
			}			
		}

		/** 
		 * Updates the database with the current mote positions
		 * @version		2004/2/18	mturon		Initial version
		 * @n			2004/3/25	mturon		Extended to insert new nodes
		 */
		public void SaveMotePositions() 
		{
			OdbcCommand command;
			string sqlBase = "UPDATE task_mote_info SET";
			string sqlNode;
			ErrorLog("\nSaving mote positions");
			Connect();
			foreach (MoteInfo moteInfo in theMoteTable.Instance.Values) 
			{
		        sqlNode = " x_coord = " + moteInfo.m_x
				        + ",y_coord = " + moteInfo.m_y
						+ " WHERE mote_id = " + moteInfo.m_nodeid
						+ " AND clientinfo_name = '" + m_Client + "'";
				command = new OdbcCommand(sqlBase + sqlNode, m_Connection);
				try 
				{
					command.ExecuteNonQuery();
				} 
				catch (Exception ex) 
				{
					ErrorLog("\nError: updating mote positions\n" + ex.Message);
					SaveMoteNew(moteInfo);
				}
			}
			Disconnect();
		}

		#region VB6 -- chart data fill
		/*
'====================================================================
' QueryDataFill
'====================================================================
' DESCRIPTION:
' HISTORY:      jprabhu     2004/1/15    Initial version
'               mturon      2004/2/27    Optimized SQL query
'
Public Function QueryDataFill()
    '
    ' collect data from result set
    '
    Dim intResult As Integer
    Dim intCols As Integer
    Dim nRows As Integer
    Dim lRowsInDB, lRowStart, lNmbRowsToReturn As Long
    Dim iMote_Id As Integer
    Dim strBuffer As String * BUFFERLEN
    Dim strItem As String
    Dim strData As String
    Dim sTmp0, sTmp1, sTmp2 As String
    Dim iIndx As Integer

    Dim strChrAttr As String * BUFFERLEN
    Dim StringLengthPtr As Integer
    Dim NumericAttributePtr As Integer
  
    sTmp1 = "nodeid, result_time,"
    For iIndx = 1 To TaskInfo.nmb_sensors
        sTmp1 = sTmp1 + " " + TaskInfo.sensor(iIndx)
        If iIndx < TaskInfo.nmb_sensors Then
            sTmp1 = sTmp1 + ","
        End If
    Next iIndx
    
    objSQL.SQL = "SELECT DISTINCT ON (nodeid) " + sTmp1 + _
                 " FROM " + objSQL.DBTable + _
                 " ORDER BY nodeid, result_time DESC"

    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        QueryDataFill = sqlErr
        Exit Function
    End If
  
    ' search the records for each mote and return it latest values
    intResult = SQLRowCount(hStmt, nRows)
      
    strBuffer = String(BUFFERLEN, 0)
    For iIndx = 1 To nRows
        intResult = SQLNumResultCols(hStmt, NumCols)
        intResult = FetchRow()
        intResult = GetColumn(strBuffer, 1)            'mote-id
        If (Trim(strBuffer) = "") Then
            GoTo skip_loop                  ' filter out bad mote-ids
        End If
        iMote_Id = CInt(strBuffer)
        intResult = GetColumn(strBuffer, 2)            'time
        TaskDataArray(iMote_Id).Time = Trim(strBuffer)
        
        'Removed, since we are not connected to live query table,
        ' Uncomment at release
        If (TaskDataArray(iMote_Id).Time > TaskDBCfg.TaskLastQueryTime) Then
            TaskDBCfg.TaskLastQueryTime = TaskDataArray(iMote_Id).Time
        End If
            
        For jindx = 1 To TaskInfo.nmb_sensors
            intResult = GetColumn(strBuffer, 2 + jindx)          'sensor data
            If Trim(strBuffer) = "" Then
                strBuffer = -1
            End If
            TaskDataArray(iMote_Id).Value(jindx) = CLng(strBuffer)
        Next jindx
skip_loop:
    Next iIndx

    bNotFirstTime = True
    QueryDataFill = sqlSuccess
    
End Function

Public Function QueryHistoryFill(intNodeID As Integer, strSensor As String, _
                                 startTime As Date, endTime As Date)

    Dim intResult As Integer
    Dim intCols As Integer
    Dim intRows As Integer
    Dim iDataIndex() As index
    Dim strBuffer As String * BUFFERLEN
      
    'create the query
    sSQL = "SELECT result_time, " + strSensor + _
                 " FROM " + objSQL.DBTable + _
                 " WHERE nodeid = " + CStr(intNodeID) + _
                 " AND result_time >= '" + CStr(startTime) + _
                 "' AND result_time <= '" + CStr(endTime) + "'"
    
    objSQL.SQL = sSQL
    
    'run the query
    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        QueryHistoryFill = sqlErr
        Exit Function
    End If
    
    '
    ' get the row count
    intResult = SQLRowCount(hStmt, intTotalRows)
      
    ' If Query did not return any results
    If (intTotalRows = 0) Then
        QueryHistoryFill = sqlErr
        Exit Function
    End If
    
    ReDim TaskHistoryData.Value(intTotalRows - 1)
    ReDim TaskHistoryData.Time(intTotalRows - 1)
        
    intRows = 0
    strBuffer = String(BUFFERLEN, 0)
    'get data
    Do While (1)
        intResult = FetchRow()
                                                   
        Select Case intResult
            Case sqlNoDataFound
                Exit Do
            Case sqlSuccess
                ' Initialise to a valid value
                TaskHistoryData.Time(intRows) = startTime
                TaskHistoryData.Value(intRows) = 0
                
                ' Get "result_time" of this reading
                intResult = GetColumn(strBuffer, 1)
                ' Check if the time is valid, else ignore reading
                If IsDate(strBuffer) Then
                    TaskHistoryData.Time(intRows) = Trim(strBuffer)
                    ' Get sensor reading
                    intResult = GetColumn(strBuffer, 2)
                    ' If the reading is a valid number add entry,
                    '   else copy old reading
                    If IsNumeric(strBuffer) Then
                        TaskHistoryData.Value(intRows) = _
                            UnitEngConvert(CLng(strBuffer), strSensor, intNodeID)
                    Else
                        If intRows > 0 Then
                            TaskHistoryData.Value(intRows) = _
                                TaskHistoryData.Value(intRows - 1)
                        Else
                            TaskHistoryData.Value(intRows) = -MOTE_NO_PARENT
                        End If
                    End If
                    intRows = intRows + 1
                End If
            Case Else
                intResult = SQLFreeStmt(hStmt, sqlClose)
                QueryHistoryFill = sqlErr
                Exit Function
        End Select
    'Next intRows
    Loop
    
    QueryHistoryFill = sqlSuccess
   
End Function

*/
		#endregion

	}  // class OdbcManager


	#region theOdbcManager singleton class
	/** 
	 * Singleton version of OdbcManager 
	 * 
	 * @version    2004/4/12    mturon      Initial version
	 */
	public sealed class theOdbcManager : OdbcManager
	{
		/** The internal singular instance of the OdbcManager. */
		private static readonly theOdbcManager instance = new theOdbcManager();
		private theOdbcManager() {}

		/** The read-only Instance property returns the one and only instance. */
		public static theOdbcManager Instance
		{
			get { return instance; }
		}
	} // class theOdbcManager
	#endregion

} // namespace TASKView.lib