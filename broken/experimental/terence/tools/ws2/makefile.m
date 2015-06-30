function makefile(option)
cd C:\cygwin\home\terence\projects\broken\experimental\terence\tools\ws2
if strcmpi(option, 'cc')
    !C:\cygwin\bin\bash compile.sh cc
    cd bin
    %mcc -m -O all ws.m broadcast.m initial_default.m initial_position.m prob_radio.m prob_radio_ack.m collect_data.m mrp.m mrp_shortest_path.m shortest_path.m default_time_series_stat.m
    cd ..
elseif strcmpi(option, 'cg')
    !C:\cygwin\bin\bash compile.sh cg
elseif strcmpi(option, 'rcg')
    !C:\cygwin\bin\bash compile.sh cg
    ws;
end


