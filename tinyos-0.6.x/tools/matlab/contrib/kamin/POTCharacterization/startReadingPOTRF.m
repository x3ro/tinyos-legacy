function startReadingPOTRF(varargin)
%startReadingPOTRF(transmitter, receivers, firstPotSetting, lastPotSetting, potSettingStep, numSamples, <plotTrueRF=0>)
%
%
%This function takes the IDs of the motes it should listen to and the pot setting that the transmitter
%is currently set to.
%It then registers a function to listen to those motes and stores their response

global POT_RF

POT_RF.transmitter = varargin{1};
POT_RF.receivers = varargin{2};
POT_RF.firstPot = varargin{3};
POT_RF.potSetting = varargin{3};
POT_RF.potSettings = [];
POT_RF.lastPot = varargin{4};
POT_RF.potStep = varargin{5};
POT_RF.numSamples = varargin{6};
if length(varargin) > 6
    POT_RF.plotTrueRF = varargin{7};
else
    POT_RF.plotTrueRF = 0;
end

global RADIO_POT_SETTING
RADIO_POT_SETTING = POT_RF.potSetting;
routePackets(POT_RF.transmitter, setPot);
routePackets(POT_RF.transmitter, radioJamOn);

global ADC_DATA_CHANNEL
ADC_DATA_CHANNEL = 0;
routePackets(POT_RF.receivers, startSensing);
routePackets(POT_RF.receivers, setClockRate(64));

addPacketListeners(getPortMapping(POT_RF.receivers), 'POTRFReceivePackets');
figure