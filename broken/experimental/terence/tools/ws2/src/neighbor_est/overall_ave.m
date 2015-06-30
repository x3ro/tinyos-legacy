%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function track_info = track_packet(seq_num, track_info)
% %% calculate how many packet we missed by subtracting the seqnum of the current packet to
% %% the sequence number of the packet i receive
% if isempty(track_info)
%     track_info.seqnum = seq_num - 1;
%     track_info.missed_packets = 0;
%     track_info.got_packets = 0;
% end
% 
% if seq_num <= track_info.seqnum
%     return;    
% end
% 
% missed_packet = seq_num - track_info.seqnum - 1;
% %% update missed packet
% track_info.missed_packets = track_info.missed_packets + missed_packet;
% %% increment got_packets
% track_info.got_packets = track_info.got_packets + 1;
% %% save down the sequence number
% track_info.seqnum = seq_num;
% 
% function prob = calculate_est(track_info)
% % %% receive estimation will be how many packet we receive over the total packet that we got. 
% % prob = track_info.got_packets / ( track_info.got_packets + track_info.missed_packets);
% % % Put bound on probability estimate
% % if prob >= 1
% %     prob = .99;
% % end
% global protocol_params;
% if track_info.got_packets > protocol_params.min_samples
%     %% receive estimation will be how many packet we receive over the total packet that we got. 
%     prob = track_info.got_packets / ( track_info.got_packets + track_info.missed_packets);
% else
%     prob = 0;
% end