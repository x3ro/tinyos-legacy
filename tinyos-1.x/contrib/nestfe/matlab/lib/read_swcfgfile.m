function sw = read_swcfgfile(cfgfile)

% Copyright (c) 2005 Songhwai Oh

sw.N = 0;
sw.id =[];
sw.name = [];
sw.pos = [];

fid = fopen(cfgfile,'r');
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    if isempty(regexp(tline,'^\s*\#'))
        spaces = zeros(1,length(tline));
        wordstarts = [];
        wordends = [];
        for n=1:length(tline)
            if ~isempty(regexp(tline(n),'\s'))
                spaces(n) = 1;
            end
            if (n==1 & spaces(n)==0) | (spaces(n-1)==1 & spaces(n)==0)
                wordstarts = [wordstarts, n];
            end
            if (n>1 & spaces(n-1)==0 & spaces(n)==1) 
                wordends = [wordends, n-1];
            end
            if (n==length(tline) & spaces(n)==0)
                wordends = [wordends, n];
            end
        end
        if ~isempty(wordstarts) & ~isempty(wordends)
            firstword = tline(wordstarts(1):wordends(1));
            if strcmp(firstword,'mote')
                if length(wordstarts)<5 | length(wordends)<5
                    error(['Incorrect mote information in ' cfgfile '.\n\tLINE: ' tline]);
                end
                % get mote information
                sw.N = sw.N + 1;
                sw.id(sw.N) = sscanf(tline(wordstarts(2):wordends(2)),'%d');
                sw.name{sw.N} = tline(wordstarts(3):wordends(3));
                xpos = sscanf(tline(wordstarts(4):wordends(4)),'%f');
                ypos = sscanf(tline(wordstarts(5):wordends(5)),'%f');
                sw.pos(sw.N,:) = [xpos,ypos];
                %fprintf('ID:%d NAME:%s POS=[%f %f]\n',sw.id(sw.N),sw.name{sw.N},sw.pos(sw.N,:));
            end
        end
    else
        % comment
    end
end
fclose(fid);
