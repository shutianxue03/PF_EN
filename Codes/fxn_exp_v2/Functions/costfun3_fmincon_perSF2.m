 function sse=costfun3_fmincon(params,Empirical_Data,p)
%firstly, analysis structure of Actual_Data then choose 5 curve fitting or 2 curve
%fitting
[curveNum, noiseLevel]    =size(Empirical_Data);        %curveNum is total num of curves to be fitted on two performance level
%Nm                        =zeros(curveNum/2,noiseLevel);
nSF         = 2;
ngroup      = 3;
ndifficulty = 2;

%initial coeffiencies
Am(1:nSF,1:ngroup) = 1;
Ae(1:nSF,1:ngroup) = 1;
Aa(1:nSF,1:ngroup) = 1;

count = 7;
%Determine parameters
for i=1:length(p.modelOption)
    if isempty(p.modelOption{i})
        continue;
    else
        switch p.modelOption{i}
            case 'Am'
                Am(1:2,2) = params(count:count+1);
                count = count+2;
                Am(1:2,3) = params(count:count+1);
                count = count+2;
            case 'Ae'
                Ae(1:2,2) = params(count:count+1);
                count = count+2;
                Ae(1:2,3) = params(count:count+1);
                count = count+2;
            case 'Aa'
                Aa(1:2,2) = params(count:count+1);
                count = count+2;
                Aa(1:2,3) = params(count:count+1);
                count = count+2;
        end
    end
end


%% Before compute predicted data point, let's first regularize input
% temp=params;
regularization = 0;
if sum(params<0)>0    %avoid input parameters < 0;
    regularization = regularization + 100000*sum(params<0);
    %params = params + params*(-1.02).*(params<0);
end
%params-temp

%%
predicted_Data = zeros(size(Empirical_Data));

temp_params = zeros(7,1);
temp_params(1:2) = params(1:2); % [r beta]

for i = 1:nSF
    for j = 1:ndifficulty
        for k = 1:ngroup
            curveid = (i-1)*6 + (j-1)*3 + k;
            temp_params(3:7) = [params([2+i 4+i]); Am(i,k); Ae(i,k); Aa(i,k)];
            predicted_Data(curveid,:) = predictedcontrast(temp_params,p.Ne,p.d(j))';
        end
    end
end
% for i = 1:curveNum
%     if i <= curveNum/2
%         temp_params(5:7)=[Am(i);Ae(i);Aa(i)];
%         predicted_Data(i,:)=predictedcontrast(temp_params,p.Ne,p.d(1))';
%     else
%         temp_params(5:7)=[Am(i-curveNum/2);Ae(i-curveNum/2);Aa(i-curveNum/2)];
%         predicted_Data(i,:)=predictedcontrast(temp_params,p.Ne,p.d(2))';
%     end
% end


predicted_Data = exp(predicted_Data); %Transformed into linear space
% to make sure all predicted_Data are positive
% predicted_Data
%compute squar error in log space
meanContrast=mean((Empirical_Data(:)));
sse=sum((log10(100*predicted_Data(:))-(Empirical_Data(:))).^2)/sum(((Empirical_Data(:))-meanContrast).^2);
% sse=sum((log10(100*predicted_Data(:))-(Empirical_Data(:))).^2);
%regularize the cost
sse = sse + regularization;

 end

function log_pContrast= predictedcontrast(parameters,Ne,d)
r=parameters(1);
beta=parameters(2);
Na=parameters(3);
Nm=parameters(4);
Am=parameters(5);
Af=parameters(6);
Aa=parameters(7);


%Ne
%d

%pContrast=((((1+(Am*Nm)^2)*((Af*Ne)^(2*r))+(Aa*Na)^2)./(1/(d*d)-(Am*Nm)^2)).^(1/(2*r)))/beta;

%avoid complex number, so we do regularization here
x=1/(d^2)-(Am*Nm)^2;
if x<0
    x=0.01;
end

log_pContrast=1/(2*r)*log((1+(Am*Nm)^2)*((Af*Ne).^(2*r))+(Aa*Na)^2)-1/(2*r)*log(x)-log(beta);

%log_pContrast

if isnan(log_pContrast)
    save('data_temp','parameters','log_pContrast');
    error('Error: all contrast should be a value');
end


if ~isreal(log_pContrast)
    save('data_temp','parameters','log_pContrast');
    error('Error: all contrast should be a real value');
end


end
