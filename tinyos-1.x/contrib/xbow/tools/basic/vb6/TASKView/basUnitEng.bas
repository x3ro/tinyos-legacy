Attribute VB_Name = "basUnitEng"
''====================================================================
'' basUnitEng.bas
''====================================================================
'' DESCRIPTION:  Library of routines for converting raw sensor
''               readings into engineering units.
''
'' HISTORY:      mturon      2004/2/11    Initial revision
''
'' $Id: basUnitEng.bas,v 1.4 2004/03/30 04:10:46 mturon Exp $
''====================================================================

Enum et_UnitType
    UNIT_TYPE_ALL_RAW
    UNIT_TYPE_TEMP_C
    UNIT_TYPE_TEMP_F
    UNIT_TYPE_TEMP_K
    UNIT_TYPE_PRESS_ATM
    UNIT_TYPE_PRESS_BAR
    UNIT_TYPE_PRESS_PA
    UNIT_TYPE_PRESS_PSI
    UNIT_TYPE_PRESS_TORR
    UNIT_TYPE_ACCEL_G
    UNIT_TYPE_ACCEL_MPS2
End Enum

Public g_unitTemp           'temperature: specific et_UnitType
Public g_unitPress          'pressure: specific et_UnitType
Public g_unitAccel          'acceleration: specific et_UnitType

'====================================================================
' UnitRawConvert_temp
'====================================================================
' DESCRIPTION:  Converts raw Panasonic ERT-J1VR103J readings to Celcius.
'               This sensor is found on the Crossbow MTS300 board.
' HISTORY:      mturon      2004/2/25    Initial version
'
Public Function UnitRawConvert_temp(rawUnits As Long) As Single
    UnitRawConvert_temp = rawUnits
    If g_unitTemp = UNIT_TYPE_ALL_RAW Then
        Exit Function
    End If
    
    If (rawUnits = 0) Then
        Exit Function
    End If
                
    Dim a, b, C, ADC_FS, R1, Rt, ADC As Single
    ADC = CSng(rawUnits)
    a = 0.00130705
    b = 0.00021438
    C = 0.000000093
    ADC_FS = 1023
    R1 = 10000
            
    Rt = R1 * (ADC_FS - ADC) / ADC
    If (Rt <= 0) Then
        Exit Function
    End If
            
    UnitRawConvert_temp = (1 / (a + b * Log(Rt) + C * Log(Rt) ^ 3)) - 273#
End Function

'====================================================================
' UnitRawConvert_humtemp
'====================================================================
' DESCRIPTION:  Converts raw Sensirion.com SHT11 readings to Celcius.
'               This sensor is found on the Crossbow MTS400 board.
' HISTORY:      mturon      2004/2/26    Initial version
'
Public Function UnitRawConvert_humtemp(rawUnits As Long) As Single
    UnitRawConvert_humtemp = rawUnits
    If g_unitTemp = UNIT_TYPE_ALL_RAW Then
        Exit Function
    End If
    
    Dim d1, d2 As Single
    ' Celcius
    d1 = -39.75     '4.0V C
    d2 = 0.01       '14-bit C
    ' Fahrenheit
    'd1 = -39.5       ' 4.0V F
    'd2 = 0.018       '14-bit F
    UnitRawConvert_humtemp = d1 + d2 * CSng(rawUnits)
End Function

Public Function UnitRawConvert_humtempwb(rawUnits As Long) As Single
    UnitRawConvert_humtempwb = rawUnits
    If g_unitTemp = UNIT_TYPE_ALL_RAW Then
        Exit Function
    End If
    Dim T As Single
    T = ((CSng(rawUnits) / 100# - 32#) * (5# / 9#))
    UnitRawConvert_humtempwb = T
End Function


'====================================================================
' UnitCalibration_MTS400
'====================================================================
' DESCRIPTION:  Returns parsed calibration values for the pressure
'               sensor on a Crossbow MTS400 board.
' HISTORY:      mturon      2004/2/27    Initial version
'
Public Function UnitCalibration_MTS400(nodeid As Integer) As Variant
    
    Dim bitsH, bitsL As Long  ' Temp shift registers for debuging
    Dim C(6) As Long          ' Define 6 word result array for parsed consts
    Dim calibration() As Long ' Variant for 4 word compressed constants
    Dim moteInfo As objMote
    
    Set moteInfo = g_MoteInfo.Item(nodeid)
    calibration = moteInfo.m_calib
    'calibration = TaskInfo.mote_calib(nodeid)
    
    '===> from TestMTS400M.nc [abroad]
    'C1 = calibration[0] >> 1;
    'C2 = ((calibration[2] &  0x3f) << 6) |  (calibration[3] &  0x3f);
    'C3 = calibration[3]  >> 6;
    'C4 = calibration[2]  >> 6;
    'C5 = ((calibration[0] &  1) << 10) |  (calibration[1] >>  6);
    'C6 = calibration[1] &  0x3f;
           
    'C6 = calibration[1] &  0x3f;
    C(6) = calibration(1) And &H3F
    
    'C5 = ((calibration[0] &  1) << 10) |  (calibration[1] >>  6);
    bitsH = calibration(0) And 1          ' top bit
    bitsL = calibration(1)                ' bottom byte
    bitsH = WSHFTL(bitsH, 10)
    bitsL = WSHFTR(bitsL, 6)
    C(5) = bitsH Or bitsL
        
    'C4 = calibration[2]  >> 6;
    bitsL = calibration(2)
    C(4) = WSHFTR(bitsL, 6)
    
    'C3 = calibration[3]  >> 6;
    bitsL = calibration(3)
    C(3) = WSHFTR(bitsL, 6)
    
    'C2 = ((calibration[2] &  0x3f) << 6) |  (calibration[3] &  0x3f);
    bitsH = calibration(2) And &H3F       ' top bit
    bitsL = calibration(3) And &H3F       ' bottom byte
    bitsH = WSHFTL(bitsH, 6)
    C(2) = bitsH Or bitsL
    
    'C1 = calibration[0] >> 1;
    bitsL = calibration(0)
    C(1) = WSHFTR(bitsL, 1)
    
    'C(6) = calibration(3) And &H3F
    'bitsH = calibration(2) And 1          ' top bit
    'bitsL = calibration(3)                ' bottom byte
    'bitsH = LShift16((bitsH), 10)
    'bitsL = RShift16((bitsL), 6)
    'C(5) = bitsH Or bitsL
    
    UnitCalibration_MTS400 = C
End Function

'====================================================================
' UnitRawConvert_prtemp
'====================================================================
' DESCRIPTION:  Converts raw Intersema.ch MS5534 readings to Celcius.
'               This sensor is found on the Crossbow MTS400 board.
' HISTORY:      mturon      2004/2/26    Initial version
'
Public Function UnitRawConvert_prtemp(rawUnits As Long, nodeid As Integer) As Single
    UnitRawConvert_prtemp = rawUnits
    If g_unitTemp = UNIT_TYPE_ALL_RAW Then
        Exit Function
    End If
    
    Dim UT1, dT As Long
    Dim T As Single
    Dim C() As Long     ' Visual BASIC has no unsigned type... need to use long
                        ' Will convert such conversions to C functions...
    C = UnitCalibration_MTS400(nodeid)
    
    UT1 = 8 * C(5) + 20224                '21384
    
    'C6 = 20
    'UT1 = 25500
    'UT1 = 8 * (C(5) And &H3FF) + 23456             ' correction hack...
    
    dT = rawUnits - UT1
    T = CSng(200 + dT * (C(6) + 50))
    T = (T / 1024#) / 10#
    
    UnitRawConvert_prtemp = T
End Function

'====================================================================
' UnitRawConvert_press
'====================================================================
' DESCRIPTION:  Converts raw Intersema.ch MS5534 readings to mBar.
'               This sensor is found on the Crossbow MTS400 board.
' HISTORY:      mturon      2004/2/27    Initial version
'
Function UnitRawConvert_press(rawUnits As Long, nodeid As Integer) As Single
    UnitRawConvert_press = rawUnits
    If g_unitPress = UNIT_TYPE_ALL_RAW Then
        Exit Function
    End If
        
    Dim OFF, SENS, X, P As Single
    
    OFF = C2 * 4 + ((C4 - 512) * dT) / 2 ^ 12
    SENS = C1 + (C3 * dT) / 2 ^ 10 + 24576
    X = (SENS * (d1 - 7168)) / 2 ^ 10 + 24576
    P = X * 100 / 2 ^ 5 + 250 * 100
    
    UnitRawConvert_press = rawUnits 'P
End Function

'====================================================================
' UnitRawConvert
'====================================================================
' DESCRIPTION:  Calls the proper low-level conversion routine for
'               a given sensor to return engineering units from a
'               raw reading.
' HISTORY:      mturon      2004/2/25    Initial version
'
Public Function UnitRawConvert(rawUnits As Long, sensorId As Integer, moteId As Integer) As Single
    
    ' rawUnits = TaskDataArray(nodeid).Value(sensorId)
    UnitRawConvert = rawUnits               ' Always default to pass-through
    
    Dim sensorName As String
    sensorName = TaskInfo.sensor(sensorId)  ' Get sensor name
    
    Select Case sensorName                  ' Jump table of conversions based on name
        Case "humtemp"
            UnitRawConvert = UnitRawConvert_humtempwb(rawUnits)
        Case "prtemp"
            UnitRawConvert = UnitRawConvert_prtemp(rawUnits, moteId)
        Case "humid"
        Case "taosbot"
        Case "toastop"
        Case "press"
            'UnitRawConvert = UnitRawConvert_press(rawUnits, MoteId)
        Case "hamatop"
        Case "hamabot"

        ' Other sensors
        Case "light"
        Case "accel_x"
        Case "accel_y"
        Case "mag_x"
        Case "mag_y"
        
        ' Malexis sensor reading
        Case "temp"
            UnitRawConvert = UnitRawConvert_temp(rawUnits)
        Case "thmtemp"
    End Select
    
End Function

'====================================================================
' UnitEngConvert
' UnitEngConvertTemp, UnitEngConvertPress, UnitEngConvertAccel
'====================================================================
' DESCRIPTION:  Convert between engineering units from
'               default to specific units.
' HISTORY:      mturon      2004/2/27    Initial version
'
Public Function UnitEngConvert(rawUnits As Long, sensorName As String, nodeid As Integer) As Single
    UnitEngConvert = rawUnits       ' default to pass-through
    
    Select Case sensorName                  ' Jump table of conversions based on name
        Case "voltage"
            If (rawUnits <> 0) Then UnitEngConvert = 1252.352 / CSng(rawUnits)
            
        Case "humtemp"
            UnitEngConvert = _
                UnitEngConvertTemp(UnitRawConvert_humtempwb(rawUnits))
        Case "prtemp"
            UnitEngConvert = _
                UnitEngConvertTemp(UnitRawConvert_prtemp(rawUnits, nodeid))
        Case "humid"
        Case "taosbot"
        Case "toastop"
        Case "press"
            UnitEngConvert = _
                UnitEngConvertPress(UnitRawConvert_press(rawUnits, nodeid))
        Case "hamatop"
        Case "hamabot"

        ' Other sensors
        Case "light"
        Case "accel_x"
            UnitEngConvert = UnitEngConvertAccel((rawUnits))
        Case "accel_y"
            UnitEngConvert = UnitEngConvertAccel((rawUnits))
        Case "mag_x"
        Case "mag_y"
        
        ' Malexis sensor reading
        Case "temp"
            UnitEngConvert = _
                UnitEngConvertTemp(UnitRawConvert_temp(rawUnits))
        Case "thmtemp"
    End Select
End Function

Function UnitEngConvertTemp(stdUnits As Single) As Single
    UnitEngConvertTemp = stdUnits
    Select Case g_unitTemp
        Case UNIT_TYPE_ALL_RAW      ' passthrough raw
        Case UNIT_TYPE_TEMP_C       ' default temperature = C
        Case UNIT_TYPE_TEMP_F
            UnitEngConvertTemp = 9# / 5# * stdUnits + 32#
        Case UNIT_TYPE_TEMP_K
            UnitEngConvertTemp = 273# + stdUnits
    End Select
End Function

Function UnitEngConvertPress(stdUnits As Single) As Single
    UnitEngConvertPress = stdUnits
    Select Case g_unitPress
        Case UNIT_TYPE_ALL_RAW      ' passthrough raw
        Case UNIT_TYPE_PRESS_ATM    ' default pressure = atm
        Case UNIT_TYPE_PRESS_BAR
            UnitEngConvertPress = 1.01325 * stdUnits
        Case UNIT_TYPE_PRESS_PA
            UnitEngConvertPress = 101325 * stdUnits
        Case UNIT_TYPE_PRESS_TORR
            UnitEngConvertPress = 760# * stdUnits
        Case UNIT_TYPE_PRESS_PSI
            UnitEngConvertPress = 14.7 * stdUnits
    End Select
End Function

Function UnitEngConvertAccel(stdUnits As Single) As Single
    UnitEngConvertAccel = stdUnits
    Select Case g_unitAccel
        Case UNIT_TYPE_ALL_RAW      ' passthrough raw
        Case UNIT_TYPE_ACCEL_G      ' default acceleration = g
        Case UNIT_TYPE_ACCEL_MPS2
            UnitEngConvertAccel = stdUnits / 9.8
    End Select
End Function


'====================================================================
' UnitEngGetName
' UnitEngGetNameTemp, UnitEngGetNamePress, UnitEngGetNameAccel
'====================================================================
' DESCRIPTION:  Returns the unit name used by the given sensor.
' HISTORY:      mturon      2004/2/27    Initial version
'
Function UnitEngGetName(sensorName As String) As String
    UnitEngGetUnitName = ""       ' Always default to none
    Select Case sensorName        ' Jump table of unit strings based on sensor
        Case "voltage"
            UnitEngGetName = "V"
            
        Case "humtemp"
            UnitEngGetName = UnitEngGetNameTemp
        Case "prtemp"
            UnitEngGetName = UnitEngGetNameTemp
        Case "humid"
        Case "taosbot"
        Case "toastop"
        Case "hamatop"
        Case "hamabot"
        Case "press"
            UnitEngGetName = UnitEngGetNamePress

        ' Other sensors
        Case "light"
        Case "accel_x"
            UnitEngGetName = UnitEngGetNameAccel
        Case "accel_y"
            UnitEngGetName = UnitEngGetNameAccel
        Case "mag_x"
        Case "mag_y"
        
        ' Malexis sensor reading
        Case "temp"
            UnitEngGetName = UnitEngGetNameTemp
        Case "thmtemp"
    End Select
End Function

Function UnitEngGetNameTemp() As String
    UnitEngGetNameTemp = ""
    Select Case g_unitTemp
        Case UNIT_TYPE_TEMP_C       ' default temperature = C
            UnitEngGetNameTemp = "C"
        Case UNIT_TYPE_TEMP_F
            UnitEngGetNameTemp = "F"
        Case UNIT_TYPE_TEMP_K
            UnitEngGetNameTemp = "K"
    End Select
End Function

Function UnitEngGetNamePress() As String
    UnitEngGetNamePress = ""
    Select Case g_unitPress
        Case UNIT_TYPE_PRESS_ATM    ' default pressure = atm
            UnitEngGetNamePress = "atm"
        Case UNIT_TYPE_PRESS_BAR
            UnitEngGetNamePress = "bar"
        Case UNIT_TYPE_PRESS_PA
            UnitEngGetNamePress = "Pa"
        Case UNIT_TYPE_PRESS_TORR
            UnitEngGetNamePress = "torr"
        Case UNIT_TYPE_PRESS_PSI
            UnitEngGetNamePress = "psi"
    End Select
End Function

Function UnitEngGetNameAccel() As String
    UnitEngGetNameAccel = ""
    Select Case g_unitAccel
        Case UNIT_TYPE_ACCEL_G      ' default acceleration = g
            UnitEngGetNameAccel = "g"
        Case UNIT_TYPE_ACCEL_MPS2
            UnitEngGetNameAccel = "m/s^2"
    End Select
End Function
