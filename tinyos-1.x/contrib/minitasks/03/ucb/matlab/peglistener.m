function peglistener( addr, msg2 )
msg = msg2.clone;
text = [];
text.msg = msg;
text.TIME = now;
%try; text = AMDispatch( text ); catch; end;
text = AMDispatch( text );
pegclient( text );


function text = IdentBody( text )
text.BODY = 'Ident';
text.unix_time = text.msg.pop_uint32;
text.unix_time_string = datestr( unixdate(text.unix_time,-7), 0 );
text.install_id = text.msg.pop_uint16;
text.xnp_program_id = text.msg.pop_uint16;
prog = text.msg.get_data';
prog = prog(1:10);
text.program_name = prog;
n=find(prog==0); if ~isempty(n); prog(n(1):end)=[]; end;
prog( prog<32 | prog>127 ) = double('.');
text.program_name_string = char(prog);
text.STRING = sprintf( 'Program "%s", Xnp 0x%04x, Install %d, Date %s', text.program_name_string, text.xnp_program_id, text.install_id, text.unix_time_string );

function text = MagStatus( text )
text.BODY = 'MagStatus';
text.nodes4_value = text.msg.pop_uint16;
text.nodes4_id = text.msg.pop_uint16;
text.nodes3_value = text.msg.pop_uint16;
text.nodes3_id = text.msg.pop_uint16;
text.nodes2_value = text.msg.pop_uint16;
text.nodes2_id = text.msg.pop_uint16;
text.nodes1_value = text.msg.pop_uint16;
text.nodes1_id = text.msg.pop_uint16;
text.worseFlags = text.msg.pop_uint8;
text.timeoutFlags = text.msg.pop_uint8;
text.myMag = text.msg.pop_uint16;
text.STRING = sprintf( 'myMag=%d, timeoutFlags=%x, worseFlags=%x, Node1=(0x%x,%d), Node2=(0x%x,%d), Node3=(0x%x,%d), Node4=(0x%x,%d)', ...
    text.myMag, text.timeoutFlags, text.worseFlags, ...
    text.nodes1_id, text.nodes1_value, ...
    text.nodes2_id, text.nodes2_value, ...
    text.nodes3_id, text.nodes3_value, ...
    text.nodes4_id, text.nodes4_value );

function text = SpanTreeStatus( text )
text.BODY = 'SpanTreeStatus';
text.numpktsrecvd = text.msg.pop_uint16;
text.crumb2_parent = text.msg.pop_uint16;
text.crumb2_seqno = text.msg.pop_uint16;
text.crumb1_parent = text.msg.pop_uint16;
text.crumb1_seqno = text.msg.pop_uint16;
text.bcastseqno = text.msg.pop_uint16;
text.route2_strength = text.msg.pop_uint16;
text.route2_parent = text.msg.pop_uint16;
text.route2_hops = text.msg.pop_uint8;
text.route1_strength = text.msg.pop_uint16;
text.route1_parent = text.msg.pop_uint16;
text.route1_hops = text.msg.pop_uint8;
text.STRING = sprintf( 'Route1(P %d, H %d, S %d), Route2(P %d, H %d, S %d), BCastSeqNo %d, Crumb1(P %d, S %d), Crumb2(P %d, S %d), numPktsReceived %d', ...
    text.route1_parent, text.route1_hops, text.route1_strength, ...
    text.route2_parent, text.route2_hops, text.route2_strength, ...
    text.bcastseqno, ...
    text.crumb1_parent, text.crumb1_seqno, ...
    text.crumb2_parent, text.crumb2_seqno, ...
    text.numpktsrecvd);

function text = SystemCommandHood( text )
text.nbh_protocol = text.msg.pop_uint8;
switch text.nbh_protocol
    case 2
        text = IdentBody( text );
    case 35
        text = SpanTreeStatus( text );
    case 59
        text = MagStatus( text );
end

function text = ConfigResponse( text )
text.config = text.msg.pop_uint8;
text.BODY = 'ConfigResponse';
switch text.config
    case 2
        text.BODY = 'MagMovingAvgSamples';
        text.magmovavgsamples = text.msg.pop_uint8;
        text.STRING = sprintf( 'MagMovingAvgSamples %d', text.magmovavgsamples );
    case 3
        text.BODY = 'RFPower';
        text.rfpower = text.msg.pop_uint16;
        text.STRING = sprintf( 'RFPower %d', text.rfpower );
    case 10
        text.BODY = 'CamPos';
        text.pos_z = text.msg.pop_float;
        text.pos_y = text.msg.pop_float;
        text.pos_x = text.msg.pop_float;
        text.STRING = sprintf( 'x %d, y %d, z %d', text.pos_x, text.pos_y, text.pos_z );
    case 30
        text.BODY = 'SpanTreeRetries';
        text.stretries_surge = text.msg.pop_uint8;
        text.stretries_route = text.msg.pop_uint8;
        text.stretries_build = text.msg.pop_uint8;
        text.STRING = sprintf( 'SpanTree Retries Build %d, Route %d, Surge %d', text.stretries_build, text.stretries_route, text.stretries_surge );
    case 31
        text.BODY = 'RTThresh';
        text.RTThresh = text.msg.pop_uint16;
        text.STRING = sprintf( '%d', text.RTThresh );
    case 43
        text.BODY = 'MagPositionAffine';
        text.r23 = text.msg.pop_int16;
        text.r22 = text.msg.pop_int16;
        text.r21 = text.msg.pop_int16;
        text.r13 = text.msg.pop_int16;
        text.r12 = text.msg.pop_int16;
        text.r11 = text.msg.pop_int16;
        text.STRING = sprintf( '\n    %12d %12d %12d\n    %12d %12d %12d', text.r11, text.r12, text.r13, text.r21, text.r22, text.r23 );
    case 50
        text.BODY = 'MagThresh';
        text.MagThresh = text.msg.pop_uint16;
        text.STRING = sprintf( '%d', text.MagThresh );
    case 51
        text.BODY = 'MagNeighborRadius';
        text.radius = text.msg.pop_uint16;
        text.STRING = sprintf( '%d', text.radius );
    case 52
        text.BODY = 'MagReadingTimeout';
        text.MagReadingTimeout = text.msg.pop_uint32;
        text.STRING = sprintf( '%d', text.MagReadingTimeout );
    case 53
        text.BODY = 'MagReportTimeout';
        text.MagReportTimeout = text.msg.pop_uint32;
        text.STRING = sprintf( '%d', text.MagReportTimeout );
    case 54
        text.BODY = 'MagCenterSendMode';
        text.MagCenterSendMode = text.msg.pop_uint8;
        text.STRING = sprintf( '%d', text.MagCenterSendMode );
    case 55
        text.BODY = 'MagCenterClosestInjectDiameter';
        text.MagCenterClosestInjectDiameter = text.msg.pop_uint16;
        text.STRING = sprintf( '%d', text.MagCenterClosestInjectDiameter );
    case 60
        text.BODY = 'MagReadingPeriod';
        text.magreadingperiod = text.msg.pop_uint32;
        text.STRING = sprintf( '%d', text.magreadingperiod );
    case 61
        text.BODY = 'MagReadingInvalidCount';
        text.MagReadingInvalidCount = text.msg.pop_uint16;
        text.STRING = sprintf( '%d', text.MagReadingInvalidCount );
    case 62
        text.BODY = 'MagRadioQuellTime';
        text.MagRadioQuellTime = text.msg.pop_uint16;
        text.STRING = sprintf( '%d', text.MagRadioQuellTime );
    case 91
         text.BODY = 'SignalRangingDone';
         text.SignalRangingDone = text.msg.pop_uint8;
         text.STRING = sprintf(' \n SignalRangingDone %d\n', text.SignalRangingDone );     
    case 92
         text.BODY = 'RangingBias';
         text.RangingBias = text.msg.pop_uint16;
         text.STRING = sprintf(' \n Ranging Bias %d\n', text.RangingBias ); 
    case 93
         text.BODY = 'RangingScale';
         text.RangingScale = text.msg.pop_uint16;
         text.STRING = sprintf(' \n RangingScale %d\n', text.RangingScale );     
    case 94
         text.BODY = 'RangingCountMin';
         text.RangingCountMin = text.msg.pop_uint8;
         text.STRING = sprintf(' \n RangingCountMin %d\n', text.RangingCountMin ); 
    case 95
         text.BODY = 'ManagementTimerBase';
         text.ManagementTimerBase = text.msg.pop_uint16;
         text.STRING = sprintf(' \n ManagementTimerBase %d\n', text.ManagementTimerBase ); 
    case 96
         text.BODY = 'ManagementTimerMask';
         text.ManagementTimerMask = text.msg.pop_uint16;
         text.STRING = sprintf(' \n ManagementTimerMask %d\n', text.ManagementTimerMask ); 
    case 97
         text.BODY = 'PositionDebug';
         text.PositionDebug = text.msg.pop_uint8;
         text.STRING = sprintf(' \n PositionDebug %d\n', text.PositionDebug ); 
    case 98
         text.BODY = 'RangingDebug';
         text.RangingDebug = text.msg.pop_uint8;
         text.STRING = sprintf(' \n RangingDebug %d\n', text.RangingDebug );
    case 99
         text.BODY = 'MaxAnchorCount';
         text.MaxAnchorCount = text.msg.pop_uint16;
         text.STRING = sprintf(' \n MaxAnchorCount %d\n', text.MaxAnchorCount );       
    case 100
        text.BODY = 'MyRangingId';
        text.MyRangingId = text.msg.pop_uint16;
        text.STRING = sprintf( '%d', text.MyRangingId );
    case 101
        text.BODY = 'RangingParameters';
        text.RangingParameters_rangingStdv = text.msg.pop_uint16;
        text.RangingParameters_rangingPeriodFudgeFactor = text.msg.pop_uint16;
        text.RangingParameters_rangingPeriodEstimate = text.msg.pop_uint16;
        text.RangingParameters_numberOfRangingEstimates = text.msg.pop_uint16;
        text.RangingParameters_numberOfBatches = text.msg.pop_uint16;
        text.STRING = sprintf( '\n    numberOfBatches %d,\n    numberOfRangingEstimates %d,\n    rangingPeriodEstimate %d,\n    rangingPeriodFudgeFactor %d,\n    rangingStdv %d\n', ...
            text.RangingParameters_numberOfBatches, ...
            text.RangingParameters_numberOfRangingEstimates, ...
            text.RangingParameters_rangingPeriodEstimate, ...
            text.RangingParameters_rangingPeriodFudgeFactor, ...
            text.RangingParameters_rangingStdv );

    case 102
        text.BODY = 'UltrasoundFilterParameters';
        text.UltrasoundFilterParameters_ultrasoundFilterHigh = text.msg.pop_uint16;
        text.UltrasoundFilterParameters_ultrasoundFilterLow = text.msg.pop_uint16;
        text.STRING = sprintf( '\n    ultrasoundFilterLow %d,\n    ultrasoundFilterHigh %d\n', ...
            text.UltrasoundFilterParameters_ultrasoundFilterLow, ...
            text.UltrasoundFilterParameters_ultrasoundFilterHigh );
    case 103
        text.BODY = 'IsLastRangingNode';
        text.IsLastRangingNode = text.msg.pop_uint8;
        text.STRING = sprintf( '%d', text.IsLastRangingNode );
    case 104
        text.BODY = 'LocalizationPeriod';
        text.LocalizationPeriod = text.msg.pop_uint16;
        text.STRING = sprintf( '%d', text.LocalizationPeriod );
    case 105
        text.BODY = 'RangingStartDelay';
        text.RangingStartDelayMask = text.msg.pop_uint16;
        text.RangingStartDelayBase = text.msg.pop_uint16;
        text.STRING = sprintf( 'base=%d mask=%d', text.RangingStartDelayBase,text.RangingStartDelayMask );

   case 106
        text.BODY = 'LocationInfo';
        text.LocationInfo_localizedLocation_SD_y = text.msg.pop_uint16;
        text.LocationInfo_localizedLocation_SD_x = text.msg.pop_uint16;
        text.LocationInfo_localizedLocation_y = text.msg.pop_uint16;
        text.LocationInfo_localizedLocation_x = text.msg.pop_uint16;        
        text.LocationInfo_realLocation_SD_y = text.msg.pop_uint16;
        text.LocationInfo_realLocation_SD_x = text.msg.pop_uint16;        
        text.LocationInfo_realLocation_y = text.msg.pop_uint16;
        text.LocationInfo_realLocation_x = text.msg.pop_uint16;
        text.LocationInfo_isAnchor = text.msg.pop_uint8;
        
        text.STRING = sprintf( '\n    isAnchor %d,\n    realLocation.x %d,\n    realLocation.y %d,\n    realLocation.stdv.x %d,\n    realLocation.stdv.y %d,\n    localizedLocation.x %d,\n    localizedLocation.y %d,\n    localizedLocation.std.x %d,\n    localizedLocation.std.y %d\n', ...
            text.LocationInfo_isAnchor, ...
            text.LocationInfo_realLocation_x, ...
            text.LocationInfo_realLocation_y, ...
            text.LocationInfo_realLocation_SD_x, ...
            text.LocationInfo_realLocation_SD_y, ...
            text.LocationInfo_localizedLocation_x, ...
            text.LocationInfo_localizedLocation_y, ...
            text.LocationInfo_localizedLocation_SD_x, ...
            text.LocationInfo_localizedLocation_SD_y);
   
   case 107
        text.BODY = 'EvaderInfo';
        text.LocationInfo_isAnchor = text.msg.pop_uint8;
        text.LocationInfo_real_x = text.msg.pop_uint16;
        text.LocationInfo_real_y = text.msg.pop_uint16;
        text.LocationInfo_real_SD_x = text.msg.pop_uint16;
        text.LocationInfo_real_SD_y = text.msg.pop_uint16;
        text.LocationInfo_localized_x = text.msg.pop_uint16;
        text.LocationInfo_localized_y = text.msg.pop_uint16;
        text.LocationInfo_localized_SD_x = text.msg.pop_uint16;
        text.LocationInfo_localized_SD_y = text.msg.pop_uint16;
        text.STRING = sprintf( '\n    isAnchor %d,\n    realLocation.x %d,\n    realLocation.y %d,\n    realLocation.stdv.x %d\n,   realLocation.stdv.y %d,\n, localizedLocation.x %d, \n localizedLocation.y %d, \n localizedLocation.std.x %d, \n localizedLocation.std.y %d, \n', ...
            text.LocationInfo_isAnchor, ...
            text.LocationInfo_realLocation_x, ...
            text.LocationInfo_realLocation_y, ...
            text.LocationInfo_realLocation_SD_x, ...
            text.LocationInfo_realLocation_SD_y, ...
            text.LocationInfo_localizedLocation_x, ...
            text.LocationInfo_localizedLocation_y, ...
            text.LocationInfo_localizedLocation_SD_x, ...
            text.LocationInfo_localizedLocation_SD_y);

    case 108
         text.BODY = 'UseWhichPosition';
	 text.useLocalizedPosition = text.msg.pop_uint8;
	 text.STRING = sprintf(' \n UseWhichPosition %d\n', text.useLocalizedPosition);
    case 109
         text.BODY = 'UseEstimatedEvader';
	 text.useLocalizedPosition = text.msg.pop_uint8;
	 text.STRING = sprintf(' \n UseEstimatedEvader %d\n', text.useEstimatedEvader);
    case 119
         text.BODY = 'PurserId';
	 text.PurserId = text.msg.pop_uint8;
	 text.STRING = sprintf('%d', text.PurserId);
    
    case 134
        text.BODY = 'RunningService';
        text.RunningService = text.msg.pop_uint8;
        text.STRING = sprintf( '%d', text.RunningService );
    otherwise
        text = rmfield( text, 'BODY' );
end

function text = MagDataReflection( text )
text.BODY = 'MagDataReflection';
text.mag_pos_y = text.msg.pop_int16;
text.mag_pos_x = text.msg.pop_int16;
text.mag_time = text.msg.pop_uint32;
text.mag_value = text.msg.pop_uint16;
text.STRING = sprintf( 'Value %d, Time %d, PosX %d, PosY %d  =>  Reading (%d,%d) [%d]', text.mag_value, text.mag_time, text.mag_pos_x/256, text.mag_pos_y/256, text.mag_pos_x/256, text.mag_pos_y/256, text.mag_value );

function text = MagHood( text )
text.maghood_protocol = text.msg.pop_uint8;
switch text.maghood_protocol
    case 11
        text = MagDataReflection( text );
end

function text = MagCenterReport( text )
text.BODY = 'MagCenterReport';
text.mag_num_reporting = text.msg.pop_uint8;
text.mag_y_sum = text.msg.pop_int32;
text.mag_x_sum = text.msg.pop_int32;
text.mag_sum = text.msg.pop_uint32;
text.mag_x_pos = text.mag_x_sum / text.mag_sum / 256;
text.mag_y_pos = text.mag_y_sum / text.mag_sum / 256;
text.mag_mean = text.mag_sum / text.mag_num_reporting;
text.STRING = sprintf( 'MagSum %d, XSum %d, YSum %d, Num %d  =>  Center (%.2f,%.2f) [%.0f]', text.mag_sum, text.mag_x_sum, text.mag_y_sum, text.mag_num_reporting, text.mag_x_pos, text.mag_y_pos, text.mag_mean );

function text = Route2TestHops( text )
text.BODY = 'Route2TestHops';
text.hops = text.msg.pop_uint8;
text.tree = text.msg.pop_uint8;
text.type = text.msg.pop_uint8;
text.bcseq = text.msg.pop_uint16;
text.STRING = sprintf( 'BCSeq %d, Type %d, Tree %d, Hops %d', text.bcseq, text.type, text.tree, text.hops );

function text = Route2TestCrumb( text )
text.BODY = 'Route2TestCrumb';
text.parent = text.msg.pop_uint16;
text.crumb = text.msg.pop_uint16;
text.mobag = text.msg.pop_uint8;
text.tree = text.msg.pop_uint8;
text.type = text.msg.pop_uint8;
text.STRING = sprintf( 'Type %d, Tree %d, MobAg %d, Crumb %d, Parent %d', text.type, text.tree, text.mobag, text.crumb, text.parent );

function text = Route2TestBase( text )
text.BODY = 'Route2TestBase';
text.data_value = text.msg.pop_uint8;
text.data_action = text.msg.pop_uint8;
text.len = text.msg.pop_uint8;
text.dest = text.msg.pop_uint8;
text.tree = text.msg.pop_uint8;
text.type = text.msg.pop_uint8;
text.STRING = sprintf( 'Type %d, Tree %d, Dest %d, Leds %d', text.type, text.tree, text.dest, text.data_value );

function text = Route2TestMobileAgent( text )
text.BODY = 'Route2TestMobileAgent';
text.data_value = text.msg.pop_uint8;
text.data_action = text.msg.pop_uint8;
text.len = text.msg.pop_uint8;
text.crumb = text.msg.pop_uint16;
text.dest = text.msg.pop_uint8;
text.type = text.msg.pop_uint8;
text.STRING = sprintf( 'Type %d, Dest %d, Crumb %d, Leds %d', text.type, text.dest, text.crumb, text.data_value );

function text = MagCenterReportCroute( text )
text.BODY = 'MagCenterReportCroute';
text.num_reporting = text.msg.pop_uint8;
text.y_sum = text.msg.pop_int32;
text.x_sum = text.msg.pop_int32;
text.mag_sum = text.msg.pop_uint32;
text.len = text.msg.pop_uint8;
text.crumb = text.msg.pop_uint16;
text.dest = text.msg.pop_uint8;
text.type = text.msg.pop_uint8;
text.STRING = sprintf( 'Type %d, Dest %d, Crumb %d', text.type, text.dest, text.crumb );
%text.x_pos = text.x_sum / text.mag_sum / 256;
%text.y_pos = text.y_sum / text.mag_sum / 256;
%ext.mag_mean = text.mag_sum / text.mag_num_reporting;
%text.STRING = sprintf( 'MagSum %d, XSum %d, YSum %d, Num %d  =>  Center (%.2f,%.2f) [%.0f]', text.mag_sum, text.x_sum, text.y_sum, text.mag_num_reporting, text.x_pos, text.y_pos, text.mag_mean );

function text = RangingReportBody( text )
text.BODY = 'RangingReport';
for i=1:8
    text.neighbors.dist(9-i)=text.msg.pop_uint16;    
    text.neighbors.addr(9-i)=text.msg.pop_uint8;        
end
text.numberOfNeighbors = text.msg.pop_uint8;
text.addr = text.msg.pop_uint16;

text.STRING=sprintf( 'Addr %d, NumNeigh %d,',text.addr, text.numberOfNeighbors);
for i=1:text.numberOfNeighbors
    text.STRING=sprintf('%s NeighAddr %d, NeighDist %d,', text.STRING, text.neighbors.addr(i), text.neighbors.dist(i));
end


function text = ManagementMessageBody( text )
text.BODY = 'ManagementMessage';
text.msg.pop_uint8;
text.hopCount = text.msg.pop_uint8;
text.distanceStdv = text.msg.pop_uint16;
text.distance = text.msg.pop_uint16;
text.locationYStdv = text.msg.pop_uint16;
text.locationXStdv = text.msg.pop_uint16;
text.locationY = text.msg.pop_uint16;
text.locationX = text.msg.pop_uint16;
text.addr = text.msg.pop_uint16;
text.STRING=sprintf( '\n    Anchor %d, X %d, Y %d, Distance %d, HopCount %d',text.addr,text.locationX,text.locationY,text.distance,text.hopCount);


function text = AnchorReportBody( text )
text.BODY = 'AnchorReport';
for i=1:4
    text.anchors.hopCount(5-i)=text.msg.pop_uint8;
    text.anchors.dist(5-i)=text.msg.pop_uint16;    
    %text.anchors.y(4-i)=text.msg.pop_uint16;    
    %text.anchors.x(4-i)=text.msg.pop_uint16;    
    text.anchors.addr(5-i)=text.msg.pop_uint16;        
end
text.numberOfAnchors = text.msg.pop_uint8;
text.addr = text.msg.pop_uint16;

text.STRING=sprintf( 'Addr %d, NumAnchors %d,',text.addr, text.numberOfAnchors);
for i=1:text.numberOfAnchors
    text.STRING=sprintf('%s AnchorAddr %d, AnchorHop %d, Anchor Dist %d', text.STRING, text.anchors.addr(i), text.anchors.hopCount(i), text.anchors.dist(i));
end


function text = MonitorReportBody( text )
text.BODY = 'MonitorReport';

global NUM_STRAYS
global NUM_SAMPLES
NUM_STRAYS=5;
NUM_SAMPLES=10;
requestType=text.msg.read_uint16(2);

switch(requestType)
case {1, 3} %ranging data; timestampL
for i=1:NUM_SAMPLES
  text.samples(NUM_SAMPLES+1-i) = text.msg.pop_uint16;
end
case {4, 6} %strays ranging data; strays timestampL
for i=1:NUM_STRAYS
  text.samples(NUM_SAMPLES+1-i) = text.msg.pop_uint16;
end
case 2 %timestampH followed by seqNo
for i=1:NUM_SAMPLES*2
  text.samples(NUM_SAMPLES*2+1-i) = text.msg.pop_uint8;
end
case 5 %strays timestampH
for i=1:NUM_STRAYS
  text.samples(NUM_SAMPLES+1-i) = text.msg.pop_uint8;
end
end

text.ID = text.msg.pop_uint16;
text.currentIndex = text.msg.pop_uint16;
text.requestType = text.msg.pop_uint16;
text.addr = text.msg.pop_uint16;

text.STRING=sprintf( 'Addr %d, ID %d, requestType %d,',text.addr, text.ID, text.requestType);
for i=1:length(text.samples)
    text.STRING=sprintf('%s %d', text.STRING, text.samples(i));
end



function text = MagLeaderToPursuer( text )
text.BODY = 'MagLeaderToPursuer';
text.strength = text.msg.pop_uint16;
text.event_y = text.msg.pop_uint16;
text.event_x = text.msg.pop_uint16;
text.leader_y = text.msg.pop_uint16;
text.leader_x = text.msg.pop_uint16;
text.STRING = sprintf('leader (%d,%d), event (%d,%d), strength %d', ...
    text.leader_x/256, ...
    text.leader_y/256, ...
    text.event_x/256, ...
    text.event_y/256, ...
    text.strength );

function text = PursuerToMagLeader( text )
text.BODY = 'PursuerToMagLeader';
text.flags = text.msg.pop_uint8;
text.last_y = text.msg.pop_uint16;
text.last_x = text.msg.pop_uint16;
text.crumb_seq_num = text.msg.pop_uint16;
text.pursuer_id = text.msg.pop_uint8;
text.STRING = sprintf( 'id %d, crumb %d, last (%d,%d), flags %x', ...
    text.pursuer_id, ...
    text.crumb_seq_num, ...
    text.last_x/256, ...
    text.last_y/256, ...
    text.flags );

function text = RoutingBody( text )
switch text.routing_protocol
    case 10
        text = MagHood( text );
    case 53
        text = Route2TestHops( text );
    case 54
        switch text.msg.getElement_data(0)
            case 2
                text = Route2TestCrumb( text );
            case 4
                text = Route2TestBase( text );
            case 5
                switch text.msg.getElement_data(4)
                    case 2
                        text = Route2TestMobileAgent( text );
                    case 13
                        text = MagCenterReportCroute( text );
                end
        end
    case 80
        text = MagLeaderToPursuer( text );
    case 81
        text = PursuerToMagLeader( text );
    case 82
        text = MagCenterReport( text );
    case 150    
        text = ManagementMessageBody( text );
    case 180
        text = SystemCommandHood( text );
    case 202
        text = ConfigResponse( text );
end

function text = AMDispatch( text )
switch text.msg.get_type
    case 100
        text = RoutingBody( RoutingSingleBroadcast( RoutingBottom( text ) ) );
    case 101
        text = RoutingBody( RoutingMultiBroadcast( RoutingBottom( text ) ) );
    case 102
        text = RoutingBody( RoutingAddress( RoutingBottom( text ) ) );
    case 177
        text = DiagMsg( text );
    case 196
        text.BODY = 'UltrasonicRanging196'; %mute this message
    case 197
        text.BODY = 'UltrasonicRanging197'; %mute this message
    case 210
        text = RangingReportBody( text );
    case 211
        text = AnchorReportBody( text);
    case 212
        text = MonitorReportBody( text);
end

function text = DiagMsg( text )
offset = 0;
msgend = 0;
text.BODY = 'DiagMsg';
text.DiagMsg = {};
text.STRING = '';
while (offset < text.msg.get_length) && (msgend == 0)
    code = text.msg.read_uint8( offset );
    offset = offset + 1;
    [text,offset,msgend] = DiagMsgAddSimple( text, offset, mod(code,16) );
    [text,offset,msgend] = DiagMsgAddSimple( text, offset, mod(fix(code/16),16) );
end

function [text,offset,msgend] = DiagMsgAddSimple( text, offset, type )
msgend = 0;
switch type
    case 0  %TYPE_END
        msgend = 1;
        
    case 1  %TYPE_INT8
        text.DiagMsg{end+1} = text.msg.read_int8( offset );
        offset = offset + 1;
        text.STRING = sprintf( '%s %d', text.STRING, text.DiagMsg{end} );
        
    case 2  %TYPE_UINT8
        text.DiagMsg{end+1} = text.msg.read_uint8( offset );
        offset = offset + 1;
        text.STRING = sprintf( '%s %d', text.STRING, text.DiagMsg{end} );
        
    case 3  %TYPE_HEX8
        text.DiagMsg{end+1} = text.msg.read_uint8( offset );
        offset = offset + 1;
        text.STRING = sprintf( '%s %02x', text.STRING, text.DiagMsg{end} );
        
    case 4  %TYPE_INT16
        text.DiagMsg{end+1} = text.msg.read_int16( offset );
        offset = offset + 2;
        text.STRING = sprintf( '%s %d', text.STRING, text.DiagMsg{end} );
        
    case 5  %TYPE_UINT16
        text.DiagMsg{end+1} = text.msg.read_uint16( offset );
        offset = offset + 2;
        text.STRING = sprintf( '%s %d', text.STRING, text.DiagMsg{end} );
        
    case 6  %TYPE_HEX16
        text.DiagMsg{end+1} = text.msg.read_uint16( offset );
        offset = offset + 2;
        text.STRING = sprintf( '%s %04x', text.STRING, text.DiagMsg{end} );
        
    case 7  %TYPE_INT32
        text.DiagMsg{end+1} = text.msg.read_int32( offset );
        offset = offset + 4;
        text.STRING = sprintf( '%s %d', text.STRING, text.DiagMsg{end} );
        
    case 8  %TYPE_UINT32
        text.DiagMsg{end+1} = text.msg.read_uint32( offset );
        offset = offset + 4;
        text.STRING = sprintf( '%s %d', text.STRING, text.DiagMsg{end} );
        
    case 9  %TYPE_HEX32
        text.DiagMsg{end+1} = text.msg.read_uint32( offset );
        offset = offset + 4;
        text.STRING = sprintf( '%s %08x', text.STRING, text.DiagMsg{end} );
        
    case 10  %TYPE_FLOAT
        text.DiagMsg{end+1} = text.msg.read_float( offset );
        offset = offset + 4;
        text.STRING = sprintf( '%s %f', text.STRING, text.DiagMsg{end} );
        
    case 11  %TYPE_CHAR
        text.DiagMsg{end+1} = text.msg.read_uint8( offset );
        offset = offset + 1;
        text.STRING = sprintf( '%s %c', text.STRING, text.DiagMsg{end} );
        
    case 14  %TYPE_TOKEN
        text.DiagMsg{end+1} = text.msg.read_uint8( offset );
        offset = offset + 1;
        text.STRING = sprintf( '%s (token %d)', text.STRING, text.DiagMsg{end} );
        
    case 15  %TYPE_ARRAY
        code2 = text.msg.read_uint8( offset );
        offset = offset + 1;
        len2 = mod( code2, 16 );
        type2 = mod( fix(code2/16), 16 );
        switch type2
            case 14  %TYPE_CHAR
                text.DiagMsg{end+1} = text.msg.read_string( offset );
                offset = offset + len2;
                text.STRING = sprintf( '%s "%s"', text.STRING, text.DiagMsg{end} );
            otherwise
                text.STRING = sprintf( '%s [', text.STRING );
                for ii = 1:len2
                    [text,offset] = DiagMsgAddSimple( text, offset, type2 );
                end
                text.STRING = sprintf( '%s ]', text.STRING );
        end
end
    
function text = RoutingSingleBroadcast( text )
text.routing_name = 'SingleBroadcast';

function text = RoutingMultiBroadcast( text )
text.routing_name = 'MultiBroadcast';
text.routing_hopsleft = text.msg.pop_uint8;

function text = RoutingAddress( text )
text.routing_name = 'Address';
text.routing_address = text.msg.get_addr;

function text = RoutingBottom( text )
text.routing_full_length = text.msg.get_length;
text.routing_protocol = text.msg.pop_uint8;
text.routing_sequence = text.msg.pop_uint8;
text.routing_origin = text.msg.pop_uint16;

function serialdate = unixdate( seconds, utcOffset )
serialdate = datenum( 1969, 12, 31, 24+utcOffset, 0, seconds );

