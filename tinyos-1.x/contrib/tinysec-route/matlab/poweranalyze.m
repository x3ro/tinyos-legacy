crcs = load('crcs.csv');
auths = load('auths.csv');
aes  = load('aes.csv');


crcr = load('crcr.csv');
authr = load('authr.csv');
aer  = load('aer.csv');

% to get to current: divide voltage by 85 (voltage gain) * 1.1 (resistor)
crcs(:,2) = crcs(:,2) / (1.1 * 85);
auths(:,2) = auths(:,2) / (1.1 * 85);
aes(:,2) = aes(:,2) / (1.1 * 85);

crcr(:,2) = crcr(:,2) / (1.1 * 85);
authr(:,2) = authr(:,2) / (1.1 * 85);
aer(:,2) = aer(:,2) / (1.1 * 85);

% isolated to just the packet time.
pcrcs = crcs(((crcs(:,1) > 0) & (crcs(:,1)<.027212)),:);
pauths  = auths(((auths(:,1) > 0) & (auths(:,1) < .027636)),:);
paes  = aes(((aes(:,1) > 0) & (aes(:,1) < .029304)),:);

figure
subplot(3,1,1), plot(crcs(:,1), crcs(:,2));  
   axis([-.002 .035 0 .03]); title('No TinySec');
subplot(3,1,2), plot(auths(:,1), auths(:,2)); 
   axis([-.002 .035 0 .03]); title('TinySec: Authentication only')
ylabel('current (amps)')
subplot(3,1,3), plot(aes(:,1), aes(:,2)); 
   axis([-.002 .035 0 .03]); title('TinySec: Authentication and Encryption')
xlabel('time (s)')

figure 
subplot(3,1,1), plot(pcrcs(:,1), pcrcs(:,2));
subplot(3,1,2), plot(pauths(:,1), pauths(:,2));
ylabel('current (amps)')
subplot(3,1,3), plot(paes(:,1), paes(:,2));
xlabel('time (s)')

figure
subplot(3,1,1), plot(crcr(:,1), crcr(:,2)); 
subplot(3,1,2), plot(authr(:,1), authr(:,2));
ylabel('current (amps)')
subplot(3,1,3), plot(aer(:,1), aer(:,2));
xlabel('time (s)')

% integrate to get amp-seconds. 
% * 1000/3600 to get millamp hours
ecrcs  = (mean(pcrcs(:,2))  *  pcrcs( length(pcrcs),1))  * 10/36;
eauths = (mean(pauths(:,2)) * pauths(length(pauths),1)) * 10/36;
eaes =   (mean(paes  (:,2)) * paes ( length(paes),1))    * 10/36;

disp(sprintf('crc-send: %f mAH', ecrcs));
disp(sprintf('auth-send: %f mAH', eauths));
disp(sprintf('ae-send: %f mAH', eaes));

