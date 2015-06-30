VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "objMote"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
''====================================================================
'' objMote.cls
''====================================================================
'' DESCRIPTION:  A class to represent information about a
''               single node or Mote.
''
'' HISTORY:      mturon      2004/3/4    Initial version
''
'' $Id: objMote.cls,v 1.3 2004/03/25 19:53:36 mturon Exp $
''====================================================================

'################## Instance Data #######################

' The nodeid is actually the index for the Dictionary of motes
Public m_nodeid As Integer

' Core information updated from the database every refresh
Public m_parent As Long         ' parent is long so it can hold none = max(uint16)
Public m_epoch As Integer       ' last epoch recorded
Public m_time As String         ' time of last result recorded

' Static information stored in the task_mote_info table
Public m_x As Integer
Public m_y As Integer
Public m_z As Integer
Public m_calib As Variant       ' calibration constants

' Client side annotations
Public m_name As String
Public m_color As String

Public Enum et_MoteFlags
  MF_SAVED = 1
  MF_DIRTY = 2
End Enum

Public m_flags As et_MoteFlags

'################## Methods #######################

'Public Property Get nodeid() As Variant
'    nodeid = m_nodeid
'End Property

'Public Property Let nodeid(ByVal vNewValue As Variant)
'    m_nodeid = vNewValue
'End Property

'Public Property Get parent() As Variant
'    'Parent = this.m_parent
'End Property

'Public Property Let parent(ByVal vNewValue As Variant)
    'this.m_parent = vNewValue
'End Property

'Public Property Get Epoch() As Variant
    'Epoch = this.m_lastEpoch
'End Property

'Public Property Let Epoch(ByVal vNewValue As Variant)
    'this.m_lastEpoch = vNewValue
'End Property

'Public Property Get ResultTime() As Variant
    'ResultTime = this.m_lastResult
'End Property

'Public Property Let ResultTime(ByVal vNewValue As Variant)
    'this.m_lastResult = vNewValue
'End Property

'Public Property Get x() As Variant
    'X = this.m_x
'End Property

'Public Property Let x(ByVal vNewValue As Variant)
    'this.m_x = vNewValue
'End Property

'Public Property Get y() As Variant
    'Y = this.m_y
'End Property

'Public Property Let y(ByVal vNewValue As Variant)
    'this.m_y = vNewValue
'End Property

'Public Property Get z() As Variant
    'Z = this.m_z
'End Property

'Public Property Let z(ByVal vNewValue As Variant)
    'this.m_z = vNewValue
'End Property

