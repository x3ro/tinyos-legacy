% ------------------------------------------------------------------------------
%   Zeevo Dynamic Configuration Script
%
%   Copyright (c) 2002 Zeevo Inc. All rights reserved.
%
% ------------------------------------------------------------------------------
% ------------------------------------------------------------------------------
%  Version Number
% ------------------------------------------------------------------------------
Version                                 uint32 , 0      ;

% ------------------------------------------------------------------------------
%  Platform setting
% ------------------------------------------------------------------------------
Platform_FPGA                           bool   ,  false ;
Platform_DEV                            bool   ,  false ;
Platform_P4                             bool   ,  true  ;
Platform_ME                             bool   ,  false ;

Interface_EMBEDDED                      bool   ,  false ;
Interface_HCI                           bool   ,  false  ;
Interface_AGENT                         bool   ,  true ;
Interface_ZERIAL                        bool   ,  false ;

Profile_SPP                             bool   ,  false ;
Profile_DUN                             bool   ,  false ;
Profile_FAX                             bool   ,  false ;
Profile_HS                              bool   ,  false ;
Profile_LAN                             bool   ,  false ;
Profile_PAN                             bool   ,  false ;
Profile_BNEP                            bool   ,  false ;
Profile_HID                             bool   ,  false ;
Profile_HCRP                            bool   ,  false ;

% ------------------------------------------------------------------------------
% Zerial Configuration
% ------------------------------------------------------------------------------

% UART
% 0 = eTM_B2400 ,  1 = eTM_B4800,   2 = eTM_B9600,  3 = eTM_B19200
% 4 = eTM_B38400,  5 = eTM_B46875,  6 = eTM_B57600, 7 = eTM_B93750
% 8 = eTM_B115200, 9 = eTM_B187500, 10= eTM_B230400,11= eTM_B375000
%12 = eTM_B460800, 13= eTM_B750000, 14= eTM_B921600

System_UartDefaultBaud                  uint8  ,  8     ;
System_UartDmaFlushThreshold            uint8  ,  8     ;
System_UartDmaRtsThreshold              uint8  ,  10    ;

% Zerial flags: 0 = disable, 1 = enable (must be in decimal!!)
% bit 0: Enable/disable host output strings (events)
% bit 1: Enable/disable disconnect notification
% bit 2: Reserved
% bit 3: Allow bonding
% bit 4: Enable link level security
% bit 5: Enable DSM blocking GPIO
ZR_Flags                                uint8   , 0x01 ;

% Default Zerial Class of device
% Use as defined in Bluetooth Assigned Numbers
% Examples, as Byte2, Byte1, Byte0:
% Misc: 0d = 0x00 (none), 0d = 0x00 (misc), 0d = 0x00 (misc)
% Modem: 66d = 0x42 (telephony, networking), 2d = 0x02 (phone), 16d = 0x10 (wired modem)
% LAN ap: 2d = 0x02 (networking), 3d = 0x03 (LAP), 0d = 0x00 (fully available)
% Printer: 4d = 0x04 (rendering), 6d = 0x06 (Imaging), 128d = 0x80 (printer, exclusive)
ZR_CodByte2                             uint8   , 0x0 ;
ZR_CodByte1                             uint8   , 0x0 ;
ZR_CodByte0                             uint8   , 0x0 ;

% The local device name can be up to 20 bytes
% Unused bytes MUST contain Null values
ZR_ZerialName0                           uint8  ,  0x5a ;  % Z
ZR_ZerialName1                           uint8  ,  0x65 ;  % e
ZR_ZerialName2                           uint8  ,  0x65 ;  % e
ZR_ZerialName3                           uint8  ,  0x76 ;  % v
ZR_ZerialName4                           uint8  ,  0x6f ;  % o
ZR_ZerialName5                           uint8  ,  0x45 ;  % E
ZR_ZerialName6                           uint8  ,  0x6d ;  % m
ZR_ZerialName7                           uint8  ,  0x62 ;  % b
ZR_ZerialName8                           uint8  ,  0x65 ;  % e
ZR_ZerialName9                           uint8  ,  0x64 ;  % d
ZR_ZerialName10                          uint8  ,  0x64 ;  % d
ZR_ZerialName11                          uint8  ,  0x65 ;  % e
ZR_ZerialName12                          uint8  ,  0x64 ;  % d
ZR_ZerialName13                          uint8  ,  0x44 ;  % D
ZR_ZerialName14                          uint8  ,  0x65 ;  % e
ZR_ZerialName15                          uint8  ,  0x76 ;  % v
ZR_ZerialName16                          uint8  ,  0x69 ;  % i
ZR_ZerialName17                          uint8  ,  0x63 ;  % c
ZR_ZerialName18                          uint8  ,  0x65 ;  % e
ZR_ZerialName19                          uint8  ,  NULL ;  % Null

% Deep Sleep
System_DeepSleepEnable                  bool   ,  true ;
System_12MCrystalWakeupDelay_TC2000     uint16 ,  32    ; % ms , max 32 ms
System_12MCrystalWakeupDelay_TC2001     uint16 ,  13    ; % ms , max 32 ms
System_12MCrystalWakeupDelay_ZV4002     uint16 ,  13    ; % ms , max 8650 ms
System_DeepSleepSwWakeupDelay           uint16 ,  4     ; % ms

% Page Scan can be locked to disabled
ZerialSys_PageScanDisableLock           bool    , false  ;

% Inquiry Scan can be locked to disabled
ZerialSys_InqScanDisableLock            bool    , false  ;

% Enable dynamic configuration of bonding PIN code
Zerial_Dynamic_Config_PIN               bool, false;

% If enabled, the Default PIN code (must be NULL terminated):
Zerial_PIN0                             uint8, 0x31;  % 1
Zerial_PIN1                             uint8, 0x32;  % 2
Zerial_PIN2                             uint8, 0x33;  % 3
Zerial_PIN3                             uint8, 0x34;  % 4
Zerial_PIN4                             uint8, NULL;  % Null
Zerial_PIN5                             uint8, NULL;  % Null
Zerial_PIN6                             uint8, NULL;  % Null
Zerial_PIN7                             uint8, NULL;  % Null
Zerial_PIN8                             uint8, NULL;  % Null
Zerial_PIN9                             uint8, NULL;  % Null
Zerial_PIN10                            uint8, NULL;  % Null
Zerial_PIN11                            uint8, NULL;  % Null
Zerial_PIN12                            uint8, NULL;  % Null
Zerial_PIN13                            uint8, NULL;  % Null
Zerial_PIN14                            uint8, NULL;  % Null
Zerial_PIN15                            uint8, NULL;  % Null

% Using 32.768K crystal instead of a 32K
System_Use_32_7K_Crystal                bool    , false  ;


% ------------------------------------------------------------------------------
% Debug Configuration
% ------------------------------------------------------------------------------

Debug_UsingBackupRadio                  bool   ,  false >
                                        true   @  Platform_FPGA ;

% Probe Mux
Debug_ProbeMuxOn                        bool   ,  false ;
Debug_EnableDefaultMuxGroup             bool   ,  false ;
Debug_MuxGroup                          uint32 ,  0x0000;
Debug_MuxGpio                           uint32 ,  0x0000;

Debug_EnableGoggleBoard                 bool   ,  false ;
Debug_EnableRfJtag                      bool   ,  false ;

% Log
Debug_XramLogForP4                      bool   ,  false ;
Debug_MaxLogSize                        uint32 ,  5000  ;

% GPIO
Debug_EnableLedsToGpio                  bool   ,  true  ;
Debug_DisableGpioInterrupt              bool   ,  false >
                                        true   @  Platform_FPGA ;

% RF parameter modification area. An entry here overrides Matt's compiled-in value.
Debug_RfpEnable_34                      bool   ,  false ;
Debug_RfpValue__34                      uint16 ,  0     ;
Debug_RfpEnable_34_Late                 bool   ,  false ;
Debug_RfpValue__34_Late                 uint16 ,  0     ;
Debug_RfpEnable_40                      bool   ,  false ;
Debug_RfpValue__40                      uint16 ,  0     ;
Debug_RfpEnable_42                      bool   ,  false ;
Debug_RfpValue__42                      uint16 ,  0     ;
Debug_RfpEnable_44                      bool   ,  false ;
Debug_RfpValue__44                      uint16 ,  0     ;
Debug_RfpEnable_46                      bool   ,  false ;
Debug_RfpValue__46                      uint16 ,  0     ;
Debug_RfpEnable_48                      bool   ,  false ;
Debug_RfpValue__48                      uint16 ,  0     ;
Debug_RfpEnable_4A                      bool   ,  false ;
Debug_RfpValue__4A                      uint16 ,  0     ;
Debug_RfpEnable_4C                      bool   ,  false ;
Debug_RfpValue__4C                      uint16 ,  0     ;
Debug_RfpEnable_4E                      bool   ,  false ;
Debug_RfpValue__4E                      uint16 ,  0     ;
Debug_RfpEnable_50                      bool   ,  false ;
Debug_RfpValue__50                      uint16 ,  0     ;
Debug_RfpEnable_52                      bool   ,  false ;
Debug_RfpValue__52                      uint16 ,  0     ;
Debug_RfpEnable_54                      bool   ,  false ;
Debug_RfpValue__54                      uint16 ,  0     ;
Debug_RfpEnable_56                      bool   ,  false ;
Debug_RfpValue__56                      uint16 ,  0     ;
Debug_RfpEnable_58                      bool   ,  false ;
Debug_RfpValue__58                      uint16 ,  0     ;
Debug_RfpEnable_5A                      bool   ,  false ;
Debug_RfpValue__5A                      uint16 ,  0     ;
Debug_RfpEnable_5C                      bool   ,  false ;
Debug_RfpValue__5C                      uint16 ,  0     ;
Debug_RfpEnable_5E                      bool   ,  false ;
Debug_RfpValue__5E                      uint16 ,  0     ;
Debug_RfpEnable_60                      bool   ,  false ;
Debug_RfpValue__60                      uint16 ,  0     ;
Debug_RfpEnable_62                      bool   ,  false ;
Debug_RfpValue__62                      uint16 ,  0     ;
Debug_RfpEnable_64                      bool   ,  false ;
Debug_RfpValue__64                      uint16 ,  0     ;
Debug_RfpEnable_66                      bool   ,  false ;
Debug_RfpValue__66                      uint16 ,  0     ;
Debug_RfpEnable_68                      bool   ,  false ;
Debug_RfpValue__68                      uint16 ,  0     ;
Debug_RfpEnable_6A                      bool   ,  false ;
Debug_RfpValue__6A                      uint16 ,  0     ;
Debug_RfpEnable_6C                      bool   ,  false ;
Debug_RfpValue__6C                      uint16 ,  0     ;
Debug_RfpEnable_6E                      bool   ,  false ;
Debug_RfpValue__6E                      uint16 ,  0     ;
Debug_RfpEnable_70                      bool   ,  false ;
Debug_RfpValue__70                      uint16 ,  0     ;
Debug_RfpEnable_72                      bool   ,  false ;
Debug_RfpValue__72                      uint16 ,  0     ;
Debug_RfpEnable_74                      bool   ,  false ;
Debug_RfpValue__74                      uint16 ,  0     ;
Debug_RfpEnable_76                      bool   ,  false ;
Debug_RfpValue__76                      uint16 ,  0     ;
Debug_RfpEnable_78                      bool   ,  false ;
Debug_RfpValue__78                      uint16 ,  0     ;
Debug_RfpEnable_7A                      bool   ,  false ;
Debug_RfpValue__7A                      uint16 ,  0     ;
Debug_RfpEnable_7C                      bool   ,  false ;
Debug_RfpValue__7C                      uint16 ,  0     ;
Debug_RfpEnable_7E                      bool   ,  false ;
Debug_RfpValue__7E                      uint16 ,  0     ;

% ------------------------------------------------------------------------------
% System Configuration
% ------------------------------------------------------------------------------

System_ForceHciUsingUartInterface       bool   ,  false ;

% USB
System_UsbSidebandSig                   bool   ,  false ;
% USB Vendor ID and Product ID
System_UsbVid		                uint16 ,  0x0B7A ;
System_UsbPid		                uint16 ,  0x07D0 ;

% Timer Server
System_MaxNumOfTimers                   uint16 ,  20    ;

% GPIO
System_NonGPIOPadResisterCfg            uint16 ,  0     ;
System_GPIOPadResisterCfg               uint16 ,  0     ;

% External RAM address start at 0x400000,
% 64=0x40 => No External Memory
% 72=0x48 => 512k Bytes External Memory
% 80=0x50 => 1M Bytes External Memory
System_XramEndHighAddr                  uint16 ,  0x48  >
                                        0x40   @  Platform_P4;
System_Class1                           bool   ,  false ;


% ------------------------------------------------------------------------------
% HTL Configuration
% ------------------------------------------------------------------------------

% Signal pool
HTL_GeneralShortBufNum                  uint8  ,  12  >
                                        30     @  Interface_HCI >
                                        10     @  Platform_FPGA ;

HTL_GeneralShortBufSize                  uint16 ,  120  ;

HTL_GeneralLongBufNum                   uint8  ,  2   >
                                        6      @  Interface_HCI >
                                        2      @  Platform_FPGA ;

HTL_GeneralLongBufSize                  uint16 ,  400 >
                                        300    @  Interface_HCI ;

% ------------------------------------------------------------------------------
% BlueOS Configuration
% ------------------------------------------------------------------------------

BP_BufMemPoolBlocks                     uint8  ,  12    ; % was 64
BP_BufMemPoolBlockSize                  uint16 ,  128   ; % was 200

% ------------------------------------------------------------------------------
% GKI buffer configuration - only used for Zerial builds
% with #ifdef FTR_GKI_REDUCED_SIZE_MEM_POOLS in target.h
% ------------------------------------------------------------------------------

GKI_Buf0_Max              uint8  ,  5  ; 64 byte, Used for service discovery (reduced from 48 to 5)
GKI_Buf1_Max              uint8  ,  2  ; 128 byte, (reduced from 20 to 2)
GKI_Buf2_Max              uint8  ,  10 ; 660 byte

% Currently the major user for this is SPP when it does discovery. It needs a minimum of 2 (reduced from 5)
GKI_Buf3_Max              uint8  ,  2  ; 1540 byte

GKI_Buf4_Max              uint8  ,  5  ; 125 byte

% ------------------------------------------------------------------------------
% Target Supervisor Configuration
% ------------------------------------------------------------------------------
%  The buffer output debug channels must support the following configurations.

TS_PrintfBufNum                         uint8  ,  8  ;
TS_PrintfBufSize                        uint16 ,  70 ;

% ------------------------------------------------------------------------------
% HTL Configuration
% ------------------------------------------------------------------------------

% TX direction ACL data buffers
HTL_ToLmNoOfBuffers                     uint8  ,  4  >
                                        8      @  Interface_HCI >
                                        2      @  Platform_FPGA >
                                        12     @  Interface_AGENT ;

HTL_ToLmDataBufferHeaderSize            uint8  ,  32 >
                                        64     @  Interface_AGENT ;

HTL_ToLmDataBufferSize                  uint16 ,  339 >
                                        678    @  Interface_HCI >
                                        339    @  Platform_FPGA >
                                        400    @  Interface_AGENT ;


HTL_ToLmNoOfScoBuffers                  uint8  ,  12  >
                                        1      @  Platform_FPGA >
                                        0      @ Interface_ZERIAL; %No SCO UART Buffers for Zerial


HTL_ToLmScoBufferHeaderSize             uint8  ,  32 ;

HTL_ToLmScoBufferSize                   uint16 ,  120    >
                                        1      @  Platform_FPGA ;

% Should be around LM_NOfRxScoBuffers-2
HTL_ScoDropThreshold                    uint16 ,  100  ;

% ------------------------------------------------------------------------------
% BBD Configuration
% ------------------------------------------------------------------------------

% TX direction sco-over-uart configuration
BBD_ScoAddSampleThreshold               uint16 ,  4  ;
BBD_ScoDropSampleThreshold              uint16 ,  8  ;
BBD_ScoDropBufThreshold                 uint16 ,  100;

% Tpoll
BBD_Tpoll                               uint16 , 20;

% 0 => SCO data routed to PCM, but no codec setup sent on GPIO
% 1 => SCO data routed to PCM, setup for OKI MM7732 sent on GPIO
% 2 => SCO data routed to PCM, setup for OKI MM7716 sent on GPIO
% 3 => SCO data routed to HCI UART
BBD_Codec                               uint8  , 3;


% ------------------------------------------------------------------------------
% Link Manager Configuration
% ------------------------------------------------------------------------------

% Feature Set
% LM Features 0 Configuration
LM_Feature0_00_3_SLOT_PKT               bool   ,  true  ;
LM_Feature0_01_5_SLOT_PKT               bool   ,  true  ;
LM_Feature0_02_ENCRYPTION               bool   ,  true  ;
LM_Feature0_03_SLOT_OFFSET              bool   ,  true  ;
LM_Feature0_04_TIMING_ACCURACY          bool   ,  true  ;
LM_Feature0_05_SWITCH                   bool   ,  true  ;
LM_Feature0_06_HOLD_MODE                bool   ,  true  ;
LM_Feature0_07_SNIFF_MODE               bool   ,  true  ;

% LM Features 1 Configuration
LM_Feature1_00_PARK_MODE                bool   ,  true  ;
LM_Feature1_01_RSSI                     bool   ,  true  ;
LM_Feature1_02_CHANN_QUAL_DATA_RATE     bool   ,  true  ;

LM_Feature1_03_SCO_LINK                 bool   ,  true  >
                                        false @Interface_ZERIAL; // Turn off SCO for Zerial

LM_Feature1_04_HV2_PKT                  bool   ,  true  >
                                        false @Interface_ZERIAL; // Turn off SCO for Zerial

LM_Feature1_05_HV3_PKT                  bool   ,  true  >
                                        false @Interface_ZERIAL; // Turn off SCO for Zerial

LM_Feature1_06_U_LAW                    bool   ,  true  >
                                        false @Interface_ZERIAL; // Turn off SCO for Zerial

LM_Feature1_07_A_LAW                    bool   ,  true  >
                                        false @Interface_ZERIAL; // Turn off SCO for Zerial


% LM Features 2 Configuration
LM_Feature2_00_CVSD                     bool   ,  true  >
                                        false @Interface_ZERIAL; // Turn off SCO for Zerial

LM_Feature2_01_PAGING_SCHEME            bool   ,  false ;
LM_Feature2_02_POWER_CONTROL            bool   ,  true  ;
LM_Feature2_03_TRANS_SCO_DATA           bool   ,  false ;
LM_Feature2_04_FLOW_CONTROL_LAG_0       bool   ,  false ;
LM_Feature2_05_FLOW_CONTROL_LAG_1       bool   ,  false ;
LM_Feature2_06_FLOW_CONTROL_LAG_2       bool   ,  false ;
LM_Feature2_07_BCAST_ENCRYPTION         bool   ,  true  ;

% Bluetooth 1.2 Features AFH & eSCO
% LM Features 3 Configuration

LM_Feature3_00_SCATTER_MODE             bool   ,  true ;

LM_Feature3_03_ENHANCED_1STFHS_INQ_SCAN bool   ,  true ;
LM_Feature3_04_INTERLACED_INQ_SCAN      bool   ,  true ;
LM_Feature3_05_INTERLACED_PAGE_SCAN     bool   ,  true ;
LM_Feature3_06_INQ_RESULT_WITH_RSSI     bool   ,  true ;
LM_Feature3_07_EXTENDED_SCO_EV3         bool   ,  true ;


% LM Features 4 Configuration
LM_Feature4_00_EXTENDED_SCO_EV4         bool   ,  true ;
LM_Feature4_01_EXTENDED_SCO_EV5         bool   ,  true ;
LM_Feature4_02_ABSENCE_MASKS            bool   ,  false;

LM_Feature4_03_AFH_CAPABLE_SLAVE        bool   ,  true  ;
LM_Feature4_04_AFH_CLASSFN_SLAVE        bool   ,  true  ;

LM_Feature4_05_ALIAS_AUTHENTICATION     bool   ,  false ;
LM_Feature4_06_ANONYMITY_MODE           bool   ,  true  ;

% LM Features 5 Configuration
LM_Feature5_03_AFH_CAPABLE_MASTER       bool   ,  true  ;
LM_Feature5_04_AFH_CLASSFN_MASTER       bool   ,  true  ;

% LM Features 7 Configuration
LM_Feature7_07_EXTENDED_FEATURES        bool   ,  false ;



% RX direction ACL data buffers
LM_NoOfDataBuffers                      uint8  ,  14    >
                                        4      @  Platform_FPGA ;
LM_UpperHeadSize                        uint8  ,  48    >
                                        72     @  Interface_AGENT;

LM_DataBodySize                         uint16 ,  393   ;

% RX direction SCO data buffers
LM_NOfRxScoBuffers                      uint8  ,  6    >
                                        0      @  Platform_FPGA >
                                        0      @ Interface_ZERIAL; %No SCO UART Buffers for Zerial

LM_NOfRxScoHeaderSize                   uint8  ,  48    >
                                        32     @  Interface_HCI >
                                        72     @  Interface_AGENT;

LM_NOfRxScoBodySize                     uint16 ,  240    >
                                        1      @  Platform_FPGA ;

% Maximum number of active links allowed - for Zerial Interface we choose P2P
% only in features. Hence the links is set to 1. Otherwise normally to 10
% (7 slaves + 3 masters)
LM_MaxNoLinksAllowed                    uint8   ,  10   >
                                        1       @  Interface_ZERIAL ;

LM_MaxNoOfParkedSlaves                  uint8   ,  10   >
                                        1       @  Interface_ZERIAL ;

% Number entries to have in LM neighborhood database. Upper layers has to do
% more inquiry filtering for new devices depending on their memory availability.
% Cannot rely on LM which uses this database
LM_NoOfBNCB                             uint8   ,  20  ;

% Link Supervision Tmo
LM_LinkSupervisionTimeout               uint16  ,  32000  ;

% LM Scheduling Type
LM_SchedulingType                       uint8   , 0;

% ------------------------------------------------------------------------------
% ZPP/ULS Configuration
% ------------------------------------------------------------------------------

% Number of datanodes allocated in LLS must be at least the number of available
% TX databuffers (acl + sco) used in ULS (LLS Rx is allocated automatically).
ULS_MaxNoTxBufs                         uint8   , 20 ;

% ------------------------------------------------------------------------------
% ULS Configuration
% ------------------------------------------------------------------------------
% Upper Layer Stack Settings
ULS_NoOfDataBufs                        uint8   , 4   >
                                        1       @ Interface_AGENT ;
ULS_DataBufferSize                      uint16  , 400 >
                                        1       @ Interface_AGENT ;

% Peer to peer message pool
ULS_NoP2pBufs                           uint8   , 10  ;
ULS_P2pBufSize                          uint16  , 370 ;

Uls_BTE_FECLock                       bool, false;

% ------------------------------------------------------------------------------
% L2CAP Configuration
% ------------------------------------------------------------------------------
% L2 Lower
L2_MaxLLCons                            uint8   , 7 ;

% L2CAP
L2_EnableRaw                            bool    , true ;
L2_MaxInMtu                             uint16  , 335  ;
L2_RawHeaderSize                        uint8   , 9    ;
L2_MaxNoUpperLayers                     uint8   , 5    ;
L2_MaxNoCons                            uint8   , 10   ;
L2_UseTimers                            uint8   , 1    ;
L2_UseLLDiscTimer                       uint8   , 1    ;

% ------------------------------------------------------------------------------
% SDP Configuration
% ------------------------------------------------------------------------------
SDP_Enable                              bool    , true ;
SDP_NoOfServiceRecords                  uint8   , 2    ;

% CAUTION:: Should not be changed to a value greater than 320 below !!!
SDP_ServiceRecordMaxSize                uint16  , 200  >
                                        320     @ Profile_HID      ;

% ------------------------------------------------------------------------------
% RFCOMM Configuration
% ------------------------------------------------------------------------------
RFC_Enable                              bool    , false >
                                        true    @ Interface_AGENT  >
                                        true    @ Interface_ZERIAL >
                                        true    @ Profile_DUN      >
                                        true    @ Profile_SPP      >
                                        true    @ Profile_FAX      >
                                        true    @ Profile_HS       >
                                        true    @ Profile_LAN      ;

RFC_NoProfilesSupported                 uint8   , 10   ;
RFC_MaxNoOfCons                         uint8   , 10   ;


% ------------------------------------------------------------------------------
% HS Configuration
% ------------------------------------------------------------------------------
HS_SetHeadSetRoleToAG                   bool    , false ;

% ------------------------------------------------------------------------------
% BNEP Configuration
% ------------------------------------------------------------------------------
BNEP_Enable                             bool    , false >
                                        true    @ Profile_PAN ;

BNEP_L2Mtu                              uint16  , 1691 ;


% ------------------------------------------------------------------------------
% HID Configuration
% ------------------------------------------------------------------------------

HIDAPP_NormallyConnectable                    bool   ,  true ;

% ------------------------------------------------------------------------------
% Applications

% Mouse app
HIDAPP_MouseEnabled                           bool   ,  true ;
HIDAPP_MouseReconnectInit                     bool   ,  true ;

% Keyboard app
HIDAPP_KeyboardEnabled                        bool   ,  false ;
HIDAPP_KeyboardReconnectInit                     bool   ,  true ;

% ------------------------------------------------------------------------------
% Temp Test  => Should be removed later
% ------------------------------------------------------------------------------
%Temp test defines
Temp_UlsTest_00                         bool    , false ;
Temp_UlsTest_01                         bool    , false ;
Temp_UlsTest_02                         bool    , false ;
Temp_UlsTest_03                         bool    , false ;
Temp_UlsTest_04                         bool    , false ;
Temp_UlsTest_05                         bool    , false ;
