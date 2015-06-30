Attribute VB_Name = "basMoteInfo"
''====================================================================
'' basUtil.bas
''====================================================================
'' DESCRIPTION:  Library of routines for storing client-side
''               mote specific information.
''
'' HISTORY:      mturon      2004/3/9    Initial version
''
'' $Id: basMoteInfo.bas,v 1.5 2004/05/07 22:41:02 mturon Exp $
''====================================================================
Option Explicit

'################## Mote Info Table #######################

' Data Structure for collecting statistics on:
'   - mote network topology and link reliability.
Public Type stMoteInfo
    ' Updated information
    nodeid As Integer
    parent As Integer
    lastEpoch As Integer
    lastResult As String
    ' Static from task_mote_info table
    X As Integer
    Y As Integer
    Z As Integer
End Type

' Use a hashtable for storing mote information structures with key=nodeid.
' Lookup:  g_MoteInfo(id)
' Verify:  g_MoteInfo.Exists(id)
' Insert:  g_MoteInfo.Add Key:=id, Item:=object
' Number:  g_MoteInfo.Count
' Delete:  g_MoteInfo.Remove(id)
' Clear:   g_MoteInfo.RemoveAll
Public g_MoteInfo As New Scripting.Dictionary

'====================================================================
' MoteTableReset
'====================================================================
' DESCRIPTION:  Frees the current mote table and intializes a new one
' HISTORY:      mturon      2004/3/9    Initial version
'
Public Function MoteTableReset()
    ' Reset Mote Info
    g_MoteInfo.RemoveAll
    Dim moteInfo As objMote
    Set moteInfo = New objMote
    moteInfo.m_nodeid = 0
    moteInfo.m_parent = 0
    moteInfo.m_name = "Gateway"
    moteInfo.m_color = vbMagenta
    g_MoteInfo.Add 0, moteInfo
End Function

'====================================================================
' MoteTableNextNodeId
'====================================================================
' DESCRIPTION:  Returns the next unique node id for a new node
' HISTORY:      mturon      2004/3/25    Initial version
'
Public Function MoteTableNextNodeId()
    Dim nodeid, nodeMax As Integer
    nodeMax = 1
    For Each nodeid In g_MoteInfo.Keys
        If nodeid >= nodeMax Then
            nodeMax = nodeid + 1
        End If
    Next
    MoteTableNextNodeId = nodeMax
End Function

'################## Utils #######################

'====================================================================
' SafeTrim
'====================================================================
' DESCRIPTION:  Gets rid of line feeds and other whitespace in a string.
' HISTORY:      mturon      2004/2/11    Initial version
'
Public Function SafeTrim(MyString As String) As String
    MyString = Replace(MyString, vbCr, "")
    SafeTrim = Trim(MyString)
End Function

'====================================================================
' SensorGetId
'====================================================================
' DESCRIPTION:  Returns the index into the global sensor table
'               of a given sensor string
' HISTORY:      mturon      2004/2/10    Initial version
'
Public Function SensorGetId(sensor As String) As Integer
    Dim i As Integer
    
    For i = LBound(SensorInfoTable) To UBound(SensorInfoTable)
        If StrComp(SensorInfoTable(i).sensorName, sensor, vbTextCompare) = 0 Then
            SensorGetId = i
            Exit Function
        End If
    Next
End Function

'====================================================================
' SensorGetGridId
'====================================================================
' DESCRIPTION:  Returns the index into the global sensor table
'               of a given sensor string
' HISTORY:      mturon      2004/2/10    Initial version
'
Public Function SensorGetGridId(sensor As String) As Integer
    Dim j As Integer
    
    For j = 1 To TaskInfo.nmb_sensors
        If StrComp(TaskInfo.sensor(j), sensor, vbTextCompare) = 0 Then
            SensorGetGridId = j
            Exit Function
        End If
    Next
End Function

