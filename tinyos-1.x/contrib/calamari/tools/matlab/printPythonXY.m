function printPythonXY(testbed)
%function printPythonXY(testbed)
%
%this prints the xy coords of the testbed in a python readable matrix;

fprintf('xy = [')
for i=1:length(testbed.xy)
  if i>1 fprintf(','); end
  if i<=26
    fprintf('[''%s'', %2.2f, %2.2f]',i+64, testbed.xy(i,1), testbed.xy(i,2))
  else
    fprintf('[''%s%s'', %2.2f, %2.2f]',i-26+64,i-26+64, testbed.xy(i,1), testbed.xy(i,2))
  end
end
fprintf(']\n\n')
