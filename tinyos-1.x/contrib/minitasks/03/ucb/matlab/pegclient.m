function pegclient( text )
	
global Motes
global isChirpMsgHeard
global ReportMsgHeard


if isfield(text,'routing_origin')
    aa = sprintf( 'x%X', text.routing_origin );
    mm = sprintf( 'Motes.%s', aa );
    
    if ~isfield(Motes,aa)
        eval([mm '=[];'])
    end
    if isfield(text,'BODY')
        eval( sprintf( '%s.%s = text;', mm, text.BODY ) );
    end

    maxRecent = 5;
    rr = sprintf( '%s.RECENT', mm );
    eval( sprintf( 'if ~isfield(%s,''RECENT''); %s = {}; end;', mm, rr ) );
    eval( sprintf( 'if ~iscell(%s); %s = {}; end;', rr, rr ) );
    eval( sprintf( 'n = max(1,length(%s)-maxRecent+2); %s = { %s{n:end}, text };', rr, rr, rr ) );
end

if isfield(text,'STRING')

    if isfield(text,'routing_origin')
        if text.routing_origin < 256; addrfmt = '%d/%d'; else addrfmt = '0x%x/%d'; end
        fprintf( [addrfmt ' %s: %s\n'], text.routing_origin, text.routing_sequence, text.BODY, text.STRING );
    else
        fprintf( '%s: %s\n', text.BODY, text.STRING );
    end

elseif ~isfield(text,'BODY')

    data = double('text.msg.get_data');
    data(data<0) = 256 + data(data<0); %convert to unsigned
    length = text.msg.get_length;
    if isfield(text,'routing_full_length'); length = text.routing_full_length; end;
    fprintf( 'AM %d length %d:', text.msg.get_type, length );
    fprintf( ' %02x', data(1:length) );
    fprintf( ' ...' );
    fprintf( ' %02x', data((length+1):end) );
    fprintf( '\n' );

    %text
    
end

if isfield(text,'BODY') 
    if strcmp(text.BODY,'MagCenterReport')
        if ~isfield(Motes,'MagCenterReport')
            Motes.MagCenterReport = {};
        end
        if ~isfield(Motes,'mag_center')
            Motes.mag_center = [];
        end
        Motes.MagCenterReport{end+1} = text;
        Motes.mag_center(:,end+1) = [ text.mag_x_pos; text.mag_y_pos; text.mag_mean ];
        if text.routing_origin >= 4096 && text.routing_origin <= 4100
            id = text.routing_origin - 4095;
            x = text.mag_x_pos;
            y = text.mag_y_pos;
            updatePeg(id,x,y);
        end
    end
    if strcmp(text.BODY,'MagDataReflection')
        if ~isfield(Motes,'MagDataReflection')
            Motes.MagDataReport = {};
        end
        Motes.MagDataReport{end+1} = text;
        updateMagData( text.routing_origin, text.mag_value ); %demo viz
    end
    %return; %%%%%%%%%%%%%
    if strcmp(text.BODY, 'SpanTreeStatus')
        guiMessageHandler('ststatus', text);    
    end
    if strcmp(text.BODY, 'UltrasonicRanging197')
	   isChirpMsgHeard = 1;
    end
    if strcmp(text.BODY, 'RangingReport')
        %guiMessageHandler('ranging', text);
    end
    if strcmp(text.BODY, 'AnchorReport')
        %guiMessageHandler('anchor', text);
    end
    if strcmp(text.BODY, 'LocationInfo')
        guiMessageHandler('location', text);
    end

	if strcmp(text.BODY, 'MonitorReport')
	    receiveMonitorData(text);
		ReportMsgHeard = ReportMsgHeard + 1;
    end
    if strcmp(text.BODY, 'ChirpMsg')
	    receiveChirpMsg(text);
	end


	
end
