function [RSquare,RSS,sse,paramsfit,paramsfit1,paramsfit2,paramsfit3] = PTM3(whichSFcond,data,varargin)
% COMPARES ACROSS SFs USING ALL GROUPS

%% Perceptual template model for contrast threshold data.
% Instruction for input parameters

% data:  data should be a conditions * noise level matrix which contains
% all contrast threshold data between (0,1).If it's not contrast threshold
% data, please normlize data to range (0,1);
% Please range data maxtrix like [baseline_70%;expCondition_70%;baseline_79%;expCondition_79%]
% baseline_70% refers contrast thresholds at baseline condition at 70% performance level
% similarly, it can model perceptual learning as [pre_70%;post_70%;pre_79%;post_79%];

% varargin specify which parameters you want to change. You can input like
% PTM(data,'Aa'), means you specify the model that assumes only internal
% noise change between baseline and experiment condition.You can input
% like PTM(data,'Am','Ae','Aa') to derive full model which assumes all
% three parameters change. The default will be model with no parameters
% change, namely the least model.

%%

if (whichSFcond==1|whichSFcond==2)
    nSF    = 2;
    data11 = data([1 7],:);
    data21 = data([2 8],:);
    data31 = data([3 9],:);
    data12 = data([4 10],:);
    data22 = data([5 11],:);
    data32 = data([6 12],:);
else
    nSF    = 1;
    data11 = data(1,:);
    data21 = data(2,:);
    data31 = data(3,:);
    data12 = data(4,:);
    data22 = data(5,:);
    data32 = data(6,:);
end

p.modelOption=cell(3,1);
%sort input, we create p.modelOption if p.modelOption = {[],[],'Aa'}, this
%refers to Aa change model
if ~isempty(varargin)
    for i=1:length(varargin)
        switch varargin{i}
            case 'Am'
                p.modelOption{1} ='Am';
            case 'Ae'
                p.modelOption{2} ='Ae';
            case 'Aa'
                p.modelOption{3} ='Aa';
                
        end
    end
end
modelName=[];
modelName = [p.modelOption{1} p.modelOption{2} p.modelOption{3}]

if length(modelName)=='AmAeAa'
    modelName = 'full'
elseif isempty(modelName)
    modelName = 'null'
else
    modelName = modelName;
end

p.d     = [1.089 1.634]';   %d' for 70% and 79%
% p.Ne  = [0 0.003 0.0061 0.0124 0.0251 0.051 0.103 0.21]';
p.Ne    = [0    0.0210    0.0410    0.0830    0.1240    0.1650    0.2480    0.3300];


if (whichSFcond==1|whichSFcond==2)

%define initial parameter
params0     = [1; 2];
params0     = [params0; ones(nSF,1)*0.01; ones(nSF,1)*0.01; 1.*ones(length(varargin)*10,1)];
paramsLower = repmat(0.0001,length(params0),1);
paramsUpper = [10; 10; repmat(.8,nSF,1); repmat(0.6119,nSF,1); repmat(5,length(varargin)*10,1)];

%fit PTM
options = optimset('MaxFunEvals',1e20,'MaxIter',1e20,'TolX',1e-20,'TolFun',1e-20);
    %Then do fitting
    [params_temp sse] = fmincon(@(params) costfun3_fmincon_perSF2(params,data,p),params0,[],[],[],[],paramsLower,paramsUpper,[],options);
    paramsfit         = ones(18,1);
    paramsfit(1:6)    = params_temp(1:6);
    count = 7;
    %Determine parameters
    for i=1:length(p.modelOption)
        if isempty(p.modelOption{i})
            continue;
        else
            switch p.modelOption{i}
                case 'Am'
                    paramsfit(7:10) = params_temp(count:count+3);
                    count = count+4;
                case 'Ae'
                    paramsfit(11:14) = params_temp(count:count+3);
                    count = count+4;
                case 'Aa'
                    paramsfit(15:18) = params_temp(count:count+3);
                    count = count+4;
            end
        end
    end
    
    % show PTM parameters
    fprintf(['\n\n#########################################################################'...
        '\n#########################################################################\n'...
        'The fitted model option is: ', modelName]);
    fprintf(['\n The parameters for fitted model are :' ...
        '\n r:   '          , num2str(paramsfit(1))...
        '\n beta:'          , num2str(paramsfit(2))...
        '\n Na_SF1:  '      , num2str(paramsfit(3))...
        '\n Na_SF2:  '      , num2str(paramsfit(4))...
        '\n Nm_SF1:  '      , num2str(paramsfit(5))...
        '\n Nm_SF2:  '      , num2str(paramsfit(6))...
        '\n\n Am_KCmod_SF1: ', num2str(paramsfit(7)),', refers to ',num2str(paramsfit(7)*100-100),'%% Multiplicative noise than baseline'...
        '\n Am_KCmod_SF2:  ', num2str(paramsfit(8)),', refers to ',num2str(paramsfit(8)*100-100),'%% Multiplicative noise than baseline'...
        '\n\n Am_KCsev_SF1: ', num2str(paramsfit(9)),', refers to ',num2str(paramsfit(9)*100-100),'%% Multiplicative noise than baseline'...
        '\n Am_KCsev_SF2:  ', num2str(paramsfit(10)),', refers to ',num2str(paramsfit(10)*100-100),'%% Multiplicative noise than baseline'...
        '\n\n Ae_KCmod_SF1: ', num2str(paramsfit(11)),', refers to ',num2str(paramsfit(11)*100-100),'%% External noise than baseline'...
        '\n Ae_KCmod_SF2:  ', num2str(paramsfit(12)),', refers to ',num2str(paramsfit(12)*100-100),'%% External noise than baseline'...
        '\n\n Ae_KCsev_SF1: ', num2str(paramsfit(13)),', refers to ',num2str(paramsfit(13)*100-100),'%% External noise than baseline'...
        '\n Ae_KCsev_SF2:  ', num2str(paramsfit(14)),', refers to ',num2str(paramsfit(14)*100-100),'%% External noise than baseline'...
        '\n\n Aa_KCmod_SF1: ', num2str(paramsfit(15)),', refers to ',num2str(paramsfit(15)*100-100),'%% Internal noise than baseline'...
        '\n Aa_KCmod_SF2:  ', num2str(paramsfit(16)),', refers to ',num2str(paramsfit(16)*100-100),'%% Internal noise than baseline'...
        '\n\n Aa_KCsev_SF1: ', num2str(paramsfit(17)),', refers to ',num2str(paramsfit(17)*100-100),'%% Internal noise than baseline'...
        '\n Aa_KCsev_SF2:  ', num2str(paramsfit(18)),', refers to ',num2str(paramsfit(18)*100-100),'%% Internal noise than baseline'...
        '\n\n The fitted model can account for ', num2str((1-sse)*100),'%% variance of data\n'...
        '\n#########################################################################\n'...
        '#########################################################################\n\n']);
    
    %show RSqure for model fitting. Closer to 1, better the fitting.
    RSquare=1-sse;
    
    Nlevels    = p.Ne';
    Nlevels(1) = 0.001;
    axismat    = [0.0001 1.5 0.005 1.5];
    
    predicted_Data = [];
    
    for i = 1:nSF
        paramsfit1(i,:) = [paramsfit(1:2); paramsfit([2+i 4+i]); 1; 1; 1]';
        paramsfit2(i,:) = [paramsfit(1:2); paramsfit([2+i 4+i]); paramsfit([6+i 10+i 14+i])]';
        paramsfit3(i,:) = [paramsfit(1:2); paramsfit([2+i 4+i]); paramsfit([8+i 12+i 16+i])]';
        
        ypredict11(i,:) = exp(predictedcontrast(paramsfit1(i,:),Nlevels', p.d(1)));
        ypredict12(i,:) = exp(predictedcontrast(paramsfit1(i,:),Nlevels', p.d(2)));
        ypredict21(i,:) = exp(predictedcontrast(paramsfit2(i,:),Nlevels', p.d(1)));
        ypredict22(i,:) = exp(predictedcontrast(paramsfit2(i,:),Nlevels', p.d(2)));
        ypredict31(i,:) = exp(predictedcontrast(paramsfit3(i,:),Nlevels', p.d(1)));
        ypredict32(i,:) = exp(predictedcontrast(paramsfit3(i,:),Nlevels', p.d(2)));
        
        predicted_Data = [predicted_Data; ypredict11(i,:); ypredict21(i,:); ypredict31(i,:); ...
            ypredict12(i,:); ypredict22(i,:); ypredict32(i,:)];
    end
    
elseif (whichSFcond==3 | whichSFcond==4)
    params0     = [1; 2];
    params0     = [params0; ones(nSF,1)*0.05; ones(nSF,1)*0.05; 1.*ones(length(varargin)*2,1)];
    paramsLower = repmat(0.0001,length(params0),1);
    %     paramsUpper = [10; 10; repmat(1,nSF,1); repmat(1,nSF,1); repmat(10,length(varargin)*2,1)];
    paramsUpper = [10; 10; repmat(1,nSF,1); repmat(1,nSF,1); repmat(2.5,length(varargin)*2,1)];
    
    % do fitting
    [params_temp sse] = fmincon(@(params) costfun3_fmincon_perSF1(params,data,p),params0,[],[],[],[],paramsLower,paramsUpper,[],options);
    
    paramsfit         = ones(10,1);
    paramsfit(1:4)    = params_temp(1:4);
    count = 5;
    %Determine parameters
    for i=1:length(p.modelOption)
        if isempty(p.modelOption{i})
            continue;
        else
            switch p.modelOption{i}
                case 'Am'
                    paramsfit(5:6) = params_temp(count:count+1);
                    count = count+2;
                case 'Ae'
                    paramsfit(7:8) = params_temp(count:count+1);
                    count = count+2;
                case 'Aa'
                    paramsfit(9:10) = params_temp(count:count+1);
                    count = count+2;
                    
            end
        end
    end
    
    
    % show PTM parameters
    fprintf(['\n\n#########################################################################'...
        '\n#########################################################################\n'...
        'The fitted model option is: ', modelName]);
    fprintf(['\n The parameters for fitted model are :' ...
        '\n r:   '          , num2str(paramsfit(1))...
        '\n beta:'          , num2str(paramsfit(2))...
        '\n Na_SF1:  '      , num2str(paramsfit(3))...
        '\n Nm_SF1:  '      , num2str(paramsfit(4))...
        '\n\n Am_KCmod_SF1: ', num2str(paramsfit(5)),', refers to ',num2str(paramsfit(5)*100-100),'%% Multiplicative noise than baseline'...
        '\n\n Am_KCsev_SF1: ', num2str(paramsfit(6)),', refers to ',num2str(paramsfit(6)*100-100),'%% Multiplicative noise than baseline'...
        '\n\n Ae_KCmod_SF1: ', num2str(paramsfit(7)),', refers to ',num2str(paramsfit(7)*100-100),'%% External noise than baseline'...
        '\n\n Ae_KCsev_SF1: ', num2str(paramsfit(8)),', refers to ',num2str(paramsfit(8)*100-100),'%% External noise than baseline'...
        '\n\n Aa_KCmod_SF1: ', num2str(paramsfit(9)),', refers to ',num2str(paramsfit(9)*100-100),'%% Internal noise than baseline'...
        '\n\n Aa_KCsev_SF1: ', num2str(paramsfit(10)),', refers to ',num2str(paramsfit(10)*100-100),'%% Internal noise than baseline'...
        '\n\n The fitted model can account for ', num2str((1-sse)*100),'%% variance of data\n'...
        '\n#########################################################################\n'...
        '#########################################################################\n\n']);
    
    RSquare=1-sse;
    
    Nlevels    = p.Ne';
    Nlevels(1) = 0.001;
    axismat    = [0.0001 1.5 0.005 1.5];
    
    predicted_Data = [];
    
    for i = 1:nSF
        paramsfit1(i,:) = [paramsfit(1:2); paramsfit([3 4]); 1; 1; 1]';
        paramsfit2(i,:) = [paramsfit(1:2); paramsfit([3 4]); paramsfit([5 7 9])]';
        paramsfit3(i,:) = [paramsfit(1:2); paramsfit([3 4]); paramsfit([6 8 10])]';
        
        ypredict11(i,:) = exp(predictedcontrast(paramsfit1(i,:),Nlevels', p.d(1)));
        ypredict12(i,:) = exp(predictedcontrast(paramsfit1(i,:),Nlevels', p.d(2)));
        ypredict21(i,:) = exp(predictedcontrast(paramsfit2(i,:),Nlevels', p.d(1)));
        ypredict22(i,:) = exp(predictedcontrast(paramsfit2(i,:),Nlevels', p.d(2)));
        ypredict31(i,:) = exp(predictedcontrast(paramsfit3(i,:),Nlevels', p.d(1)));
        ypredict32(i,:) = exp(predictedcontrast(paramsfit3(i,:),Nlevels', p.d(2)));
        
        predicted_Data = [predicted_Data; ypredict11(i,:); ypredict21(i,:); ypredict31(i,:); ...
            ypredict12(i,:); ypredict22(i,:); ypredict32(i,:)];
    end
end

RSS = sum((log10(100*predicted_Data(:))-(data(:))).^2);

