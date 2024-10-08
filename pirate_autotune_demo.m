% Testing autotune design with sinusoid input
% Period detection, selection, and correction
% Run the last section to hear the pitch correction.
% WILL PLAY SOUND
clc; clear all; close all;

%% Generate input sine
Fs = 125e6/2048; % Will be much higher in FPGA, need to decimate, voice signal only needs so high of a sampling rate though
t = linspace(0,1,Fs);
f = 448;
signal = sin(2*pi*f*t);

%% Period detection
% Count the number of clock cycles between neg to pos zero crossings
y = round((2^8-1)*(signal(1:Fs/16))).';     % 8 bit signal

% Zero crossing counter
signs = sign(y);                            % Sign of sample value
signs(signs == 0) = 1;                      % Replace all 0's with 1

j = 1;
period_detect = 0;
go = true;
while(go)
    prev = signs(j);
    next = signs(j+1);
    period_detect = period_detect + 1;      %counter
    j = j + 1;
    if(next>prev) go = false; end           %break at neg to pos zero crossing
end

%% Period selection
% Sort detected period into a bin corresponding to the correct note, to which
% the signal will be tuned

% Chromatic scale C3-B3
oct3 =  [130.81... C
         138.59... C#
         146.83... D
         155.56... D#
         164.81... E
         174.61... F
         185.00... F#
         196.00... G
         207.65... G#
         220.00... A
         233.08... A#
         246.94]; %B

notes = [oct3 2*oct3 4*oct3].'; % vector of notes C3-B5
mid = notes(1:end-1) + diff(notes)/2; % mid points between notes for comparators

% Notes defined in terms of clock cycles. Convert to hex and export as .mem
% file for RAM in FPGA
periods = round(Fs./notes);
mid_pers =  round(Fs./mid);

% Find which bin the frequency falls into (36 bins) Here it is implemented
% as a for loop, but in hardware it has a stage of
% parallel comparators, AND gates, and a mux.
bin(1) = period_detect > mid_pers(1);
bin(length(periods)) = period_detect <= mid_pers(end);
for k = 1:length(mid)
    bin(k+1) = (period_detect <= mid_pers(k)) && (period_detect > mid_pers(k+1)); % Comparators and AND gates
end

[~,bin_num] = max(bin); %mux

period_select = periods(bin_num); % Note to tune to

%% Period correction
% TD-PSOLA algorithm

win_size_max = 2*max(periods);
win_size_req = win_size_max./2./periods;
step_size = floor(win_size_req);
win_size = floor(win_size_max./step_size);
step = step_size(bin_num);

n = floor(win_size_max/step);

% hop size
hop = round(period_detect/2);
% 8-bit 2*period hann window zero padded
w = [round((2^8-1)*hann(2*period_detect)); zeros(length(y)-2*period_detect,1)]; 

% Slide window by hop size and multiply by signal
go = true;
ii = 2;
W(:,1) = w;
windows(:,1) = w.*y;
while go
    W(:,ii) = [zeros((ii-1)*hop,1); w(1:length(w)-((ii-1)*hop))];
    windows(:,ii) = W(:,ii).*y;
    if (length(w)-hop < (ii-1)*hop)
        go = false;
    end
    ii = ii + 1;
end

% PITCH CORRECTION*****************************************************
% Shift each window by the difference in detected period and selected
% period

correct =  period_select - period_detect; % Number of clock cycles by which to adjust detected period

shifted_windows(:,1) = windows(:,1);
for jj = 2:size(windows,2)
    current_win = windows(:,jj);
    if (correct > 0)     % stretch (down-shift)
        shifted_windows(:,jj) = [zeros((jj-1)*correct,1); current_win(1:end-(jj-1)*correct)];
    elseif (correct < 0) % compress (up-shift)
        shifted_windows(:,jj) = [current_win((-correct)*(jj-1)+1:end); zeros((jj-1)*(-correct),1)];
    else (correct == 0)
        shifted_windows = windows; % No correction
        break;
    end
end

y_out = sum(shifted_windows,2); % Pitch corrected output converted back to 8 bit


%% Plots

figure
plot(2*periods)
hold on
plot(win_size)
legend('2 x period','Used window size')
title('Required vs. Used Window size')
xlabel('Bin')
ylabel('Length of window')

figure
plot(y,'Linewidth',1)
hold on
plot(y_out/(256*2))
title('8-bit Sine')
legend(['Input: ' num2str(f) ' Hz'],['Output: ' num2str(Fs/period_select) ' Hz'])
xlabel('Clock cycles')

figure
plot(W)
title('8-bit Sliding Hann window')
xlabel('Clock cycles (7.81 MHz)')

x = 1400;
figure
subplot(611)
plot(windows(:,1))
hold on
plot(shifted_windows(:,1))
legend(['Original signal (' num2str(f) ' Hz)'],['Pitched signal (' num2str(Fs/period_select) ' Hz)'])
title('2 x period 8-bit Hann windowed signal with hop size 1 x period')
xlim([0 x])
subplot(612)
plot(windows(:,2))
hold on
plot(shifted_windows(:,2))
xlim([0 x])
subplot(613)
plot(windows(:,3))
hold on
plot(shifted_windows(:,3))
xlim([0 x])
subplot(614)
plot(windows(:,4))
hold on
plot(shifted_windows(:,4))
xlim([0 x])
subplot(615)
plot(windows(:,5))
hold on
plot(shifted_windows(:,5))
xlim([0 x])
subplot(616)
plot(sum(windows,2))
hold on
plot(sum(shifted_windows,2))
xlim([0 x])
title('Sum of windowed signals')

xlabel('Clock cycles (7.81 MHz)')

%% Play sounds
fprintf(['Playing original signal: ' num2str(f) ' Hz... \n'])
sound(y,Fs)
pause(1.5)
fprintf(['Playing pitched signal: ' num2str(Fs/period_select) ' Hz...\n'])
sound(y_out,Fs) % Convert back to 8 bit signal

%%
notes_rp = dec2hex((periods));
mid_rp = dec2hex((mid_pers));
