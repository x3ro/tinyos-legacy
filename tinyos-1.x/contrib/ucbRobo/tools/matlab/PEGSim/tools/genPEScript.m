%genPEscript

% [P, E] = PEInit(1,[10; 10; 0; 0],0,0,1,[60; 80; 1; -2]);
% %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
% save examples/PE100x100_1.mat P E
% 
% [P, E] = PEInit(1,[10; 10; 0; 0],0,0,1,[60; 20; 1; 2]);
% %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
% save examples/PE100x100_2.mat P E
% 
% 
% 
% [P, E] = PEInit(1,[5; 5; 0; 0],0,0,1,[5; 25; 1; -2]);
% %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
% save examples/PE25x25_1.mat P E
% 
% [P, E] = PEInit(1,[12; 12; 0; 0],0,0,1,[0; 20; 3; -1/2]);
% %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
% save examples/PE25x25_2.mat P E
% 
% [P, E] = PEInit(1,[20; 20; 0; 0],0,0,1,[12; 12; -1; -1]);
% %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
% save examples/PE25x25_3.mat P E
% 
% [P, E] = PEInit(1,[22; 5; 0; 0],0,0,1,[12; 12; -1; 2]);
% %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
% save examples/PE25x25_4.mat P E
% 
% [P, E] = PEInit(1,[9; 23; 0; 0],0,0,1,[9; 4; 1; 0]);
% %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
% save examples/PE25x25_5.mat P E

[P, E] = PEInit(1,[30; 30; 0; 0],0,0,1,[30; 50; -2; -5]);
%Pn,Ppos,Pmeas_std,Pact_std,En,Epos
save examples/PE50x50_1.mat P E

[P, E] = PEInit(1,[37; 37; 0; 0],0,0,1,[25; 45; 3; -1/2]);
%Pn,Ppos,Pmeas_std,Pact_std,En,Epos
save examples/PE50x50_2.mat P E

[P, E] = PEInit(1,[45; 45; 0; 0],0,0,1,[37; 37; -1; -1]);
%Pn,Ppos,Pmeas_std,Pact_std,En,Epos
save examples/PE50x50_3.mat P E

[P, E] = PEInit(1,[47; 30; 0; 0],0,0,1,[37; 37; -1; 2]);
%Pn,Ppos,Pmeas_std,Pact_std,En,Epos
save examples/PE50x50_4.mat P E

[P, E] = PEInit(1,[34; 48; 0; 0],0,0,1,[34; 29; 1; 0]);
%Pn,Ppos,Pmeas_std,Pact_std,En,Epos
save examples/PE50x50_5.mat P E