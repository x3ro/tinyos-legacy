function [plotData, motes, channels] = plotOscopeMsg(fileName,typeFlag)
% plotOscopeMsg(fileName,typeFlag)
% Plots a file of OscopeMsgs (embedded in TOSMsgs)
%
% INPUT:
%   typeFlag == '0' for default TOSMsgs (ex. mica motes)
%   typeFlag == '1' for telos TOSMsgs
%   typeFlag == '2' for TOSMsgs in default format except Oscope Struct has
%                   11 samples instead of 10 samples per packet
%   typeFlag == '3' for telos TOSMsgs with 8 extra bytes appended
%                   (simulation output)
% 
% INPUT FILE FORMAT (all dumps from Listen.java)
% - script ignores characters after 'sf@' (not for matlab R13)
% - all byte pairs (16 bits) are in (LSB,MSB) format.  See Node ID example
%   below
%
% - Default TOSMsg format
% FF FF 0A 7D 1C 08 00 C7 00 00 00 4F 02 22 02 5A 02 0E 02 2B 02 E9 01 1D 02 F9 01 12 02 F5 01 1E 02
% * 33 bytes total, 29 byte payload
% * Oscope Struct starts from byte 6
% * Node ID = 08 00  (00 is the MSB)
% * sample number = C7 00 is the sample number of the last reading in the
%   message
% * channel number = 00 00
% * readings are 2 bytes each, 10 samples per message (ex. 00 4F in LSB MSB
%   format)
%
% - Telos TOSMsg format
% 1A 01 08 89 FF FF FF FF 0A 7D 05 00 5A 0F 03 00 32 08 EE 07 D3 07 1F 08 EF 07 E7 07 AB 07 E3 07 A7 07 D3 07 
% * 36 bytes total, 28 byte payload
% * Oscope Struct starts from byte 11
% * Node ID = 05 00, (00 is the MSB)
% * sample number = 5A 0F
% * channel number = 03 00
% * readings are 2 bytes each, 10 samples per message
%
% NOTES:
% - Doesn't handle duplicate packets well (nor does oscope, I presume)
%   will plot with lines running backwards
% - Doesn't handle packets of out sequence for a particular mote well
%   will plot with lines running backwards
% - Plots channels for motes even if no data
% - useful unix functions for forcing other output files to comply:
%   cut -d' ' -f1-36 filename | uniq - > filename_processed # removes
%                                #duplicates and chops off extra bytes

if ~exist('typeFlag')
    typeFlag = 0; %defaults to default type
end

if (strcmp(version('-release'),'13'))
    switch typeFlag
        case 0, %default TinyOS TOSMsg
            offset = 6;
            pktSamples = 10;
            columns = 33;
        case 1, %default Telos TOSMsg
            offset = 11;
            pktSamples = 10;
            columns = 36;
        case 2, %default TinyOS TOSMsg with 11 samples in OscopeMsg
            offset = 6;
            pktSamples = 11;
            columns = 35;
        case 3, %default Telos TOSMsg with 8 additional bytes
            offset = 11;
            pktSamples = 10;
            columns = 44;
    end
    fid = fopen(fileName);
    charDat = fscanf(fid,'%2s',[columns*2 inf])';
    fclose(fid);
    colvec = 2*ones(1,columns);
    dat = mat2cell(charDat,size(charDat,1),colvec);
else 
    fid = fopen(fileName);
    switch typeFlag
        case 0, %default TinyOS TOSMsg
            dat = textscan(fid,'%2s%2s%2s%2s%2s%2s%2s%2s%2s%2s %2s%2s%2s%2s%2s%2s%2s%2s%2s%2s %2s%2s%2s%2s%2s%2s%2s%2s%2s%2s %2s%2s%2s',...
                'commentStyle','sf@');
            offset = 6;
            pktSamples = 10;
        case 1, %default Telos TOSMsg
            offset = 11;
            dat = textscan(fid,'%2s%2s%2s%2s%2s%2s%2s%2s%2s%2s %2s%2s%2s%2s%2s%2s%2s%2s%2s%2s %2s%2s%2s%2s%2s%2s%2s%2s%2s%2s %2s%2s%2s%2s%2s%2s',...
                'commentStyle','sf@');
            pktSamples = 10;
        case 2, %default TinyOS TOSMsg with 11 samples in OscopeMsg
            offset = 6;
            dat = textscan(fid,'%2s%2s%2s%2s%2s%2s%2s%2s%2s%2s %2s%2s%2s%2s%2s%2s%2s%2s%2s%2s %2s%2s%2s%2s%2s%2s%2s%2s%2s%2s %2s%2s%2s%2s%2s',...
                'commentStyle','sf@');
            pktSamples = 11;
        case 3, %default Telos TOSMsg with 8 additional bytes
            offset = 11;
            dat = textscan(fid,'%2s%2s%2s%2s%2s%2s%2s%2s%2s%2s %2s%2s%2s%2s%2s%2s%2s%2s%2s%2s %2s%2s%2s%2s%2s%2s%2s%2s%2s%2s %2s%2s%2s%2s%2s%2s %2s%2s%2s%2s%2s%2s%2s%2s',...
                'commentStyle','sf@');
            pktSamples = 10;
    end
    fclose(fid);
end

pDat.sourceAddr = hex2dec(strcat(dat{offset+1},dat{offset}));
pDat.sampNum = hex2dec(strcat(dat{offset+3},dat{offset+2}));
pDat.channel = hex2dec(strcat(dat{offset+5},dat{offset+4}));
pDat.reading = [];
for i = offset+6:2:(offset+5+pktSamples*2)
    pDat.reading(:,end+1) = hex2dec(strcat(dat{i+1},dat{i}));
end

%% Plotting Data Structure
motes = unique(pDat.sourceAddr);
channels = unique(pDat.channel);
plotData = cell(length(motes),length(channels));
for i = 1:length(pDat.sourceAddr)
    mt = find(motes == pDat.sourceAddr(i));
    ch = find(channels == pDat.channel(i));
    start = pDat.sampNum(i);
    %% modify this line if you want to handle duplicate packets, etc.
    plotData{mt,ch}(:,end+1:end+pktSamples) = ...
        [start-pktSamples+1:start; pDat.reading(i,1:pktSamples)];
end

%% Plotting
scrsz = get(0,'ScreenSize');
colorvec = ['g' 'b' 'r' 'c' 'm' 'y' 'k'];
h = figure('Position',[1 scrsz(4)/2, scrsz(3)/2 scrsz(4)-100]);
handle = [];
chanNames = {};
for j = 1:length(motes)
    subplot(length(motes),1,j);
    hold on;
    for k = 1:length(channels)
        linecolor = colorvec(mod(k,length(colorvec))+1);
        handle(end+1) = plot(plotData{j,k}(1,:),plotData{j,k}(2,:),linecolor);
        chanNames{end+1} = sprintf('Mote %d Channel %d',motes(j),channels(k));
    end
    title(sprintf('Mote %d',motes(j)));
    legend(handle,chanNames);
    hold off;
end
