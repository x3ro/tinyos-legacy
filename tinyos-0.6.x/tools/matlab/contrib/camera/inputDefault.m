function value = inputDefault(inputString, defaultValue)
%inputDefault -- prompt the user for input and provide a default value
%  value = inputDefualt(inputString, defaultValue) displays the message inputString
%  along with the defaultValue to the user and prompts for user input.  If
%  a return is pressed the returned value is defaultValue, otherwise it is
%  the user input.

% Shawn Schaffert, 2002-06-27

value = input([inputString ' (default ' num2str(defaultValue) '):']);
if isempty(value)
    value = defaultValue;
end
