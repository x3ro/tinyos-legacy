function recvAllMsgs(varargin)
% A generic function to connect all matlab message handlers.
% If no arguments are given, we connect all matlab message handlers of
% applications in the global structure APPS.
% Otherwise, we only connect matlab message handlers of the structure
% passed in.  This structure 'appStruct' must have appStruct.Comm.xxx.Msg
% and appStruct.Comm.xxx.Handler, where xxx is the name of a message that's
% being handled.  Read the general README for specifics on how to layout
% appStruct and its subcomponents.
%
% usage: recvAllMsgs()
%       recvAllMsgs(MAGLIGHT) % MAGLIGHT is a structure containing
%       application communication info

global APPS;
if isempty(APPS)
    disp('no applications running');
    return;
end

if (nargin == 1)
    appStruct = varargin{1};
    loopMsgHandlers(appStruct);
else
    appNames = fieldnames(APPS);
    for j = 1:length(appNames)
        appStruct = APPS.(appNames{j});
        loopMsgHandlers(appStruct);
    end
end

% helper function
function loopMsgHandlers(appStruct)
if ~isfield(appStruct,'Comm')
    return; % skips non-compliant structures
end
msgNames = fieldnames(appStruct.Comm);
for i = 1:length(msgNames)
    for k = 1:length(appStruct.Comm.(msgNames{i}).Handler)
        receive(appStruct.Comm.(msgNames{i}).Handler{k},appStruct.Comm.(msgNames{i}).Msg);
    end
end

function usage
disp('usage: recvAllMsgs()');
disp('    recvAllMsgs(MAGLIGHT) % MAGLIGHT is a structure containing');
disp('     application communication info')