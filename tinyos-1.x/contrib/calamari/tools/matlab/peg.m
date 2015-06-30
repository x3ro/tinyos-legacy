function [varargout] = peg( addr, cmd, varargin )
peginit;
global G_PEG;

%%% Instatiate a default, empty raw message with no AM type
msg = rawMsg( G_PEG.group, [], [] );
protocol = [];

%%% If cmd has a paren, take its arguments as those within the parens.
%%% Compose the message given the cmd string and arguments
origcmd = cmd;
[cmd,cmdargs] = getargs(cmd);
if length(cmdargs) == 0; cmdargs = varargin; end;
ncmdargs = length( cmdargs );
if strcmpi(cmd,'on') || strcmpi(cmd,'On')
    checkargs( cmd, ncmdargs, 0 );
    msg = rawMsg( G_PEG.group, 249, [1 0] );
    
elseif strcmpi(cmd,'off') || strcmpi(cmd,'Off')
    checkargs( cmd, ncmdargs, 0 );
    msg = rawMsg( G_PEG.group, 249, [0 0] );
    
elseif strcmpi(cmd,'reset') || strcmpi(cmd,'Reset')
    checkargs( cmd, ncmdargs, 0 );
    msg = rawMsg( G_PEG.group, 248, [0] );
    
elseif strcmpi(cmd,'GameInit')
    peg(addr,'reset'); pause(0.2);
    peg(addr,'on'); pause(1.3);
    peg(addr,'ident');
    return;

elseif strcmpi(cmd,'GameSensorStruct')
    checkargs( cmd, ncmdargs, 0 );
    s = [];
    s.RFPower = 4;
    s.MagThresh = 150;
    s.MagReadingTimeout = 65536;
    s.MagCenterSendMode = 1;
    s.Service = 10;
    if nargout == 1; varargout{1} = s; end;
    return;
    
elseif strcmpi(cmd,'GamePursuerStruct')
    checkargs( cmd, ncmdargs, 0 );
    s = [];
    s = peg('','GameConfigStruct');
    s.Service = 66;
    if nargout == 1; varargout{1} = s; end;
    return;
    
elseif strcmpi(cmd,'GameSensorConfig')
    checkargs( cmd, ncmdargs, 0:1 );
    s = peg('','GameSensorStruct');
    if ncmdargs == 1; s = cmdargs{1}; end;
    ff = fields(s);
    for n = 1:length(ff); f=ff{n}, peg( addr, f, getfield(s,f) ); pause(0.2); end;
    
elseif strcmpi(cmd,'GameSensorQuery')
    checkargs( cmd, ncmdargs, 0:1 );
    s = peg('','GameSensorStruct');
    if ncmdargs == 1; s = cmdargs{1}; end;
    ff = fields(s);
    for n = 1:length(ff); f=ff{n}, peg( addr, f ); pause(2); end;
    
elseif strcmpi(cmd,'GamePursuerConfig')
    checkargs( cmd, ncmdargs, 0:1 );
    s = peg('','GamePursuerStruct');
    if ncmdargs == 1; s = cmdargs{1}; end;
    ff = fields(s);
    for n = 1:length(ff); f=ff{n}; peg( addr, f, getfield(s,f) ); pause(0.2); end;
    
elseif strcmpi(cmd,'GamePursuerQuery')
    checkargs( cmd, ncmdargs, 0:1 );
    s = peg('','GamePusuerStruct');
    if ncmdargs == 1; s = cmdargs{1}; end;
    ff = fields(s);
    for n = 1:length(ff); f=ff{n}; peg( addr, f ); pause(2); end;

elseif strcmpi(cmd,'SetStruct')
    checkargs( cmd, ncmdargs, 1 );
    if ncmdargs == 1; s = cmdargs{1}; end;
    ff = fields(s);
    for n = 1:length(ff); f=ff{n}; peg( addr, f, getfield(s,f) ); pause(0.2); end;
    
elseif strcmpi(cmd,'QueryStruct')
    checkargs( cmd, ncmdargs, 1 );
    if ncmdargs == 1; s = cmdargs{1}; end;
    ff = fields(s);
    for n = 1:length(ff); f=ff{n}; peg( addr, f ); pause(0.2); end;
    
elseif strcmpi(cmd,'ChangeGroupId')
    checkargs( cmd, ncmdargs, 2 );
    msg = rawMsg( G_PEG.group, 247, [] );
    msg.push_uint8( cmdargs{1} );
    msg.push_uint16( cmdargs{2} );

elseif strcmpi(cmd,'MsgBuffersDebug')
    checkargs( cmd, ncmdargs, 1 );
    msg = rawMsg( G_PEG.group, 11, [cmdargs{1}] );
    
elseif strcmpi(cmd,'ident') || strcmpi(cmd,'Ident')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8( 1 );
    protocol = 180;
    
elseif strcmpi(cmd,'ConfigStore')
    checkargs( cmd, ncmdargs, 1 );
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 11 );
    protocol = 180;
    
elseif strcmpi(cmd,'DefaultConfig')
    peg(addr,'ConfigStore(0)');
    return;
    
elseif strcmpi(cmd,'ReadConfig')
    peg(addr,'ConfigStore(1)');
    return;
    
elseif strcmpi(cmd,'WriteConfig')
    peg(addr,'ConfigStore(2)');
    return;
    
elseif strcmpi(cmd,'magstatus') || strcmpi(cmd,'MagStatus')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8( 0 );
    msg.push_uint8( 58 );
    protocol = 180;
    
elseif strcmpi(cmd,'MagPurge')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8( 226 );
    msg.push_uint8( 58 );
    protocol = 180;
    
elseif strcmpi(cmd,'streinit') || strcmpi(cmd,'STReinit')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8( 32 );
    protocol = 180;
    
elseif strcmpi(cmd,'ststatus') || strcmpi(cmd,'STStatus')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8( 34 );
    protocol = 180;
    
elseif strcmpi(cmd,'service') || strcmpi(cmd,'Service')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(134)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 133 );
    protocol = 200;

elseif strcmpi(cmd,'InitialService')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(135)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 135 );
    protocol = 200;

elseif strcmpi(cmd,'ServiceVect')
    checkargs( cmd, ncmdargs, 2:2:24 );
    msg = rawMsg( G_PEG.group, [], [cmdargs{:}] );
    protocol = 132;
        
elseif strcmpi(cmd,'MagMovavgSamples')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(2)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 2 );
    protocol = 200;
    
elseif strcmpi(cmd,'rfpower') || strcmpi(cmd,'RFPower')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(3)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 3 );
    protocol = 200;
    
elseif strcmpi(cmd,'CamPos')
    checkargs( cmd, ncmdargs, [0 3] );
    if ncmdargs == 0; peg( addr, 'config_query(10)' ); return; end;
    msg.push_float( cmdargs{1} );
    msg.push_float( cmdargs{2} );
    msg.push_float( cmdargs{3} );
    msg.push_uint8( 10 );
    protocol = 200;
    
elseif strcmpi(cmd,'stretries') || strcmpi(cmd,'STRetries')
    checkargs( cmd, ncmdargs, [0 3] );
    if ncmdargs == 0; peg( addr, 'config_query(30)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( cmdargs{2} );
    msg.push_uint8( cmdargs{3} );
    msg.push_uint8( 30 );
    protocol = 200;
    
elseif strcmpi(cmd,'rtthresh') || strcmpi(cmd,'RTThresh')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; peg( addr, 'config_query(31)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 31 );
    protocol = 200;
    
elseif strcmpi(cmd,'MagPositionAffine')
    checkargs( cmd, ncmdargs, [0 6] );
    if ncmdargs == 0; peg( addr, 'config_query(43)' ); return; end;
    msg.push_int16( cmdargs{1} );
    msg.push_int16( cmdargs{2} );
    msg.push_int16( cmdargs{3} );
    msg.push_int16( cmdargs{4} );
    msg.push_int16( cmdargs{5} );
    msg.push_int16( cmdargs{6} );
    msg.push_uint8( 43 );
    protocol = 200;
    
elseif strcmpi(cmd,'MagThresh')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(50)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 50 );
    protocol = 200;
    
elseif strcmpi(cmd,'MagReadingTimeout')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(52)' ); return; end;
    msg.push_uint32( cmdargs{1} );
    msg.push_uint8( 52 );
    protocol = 200;
    
elseif strcmpi(cmd,'MagNeighborRadius')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(51)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 51 );
    protocol = 200;
    
elseif strcmpi(cmd,'MagReportTimeout')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(53)' ); return; end;
    msg.push_uint32( cmdargs{1} );
    msg.push_uint8( 53 );
    protocol = 200;
    
elseif strcmpi(cmd,'MagCenterSendMode')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(54)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 54 );
    protocol = 200;
    
elseif strcmpi(cmd,'MagCenterClosestInjectDiameter')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(55)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 55 );
    protocol = 200;
    
elseif strcmpi(cmd,'MagThreshUpper')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(56)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 56 );
    protocol = 200;
    
elseif strcmpi(cmd,'QuellPursuerCoord')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(57)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 57 );
    protocol = 200;
    
elseif strcmpi(cmd,'MagReadingPeriod')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(60)' ); return; end;
    msg.push_uint32( cmdargs{1} );
    msg.push_uint8( 60 );
    protocol = 200;
    
elseif strcmpi(cmd,'MagReadingInvalidCount')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(61)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 61 );
    protocol = 200;
    
elseif strcmpi(cmd,'MagRadioQuellTime')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(62)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 62 );
    protocol = 200;
    
elseif strcmpi(cmd,'ssthresh') || strcmpi(cmd,'SSTresh')
    checkargs(cmd,ncmdargs,0:1);
    if ncmdargs == 0; peg(addr, 'config_query(31)' ); return; end;
    msg.push_uint16 (cmdargs{1});
    msg.push_uint8 (31);
    protocol = 200;
    
elseif strcmpi(cmd,'config_query') || strcmpi(cmd,'ConfigQuery')
    checkargs( cmd, ncmdargs, 1 );
    msg.push_uint8( cmdargs{1} );
    protocol = 201;

elseif strcmpi(cmd,'RangingExchangeParameters')
    checkargs( cmd, ncmdargs, [0 5] );
    if ncmdargs == 0; peg( addr, 'config_query(90)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint16( cmdargs{2} );
    msg.push_uint16( cmdargs{3} );
    msg.push_uint16( cmdargs{4} );
    msg.push_uint16( cmdargs{5} );
    msg.push_uint8( 90 );
    protocol = 200;

    
elseif strcmpi(cmd, 'ShortestPathTimeout')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(91)' ); return; end;
    msg.push_uint16( cmdargs{1});
    msg.push_uint8( 91 );
    protocol = 200;

elseif strcmpi(cmd, 'UltrasoundRangingBias')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(92)' ); return; end;
    msg.push_uint16( cmdargs{1});
    msg.push_uint8( 92 );
    protocol = 200;

elseif strcmpi(cmd, 'UltrasoundRangingScale')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(93)' ); return; end;
    msg.push_float( cmdargs{1});
    msg.push_uint8( 93 );
    protocol = 200;

elseif strcmpi(cmd, 'RangingCountMin')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(94)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 94 );
    protocol = 200;

elseif strcmpi(cmd, 'ManagementTimerBase')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(95)' ); return; end;
    msg.push_uint16( cmdargs{1});
    msg.push_uint8( 95 );
    protocol = 200;

elseif strcmpi(cmd, 'ManagementTimerMask')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(96)' ); return; end;
    msg.push_uint16( cmdargs{1});
    msg.push_uint8( 96 );
    protocol = 200;

elseif strcmpi(cmd, 'PositionDebug')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(97)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 97 );
    protocol = 200;
  
elseif strcmpi(cmd, 'RangingDebug')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(98)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 98 );
    protocol = 200;  
    
elseif strcmpi(cmd,'MyRangingId')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(100)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 100 );
    protocol = 200;
    
elseif strcmpi(cmd,'RangingParameters')
    checkargs( cmd, ncmdargs, [0 6] );
    if ncmdargs == 0; peg( addr, 'config_query(101)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint16( cmdargs{2} );
    msg.push_uint16( cmdargs{3} );
    msg.push_uint16( cmdargs{4} );
    msg.push_uint16( cmdargs{5} );
    msg.push_uint16( cmdargs{6} );
    msg.push_uint8( 101 );
    protocol = 200;
        
elseif strcmpi(cmd,'RangingFilterParameters')
    checkargs( cmd, ncmdargs, [0 2] );
    if ncmdargs == 0; peg( addr, 'config_query(102)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint16( cmdargs{2} );
    msg.push_uint8( 102 );
    protocol = 200;

elseif strcmpi(cmd,'IsLastRangingNode')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(103)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 103 );
    protocol = 200;


elseif strcmpi(cmd,'debugAddr')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(253)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 253 );
    protocol = 200;

elseif strcmpi(cmd,'verbose')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(254)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 254 );
    protocol = 200;

elseif strcmpi(cmd,'InitiateSchedule')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(104)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 104 );
    protocol = 200;

elseif strcmpi(cmd,'RangingStartDelay')
    checkargs( cmd, ncmdargs, [0 2] );
    if ncmdargs == 0; peg( addr, 'config_query(105)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint16( cmdargs{2} );
    msg.push_uint8( 105 );
    protocol = 200;
	
elseif strcmpi(cmd,'LocationInfo')
    checkargs( cmd, ncmdargs, [0 9] );
    if ncmdargs == 0; peg( addr, 'config_query(106)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint16( cmdargs{2} );
    msg.push_uint16( cmdargs{3} );
    msg.push_uint16( 0 );
	msg.push_uint16( 0 );
	msg.push_uint16( 65535 );
	msg.push_uint16( 65535);
	msg.push_uint16(65535 );
	msg.push_uint16(65535 );
    msg.push_uint8( 106 );
    protocol = 200;

elseif strcmpi(cmd,'EvaderInfo')
    checkargs( cmd, ncmdargs, [0 3] );
    if ncmdargs == 0; peg( addr, 'config_query(107)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint16( cmdargs{2} );
    msg.push_uint16( cmdargs{3} );
    msg.push_uint16( 65535 );
	msg.push_uint16( 65535 );
	msg.push_uint16( 65535 );
	msg.push_uint16( 65535);
	msg.push_uint16(65535 );
	msg.push_uint16(65535 );
    msg.push_uint8( 107 );
    protocol = 200;

elseif strcmpi(cmd,'txRetry')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; peg( addr, 'config_query(108)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 108 );
    protocol = 200;

elseif strcmpi(cmd,'txDelay')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; peg( addr, 'config_query(109)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 109 );
    protocol = 200;

elseif strcmpi(cmd,'deltaDistanceThreshold')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; peg( addr, 'config_query(110)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 110 );
    protocol = 200;

elseif strcmpi(cmd,'txAnchorPeriod')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; peg( addr, 'config_query(111)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 111 );
    protocol = 200;

elseif strcmpi(cmd,'medianTube')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; peg( addr, 'config_query(112)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 112 );
    protocol = 200;

elseif strcmpi(cmd,'proportionalMedianTube')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; peg( addr, 'config_query(113)' ); return; end;
    msg.push_float( cmdargs{1} );
    msg.push_uint8( 113 );
    protocol = 200;

elseif strcmpi(cmd,'diagMsgOn')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; peg( addr, 'config_query(114)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 114 );
    protocol = 200;

elseif strcmpi(cmd,'txDelayMask')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; peg( addr, 'config_query(115)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 115 );
    protocol = 200;

elseif strcmpi(cmd,'calamariRFPower')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; peg( addr, 'config_query(116)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 116 );
    protocol = 200;

elseif strcmpi(cmd,'exchangeRanging')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; peg( addr, 'config_query(117)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 117 );
    protocol = 200;

elseif strcmpi(cmd,'negativeLocalizationUnsigned')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; peg( addr, 'config_query(118)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 118 );
    protocol = 200;

elseif strcmpi(cmd, 'RSSIRangingBias')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(120)' ); return; end;
    msg.push_uint16( cmdargs{1});
    msg.push_uint8( 120 );
    protocol = 200;

elseif strcmpi(cmd, 'RSSIRangingScale')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(121)' ); return; end;
    msg.push_float( cmdargs{1});
    msg.push_uint8( 121 );
    protocol = 200;

elseif strcmpi(cmd, 'rangingExchangeBehavior')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(122)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 122 );
    protocol = 200;

elseif strcmpi(cmd, 'managementHopDelay')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(123)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 123 );
    protocol = 200;

elseif strcmpi(cmd,'UseLocalizedPosition')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(108)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 108 );
    protocol = 200;

elseif strcmpi(cmd,'UseEstimatedEvader')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(109)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 109 );
    protocol = 200;

elseif strcmpi(cmd, 'MaxAnchorRank')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(99)' ); return; end;
    msg.push_uint16( cmdargs{1});
    msg.push_uint8( 99 );
    protocol = 200;
  
elseif strcmpi(cmd,'RangingTech')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(119)' ); return; end;
    if(strcmpi(cmdargs{1},'RSSI'))
      msg.push_uint8(1);
    elseif(strcmpi(cmdargs{1},'Ultrasound'))
      msg.push_uint8(2);
    end
    msg.push_uint8( 119 );
    protocol = 200;

elseif strcmpi(cmd,'blink') || strcmpi(cmd,'Blink')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(160)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 160 );
    protocol = 200;
    
elseif strcmpi(cmd,'rtbuild') || strcmpi(cmd,'RTBuild')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8( 1 ); % command build
    msg.push_uint8( 0 );
    protocol = 50;
    
elseif strcmpi(cmd,'rtcrumb') || strcmpi(cmd,'RTCrumb')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; error('usage: RTCrumb(ma) where ma=2 is MA1, ma=3 is MA2, ma=16 is MAALL'); end;
    msg.push_uint8( 2 ); % command crumb
    msg.push_uint8( cmdargs{1} );
    protocol = 50;
    
elseif strcmpi(cmd,'rtroute') || strcmpi(cmd,'RTRoute')
    checkargs( cmd, ncmdargs, [0 2] );
    if ncmdargs == 0; error('usage: RTRoute(ma,led) where ma=2 is MA1, ma=3 is MA2, ma=16 is MAALL'); end;
    msg.push_uint8( 3 ); % command route
    msg.push_uint8( cmdargs{1} ); % 2 (ma1), 3 (ma2), 16 (maall)
    msg.push_uint8( 1 ); % turn on leds
    msg.push_uint8( cmdargs{2} ); % leds value
    protocol = 50;
    
elseif strcmpi(cmd,'rtloop') || strcmpi(cmd,'RTLoop')
    checkargs( cmd, ncmdargs, [0 2] );
    if ncmdargs == 0; error('usage: RTLoop(ma,led) where ma=2 is MA1, ma=3 is MA2, ma=16 is MAALL'); end;
    msg.push_uint8( 3 ); % command route
    msg.push_uint8( cmdargs{1} ); % 2 (ma1), 3 (ma2), 16 (maall)
    msg.push_uint8( 2 ); % turn on leds
    msg.push_uint8( cmdargs{2} ); % leds value
    msg.push_uint32( 0 );
    msg.push_uint32( 0 );
    protocol = 50;

elseif strcmpi(cmd,'MagCenterAlwaysInject')
    checkargs( cmd, ncmdargs, 2 );
    msg = MagCenterInject( msg, cmdargs{1}, cmdargs{2} );
    protocol = 3;
 
elseif strcmpi(cmd, 'CalamariSetRanging')
%    checkargs( cmd, ncmdargs, 0 );
    checkargs( cmd, ncmdargs, 3:2:13 );
    msg.push_uint8( cmdargs{1} );
    for rangearg=2:2:12
      if rangearg>length(cmdargs)       
	msg.push_uint8( 0 );
	msg.push_uint16( 0 );
      else
	msg.push_uint8( cmdargs{rangearg} );
	msg.push_uint16( cmdargs{rangearg+1} );
      end
    end
    msg.push_uint8(58);			
    protocol = 180;
    
elseif strcmpi(cmd, 'CalamariToggleLed')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(60); 
    protocol = 180;    
    
elseif strcmpi(cmd, 'CalamariRangeOnce')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(62);    
    protocol = 180;    
 
elseif strcmpi(cmd, 'CalamariReportAnchors')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(64); 
    protocol = 180;

elseif strcmpi(cmd, 'CalamariReportRanging')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(66); 
    protocol = 180;


elseif strcmpi(cmd, 'CalamariSendAllAnchors')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(90); 
    protocol = 180;

elseif strcmpi(cmd, 'CalamariReportRangingValues')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; 
      msg.push_uint16( 65535 );% report all 
    else
      msg.push_uint16( cmdargs{1});% report all 
    end
    msg.push_uint8(92); 
    protocol = 180;

elseif strcmpi(cmd, 'CalamariRangingExchange')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(94); 
    protocol = 180;

elseif strcmpi(cmd, 'CalamariReportCorrections')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(96); 
    protocol = 180;

elseif strcmpi(cmd, 'CalamariStop')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(68);    
    protocol = 180;

elseif strcmpi(cmd, 'CalamariStart')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(70); 
    protocol = 180;    
    
elseif strcmpi(cmd, 'CalamariResume')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(72);    
    protocol = 180;

elseif strcmpi(cmd, 'CalamariRanging')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(74); 
    protocol = 180;
    
elseif strcmpi(cmd, 'CalamariResetRanging')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(76);    
    protocol = 180;
    
elseif strcmpi(cmd, 'CalamariShortestPath')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(78);    
    protocol = 180;

elseif strcmpi(cmd, 'CalamariResetShortestPath')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(80);    
    protocol = 180;

elseif strcmpi(cmd, 'CalamariLocalization')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(82);    
    protocol = 180;

elseif strcmpi(cmd, 'CalamariResetLocalization')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(84);    
    protocol = 180;

elseif strcmpi(cmd, 'CalamariCorrection')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(86);    
    protocol = 180;

elseif strcmpi(cmd, 'CalamariResetCorrection')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(88);    
    protocol = 180;
    
elseif strcmpi(cmd,'CalamariMonitorReport')
    checkargs( cmd, ncmdargs, 2 );
	msg.push_uint16( cmdargs{1});
	msg.push_uint16( cmdargs{2});
	msg.push_uint8(108); 
    protocol = 180;
	
elseif strcmpi(cmd,'CollisionCmd')
    checkargs( cmd, ncmdargs, 2 );
	msg.push_uint8( cmdargs{1});
	msg.push_int16( cmdargs{2});
	%msg.push_uint8(190); 
    msg.amTypeSet( 109 );
    msg.set_type( 109 );
    %protocol = 180;
    
elseif strcmpi(cmd,'CollisionReportCmd')
    checkargs( cmd, ncmdargs, 0 );
	%msg.push_uint8( cmdargs{1});
	%msg.push_int16( cmdargs{2});
    msg.push_uint8(190); 
    msg.amTypeSet( 190 );
    msg.set_type( 190 );

elseif strcmpi(cmd,'CollisionPowerCmd')
    checkargs( cmd, ncmdargs, 1 );
	msg.push_uint8( cmdargs{1});
	%msg.push_int16( cmdargs{2});
    %msg.push_uint8(190); 
    msg.amTypeSet( 191 );
    msg.set_type( 191 );
    
elseif strcmpi(cmd,'MagCenterClosestInject')
    checkargs( cmd, ncmdargs, 2 );
    msg = MagCenterInject( msg, cmdargs{1}, cmdargs{2} );
    protocol = 4;
     
elseif strcmpi(cmd, 'TinySecTransmitMode')
  % 1 for auth_only, 2 for encrypt_and_auth, 3 for disabled
    checkargs( cmd, ncmdargs, 0:1); 
    if ncmdargs == 0; peg( addr, 'config_query(36)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 36 );
    protocol = 200;
    
elseif strcmpi(cmd, 'TinySecReceiveMode')
  % 1 for receive_authenticated, 2 for receive_crc, 3 for receive_any
    checkargs( cmd, ncmdargs, 0:1); 
    if ncmdargs == 0; peg( addr, 'config_query(37)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 37 );
    protocol = 200;
    
else
    error(['unknown cmd ' cmd]);
end

%%% Mung the destination address: assume it's in hex if it's a string, set
%%% the destination to broadcast if it's the string 'all'.
dest = [];
retries = 1;
origaddr = addr;
[addr,addrargs] = getargs(addr);
naddrargs = length( addrargs );
if strcmpi(addr,'addr')
    checkargs( addr, naddrargs, 1 );
    addr = addrargs{1};
    addrargs = {};
end
if isnumeric(addr)
    dest = addr;
elseif ~isempty(str2num(addr))
    dest = str2num(addr);
elseif strncmpi(addr,'0x',2)
    dest = hex2dec( addr(3:end) );
elseif strcmpi(addr,'all')
    dest = 65535;
end
if ~isempty(protocol)
    retries = 1;
    if ~isempty(dest)
        SingleBroadcastRouting( protocol, G_PEG, msg );
    elseif strcmpi(addr,'bcast')
        checkargs( addr, naddrargs, 0:1 );
        hopsleft = 0;
        if naddrargs == 1; hopsleft = addrargs{1}; end;
        BroadcastRouting( protocol, G_PEG, msg, hopsleft );
        dest = 65535;
    end
end
if isempty(dest)
    error(sprintf('unknown message destination %s',addr));
end

%%% Send the message to the given address, either to an active writer or a
%%% port number on localhost.
if nargout > 0
    varargout{1} = msg;
    
elseif isjava(G_PEG.source)
    for retry = 1:retries
        tryagain = 0;
        try; sendMsg( G_PEG.source, dest, msg ); catch; tryagain=1; end;
        if tryagain == 1
            try; G_PEG.writer.Close; catch; end;
            G_PEG.source = net.tinyos.util.SerialForwarderStub( G_PEG.host, G_PEG.port );
            G_PEG.source.Open;
            sendMsg( G_PEG.source, dest, msg );
        end
        if retry ~= retries; pause(0.2); end;
    end
end

%%% MagCenter*Inject packet
function msg = MagCenterInject( msg, x, y )
    mag_sum = 1;
    x_sum = round(x * 256);
    y_sum = round(y * 256);
    num_reporting = 1;
    msg.push_uint32( mag_sum );
    msg.push_int32( x_sum );
    msg.push_int32( y_sum );
    msg.push_uint8( num_reporting );

%%% Set the AM type, routing method header, and bottom routing header for
%%% Single Broadcast Routing (one hop, minimize header use).
function SingleBroadcastRouting( protocol, PEG, msg )
% changed to 190
msg.amTypeSet( 100 );
msg.set_type( 100 );
BottomRouting( protocol, PEG, msg );

%%% Set the AM type, routing method header, and bottom routing header for
%%% Single Broadcast Routing (one hop, minimize header use).
function BroadcastRouting( protocol, PEG, msg, hopsleft )
msg.amTypeSet( 101 );
msg.set_type( 101 );
msg.push_uint8( hopsleft );
BottomRouting( protocol, PEG, msg );

%%% Push the bottom routing header onto the message: origin address,
%%% sequence number, and protocol number.
function BottomRouting( protocol, PEG, msg )
msg.push_uint16( PEG.myaddr );
msg.push_uint8( PEG.seq );
msg.push_uint8( protocol );

%%% getargs: break 'fuzzy(wuzzy,bear)' into 'fuzzy' and '(wuzzy,bear)'
function [fun,funargs] = getargs( fun )
funargs = cell(0);
ii = strfind( fun, '(' );
if ~isempty(ii)
    funargs = eval([ 'blinddeal' fun(ii:end) ';' ]);
    fun = fun(1:(ii-1));
end

function cc = blinddeal( varargin )
cc = varargin;

function checkargs( cmd, numarg, argcheck )
if ~any(argcheck == numarg); error(['Wrong number of arguments to ' cmd]); end
