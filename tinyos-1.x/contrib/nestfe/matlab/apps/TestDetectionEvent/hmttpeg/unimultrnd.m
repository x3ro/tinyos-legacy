function sample = unimultrnd(N)
% UNIMULTRND(N) Generates a uniform multinomial random number
%   N - number of possible values

rnd = rand(1);
for n=1:N
    if rnd < n/N
        sample = n;
        break;
    end
end