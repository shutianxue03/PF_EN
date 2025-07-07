
flag_plot=1;
% Fitting LAM/PTM to group averaged data (ie., thresh)
fprintf('\n\nFitting LAM & PTM to group-averaged data...\n')

if ~flag_combineMode
    
    % convert to log cst, then take ave, then convert back to energy
    thresh_log_aveSubj = squeeze(nanmean(thresh_log_allSubj,1));
    threshEnergy_aveSubj = (10.^thresh_log_aveSubj).^2; % threshold energy
    nData_perLoc_aveSubj = squeeze(mean(nData_perLoc_allSubj, 1));
    
    for iLoc = 1:nLoc
        fprintf('     L%d...', iLoc)
        
        %%%%% LAM %%%%%
        for iPerf = 1:nPerf
            %--------------------------------------------------------------------------%
            [est_LAM, ~, RSS, R2]= fitTvC_LAM(noiseEnergy_true, squeeze(threshEnergy_aveSubj(iLoc, :, iPerf)), flag_weightedFitting, nData_perLoc_aveSubj(iLoc, :), flag_plot);
            %--------------------------------------------------------------------------%
            est_LAM_aveSubj(iLoc, iPerf, :) = [log10(sqrt(est_LAM(2))), D_ideal./est_LAM(1)*100];
            R2_LAM_aveSubj(iLoc, iPerf) = R2;
            TvC_energy_LAM_aveSubj(iLoc, iPerf, :) = fxn_LAM(est_LAM, noiseEnergy_intp_true);
        end % iperf
        
        %%%%% PTM %%%%%
        %--------------------------------------------------------------------------%
        [est_PTM, ~, RSS, R2]= fitTvC_PTM(noiseEnergy_true, squeeze(threshEnergy_aveSubj(iLoc, :, :)), dprimes, flag_weightedFitting, nData_perLoc_aveSubj(iLoc, :), flag_plot);
        %--------------------------------------------------------------------------%
        est_PTM_aveSubj(iLoc, :) = est_PTM;
        for iPerf = 1:nPerf
            TvC_energy_PTM_aveSubj(iLoc, iPerf, :) = fxn_PTM(est_PTM, noiseEnergy_intp_true, dprimes(iPerf));
            R2_PTM_aveSubj(iLoc, iPerf) = R2(iPerf);
        end
%         fprintf('DONE\n')
    end % iLoc
    
end
