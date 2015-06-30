% Script to test whether my variant Floyd-Warshall Algorithm works

tic;
testSize = 100;
D = SN.linkP(1:testSize,1:testSize);
%% !!Test regular Floyd Warshall
%%flipZero = (D == 0);
%%D = D + flipZero*100;
P = (D > 0) - eye(size(D));
P = diag(1:testSize) * P;
for k = 1:testSize
  for i = 1:testSize
    for j = 1:testSize
%%% !!To prevent numberical roundoff errors
%%%      newVal = floor(D(i,k)*D(k,j)*1000)/1000;
%%%      [D(i,j), swap] = max([D(i,j) newVal]);
      [D(i,j), swap] = max([D(i,j) D(i,k)*D(k,j)]);
%%     [D(i,j), swap] = min([D(i,j) D(i,k)+D(k,j)]);
      if (swap == 2)
	P(i,j) = P(k,j);
      end % update P
    end
  end
end
toc;
