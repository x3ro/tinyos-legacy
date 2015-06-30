function pegbodies( bodyname )

global Motes;

nmotes = 0;
nbodies = 0;
nreports = 0;
if isstruct( Motes )
    for name = sort( fieldnames( Motes )' )
        name = name{1};
        if name(1) == 'x'
            nmotes = nmotes + 1;
            mote = getfield( Motes, name );
            if isfield( mote, bodyname )
                nbodies = nbodies + 1;
                body = getfield( mote, bodyname );
                if isfield( body, 'STRING' )
                    nreports = nreports + 1;
                    fprintf( '0%s: %s\n', name(1:end), body.STRING );
                end
            else
                fprintf( '0%s ... no %s body\n', name(1:end), bodyname );
            end
        end
    end
end
fprintf( '  %d motes, %d %s bodies, %d reports printed\n', nmotes, nbodies, bodyname, nreports );
