function change_bs_station(old,new)
global sim_params protocol_params all_mote;
all_mote.parent(new) = protocol_params.invalid_parent;
all_mote.hop(new) = 0;
all_mote.hop(old) = Inf;
sim_params.base_station = new;
