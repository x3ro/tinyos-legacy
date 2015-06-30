
% gen_trajectory(trajname,ntracks,tmax,tlen,L,vmax,vmin,randombirth)
gen_trajectory('demo',4,50,40,100,5,1,1);

% gen_swobs_PIR(trajfile,swobsfile,layout,Rs,dist,unitlen,showfig)
gen_swobs_PIR('demo','demo_sw','uniform',7.62,5,1,1);

% sim_online_tracking(trajfile,swobsfile,savedata,doPEG)
sim_online_tracking('demo','demo_sw','demo_sw_mcmc',1,[],[]);