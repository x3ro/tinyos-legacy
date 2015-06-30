function summary = PWSummarize(basedir, num)
% num participating senders
% num packets sent
% num bytes sent
% num packest received
% num bytes received


for i= 1:num
  cd(basedir);
  data = load (sprintf('Experiment_%d.txt', i));
  summary(i,:) = [i ...
                  sum(data(:,2)) ...
                  sum(data(:,3)) ...
                  sum(data(:,4)) ...
                  sum(data(:,5)) ];
end
  
    
    
