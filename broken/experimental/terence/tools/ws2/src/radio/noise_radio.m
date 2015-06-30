function output = noise_radio(varargin)
output = feval(varargin{:});

% this file is really the core of this program, rewriting this will almost rewrite the whole thing
% this provide send_packet function for the application layer and it needs to called send_packet_done
% and receive in the application layer somehow
% it is important to make this file as general as possible, such as function to evaluate some parameters
% because that's the whole point of this software, that is, to study different effect of protocol and stuff
% you have array of mote for you to save information into and that's the only data stucture you are given
% you need to handle a event called move_node all the radio properties should be set with field name radio_... 
% so it would not collide with application layer. this also help hiding data, since application should not access this field

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PUBLIC FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is called to initialise this generic layer
% put all your stuff in this structure. args for this function is empty