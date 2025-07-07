%%
% simulate whether adding extra points can improve fitting

close all, clc

SF = 6;%input('\n       >>> SF: ');
subjName = 'RC';%'input('\n       >>> subj name: ');
modeFit = 2;%input('\n       >>> Fitting mode: 1=Binned, 2=BinnedF, 3=F, 4=Raw');
cst_ln_manual = input('\n       >>> Manually add constim stim: ');
ntrialsPerLv  = 40;%input('\n       >>> How many trials per level (40 or 50): ');
iModel = 3; % 1=logistic, 2=Cumulative, 3=Gumbel, 4=Weibull

%%
% SX_analysis_setting
[nLoc_tgt, nNoise] = size(cst_ln_manual);
nConstim = 0; for iLoc=1:nLoc_tgt, for iN=1:nNoise; if ~isnan(cst_ln_manual{iLoc, iN}), nConstim=nConstim+length(cst_ln_manual{iLoc, iN});  end, end, end
fprintf('%d added levels\n', nConstim)

modeFit_all = {'Binned', 'BinnedFiltered', 'Filtered', 'Raw'};
modeFit = modeFit_all{modeFit};

nameFile = sprintf('Data/nNoise7/SF%d/%s/%s_fitPMF_%s.mat', SF, subjName, subjName, modeFit);
load(nameFile, 'cst_log_unik_allC', 'curveX_log', 'nCorr_allC', 'nData_allC', 'estP_allC');

iccc = 5; % all data


switch iModel
    case 1, fit.PF = @PAL_Logistic;
    case 2, fit.PF = @PAL_CumulativeNormal;
    case 3, fit.PF = @PAL_Gumbel;
    case 4, fit.PF = @PAL_Weibull;
end


for iLoc = 1:nLoc_tgt
    for iNoise = 1:nNoise

        %---------------------
        % extract add points
        %---------------------
        cst_add = cst_ln_manual{iLoc, iNoise}/100;
        
        if ~isnan(cst_add)
            
            %---------------------
            % extract old data
            %---------------------
            cst_log_unik_old = cst_log_unik_allC{iccc}{iLoc, iNoise};
            nData_old = nData_allC{iccc}{iLoc, iNoise};
            nCorr_old = nCorr_allC{iccc}{iLoc, iNoise};
            estP_old = getCI(estP_allC{iccc}(:, iLoc, iNoise, iModel, :), 1, 1);
            fprintf('\nLoc#%d N#%d: ', iLoc, iNoise)
            nadd = length(cst_add);
            if iModel~=4, cst_add = log10(cst_add); end
            
            %---------------------
            % look at the plot, manually enter anticipated pC
            %---------------------
            figure('Position', [0 300 1e3 500]), hold on
            
            sim_plotPMF(iModel, {cst_log_unik_old, nCorr_old./nData_old, nData_old, estP_old}, 'k')
            
            for iadd = 1:nadd, xline(cst_add(iadd), 'r'); end
            title(sprintf('L#%d N#%d (Model%d)\nAdded %d levels', iLoc, iNoise, iModel, nadd))
            set(findall(gcf, '-property', 'fontsize'), 'fontsize',20)
            set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',2)

            cst_log_unik_new = cst_log_unik_old;
            nData_new = nData_old;
            nCorr_new = nCorr_old;
            for iadd = 1:nadd
                %---------------------
                % predict pC given the model
                %---------------------
                pC_add = fit.PF(estP_old, cst_add(iadd));
                pC_add = input(sprintf('\n       >>> Current pC is %.0f%%, enter the new pC (eg. .6): ', pC_add*100));
                nData_add = ntrialsPerLv;
                nCorr_add = round(pC_add*nData_add);
                
                %---------------------
                % add cst and pC into the data set
                %---------------------
                cst_log_unik_new = [cst_log_unik_new; cst_add(iadd)];
                nData_new= [nData_new; nData_add];
                nCorr_new= [nCorr_new; nCorr_add];
            end % iadd
            
            %---------------------
            % refit PMF
            %---------------------
            switch iModel
                case 1, fit.PF = @PAL_Logistic;
                case 2, fit.PF = @PAL_CumulativeNormal;
                case 3, fit.PF = @PAL_Gumbel;
                case 4, fit.PF = @PAL_Weibull;
            end
            
            % adjust the format of cst (linear/log)
            searchGrid = fit.searchGrid;
            
            % estimate parameters
            [estP_new] = PAL_PFML_Fit(cst_log_unik_new', nCorr_new', nData_new', ...
                searchGrid, fit.paramsFree, fit.PF,'SearchOptions',fit.options,'LapseLimits',fit.lapseLimits,'GuessLimits',fit.guessLimits);
           
            %---------------------
            % evaluate
            %---------------------
            figure('Position', [0 300 1e3 500]), hold on
            
            sim_plotPMF(iModel, {cst_log_unik_old, nCorr_old./nData_old, nData_old, estP_old}, 'k')
            sim_plotPMF(iModel, {cst_log_unik_new, nCorr_new./nData_new, nData_new, estP_new'}, 'r')
            
            for iadd = 1:nadd, xline(cst_add(iadd), 'r'); end
            title(sprintf('L#%d N#%d (Model%d)\nAdded %d levels', iLoc, iNoise, iModel, nadd))
            set(findall(gcf, '-property', 'fontsize'), 'fontsize',20)
            set(findall(gcf, '-property', 'LineWidth'), 'LineWidth',2)
            fprintf('\n       >>> Press any key to continue'), pause
            close all
        end % ~isnan
    end % iNoise
end % iLoc

fprintf(' \n\nDONE\n\n')

%% function
function sim_plotPMF(iModel, data, color_)

% data1: {cst_log_unik1, pC1, estP1}
% data2: {cst_log_unik2, pC2, estP2}

switch iModel
    case 1, fit.PF = @PAL_Logistic;
    case 2, fit.PF = @PAL_CumulativeNormal;
    case 3, fit.PF = @PAL_Gumbel;
    case 4, fit.PF = @PAL_Weibull;
end

curveX = linspace(-3, 2, 1e4);
if iModel == 4, curveX = 10.^curveX; end

cst_log_unik = data{1};
pC = data{2};
nData = data{3};
estP = data{4};


%%% plot pC as a fxn of log cst

for icst_unik = 1: length(cst_log_unik)
    plot(cst_log_unik(icst_unik), pC(icst_unik), ['o', color_],'MarkerSize',1+round(nData(icst_unik))/3,'Linewidth',1, 'HandleVisibility', 'off');
end

%%% plot PMF and extract PSE
pC_pred = fit.PF(estP, curveX);
plot(curveX, pC_pred, [ '-', color_]) % do NOT change curveX to X!

%%%
xticks_log = -2.5:.1:0;
yticks([0, .5,  .75, .79, .82, 1])
yticks(.5:.1:1)

xlim(xticks_log([1,end]))
xticks(xticks_log), xtickangle(90)
xticklabels(round(10.^xticks_log*100, 1))
ylim([0, 1])


yline(.5, 'color', ones(1,3)*.5);
set(gca, 'XGrid', 'on', 'YGrid', 'on') % grid on

%CHANGE BACK AFTER PLOTTING PILOT DATA
% legend(legends_models, 'Location', 'south', 'NumColumns', 2)

end