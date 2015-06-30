function updatePeg(id,x,y)

global VIS;
%
% This is a placeholder function to update pursuer and evader information
%
% the message is assumed to have the following fields:
%
% typedef struct MagCenterReport_t {
%    uint32_t mag_sum;
%    int32_t mag_x_sum;
%    int32_t mag_y_sum;
%    uint8_t mag_num_reporting;
%    uint8_t hops_left;
%    uint16_t origin_address;
%    uint8_t origin_sequence;
%    uint8_t protocol;
% } MagCenterReport_t;

% The origin address switches the following:
%   it if is 0x1000, it is evader's gps estimate
%   it if is 0x1001, it is pursuer1's gps estimate
%   it if is 0x1002, it is pursuer2's gps estimate
%   it if is 0x1003, it is pursuer1's estimate of evader's position
%   it if is 0x1004, it is pursuer2's estimate of evader's position

disp('update peg called')
VIS.agent(id).real_pos = [x y]/VIS.node_separation;
VIS.agent(id).calc_pos = [x y]/VIS.node_separation;
VIS.flag.agent_updated = 1;


