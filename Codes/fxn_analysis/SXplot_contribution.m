if iTvCModel==2
    %1. Base Model
    mdl_base = fitlm(dataTable, 'Thresh ~ 1');
    
    % 2. Main Effects of Parameters
    mdl_main = fitlm(dataTable, 'Thresh ~ Nadd + Gain');
    
    % 3. Main Effects + Condition Effects
    mdl_conditions = fitlm(dataTable, 'Thresh ~ Nadd + Gain + SF + LocComb');
    
    % 4. Main Effects + Condition Interactions
    mdl_condition_interactions = fitlm(dataTable, 'Thresh ~ Nadd + Gain + SF * LocComb');
    
    % 5. Main Effects + Parameter Interactions
    mdl_param_interactions = fitlm(dataTable, 'Thresh ~ Nadd * Gain');
    
    % 6. Full Model
    mdl_full = fitlm(dataTable, 'Thresh ~ Nadd * Gain + SF * LocComb');
    
    % Compare across Models using BIC
    models = {'Base', mdl_base;
        'ParamMain', mdl_main;
        'ParamMain+CondMain', mdl_conditions;
        'ParamMain+CondInt', mdl_condition_interactions;
        'ParamInt', mdl_param_interactions;
        'Full', mdl_full};
    
    n = height(dataTable); % Sample size
    results = table('Size', [0, 4], ...
        'VariableTypes', {'string', 'double', 'double', 'double'}, ...
        'VariableNames', {'Model', 'NumParams', 'AIC', 'BIC'});
    
    % Calculate AIC and BIC for each model
    for iiIndLoc_s = 1:size(models, 1)
        mdl = models{iiIndLoc_s,2};
        RSS = sum(mdl.Residuals.Raw.^2);
        k = mdl.NumCoefficients; % Number of parameters (including intercept)
        % Calculate AIC and BIC
        AIC = n * log(RSS / n) + 2 * k;
        BIC = n * log(RSS / n) + k * log(n);
        results = [results; {models{iiIndLoc_s,1}, k, AIC, BIC}];
    end
    
    % Display results sorted by AIC
    results = sortrows(results, 'BIC'); fprintf('[BIC] The best model is: %s \n', results.Model(1));
    %     results = sortrows(results, 'AIC'); fprintf('[AIC] The best model is: %s \n', results{1,1});
    
    %%%%%%%%%%%%%
    % analyze the best model
    mdl_opt = models{find(strcmp(models(:, 1), results.Model(1))), 2}; % Retrieve the corresponding model
    
    coeff_table = mdl_opt.Coefficients;
    R2 = mdl_opt.Rsquared.Ordinary;
    adjR2 = mdl_opt.Rsquared.Adjusted;
    
    % Initialize a summary string
    str_summary = sprintf('\nR2=%.2f; Adjusted R2=%.2f', R2, adjR2);
    
    % Add coefficients to the summary
    str_summary = sprintf('%s\n', str_summary);
    for iiIndLoc_s = 1:height(coeff_table)
        term = coeff_table.Properties.RowNames{iiIndLoc_s};
        estimate = coeff_table.Estimate(iiIndLoc_s);
        p = coeff_table.pValue(iiIndLoc_s);
        if p<=0.05, str_summary = sprintf('%s%.2f, p=%.3f [%s]\n', str_summary, estimate, p, term); end
    end
    
    % Display the summary
    fprintf(str_summary);
end