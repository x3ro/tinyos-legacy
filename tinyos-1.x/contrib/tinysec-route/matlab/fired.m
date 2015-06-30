function ret = fired()
global RouteTimings
global Experiment
global TopologyGraph
global fired_arg_pairs
global fired_arg_number
global fired_arg_modes
global fired_arg_basedir
global fired_i
global fired_j
global fired_k
global fired_STATE_POINT
global fired_TIMER

switch fired_STATE_POINT
    case 0
        if (fired_k > length(fired_arg_modes))
            disp('stopping timer')
            stop(fired_TIMER)
            % go back to mode=AUTH_ONLY
            disp('switching back to TRANSMIT_AUTH_ONLY')
            changeMode(1)
            return       
        end
        warning off MATLAB:MKDIR:DirectoryExists
        switch(fired_arg_modes(fired_k)) 
            case 1
                cd(fired_arg_basedir);
                mkdir(fired_arg_basedir, 'tsruns-auth');
                cd 'tsruns-auth';
                disp('cd tsruns-auth')
            case 2
                cd(fired_arg_basedir)
                mkdir(fired_arg_basedir, 'tsruns-ae');
                cd 'tsruns-ae'
                disp('cd to tsruns-ae')
            case 3
                cd(fired_arg_basedir)
                mkdir(fired_arg_basedir, 'tsruns-crc');
                cd 'tsruns-crc'
                disp('cd to tsruns-crc')
        end
        changeMode(fired_arg_modes(fired_k));
        fired_STATE_POINT = 1;
        fired_i = 1;
    case 1
        if fired_i > size(fired_arg_pairs, 1)
            fired_k = fired_k + 1;
            fired_STATE_POINT = 0;
            return
        end
        fired_j = 1;
        RouteTimings= [];
        Experiment = ...
           [Experiment ; fired_arg_pairs(fired_i,1) fired_arg_pairs(fired_i,2)];

        disp(sprintf('[rtcrumb] to:%d messages:%d',fired_arg_pairs(fired_i,2),fired_arg_number))
        for local_i = 1:3
            peg(fired_arg_pairs(fired_i, 2), 'rtcrumb', 2);
            pause(1)
        end
        fired_STATE_POINT = 2;
    case 2
        if(length(RouteTimings) < fired_arg_number)
            disp(sprintf('[rtloop] from:%d to:%d counter:%d total: %d mode:%s',fired_arg_pairs(fired_i,1), ...
                fired_arg_pairs(fired_i,2),fired_j,length(RouteTimings),sendMode(fired_arg_modes(fired_k))))
            peg(fired_arg_pairs(fired_i,1),'rtloop',2,mod(fired_j,256));
            fired_j = fired_j + 1;
        else
            savefile =  sprintf('Experiment_hops_%d_from_%d_to_%d.txt', ...
                TopologyGraph(fired_arg_pairs(fired_i,1),3)+TopologyGraph(fired_arg_pairs(fired_i,2),3), ...
                fired_arg_pairs(fired_i,1), fired_arg_pairs(fired_i,2));
            save(savefile, 'RouteTimings', '-ASCII');
            fired_i = fired_i + 1;
            fired_STATE_POINT = 1;
        end
end
ret = 0;
    
% modes -> AUTH_ONLY:1 ENCRYPT_AND_AUTH:2 CRC:3 
function ret = changeMode(mode)
disp(sprintf('changing transmit mode: %s', sendMode(mode)))
for local_i=1:3
    peg('all', 'TinySecTransmitMode', mode);
    pause(1)
end

if (mode == 3)
    newrecmode = 2;
    newbsmode = 'BSSNoTS';
else 
    newrecmode = 1;
    newbsmode = 'BSSTSAuth';                
end

% changes receive mode with both base station modes
peg('all', 'BSSTSAuth');
pause(1)           
disp(sprintf('changing receive mode: %s', receiveMode(newrecmode)))
for local_i = 1:3                
    peg('all', 'TinySecReceiveMode', newrecmode);
    pause(1)
end
peg('all', 'BSSNoTS');
pause(1)
for local_i = 1:3                
    peg('all', 'TinySecReceiveMode', newrecmode);
    pause(1)
end            

% switch to new base station mode
disp(sprintf('changing base station transmit mode: %s', newbsmode))
peg('all', newbsmode);

function ret = sendMode(mode)
switch(mode)
    case 1
        ret = 'TRANSMIT_AUTH_ONLY';
    case 2
        ret = 'TRANSMIT_ENCRYPT_AND_AUTH';
    case 3
        ret = 'TRANSMIT_CRC';
end

function ret = receiveMode(mode)
switch(mode)
    case 1
        ret = 'RECEIVE_AUTH';
    case 2
        ret = 'RECEIVE_CRC';
    case 3
        ret = 'RECEIVE_ANY';
end

% fired(pairs, number, modes)
% 0:
%    for k = 1:length(modes)
%       cd to directory based on mode
%       for j = 1:3 
%            change modes to modes[k]
%       for i = 1:length(pairs)
%         Experiment = [Experiment; pairs]
% 1       for j = 1:3 
%             drop crumb with pairs(dst)  
% 2       while (length(RouteTimings) < fired_number)
%              peg src rtloop (j++)
%         save RouteTimings
% 3:    
    