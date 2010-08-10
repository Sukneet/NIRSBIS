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

cut1 = 60;
cut2 = 60;
figure;
plot (linspace (0,30,length(fHb_1)-cut1+1),fHb_1(cut1:length(fHb_1)));hold; plot (linspace (0,30,length(fHbO2_1)-cut1+1),fHbO2_1(cut1:length(fHbO2_1)),'r'); title({path,'Sensor 1'});legend('HHb','O2Hb');xlabel('time (s)'); ylabel('concentration changes (\mumol/l)');
%print('-dpng', printname1)
figure;
plot (linspace (0,30,length(fHb_2)-cut2+1),fHb_2(cut2:length(fHb_2))); hold; plot (linspace (0,30,length(fHbO2_2)-cut2+1),fHbO2_2(cut2:length(fHbO2_2)),'r'); title({path,'Sensor 2'}); legend('HHb','O2Hb');xlabel('time (s)'); ylabel('concentration changes (\mumol/l)');
%print('-dpng', printname2)

n = length (fHb_1);
f = -n/2*(100/n):100/n:n/2*(100/n)-100/n;
figure;
plot (f,abs(fftshift(fft(fHb_1)))); title({'fft of concentration change in Hb after filtering','Sensor 1'}); xlabel('frequency (Hz)');
print('-dpng', 'fftHb_1f')
figure;
n = length (Hb_1_data);
f = -n/2*(100/n):100/n:n/2*(100/n)-100/n;
plot (f,abs(fftshift(fft(Hb_1_data)))); title({'fft of concentration change in Hb before filtering','Sensor 1'}); xlabel('frequency (Hz)');
print('-dpng', 'fftHb_1')

n = length (fHbO2_1);
f = -n/2*(100/n):100/n:n/2*(100/n)-100/n;
figure;
plot (f,abs(fftshift(fft(fHbO2_1)))); title({'fft of concentration change in O2Hb after filtering','Sensor 1'}); xlabel('frequency (Hz)');
print('-dpng', 'fftHbO2_1f')
figure;
n = length (HbO2_1_data);
f = -n/2*(100/n):100/n:n/2*(100/n)-100/n;
plot (f,abs(fftshift(fft(HbO2_1_data)))); title({'fft of concentration change in O2Hb before filtering','Sensor 1'}); xlabel('frequency (Hz)');
print('-dpng', 'fftHbO2_1')

n = length (fHb_2);
f = -n/2*(100/n):100/n:n/2*(100/n)-100/n; 
figure;
plot (f,abs(fftshift(fft(fHb_2)))); title({'fft of concentration change in Hb after filtering','Sensor 2'}); xlabel('frequency (Hz)'); 
print('-dpng', 'fftHb_2f')
figure;
n = length (HbO2_2_data);
f = -n/2*(100/n):100/n:n/2*(100/n)-100/n;
plot (f,abs(fftshift(fft(HbO2_2_data))));title({'fft of concentration change in Hb before filtering','Sensor 2'}); xlabel('frequency (Hz)');
print('-dpng', 'fftHb_2')

n = length (fHbO2_2);
f = -n/2*(100/n):100/n:n/2*(100/n)-100/n;  
figure;
plot (f,abs(fftshift(fft(fHbO2_2))));title({'fft of concentration change in O2Hb after filtering','Sensor 2'}); xlabel('frequency (Hz)');
print('-dpng', 'fftHbO2_2f')
figure;
n = length (Hb_2_data);
f = -n/2*(100/n):100/n:n/2*(100/n)-100/n;
plot (f,abs(fftshift(fft(Hb_2_data))));title({'fft of concentration change in O2Hb before filtering','Sensor 2'}); xlabel('frequency (Hz)');
print('-dpng', 'fftHbO2_2')