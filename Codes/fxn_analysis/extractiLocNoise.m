
%% define index reference and index in use
if nLocSingle==5 % fovea + ecc 4
    ind_LocNoise_ref = ind_LocNoise5;
    ind_LocNoise_inUse = ind_LocNoise5_inUse;
    if flag_combineEcc4 && any(strcmp(subjName, subjList_AB)), ind_LocNoise_inUse = ind_LocNoise9_inUse; end
    if flag_combineEcc4 && any(strcmp(subjName, subjList_JA)), ind_LocNoise_inUse = ind_LocNoise9_inUse; end
else % fovea + ecc 4 and 8
    ind_LocNoise_ref = ind_LocNoise9;
    ind_LocNoise_inUse = ind_LocNoise9_inUse;
end

%% index of noise 
iNoise = ind_LocNoise_ref(2, iLocNoise_); % iLocNoise_ is based on nLocSingle x nNoise structure

%% extract index of loc and noise of the current iteration
if flag_collapseHM % assign the entry of collapsed HM to Left and Right
    if nLocSingle==5 % fovea + ecc 4
        if find(ind_LocNoise_ref(1, iLocNoise_) == 1:2:5)
            iLocNoise = find(ind_LocNoise_inUse(1, :) == ind_LocNoise_ref(1, iLocNoise_) & ind_LocNoise_inUse(2, :) == iNoise);
        elseif find(ind_LocNoise_ref(1, iLocNoise_) == [2,4])
            iLocNoise = find(ind_LocNoise_inUse(1, :) == 6 & ind_LocNoise_inUse(2, :) == iNoise);
        end
        
    else % fovea + ecc 4 and 8
        if find(ind_LocNoise_ref(1, iLocNoise_) == 1:2:9)
            iLocNoise = find(ind_LocNoise_inUse(1, :) == ind_LocNoise_ref(1, iLocNoise_) & ind_LocNoise_inUse(2, :) == iNoise);
        elseif find(ind_LocNoise_ref(1, iLocNoise_) == [2,4])
            iLocNoise = find(ind_LocNoise_inUse(1, :) == 10 & ind_LocNoise_inUse(2, :) == iNoise);
        elseif find(ind_LocNoise_ref(1, iLocNoise_) == [6,8])
            iLocNoise = find(ind_LocNoise_inUse(1, :) == 11 & ind_LocNoise_inUse(2, :) == iNoise);
        end
        
        if flag_combineEcc4
            if find(ind_LocNoise_ref(1, iLocNoise_) == 1:2:5)
                iLocNoise = find(ind_LocNoise_inUse(1, :) == ind_LocNoise_ref(1, iLocNoise_) & ind_LocNoise_inUse(2, :) == iNoise);
            elseif find(ind_LocNoise_ref(1, iLocNoise_) == [2,4])
                if any(strcmp(subjName, subjList_AB)), ind = 10;
                elseif any(strcmp(subjName, subjList_SX)), ind = 6;
                elseif any(strcmp(subjName, subjList_JA)), ind = 10;
                end
                iLocNoise = find(ind_LocNoise_inUse(1, :) == ind & ind_LocNoise_inUse(2, :) == iNoise);
            end
        end
    end
    
else % NOT collapse
    if nLocSingle==5 % fovea + ecc 4
        if find(ind_LocNoise_ref(1, iLocNoise_) == 1:5)
            iLocNoise = find(ind_LocNoise_inUse(1, :) == ind_LocNoise_ref(1, iLocNoise_) & ind_LocNoise_inUse(2, :) == iNoise);
        end
    else % fovea + ecc 4 and 8
        if find(ind_LocNoise_ref(1, iLocNoise_) == 1:9)
            iLocNoise = find(ind_LocNoise_inUse(1, :) == ind_LocNoise_ref(1, iLocNoise_) & ind_LocNoise_inUse(2, :) == iNoise);
        end
    end
end

iLoc_inUse = ind_LocNoise_inUse(1, iLocNoise);
iLoc_record = ind_LocNoise_ref(1, iLocNoise_);
assert(iNoise == ind_LocNoise_inUse(2, iLocNoise))
