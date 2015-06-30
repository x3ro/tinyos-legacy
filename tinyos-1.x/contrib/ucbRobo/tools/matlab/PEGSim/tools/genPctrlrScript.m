% genPctrlrScript
global dT;

dT = 0.1;

Pctrlr = PpolicyNonLinOptInit(10,30,diag([1,1,0.1,0.1]),1,100,2,0.2,3);
save('examples/Pctrlr_CovGamma_1','Pctrlr');
%ch,ph,xWt,uWt,gWt,s_q,s_r,ctrlChoice

Pctrlr = PpolicyNonLinOptInit(10,30,diag([1,1,0.1,0.1]),1,1,1,0.2,3);
save('examples/Pctrlr_CovGamma_2','Pctrlr');
%ch,ph,xWt,uWt,gWt,s_q,s_r,ctrlChoice

Pctrlr = PpolicyNonLinOptInit(10,30,diag([1,1,0.1,0.1]),1,1,2,0.2,1);
save('examples/Pctrlr_Basic_1','Pctrlr');
%ch,ph,xWt,uWt,gWt,s_q,s_r,ctrlChoice