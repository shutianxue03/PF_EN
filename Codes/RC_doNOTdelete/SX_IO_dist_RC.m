clc
close all


nTrials = 1e2;
nBins = 20;
cst_template = 1;
cst_all = 10.^linspace(-3, 0, 15); nCST = length(cst_all);
noiseSD_all = linspace(0, 1, 10); nNoiseSD = length(noiseSD_all);
SF = 6;

visual.bgColor = .5;
visual.ppd = 32;
params.gaborsiz = 3.3.*visual.ppd;
params.gaborsiz = round(params.gaborsiz/2)*2;
params.gaborenvelopedev = 1.*visual.ppd;
params.gaborangle = [135 45];
params.gaborfrequency = SF/visual.ppd;
% params.gaborexc = round(params.gaborexc);

%% create the template
gaborPhase = 0;
template_L = CreateGabor(params.gaborsiz,params.gaborenvelopedev,135,params.gaborfrequency,...
    gaborPhase,2.*visual.bgColor.*cst_template);
template_R = CreateGabor(params.gaborsiz,params.gaborenvelopedev,45,params.gaborfrequency,...
    gaborPhase,2.*visual.bgColor.*cst_template);
template_diff =  template_L(:)-template_R(:);

figure, hold on

sigma_sim_all = nan(1, nNoiseSD);
sigma_theo_all = sigma_sim_all;

for iNoise = 1:nNoiseSD
    
    noiseSD = noiseSD_all(iNoise);
    sigma_theo = sqrt(sumsqr(template_diff))*noiseSD*visual.bgColor; % only depends on noiseSD
    sigma_theo_all(iNoise) = sigma_theo;
    
    pC_sim_all = nan(nCST, 2);
    pC_theo_all = nan(1, nCST);
    mu_sim_all =  nan(1, nCST);
    mu_theo_all =  mu_sim_all;
    
    %     figure, hold on
    for iCST = 1:nCST
        
        cst = cst_all(iCST);
        
        internalVar_L_allT = nan(1, nTrials);
        correctness_L_allT = internalVar_L_allT;
        internalVar_R_allT = internalVar_L_allT;
        correctness_R_allT = internalVar_L_allT;
        
        %         for ORI = [1,2]
        ORI=2;
        
        gabor = CreateGabor(params.gaborsiz,params.gaborenvelopedev,params.gaborangle(ORI),params.gaborfrequency,...
            gaborPhase, 2.*visual.bgColor.*cst);
        
        for iTrial = 1:nTrials
            % create dynamic white noise sequence
            noiseImg = randn(params.gaborsiz, params.gaborsiz).*noiseSD.*visual.bgColor; %Make the noise and adjust its contrast
            noiseImg = noiseImg+gabor;
            
            % make texture
%             aperture = CreateCircularAperture(params.gaborsiz,round(.25.*visual.ppd));
%             stimImg = min(max(noiseImg.*aperture + visual.bgColor,0),1);
%             stimImg_L = min(max(template_L.*aperture + visual.bgColor,0),1);
%             stimImg_R = min(max(template_R.*aperture + visual.bgColor,0),1);
            
            stimImg = noiseImg;%min(max(noiseImg.*aperture + visual.bgColor,0),1);
            stimImg_L = template_L;%min(max(gabor1.*aperture + visual.bgColor,0),1);
            stimImg_R = template_R;%min(max(gabor2.*aperture + visual.bgColor,0),1);
            
            %---------------------------------------------------------------------------
            internalVar = sum(stimImg(:).*template_diff, 'all');
            
            if ORI==1 % Left
                resp = internalVar>0;
            else
                resp = internalVar<0;
            end
            if resp==1, correctness=1; else, correctness=0; end
            %---------------------------------------------------------------------------
            
            if ORI==1
                internalVar_L_allT(iTrial) = internalVar;
                correctness_L_allT(iTrial) = correctness;
            else
                internalVar_R_allT(iTrial) = internalVar;
                correctness_R_allT(iTrial) = correctness;
            end
        end %iTrial
        
        
        %             histogram(internalVar_L_allT, nBins, 'FaceColor', 'r','FaceAlpha',.3, 'Normalization', 'probability')
        %             histogram(internalVar_R_allT, nBins, 'FaceColor', 'b','FaceAlpha',.3,'Normalization', 'probability')
        %             xlim([-200, 200])
        %             title(sprintf('CST=%.0f%%, Noise SD=%.1f\nMean=%.1f, %.1f // SD = %.1f, %.1f\npC = %.1f%% %.1f%%', ...
        %                 cst*100, params.extNoiseLvl(iNoise), ...
        %                 median(-internalVar_L_allT), mean(internalVar_R_allT), std(-internalVar_L_allT), std(internalVar_R_allT), ...
        %                 mean(correctness_L_allT)*100, mean(correctness_R_allT)*100))
        
        mu_sim_all(iCST) = median(internalVar_L_allT);
        sigma_sim_all(iNoise) = std(internalVar_L_allT);
        pC_sim_all(iCST, :) = [mean(correctness_L_allT), mean(correctness_R_allT)];
        
        % calculate theoretical pC
        mu_theo = sum(gabor(:) .*template_diff);
        mu_theo_all(iCST) = mu_theo;
        
        if ORI==1
            pC_theo_all(iCST) = 1-normcdf(0, mu_theo, sigma_theo);
        else
            pC_theo_all(iCST) = normcdf(0, mu_theo, sigma_theo);
        end
        
        %     pause
    end % iCST
    
    %%
    %     figure, plot(cst_all, real(sqrt(med_sim_all)), 'o'), xlabel('CST'), ylabel('sqrt(Simulated mu)')
    %     figure, hold on, plot(log10(cst_all), log10(sd_sim_all), 'o'), xlabel('Log CST'), ylabel('log Simulated sd')
    %     figure, hold on, plot(cst_all, sd_sim_all, 'o'), xlabel('Log CST'), ylabel('Simulated sd')%, plot([-2.3, 0], [-2.3, 0], '-')
    
    %%
    
    plot(log10(cst_all), pC_sim_all(:, 1), '-ro')
    plot(log10(cst_all), pC_sim_all(:, 2), '-bo')
    plot(log10(cst_all), pC_theo_all, 'k-', 'LineWidth', 2)
    xlim([min(log10(cst_all)), max(log10(cst_all))])
    ylim([.45, 1])
    yline(.5, 'k-');
    pause
    
end % iNoise

close all