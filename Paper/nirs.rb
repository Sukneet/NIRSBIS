#!/usr/bin/env ruby1.9.1

require 'serialport'
require 'rubygems'
require 'gnuplot'

$a750_Hb = 1.532
$a750_HbO2 = 0.600
$a850_hb = 0.781
$a850_HbO2 = 1.097

$DPF_750 = 5.0055
$DPF_850 = 4.6564

$raw_750_1 = Array.new	
$raw_850_1 = Array.new
$raw_750_2 = Array.new	
$raw_850_2 = Array.new
$i = 0

$C_Hb_1 = Array.new
$C_HbO2_1 = Array.new
$C_Hb_2 = Array.new
$C_HbO2_2 = Array.new

def plot 
	Gnuplot.open do |gp|
		Gnuplot::Plot.new( gp ) do |plot|

			#plot.xrange "[-10:10]"
			plot.title  "NIRS - Sensor 1"
			plot.ylabel "O2HHb, HHb umol"
			plot.xlabel "time"
	
			plot.data = [
			 Gnuplot::DataSet.new($C_Hb_1) { |ds|
				ds.with = "lines"
				ds.title = "Hb"
				ds.linewidth = 2
			 },
			
			 Gnuplot::DataSet.new($C_HbO2_1) { |ds|
				ds.with = "linespoints"
				ds.title = "HbO2"
				ds.linewidth = 2
			 }
			]
		end
	end
	Gnuplot.open do |gp|
		Gnuplot::Plot.new( gp ) do |plot|

			#plot.xrange "[-10:10]"
			plot.title  "NIRS - Sensor 2"
			plot.ylabel "O2HHb, HHb umol"
			plot.xlabel "time"
	
			plot.data = [
			 Gnuplot::DataSet.new($C_Hb_2) { |ds|
				ds.with = "lines"
				ds.title = "Hb"
				ds.linewidth = 2
			 },
			
			 Gnuplot::DataSet.new($C_HbO2_2) { |ds|
				ds.with = "linespoints"
				ds.title = "HbO2"
				ds.linewidth = 2
			 }
			]
		end
	end
end

def getData
	tmpdata = $sp.getc
	if (tmpdata ==nil)
		tmpdata=0.to_s;
	end
	tmpdata = tmpdata << 8
	tmp = $sp.getc
	if (tmp ==nil)
		tmp = 0.to_s; 
	end
	tmpdata += tmp
	puts tmpdata
	tmpdata = tmpdata.unpack('H*')[0].to_i
	full = "0xffff".hex
	val = tmpdata.to_f / full.to_f
	
	return (val)
end

$sp = SerialPort.new ("/dev/rfcomm1")
$sp.baud = 115200
$sp.read_timeout = 150

samples = "1000"
#samples.each_byte{|b| $sp.write b.chr}
$sp.write ('S')

while $i<samples.to_i
	#sleep 0.0016
	## 750 ##
	## sensor 1
	val_1_1 = getData
	$raw_750_1 << val_1_1
	
	## sensor 2
	val_1_2 = getData
	$raw_750_2 << val_1_2
			
	#sleep 0.0008
	## 850 ##
	## sensor 1
	val_2_1 = getData
	$raw_850_1 << val_2_1
	
	## sensor 2
	val_2_2 = getData
	$raw_850_2 << val_2_2
	
	#calculations
	$C_Hb_1 << ($a750_HbO2.to_f * (val_1_2.to_f/ $DPF_850.to_f) - $a850_HbO2.to_f * (val_1_1.to_f/ $DPF_750.to_f)) / ($a750_HbO2.to_f * $a850_Hb.to_f - $a850_HbO2.to_f * $a750_Hb.to_f)
	$C_HbO2_1 << ($a750_Hb.to_f * (val_1_2.to_f/ $DPF_850.to_f) - $a850_Hb.to_f * (val_1_1.to_f/ $DPF_750.to_f)) / ($a750_Hb.to_f * $a850_HbO2.to_f - $a850_Hb.to_f * $a750_HbO2.to_f)
	
	$C_Hb_2 << ($a750_HbO2.to_f * (val_2_2.to_f/ $DPF_850.to_f) - $a850_HbO2.to_f * (val_2_1.to_f/ $DPF_750.to_f)) / ($a750_HbO2.to_f * $a850_Hb.to_f - $a850_HbO2.to_f * $a750_Hb.to_f)
	$C_HbO2_2 << ($a750_Hb.to_f * (val_2_2.to_f/ $DPF_850.to_f) - $a850_Hb.to_f * (val_2_1.to_f/ $DPF_750.to_f)) / ($a750_Hb.to_f * $a850_HbO2.to_f - $a850_Hb.to_f * $a750_HbO2.to_f)		
	$i = $i + 1 
end

file = File.open("Hb_1_data", "rw")
$C_Hb_1.each { |d| file.puts(d)}
file.close

file = File.open("HbO2_1_data", "rw")
$C_HbO2_1.each { |d| file.puts(d)}
file.close

file = File.open("Hb_2_data", "rw")
$C_Hb_2.each { |d| file.puts(d)}
file.close

file = File.open("HbO2_2_data", "rw")
$C_HbO2_2.each { |d| file.puts(d)}
file.close

plot
$sp.close
	
