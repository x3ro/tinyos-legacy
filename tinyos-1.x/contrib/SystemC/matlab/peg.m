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
if strcmp(cmd,'on') || strcmp(cmd,'On')
    checkargs( cmd, ncmdargs, 0 );
    msg = rawMsg( G_PEG.group, 249, [1 0] );
    
elseif strcmp(cmd,'off') || strcmp(cmd,'Off')
    checkargs( cmd, ncmdargs, 0 );
    msg = rawMsg( G_PEG.group, 249, [0 0] );
    
elseif strcmp(cmd,'reset') || strcmp(cmd,'Reset')
    checkargs( cmd, ncmdargs, 0 );
    msg = rawMsg( G_PEG.group, 248, [0] );
    
elseif strcmp(cmd,'GameInit')
    peg(addr,'reset'); pause(0.2);
    peg(addr,'on'); pause(1.3);
    peg(addr,'ident');
    return;

elseif strcmp(cmd,'GameSensorStruct')
    checkargs( cmd, ncmdargs, 0 );
    s = [];
    s.RFPower = 4;
    s.MagThresh = 150;
    s.MagReadingTimeout = 65536;
    s.MagCenterSendMode = 1;
    s.Service = 10;
    if nargout == 1; varargout{1} = s; end;
    return;
    
elseif strcmp(cmd,'GamePursuerStruct')
    checkargs( cmd, ncmdargs, 0 );
    s = [];
    s = peg('','GameConfigStruct');
    s.Service = 66;
    if nargout == 1; varargout{1} = s; end;
    return;
    
elseif strcmp(cmd,'GameSensorConfig')
    checkargs( cmd, ncmdargs, 0:1 );
    s = peg('','GameSensorStruct');
    if ncmdargs == 1; s = cmdargs{1}; end;
    ff = fields(s);
    for n = 1:length(ff); f=ff{n}, peg( addr, f, getfield(s,f) ); pause(0.2); end;
    
elseif strcmp(cmd,'GameSensorQuery')
    checkargs( cmd, ncmdargs, 0:1 );
    s = peg('','GameSensorStruct');
    if ncmdargs == 1; s = cmdargs{1}; end;
    ff = fields(s);
    for n = 1:length(ff); f=ff{n}, peg( addr, f ); pause(2); end;
    
elseif strcmp(cmd,'GamePursuerConfig')
    checkargs( cmd, ncmdargs, 0:1 );
    s = peg('','GamePursuerStruct');
    if ncmdargs == 1; s = cmdargs{1}; end;
    ff = fields(s);
    for n = 1:length(ff); f=ff{n}; peg( addr, f, getfield(s,f) ); pause(0.2); end;
    
elseif strcmp(cmd,'GamePursuerQuery')
    checkargs( cmd, ncmdargs, 0:1 );
    s = peg('','GamePusuerStruct');
    if ncmdargs == 1; s = cmdargs{1}; end;
    ff = fields(s);
    for n = 1:length(ff); f=ff{n}; peg( addr, f ); pause(2); end;

elseif strcmp(cmd,'SetStruct')
    checkargs( cmd, ncmdargs, 1 );
    if ncmdargs == 1; s = cmdargs{1}; end;
    ff = fields(s);
    for n = 1:length(ff); f=ff{n}; peg( addr, f, getfield(s,f) ); pause(0.2); end;
    
elseif strcmp(cmd,'QueryStruct')
    checkargs( cmd, ncmdargs, 1 );
    if ncmdargs == 1; s = cmdargs{1}; end;
    ff = fields(s);
    for n = 1:length(ff); f=ff{n}; peg( addr, f ); pause(0.2); end;
    
elseif strcmp(cmd,'ChangeGroupId')
    checkargs( cmd, ncmdargs, 2 );
    msg = rawMsg( G_PEG.group, 247, [] );
    msg.push_uint8( cmdargs{1} );
    msg.push_uint16( cmdargs{2} );

elseif strcmp(cmd,'MsgBuffersDebug')
    checkargs( cmd, ncmdargs, 1 );
    msg = rawMsg( G_PEG.group, 11, [cmdargs{1}] );
    
elseif strcmp(cmd,'ident') || strcmp(cmd,'Ident')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8( 1 );
    protocol = 180;
    
elseif strcmp(cmd,'ConfigStore')
    checkargs( cmd, ncmdargs, 1 );
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 11 );
    protocol = 180;
    
elseif strcmp(cmd,'DefaultConfig')
    peg(addr,'ConfigStore(0)');
    return;
    
elseif strcmp(cmd,'ReadConfig')
    peg(addr,'ConfigStore(1)');
    return;
    
elseif strcmp(cmd,'WriteConfig')
    peg(addr,'ConfigStore(2)');
    return;
    
elseif strcmp(cmd,'magstatus') || strcmp(cmd,'MagStatus')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8( 0 );
    msg.push_uint8( 58 );
    protocol = 180;
    
elseif strcmp(cmd,'MagPurge')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8( 226 );
    msg.push_uint8( 58 );
    protocol = 180;
    
elseif strcmp(cmd,'streinit') || strcmp(cmd,'STReinit')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8( 32 );
    protocol = 180;
    
elseif strcmp(cmd,'ststatus') || strcmp(cmd,'STStatus')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8( 34 );
    protocol = 180;
    
elseif strcmp(cmd,'service') || strcmp(cmd,'Service')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(134)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 133 );
    protocol = 200;

elseif strcmp(cmd,'InitialService')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(135)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 135 );
    protocol = 200;

elseif strcmp(cmd,'ServiceVect')
    checkargs( cmd, ncmdargs, 2:2:24 );
    msg = rawMsg( G_PEG.group, [], [cmdargs{:}] );
    protocol = 132;
        
elseif strcmp(cmd,'MagMovavgSamples')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(2)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 2 );
    protocol = 200;
    
elseif strcmp(cmd,'rfpower') || strcmp(cmd,'RFPower')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(3)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 3 );
    protocol = 200;
    
elseif strcmp(cmd,'CamPos')
    checkargs( cmd, ncmdargs, [0 3] );
    if ncmdargs == 0; peg( addr, 'config_query(10)' ); return; end;
    msg.push_float( cmdargs{1} );
    msg.push_float( cmdargs{2} );
    msg.push_float( cmdargs{3} );
    msg.push_uint8( 10 );
    protocol = 200;
    
elseif strcmp(cmd,'stretries') || strcmp(cmd,'STRetries')
    checkargs( cmd, ncmdargs, [0 3] );
    if ncmdargs == 0; peg( addr, 'config_query(30)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( cmdargs{2} );
    msg.push_uint8( cmdargs{3} );
    msg.push_uint8( 30 );
    protocol = 200;
    
elseif strcmp(cmd,'rtthresh') || strcmp(cmd,'RTThresh')
    checkargs( cmd, ncmdargs, [0 1] );
    if ncmdargs == 0; peg( addr, 'config_query(31)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 31 );
    protocol = 200;
    
elseif strcmp(cmd,'MagPositionAffine')
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
    
elseif strcmp(cmd,'MagThresh')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(50)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 50 );
    protocol = 200;
    
elseif strcmp(cmd,'MagReadingTimeout')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(52)' ); return; end;
    msg.push_uint32( cmdargs{1} );
    msg.push_uint8( 52 );
    protocol = 200;
    
elseif strcmp(cmd,'MagNeighborRadius')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(51)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 51 );
    protocol = 200;
    
elseif strcmp(cmd,'MagReportTimeout')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(53)' ); return; end;
    msg.push_uint32( cmdargs{1} );
    msg.push_uint8( 53 );
    protocol = 200;
    
elseif strcmp(cmd,'MagCenterSendMode')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(54)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 54 );
    protocol = 200;
    
elseif strcmp(cmd,'MagCenterClosestInjectDiameter')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(55)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 55 );
    protocol = 200;
    
elseif strcmp(cmd,'MagThreshUpper')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(56)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 56 );
    protocol = 200;
    
elseif strcmp(cmd,'QuellPursuerCoord')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(57)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 57 );
    protocol = 200;
    
elseif strcmp(cmd,'MagReadingPeriod')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(60)' ); return; end;
    msg.push_uint32( cmdargs{1} );
    msg.push_uint8( 60 );
    protocol = 200;
    
elseif strcmp(cmd,'MagReadingInvalidCount')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(61)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 61 );
    protocol = 200;
    
elseif strcmp(cmd,'MagRadioQuellTime')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(62)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 62 );
    protocol = 200;
    
elseif strcmp(cmd,'ssthresh') || strcmp(cmd,'SSTresh')
    checkargs(cmd,ncmdargs,0:1);
    if ncmdargs == 0; peg(addr, 'config_query(31)' ); return; end;
    msg.push_uint16 (cmdargs{1});
    msg.push_uint8 (31);
    protocol = 200;
    
elseif strcmp(cmd,'config_query') || strcmp(cmd,'ConfigQuery')
    checkargs( cmd, ncmdargs, 1 );
    msg.push_uint8( cmdargs{1} );
    protocol = 201;

elseif strcmp(cmd, 'SignalRangingDone')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(91)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 91 );
    protocol = 200;

elseif strcmp(cmd, 'RangingBias')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(92)' ); return; end;
    msg.push_uint16( cmdargs{1});
    msg.push_uint8( 92 );
    protocol = 200;

elseif strcmp(cmd, 'RangingScale')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(93)' ); return; end;
    msg.push_uint16( cmdargs{1});
    msg.push_uint8( 93 );
    protocol = 200;

elseif strcmp(cmd, 'RangingCountMin')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(94)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 94 );
    protocol = 200;

elseif strcmp(cmd, 'ManagementTimerBase')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(95)' ); return; end;
    msg.push_uint16( cmdargs{1});
    msg.push_uint8( 95 );
    protocol = 200;

elseif strcmp(cmd, 'ManagementTimerMask')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(96)' ); return; end;
    msg.push_uint16( cmdargs{1});
    msg.push_uint8( 96 );
    protocol = 200;

elseif strcmp(cmd, 'PositionDebug')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(97)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 97 );
    protocol = 200;
  
elseif strcmp(cmd, 'RangingDebug')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(98)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 98 );
    protocol = 200;  
    
elseif strcmp(cmd,'MyRangingId')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(100)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 100 );
    protocol = 200;
    
elseif strcmp(cmd,'RangingParameters')
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
        
elseif strcmp(cmd,'UltrasoundFilterParameters')
    checkargs( cmd, ncmdargs, [0 2] );
    if ncmdargs == 0; peg( addr, 'config_query(102)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint16( cmdargs{2} );
    msg.push_uint8( 102 );
    protocol = 200;

elseif strcmp(cmd,'IsLastRangingNode')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(103)' ); return; end;
    msg.push_uint8( cmdargs{1} );
    msg.push_uint8( 103 );
    protocol = 200;

elseif strcmp(cmd,'LocalizationPeriod')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(104)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 104 );
    protocol = 200;

elseif strcmp(cmd,'RangingStartDelay')
    checkargs( cmd, ncmdargs, [0 2] );
    if ncmdargs == 0; peg( addr, 'config_query(105)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint16( cmdargs{2} );
    msg.push_uint8( 105 );
    protocol = 200;
	
elseif strcmp(cmd,'LocationInfo')
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

elseif strcmp(cmd,'EvaderInfo')
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

elseif strcmp(cmd,'UseLocalizedPosition')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(108)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 108 );
    protocol = 200;

elseif strcmp(cmd,'UseEstimatedEvader')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(109)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 109 );
    protocol = 200;

elseif strcmp(cmd, 'MaxAnchorRank')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(99)' ); return; end;
    msg.push_uint16( cmdargs{1});
    msg.push_uint8( 99 );
    protocol = 200;
  
elseif strcmp(cmd,'PursuerId')
    checkargs( cmd, ncmdargs, 0:1);
    if ncmdargs == 0; peg( addr, 'config_query(119)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 119 );
    protocol = 200;

elseif strcmp(cmd,'blink') || strcmp(cmd,'Blink')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; peg( addr, 'config_query(160)' ); return; end;
    msg.push_uint16( cmdargs{1} );
    msg.push_uint8( 160 );
    protocol = 200;
    
elseif strcmp(cmd,'rtbuild') || strcmp(cmd,'RTBuild')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8( 1 ); % command build
    msg.push_uint8( 0 );
    protocol = 50;
    
elseif strcmp(cmd,'rtcrumb') || strcmp(cmd,'RTCrumb')
    checkargs( cmd, ncmdargs, 0:1 );
    if ncmdargs == 0; error('usage: RTCrumb(ma) where ma=2 is MA1, ma=3 is MA2, ma=16 is MAALL'); end;
    msg.push_uint8( 2 ); % command crumb
    msg.push_uint8( cmdargs{1} );
    protocol = 50;
    
elseif strcmp(cmd,'rtroute') || strcmp(cmd,'RTRoute')
    checkargs( cmd, ncmdargs, [0 2] );
    if ncmdargs == 0; error('usage: RTRoute(ma,led) where ma=2 is MA1, ma=3 is MA2, ma=16 is MAALL'); end;
    msg.push_uint8( 3 ); % command route
    msg.push_uint8( cmdargs{1} ); % 2 (ma1), 3 (ma2), 16 (maall)
    msg.push_uint8( 1 ); % turn on leds
    msg.push_uint8( cmdargs{2} ); % leds value
    protocol = 50;
    
elseif strcmp(cmd,'rtloop') || strcmp(cmd,'RTLoop')
    checkargs( cmd, ncmdargs, [0 2] );
    if ncmdargs == 0; error('usage: RTLoop(ma,led) where ma=2 is MA1, ma=3 is MA2, ma=16 is MAALL'); end;
    msg.push_uint8( 3 ); % command route
    msg.push_uint8( cmdargs{1} ); % 2 (ma1), 3 (ma2), 16 (maall)
    msg.push_uint8( 2 ); % turn on leds
    msg.push_uint8( cmdargs{2} ); % leds value
    msg.push_uint32( 0 );
    msg.push_uint32( 0 );
    protocol = 50;

elseif strcmp(cmd,'MagCenterAlwaysInject')
    checkargs( cmd, ncmdargs, 2 );
    msg = MagCenterInject( msg, cmdargs{1}, cmdargs{2} );
    protocol = 3;
 
elseif strcmp(cmd, 'CalamariRangeOnce')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(62);    
    protocol = 180;    
 
elseif strcmp(cmd, 'CalamariReportAnchors')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(64); 
    protocol = 180;

elseif strcmp(cmd, 'CalamariReportRanging')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(66); 
    protocol = 180;


elseif strcmp(cmd, 'CalamariStop')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(68);    
    protocol = 180;

elseif strcmp(cmd, 'CalamariStart')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(70); 
    protocol = 180;    
    
elseif strcmp(cmd, 'CalamariResume')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(72);    
    protocol = 180;

elseif strcmp(cmd, 'CalamariRanging')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(74); 
    protocol = 180;
    
elseif strcmp(cmd, 'CalamariResetRanging')
    checkargs( cmd, ncmdargs, 0 );
    msg.push_uint8(76);    
    protocol = 180;
    
elseif strcmp(cmd,'CalamariMonitorReport')
    checkargs( cmd, ncmdargs, 2 );
	msg.push_uint16( cmdargs{1});
	msg.push_uint16( cmdargs{2});
	msg.push_uint8(108); 
    protocol = 180;
	
elseif strcmp(cmd,'CollisionCmd')
    checkargs( cmd, ncmdargs, 2 );
	msg.push_uint8( cmdargs{1});
	msg.push_int16( cmdargs{2});
	%msg.push_uint8(190); 
    msg.amTypeSet( 109 );
    msg.set_type( 109 );
    %protocol = 180;
    
elseif strcmp(cmd,'CollisionReportCmd')
    checkargs( cmd, ncmdargs, 0 );
	%msg.push_uint8( cmdargs{1});
	%msg.push_int16( cmdargs{2});
    msg.push_uint8(190); 
    msg.amTypeSet( 190 );
    msg.set_type( 190 );

elseif strcmp(cmd,'CollisionPowerCmd')
    checkargs( cmd, ncmdargs, 1 );
	msg.push_uint8( cmdargs{1});
	%msg.push_int16( cmdargs{2});
    %msg.push_uint8(190); 
    msg.amTypeSet( 191 );
    msg.set_type( 191 );
    
elseif strcmp(cmd,'MagCenterClosestInject')
    checkargs( cmd, ncmdargs, 2 );
    msg = MagCenterInject( msg, cmdargs{1}, cmdargs{2} );
    protocol = 4;
     
elseif strcmp(cmd, 'TinySecTransmitMode')
  % 1 for auth_only, 2 for encrypt_and_auth, 3 for disabled
    checkargs( cmd, ncmdargs, 0:1); 
    if ncmdargs == 0; peg( addr, 'config_query(36)' ); return; end;
    msg.push_uint8( cmdargs{1});
    msg.push_uint8( 36 );
    protocol = 200;
    
elseif strcmp(cmd, 'TinySecReceiveMode')
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
if strcmp(addr,'addr')
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
elseif strcmp(addr,'all')
    dest = 65535;
end
if ~isempty(protocol)
    retries = 1;
    if ~isempty(dest)
        SingleBroadcastRouting( protocol, G_PEG, msg );
    elseif strcmp(addr,'bcast')
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
