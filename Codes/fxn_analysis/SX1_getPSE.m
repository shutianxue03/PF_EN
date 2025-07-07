
nameFile_PSE = sprintf('Data_OOD/%s/%s_B%d.mat',cond, subjName, nB);
dir_PSE = dir(nameFile_PSE);

if isempty(dir_PSE)
    %% load data
    
    nameFile_ccc = sprintf('Data_OOD/%s/%s_ccc.mat', cond, subjName);
    dir_ccc = dir(nameFile_ccc);
    if isempty(dir_ccc)
        ccc = []; % iLoc // iNoise// Gabor cst // correctness
        fprintf('%s: Extracting CCC data... ', subjName)
        nameFile_data = sprintf('Data/%s/%s/PF_LAM_%s_%s_b*.mat', cond, subjName, cond, subjName); % SX
        dir_allFiles = dir(nameFile_data);
        nFile = length(dir_allFiles);
        for ifile = 1:nFile
            load(dir_allFiles(ifile).name)
            if flag_ABdata, iblock_start = (ifile-1).*nBlocksPerSess+1; iblock_end = iblock_start+nBlocksPerSess-1;
            else, iblock_start = 1; iblock_end = nBlocksPerSess;
            end
            for iblock =iblock_start : iblock_end
                ccc = [ccc;...
                    real_sequence(iblock).targetLoc(real_sequence(iblock).trialDone==1)'...
                    real_sequence(iblock).extNoiseLvl(real_sequence(iblock).trialDone==1)'...
                    real_sequence(iblock).scontrast(real_sequence(iblock).trialDone==1)'...
                    real_sequence(iblock).iscor(real_sequence(iblock).trialDone==1)'];
            end % for iblock
            fprintf('=')
        end % for ifile
        save(nameFile_ccc, 'ccc')
        fprintf('\nCCC file created (%d trials)\n', size(ccc, 1))
    else
        load(nameFile_ccc, 'ccc')
        fprintf('%s: CCC file loaded\n', subjName)
    end
    
    %% empty containers
    PMF_pred = cell(nLoc, nNoise);
    cst_all = PMF_pred; % unique contrasts (after rounding)
    nData_all = PMF_pred; % number of data points at that cst
    nCorr_all = PMF_pred; % number of correct responses at that cst
    pC_all = PMF_pred; % pC
    PSE_allB = nan(nB, nLoc, nNoise, length(perfPSE_all));
    % separate gabor type to categorize correctness in my study!!
    
    %% estimated PSE
    posInd_all = 1:nLoc;
    for iNoise = 1:nNoise
        for iLoc = 1:nLoc
            % extract data
            iLoc_all = ccc(:,1);
            iNoise_all = ccc(:,2);
            icor_all = ccc(:,4);
            % round cst
            ccc(iLoc_all==iLoc & iNoise_all==iNoise, 3) = round(ccc(iLoc_all==iLoc & iNoise_all==iNoise,3).*100)./100;
            
            % get unique cst
            cst_unik = unique(ccc(iLoc_all==iLoc & iNoise_all==iNoise, 3));
            n_cstUnik = length(cst_unik);
            nData_unik = nan(n_cstUnik, 1);
            nCorr_unik = nData_unik;
            pC_unik = nData_unik;
            
            icst_all = ccc(:,3); % do NOT move upward, as it has to be rounded first
            
            for icst_unik = 1:n_cstUnik
                indTrial = (iLoc_all==posInd_all(iLoc) & (iNoise_all==iNoise) & (icst_all>cst_unik(icst_unik)-0.001) & (icst_all<=cst_unik(icst_unik)+0.001));
                nData_unik(icst_unik) = nansum(indTrial==1);
                nCorr_unik(icst_unik) = nansum(icor_all(indTrial));
                pC_unik(icst_unik) = nCorr_unik(icst_unik)./nData_unik(icst_unik);
            end
            cst_all{iLoc, iNoise} = cst_unik;
            nData_all{iLoc, iNoise} = nData_unik;
            nCorr_all{iLoc, iNoise} = nCorr_unik;
            pC_all{iLoc, iNoise} = pC_unik;
            
            % fit PMF
            [est_paramsPMF, LL, exitflag] = PAL_PFML_Fit(cst_unik, nCorr_unik, nData_unik, fit.searchGrid, fit.paramsFree, fit.PF,'SearchOptions',fit.options,'lapseLimits',fit.lapseLimits,'lapseLimits',fit.guessLimits);
            PMF_pred{iLoc,iNoise} = fit.PF(est_paramsPMF, fit.curveX);
            
            for iperf = 1:length(perfPSE_all)
                perfPSE = perfPSE_all(iperf)/100;
                % create params for bootstrapping
                if nB>1
                    [SD, paramsSim, LLSim, converged] = PAL_PFML_BootstrapParametric((cst_unik'), nData_unik, est_paramsPMF, fit.paramsFreeB, nB, fit.PF);
                    for iB = 1:nB
                        PSE_temp = fit.PF(paramsSim(iB, :), perfPSE, 'Inverse');
                        % limit thresholds between 0.005 and 1
                        if PSE_temp > 1, PSE_temp = 1;
                        elseif PSE_temp <0.005, PSE_temp = 0.005;
                        end
                        PSE_allB(iB, iLoc, iNoise, iperf) = PSE_temp;
                    end % for iB=1:nB
                else
                    PSE_allB(1, iLoc, iNoise, iperf) = fit.PF(est_paramsPMF, perfPSE, 'Inverse');
                end
            end % for iLoc
        end % for iperf
        fprintf('Noise #%d/%d DONE.\n', iNoise, nNoise)
    end % for iNoise
    
    %% save
    clear i*_all
    save(nameFile_PSE,  'PMF_pred', '*_all', '*_allB')
    fprintf('%s: PSE data saved\n', subjName)
end

