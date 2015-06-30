function PWGraph(basedir, modes, num, duration)

% bytes per second
f = figure
l={};
for m = 1:length(modes)
  switch modes(m)
   case 1
    d='ae';
    draw='r.-.';
    l = {l{:} 'Authentication and encryption'}
   case 2
    d='auth';
    draw='g*-';
    l = {l{:} 'Authentication'}
   case 3
    d='crc';
    draw='b+--';
    l = {l{:} 'No TinySec'}
  end
  try
    dir=strcat(basedir, '/', d)
    data=PWSummarize(dir, num)
  catch
    disp('shiznit');
    continue
  end  
  plot(data(:, 1), data(:,5)/duration, draw);
  if m== 1
    hold on
  end
end
hold off
xlabel('Number of senders');
ylabel('Total application received bandwidth (bytes/s)');
legend(l,4)
cd(basedir);
axis([1 num 0 (max(data(:,5))/duration +100) ])
set(gca, 'XTick', 1:num);
print(f, '-depsc2', 'bw.eps');

% packets per second:
f = figure
l={};
for m = 1:length(modes)
  switch modes(m)
   case 1
    d='ae';
    draw='r.-.';
    l = {l{:} 'Authentication and encryption'}
   case 2
    d='auth';
    draw='g*-';
    l = {l{:} 'Authentication'}
   case 3
    d='crc';
    draw='b+--';
    l = {l{:} 'No TinySec'}
  end
  try
    dir=strcat(basedir, '/', d)
    data=PWSummarize(dir, num)
  catch
    disp('shiznit');
    continue
  end  
  plot(data(:, 1), data(:,4)/duration, draw);
  if m== 1
    hold on
  end
end
hold off
xlabel('Number of senders');
ylabel('Total received packets/second');
legend(l,4)
cd(basedir);
axis([1 num 0 ((max(data(:,4)))/duration +1) ])
set(gca, 'XTick', 1:num);
print(f, '-depsc2', 'pps.eps');
