#!/usr/bin/env ruby1.9.1

	require 'serialport'
	require 'rubygems'
	require 'gnuplot'
	
	a750_Hb = 1.532
	a750_HbO2 = 0.600
	a850_Hb = 0.781
	a850_HbO2 = 1.097
	
	DPF_750 = 5.0055
	DPF_850 = 4.6564
	
	raw_750_1 = Array.new	
	raw_850_1 = Array.new
	raw_750_2 = Array.new	
	raw_850_2 = Array.new
	$i = 0
	
	$C_Hb_1 = Array.new
	$C_HbO2_1 = Array.new
	$C_Hb_2 = Array.new
	$C_HbO2_2 = Array.new
	
	#plotting
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
	
	#get data from serial port
	def getData
		tmpdata = $sp.getc
		if (tmpdata ==nil)
			tmpdata=0.to_s;
		end
		#top 8 bits
		tmpdata = tmpdata << 8
		tmp = $sp.getc
		if (tmp ==nil)
			tmp = 0.to_s; 
		end
		#bottom 8 bits
		tmpdata += tmp
		puts tmpdata
		tmpdata = tmpdata.unpack('H*')[0].to_i
		full = "0xffff".hex
		# value is portional to 0xffff due to the way ADC samples
		val = tmpdata.to_f / full.to_f
		
		return (val)
	end
	
	$sp = SerialPort.new ("/dev/rfcomm1")
	$sp.baud = 115200
	#1000 = 1s
	$sp.read_timeout = 1000
	
	samples = "8000"
	#samples.each_byte{|b| $sp.write b.chr}
	#single microcontroller to begin sampling
	$sp.write ('S')
	num_samp=0;
	beginning = Time.now 
	while $i<=samples.to_i
		if ($sp.getc == 'S')
			#sleep 0.0016
			## 750 ##
			## sensor 1
			val_1_1 = getData
			raw_750_1 << val_1_1.to_f
			
			## sensor 2
			val_1_2 = getData
			raw_750_2 << val_1_2.to_f
					
			#sleep 0.0008
			## 850 ##
			## sensor 1
			val_2_1 = getData
			raw_850_1 << val_2_1.to_f
			
			## sensor 2
			val_2_2 = getData
			raw_850_2 << val_2_2.to_f
			num_samp= num_samp+1
		else
			puts "false"
		end	
		$i = $i + 1 
	end
	puts "Time elapsed #{Time.now - beginning} seconds"
	$i=1
	until $i>=num_samp.to_i
		#do the math
		if ((raw_750_1[$i] != 0 && raw_750_1[$i-1] != 0)  &&  (raw_850_1[$i] !=0 && raw_850_1[$i-1] !=0))
			delta_OD_1 = Math.log(raw_750_1[$i-1] / raw_750_1[$i]);
			delta_OD_2 = Math.log(raw_850_1[$i-1] / raw_850_1[$i]);
			# d is 1cm 
			$C_Hb_1 << (a750_HbO2.to_f * (delta_OD_2.to_f / DPF_850.to_f) - a850_HbO2.to_f * (delta_OD_1.to_f/ DPF_750.to_f)) / (a750_HbO2.to_f * a850_Hb.to_f - a850_HbO2.to_f * a750_Hb.to_f)
			$C_HbO2_1 << (a750_Hb.to_f * (delta_OD_2.to_f / DPF_850.to_f) - a850_Hb.to_f * (delta_OD_1.to_f/ DPF_750.to_f)) / (a750_Hb.to_f * a850_HbO2.to_f - a850_Hb.to_f * a750_HbO2.to_f)	
		end

		if ((raw_750_2[$i] != 0 && raw_750_2[$i-1] != 0)  &&  (raw_850_2[$i] !=0 && raw_850_2[$i-1] !=0))
			delta_OD_1 = Math.log(raw_750_2[$i-1] / raw_750_2[$i]);
			delta_OD_2 = Math.log(raw_850_2[$i-1] / raw_850_2[$i]);
			# d is 1cm 
			$C_Hb_2 << (a750_HbO2.to_f * (delta_OD_2.to_f / DPF_850.to_f) - a850_HbO2.to_f * (delta_OD_1.to_f/ DPF_750.to_f)) / (a750_HbO2.to_f * a850_Hb.to_f - a850_HbO2.to_f * a750_Hb.to_f)
			$C_HbO2_2 << (a750_Hb.to_f * (delta_OD_2.to_f / DPF_850.to_f) - a850_Hb.to_f * (delta_OD_1.to_f/ DPF_750.to_f)) / (a750_Hb.to_f * a850_HbO2.to_f - a850_Hb.to_f * a750_HbO2.to_f)
		end	
		$i = $i +1
	end
	
	# write change in concentrations to files
	file = File.open("Hb_1_data", "w")
	$C_Hb_1.each { |d| file.puts(d)}
	file.close
	
	file = File.open("HbO2_1_data", "w")
	$C_HbO2_1.each { |d| file.puts(d)}
	file.close
	
	file = File.open("Hb_2_data", "w")
	$C_Hb_2.each { |d| file.puts(d)}
	file.close
	
	file = File.open("HbO2_2_data", "w")
	$C_HbO2_2.each { |d| file.puts(d)}
	file.close

	# plot data, kinda broken
	#plot
	$sp.close
	
