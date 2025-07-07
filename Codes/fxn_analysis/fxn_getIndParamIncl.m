function indParam_allCand = fxn_getIndParamIncl(nParams_full, iCond_all)

switch nParams_full
    case 2, indParam_allCand = combvec(iCond_all, iCond_all);
    case 3, indParam_allCand = combvec(iCond_all, iCond_all, iCond_all);
    case 4, indParam_allCand = combvec(iCond_all, iCond_all, iCond_all, iCond_all);
end

indParam_allCand = indParam_allCand';

