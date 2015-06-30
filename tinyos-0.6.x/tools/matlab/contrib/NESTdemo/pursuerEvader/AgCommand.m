function p=AgCommand(magOn, sounderOn, varargin)
%p=AgCommand(magOn, sounderOn, pot, minValidDistance, magCutoff)
%
%This packet will turn the AGRO network on with the following parameters

global TOS_BCAST_ADDR
global GROUP_ID

if length(varargin)>2
    magCutoff=varargin{3};
else
    magCutoff=0;
end
if length(varargin)>1
    minValidDistance=varargin{2};
else
    minValidDistance=0;
end
if length(varargin)>0
    pot=varargin{1};
else
    pot=255;
end

p = packet(getDefaultPacketHeaders);                 %first add the tos headers
p = set(p,'address', TOS_BCAST_ADDR);       %and set their values correctly for a command packet
p = set(p,'AM', 12);
p = set(p,'groupID', GROUP_ID);
p = set(p,'length', 6);
p = set(p,'magOn', magOn);
p = set(p,'sounderOn', sounderOn);
p = set(p,'pot', pot);
p = addField(p,createField('zeros',3)); %empty 3 bytes
p = addField(p,createField('minValidDistance',2)); %create 2-byte field
p = set(p,'minValidDistance',minValidDistance);
p = addField(p,createField('magCutoff',2));
p = set(p,'magCutoff',magCutoff);
