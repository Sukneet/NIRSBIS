clear;
close all;
clc;

path = 'Left Motor Cortex - Right Hand Movement';
data1 = strcat(path,'\Hb_1_data');
data2 = strcat(path,'\Hb_2_data');
data3 = strcat(path,'\HbO2_1_data');
data4 = strcat(path,'\HbO2_2_data');
printname1 = strcat(path,'\sensor1');
printname2 = strcat(path,'\sensor2');
load (data1)
load (data2)
load (data3)
load (data4)

fNorm = 0.5 / (200/2);
[b,a] = butter(4, fNorm, 'low');

fHb_1 = filtfilt(b, a, Hb_1_data);
fHb_2 = filtfilt(b, a, HbO2_2_data);
fHbO2_1 = filtfilt(b, a, HbO2_1_data);
fHbO2_2 = filtfilt(b, a, Hb_2_data);

figure;
plot (linspace (0,30,length(fHb_1)),fHb_1);hold; plot (linspace (0,30,length(fHbO2_1)),fHbO2_1,'r'); title({path,'Sensor 1'});legend('HHb','O2Hb');xlabel('time (s)'); ylabel('concentration changes (\mumol/l)');
print('-dpng', printname1)
figure;
plot (linspace (0,30,length(fHb_2)),fHb_2); hold; plot (linspace (0,30,length(fHbO2_2)),fHbO2_2,'r'); title({path,'Sensor 2'}); legend('HHb','O2Hb');xlabel('time (s)'); ylabel('concentration changes (\mumol/l)');
print('-dpng', printname2)