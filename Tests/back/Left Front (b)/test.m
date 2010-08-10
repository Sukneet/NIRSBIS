clear;
close all;
clc;
load Hb_1_data
load Hb_2_data
load HbO2_1_data
load HbO2_2_data

fNorm = 0.5 / (100/2);
[b,a] = butter(6, fNorm, 'low');

fHb_1 = filtfilt(b, a, Hb_1_data);
fHb_2 = filtfilt(b, a, Hb_2_data);
fHbO2_1 = filtfilt(b, a, HbO2_1_data);
fHbO2_2 = filtfilt(b, a, HbO2_2_data);


figure;
plot (linspace (0,30,length(fHb_1)-39),fHb_1(40:length(fHb_1)),'r');hold; plot (linspace (0,30,length(fHbO2_1)-39),fHbO2_1(40:length(fHbO2_1)));
figure;
plot (linspace (0,30,length(fHb_2)-29),fHb_2(30:length(fHb_2)),'r'); hold; plot (linspace (0,30,length(fHbO2_2)-29),fHbO2_2(30:length(fHbO2_2)));