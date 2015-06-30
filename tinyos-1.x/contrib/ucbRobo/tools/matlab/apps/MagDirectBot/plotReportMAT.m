function plotReportMAT(R)
% Plots the data from the report matrix after a full experiment.
[M,N] = size(R);
figure; clf
axis([-1 9 -1 5]);
hold on
for n1=0:8
    for n2=0:4
        plot(n1,n2,'k.');
    end
end
for n=1:N
    x = floor(mod(R(1,n),100)/10);
    y = mod(mod(R(1,n),100),10);
    plot(x,y,'ro','MarkerSize',15);
    text(x+.1,y,sprintf('%d',R(M,n)));
end
