function [pred_log, params, indParam, GoF, str_legends] = fxn_spitPred(iTvCModel, iCand, GoF_raw, R2_raw, params_allCand, indParam_allCand, indParamExist, noiseEnergy, dprime, SF_fit, slope_ideal, str_legends)

params = params_allCand(iCand, :);
switch iTvCModel
    case 1
        %-----------------------------------------------------------------%
        threshEnergy_pred = fxn_LAM(params, noiseEnergy);
        %-----------------------------------------------------------------%
    case 2
        %-----------------------------------------------------------------%
        threshEnergy_pred = fxn_PTM(indParamExist, params, noiseEnergy, dprime, SF_fit);
        %-----------------------------------------------------------------%
end
pred_log = log10(sqrt(threshEnergy_pred));
indParam = indParam_allCand(iCand, :);

if iTvCModel==1, params(1) = slope_ideal/params(1)*100; params(2) = sqrt(params(2)); end
GoF = GoF_raw(iCand);
R2 = R2_raw(iCand);
str_legends = [str_legends, {sprintf('%.2f [%s]', R2, strjoin(arrayfun(@num2str, round(params, 2), 'UniformOutput', false), ', '))}];

end