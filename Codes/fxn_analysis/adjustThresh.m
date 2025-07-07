


function PSE_best_allSubj = adjustThresh(PSE_best_allSubj, SF)

iperf=3;

switch SF
    case 5
        nLoc = 9;
        
        isubj=1; % AB
        PSE_best_allSubj(isubj, 7, 2, iperf) = log10(32/100);
        
        isubj=2; % MJ
        PSE_best_allSubj(isubj, 1, 2, iperf) = log10(2/100);
        PSE_best_allSubj(isubj, 2, 5, iperf) = log10(4.8/100);
        PSE_best_allSubj(isubj, 3, 6, iperf) = log10(10.5/100);
        PSE_best_allSubj(isubj, 3, 7, iperf) = log10(10.3/100);
        PSE_best_allSubj(isubj, 7, 3, iperf) = log10(39/100);
        PSE_best_allSubj(isubj, 8, 1, iperf) = log10(6.3/100);
        PSE_best_allSubj(isubj, 8, 7, iperf) = log10(12.6/100);
        
        isubj=3; % LH
        PSE_best_allSubj(isubj, 2, 1, iperf) = log10(2.5/100);
        PSE_best_allSubj(isubj, 3, 7, iperf) = log10(11.5/100);
        PSE_best_allSubj(isubj, 4, 1, iperf) = log10(2.7/100);
        PSE_best_allSubj(isubj, 4, 3, iperf) = log10(2.7/100);
        PSE_best_allSubj(isubj, 6, 2, iperf) = log10(4/100);
        PSE_best_allSubj(isubj, 7, 4, iperf) = log10(7.7/100);
        PSE_best_allSubj(isubj, 7, 5, iperf) = log10(10.4/100);
        PSE_best_allSubj(isubj, 9, 1, iperf) = log10(6.7/100);
        PSE_best_allSubj(isubj, 9, 6, iperf) = log10(11/100);
        
        
        isubj=4; % SP
        PSE_best_allSubj(isubj, 1, 2, iperf) = log10(2.5/100);
        PSE_best_allSubj(isubj, 5, 2, iperf) = log10(4.2/100);
        PSE_best_allSubj(isubj, 6, 1, iperf) = log10(5.3/100);
        PSE_best_allSubj(isubj, 6, 3, iperf) = log10(6.5/100);
        PSE_best_allSubj(isubj, 6, 5, iperf) = log10(7.9/100);
        PSE_best_allSubj(isubj, 6, 6, iperf) = log10(12.6/100);
        PSE_best_allSubj(isubj, 7, 3, iperf) = log10(15.3/100);
        PSE_best_allSubj(isubj, 8, 5, iperf) = log10(7.2/100);
        PSE_best_allSubj(isubj, 9, 4, iperf) = log10(7.2/100);
        PSE_best_allSubj(isubj, 9, 5, iperf) = log10(10.5/100);
        
        isubj=5; % AS
        PSE_best_allSubj(isubj, 2, 3, iperf) = log10(6/100);
        PSE_best_allSubj(isubj, 2, 5, iperf) = log10(6.5/100);
        PSE_best_allSubj(isubj, 3, 2, iperf) = log10(7/100);
        PSE_best_allSubj(isubj, 3, 3, iperf) = log10(6.3/100);
        PSE_best_allSubj(isubj, 3, 6, iperf) = log10(10/100);
        PSE_best_allSubj(isubj, 6, 5, iperf) = log10(10/100);
        PSE_best_allSubj(isubj, 7, 4, iperf) = log10(25/100);
        
        isubj=6; % CM
        PSE_best_allSubj(isubj, 1, 7, iperf) = log10(12/100);
        PSE_best_allSubj(isubj, 2, 6, iperf) = log10(6.3/100);
        PSE_best_allSubj(isubj, 3, 5, iperf) = log10(6/100);
        PSE_best_allSubj(isubj, 3, 7, iperf) = log10(10/100);
        PSE_best_allSubj(isubj, 4, 3, iperf) = log10(4/100);
        PSE_best_allSubj(isubj, 4, 4, iperf) = log10(6.5/100);
        PSE_best_allSubj(isubj, 4, 7, iperf) = log10(15/100);
        PSE_best_allSubj(isubj, 6, 3, iperf) = log10(6.5/100);
        PSE_best_allSubj(isubj, 8, 2, iperf) = log10(7.9/100);
        PSE_best_allSubj(isubj, 8, 4, iperf) = log10(10/100);
        PSE_best_allSubj(isubj, 8, 5, iperf) = log10(10/100);
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    case 6
        nLoc = 5;
        
        isubj=1; % SX
        PSE_best_allSubj(isubj, 1, 1, iperf) = log10(6/100);
        PSE_best_allSubj(isubj, 4, 1, iperf) = log10(6.5/100);
        
        isubj=2; % DT
        PSE_best_allSubj(isubj, 1, 2, iperf) = log10(3/100);
        PSE_best_allSubj(isubj, 1, 5, iperf) = log10(6.3/100);
        
        isubj=3; % RC (all good)
        
        isubj=4; % HL
        PSE_best_allSubj(isubj, 2, 3, iperf) = log10(15.8/100);
        PSE_best_allSubj(isubj, 3, 7, iperf) = log10(25.2/100);
        PSE_best_allSubj(isubj, 4, 4, iperf) = log10(10/100);
        
        isubj=5; % HH (all good)
end

IsNaN = isnan(squeeze(PSE_best_allSubj(:, 1:nLoc, :, iperf)));
assert(sum(IsNaN(:))==0)
