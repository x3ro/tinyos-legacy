% For outputting D to test Floyd-Warshall Algorithm
D = SN.linkP(1:testSize,1:testSize);

fid = fopen('mat.txt','w');
fprintf(fid,'%d %d\n',testSize,0); % number of edges doesn't matter
for i = 1:testSize
  for j = 1:testSize
    if D(i,j) ~= 0
      fprintf(fid,'%d %d %.3f\n',i-1,j-1,D(i,j));
%       fprintf(fid,'%d %d %d\n',i-1,j-1,floor(1000*D(i,j)));
    end
  end
end
