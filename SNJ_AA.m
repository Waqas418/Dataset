clc;
clear all;
%This code produces samples of ISRJ Signal with number of forwards=1~4,
%slice period= 5~10 , microseconds jamming cycle= 20~50.
for sample = 1:2
    disp(['Sample ', num2str(sample), ':']);
    
    % Parameters for TS(t) pulse train
    Ts = 5e-6; % Pulse width in seconds
    PRF_TS = 5e-6; % Pulse repetition frequency in seconds
    A = 1; % Amplitude of TS(t) pulse train

    % Parameters for TW(t) pulse train
    Tw = 2e-6; % Pulse width in seconds
    PRF_TW = 2e-6; % Pulse repetition frequency in seconds
    B = 1; % Amplitude of TW(t) and TW1(t) pulse trains

    % Parameters for the original chirp waveform
    start_frequency = -6e6;          % Start frequency in Hz
    end_frequency = 6e6;           % End frequency in Hz
    pulse_duration = 20e-6;         % Pulse duration in seconds
    total_duration = 100e-6;        % Total duration to visualize
    start_time = 60e-6;             % Start time for the chirp waveform

    % Sampling frequency
    fs = 75e6;  % Adjust as needed

    % Time vector
    t = linspace(0, total_duration, total_duration * fs);

    % Randomly select the number of forwards between 1 and 4
    num_forwards = randi([1, 4]);

    % Randomly select the slice period between 7 and 12 microseconds
    slice_period = (12e-6 - 7e-6) * rand + 5e-6; % in microseconds

    % Randomly select the jamming duty cycle between 60% and 90%
    jamming_duty_cycle = (90 - 60) * rand + 20; %

    % Calculate the duration of the jamming pulse
    jamming_pulse_duration = slice_period * jamming_duty_cycle / 100;

    % Generate original chirp waveform with pulse duration
    chirp_waveform_original = chirp(t-start_time, start_frequency, pulse_duration, end_frequency, 'linear', 'complex');

    % Ensure original chirp waveform is zero before 0 microseconds and after 20 microseconds
    chirp_waveform_original(t < start_time) = 0;
    chirp_waveform_original(t > (start_time+pulse_duration)) = 0;

    % Initialize J(t) to accumulate ISRJ signals
    J_signal_accumulated = zeros(size(t));

    % Main loop for iterating over forwards
    for forward = 1:num_forwards
        % Generate the TS(t) pulse train
        TS_pulse_train = zeros(size(t));
        TS_pulse_train(mod(t, PRF_TS) <= Ts) = A; % Generate rectangular pulses

        % Generate the TW(t) pulse train
        TW_pulse_train = zeros(size(t));
        TW_pulse_train(mod(t, PRF_TW) <= Tw) = B; % Generate rectangular pulses

        % Generate the delayed TW1(t) pulse train
        delayed_TW_pulse_train = zeros(size(t));
        for i = 1:length(t)
            % Check if the current time is within the TW(t) pulse width
            if mod(t(i), PRF_TW) <= Tw
                % Check if it's within the jamming pulse duration
                if mod(t(i), slice_period) <= jamming_pulse_duration
                    delayed_TW_pulse_train(i) = B; % Set to amplitude B (jamming)
                else
                    delayed_TW_pulse_train(i) = 0; % Set to zero (idle)
                end
            end
        end

        % Multiply TS(t) with TW(t) and TW1(t)
        Pulse_train_multiplied = TS_pulse_train .* TW_pulse_train;
        Pulse_train_multiplied_delayed = TS_pulse_train .* delayed_TW_pulse_train;

        % Multiply P(t) with X(t) to get J(t)
        J_signal = Pulse_train_multiplied_delayed .* chirp_waveform_original;

        % Accumulate ISRJ signals
        J_signal_accumulated = J_signal_accumulated + J_signal;
    end

    % Generate white Gaussian noise
    sigma_squared = 0.1; % Variance of the white Gaussian noise
    white_gaussian_noise = sqrt(sigma_squared) * randn(size(t)); % Scale by square root of variance

    % Multiply J(t) with white Gaussian noise
    J_with_noise = 0.0005*(J_signal_accumulated .* white_gaussian_noise);

    % %Plot the result
    % figure;
    % 
    % plot(t * 1e6, real(J_with_noise));
    % xlabel('Time (\mu s)');
    % ylabel('Normalized Amplitude');
    % title('SNJ Time Domain Waveform');

  figure;
    spectrogram(J_with_noise, hann(256), 250, 1024, fs, 'centered', 'yaxis');
    set(gca, 'YDir', 'reverse');
    title('SNJ Time Frequency Spectrogram');
    title(sprintf('Sample %d: SNJ (Time Frequency Waveform)', sample));
    saveas(gcf, ['C:\Users\waq\Desktop\New folder\New folder', sprintf('SNJ_sample_%d.png', sample)]);

    % Calculate the modulus (magnitude) and phase of the complex chirp waveform
    modulus_chirp = abs(J_with_noise);
    phase_chirp = angle(J_with_noise);


    % Plot the spectrogram of the real part of the original chirp waveform with the additional delay
    figure;
    spectrogram(real(J_with_noise), hann(256), 250, 1024, fs, 'centered', 'yaxis');
    title(sprintf('SNJ(Spectrogram - Real Part) - Sample %d', sample));
    set(gca, 'YDir', 'reverse');
    % Save the figure
    saveas(gcf, fullfile('C:\Users\waq\Desktop\New folder\New folder', sprintf('SNJ_RealPart_Sample_%d.png', sample)));

    % Plot the spectrogram of the imaginary part of the original chirp waveform with the additional delay
    figure;
    spectrogram(imag(J_with_noise), hann(256), 250, 1024, fs, 'centered', 'yaxis');
    title(sprintf('SNJ(Spectrogram - Imaginary Part) - Sample %d', sample));
    set(gca, 'YDir', 'reverse');
    % Save the figure
    saveas(gcf, fullfile('C:\Users\waq\Desktop\New folder\New folder', sprintf('SNJ_ImaginaryPart_Sample_%d.png', sample)));

    % Plot the spectrogram of the modulus (magnitude) of the original chirp waveform
    figure;
    spectrogram(modulus_chirp, hann(256), 250, 1024, fs, 'centered', 'yaxis');
    title(sprintf('SNJ(Spectrogram - Modulus) - Sample %d', sample));
    set(gca, 'YDir', 'reverse');
    % Save the figure
    saveas(gcf, fullfile('C:\Users\waq\Desktop\New folder\New folder', sprintf('SNJ_Modulus_Sample_%d.png', sample)));

    % Plot the spectrogram of the phase of the original chirp waveform
    figure;
    spectrogram(phase_chirp, hann(256), 250, 1024, fs, 'centered', 'yaxis');
    title(sprintf('SNJ(Spectrogram - Phase) - Sample %d', sample));
    set(gca, 'YDir', 'reverse');
    % Save the figure
    saveas(gcf, fullfile('C:\Users\waq\Desktop\New folder\New folder', sprintf('SNJ_Phase_Sample_%d.png', sample)));
end
