%----------------%
SX_fitTvC_setting
%----------------%
clc
text_locType = 'combLoc';
switch str_SF, case 'SF456', SF_load_all = [4, 5, 6]; case 'SF46', SF_load_all = [4, 6]; end
iNoise_thresh = 1; % 1=the threshold at no noise

% 1{'Fov'}    2{'ecc4'}    3{'ecc8'}
% 4{'HM4'}    5{'VM4'}    6{'LVM4'}    7{'UVM4'}
% 8{'HM8'}    9{'VM8'}   10{'LVM8'}    11{'UVM8'}

% Load the optimal model
% load(sprintf('IndCand_GroupBest_all4_SF%s.mat', str_SF), 'IndCand_GroupBest_all4')

for iTvCModel = 2%1:nTvC

    switch iTvCModel
        case 1 % LAM
            y_ticks = ticks_LAM; y_ticklabels = ticklabels_LAM; namesLF = namesLF_LAM; namesLF_Labels = namesLF_Labels_LAM;
            iParams_all = 1:2; str_sgtitle = namesTvCModel{iTvCModel};

        case 2 % PTM
            str_sgtitle = sprintf('%s %s', namesTvCModel{iTvCModel}, nameModel);
            switch nameModel
                case 'NoNmul', y_ticks = ticks_PTM(2:4); y_ticklabels = ticklabels_PTM(2:4); iParams_all = 1:3; namesLF = namesLF_PTM(2:4); namesLF_Labels = namesLF_PTM(2:4);
                case 'FullModel', y_ticks = ticks_PTM; y_ticklabels = ticklabels_PTM;iParams_all = 1:4; namesLF = namesLF_PTM; namesLF_Labels = namesLF_PTM;
            end
    end
    nParams = length(iParams_all);

    % Loop through each error type
    for iErrorType = 1%1:nErrorType; % namesErrorType = {'ErrLogCst'}    {'ErrLnCst'}    {'ErrLnEg'}

        % Loop through each location group
        for iiIndLoc_s = 1:nIndLoc_s
            
            %--------------------%
            fxn_createLMMtable
            %--------------------%

            %% 0. TvC and Fitting
            if flag_plot_TvC
                SXplot_TvC_forPRE3
            end

            %% 1. Main effect of SF and Loc on each parameter (plot IVs)
            if flag_plot_ANOVA
                %--------------------------------------------------------------------------------
                SXplot_params_SFxLoc
                %--------------------------------------------------------------------------------
            end % flag_plot_ANOVA

            %% 2. Corr between asymmetries
            if flag_plot_CorrAsym
                SXplot_corrAsym_forPRE3
            end % if flag_plot_CorrAsym

        end % iiIndLoc_s

        close all, clc

    end % iErrorType
end % iTvC
