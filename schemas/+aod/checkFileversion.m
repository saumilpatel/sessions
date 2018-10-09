
function oldversion=checkFileVersion(fn)

oldversion = false ;
try
    version = h5readatt(fn,'/','Version') ;
    if (version==2)
        oldversion = false ;
        % motion data are in the new 3d format
    else
        br = aodReader(fn, 'Motion') ;
        sz = size(br.motionCoordinates) ;
        if rem(nthroot(sz(1),3),1)==0 % a way to handle files older than version 2 where a volume with cubic dimension was collected
            oldversion = false ;
        end
    end
catch
end
