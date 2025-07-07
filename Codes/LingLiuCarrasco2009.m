% === Parameters ===
nDots = 80;                   % Number of motion elements (dots)
nDetectors = 180;            % Number of direction-selective detectors (1 per degree)
detector_pref = linspace(-180, 180, nDetectors);  % Preferred directions
refDirection = 0;            % Reference direction (e.g., upward)

spontaneousRate = 10;        % Baseline firing rate
F = 40;                      % Max firing rate (signal strength)
r = 90;                      % Tuning width of direction-selective neuron
AG = 1.4;                    % Attentional gain factor (1 = no gain)
TA = 0.0032;                 % Tuning suppression slope (0 = no tuning)
nTrials = 10;              % Monte Carlo iterations

nSamples_all = [1,10,20,40];
nnSamples = length(nSamples_all);

figure, hold on
for iSample = 1:nnSamples

    nSamples = nSamples_all(iSample);               % Number of local elements sampled (subsampling)

    % === Simulation ===
    dotNoiseSD_all = [1, 16, 32, 64, 100];             % External noise level (standard deviation of dot directions)
    nNoise = length(dotNoiseSD_all);
    thresh_allN = nan(1, nNoise);

    for iNoise = 1:nNoise
        dotNoiseSD  = dotNoiseSD_all(iNoise);
        hEstimates = zeros(nTrials,1);

        parfor iTrial = 1:nTrials
            % Generate random dot directions around reference with SD = dotNoiseSD
            dotDirections = refDirection + dotNoiseSD * randn(nDots,1);

            % Simulate population responses to each dot
            responses = zeros(nDots, nDetectors);
            for i = 1:nDots
                for j = 1:nDetectors
                    raw_diff = dotDirections(i) - detector_pref(j);
                    angle_diff = deg2rad(mod(raw_diff + 180, 360) - 180);
                    gain = AG * (1 - TA * abs(rad2deg(angle_diff)));  % Apply gain+tuning
                    gain = max(gain, 0);  % Half-wave rectification
                    mu = spontaneousRate + (F * gain - spontaneousRate) * exp(- (angle_diff).^2 / (2*deg2rad(r)^2));
                    responses(i,j) = poissrnd(mu);  % Poisson response
                end
            end

            % Subsample and integrate across dots
            sampled_idx = randsample(nDots, nSamples);
            pooledResponse = mean(responses(sampled_idx,:), 1);

            % Decode using MLE (choose direction with highest response)
            [~, maxIdx] = max(pooledResponse);
            hEstimates(iTrial) = detector_pref(maxIdx);
        end % end of trial

        % === Estimate threshold (SD of estimates) and plot ===

        threshold = std(hEstimates);  % This is the "threshold" for this external noise level
        fprintf('Estimated threshold at noise SD = %g: %.2f deg\n', dotNoiseSD, threshold);
        %
        % % Optional: histogram of direction estimates
        % figure; histogram(hEstimates, 30); xlabel('Estimated direction (°)'); ylabel('Count');
        % title(sprintf('Decoded Global Motion Estimates (Threshold ≈ %.2f°)', threshold));
        thresh_allN(iNoise) = threshold;
    end % end of iNoise

    %%
    
    % plot(log10(dotNoiseSD_all), log10(thresh_allN), '-')
    loglog(dotNoiseSD_all, thresh_allN, 'o-')

end % subsampling