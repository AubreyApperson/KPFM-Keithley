#pragma rtGlobals=1		// Use modern global access method.

//Description:  This proceedure file contains commands to set a Keithley 2400 sourcemeter to a particular voltage.
//  This is helpful as samples can be biased while running AFM or KPFM on them.  Note that aggregate information
//  can be helpful in determining DOS data on samples.  

// Usage:  	To load this proceedure, open your current experiment proceedure window (Windows > proceedure windows > 
//				proceedure window), paste ' #include "your_file_path_here" 'and change it to the file path of this file 
// 				for example:  ' #include "C:\Documents and Settings\computation\Desktop\kpfmv2.0"  '.
//			1. Use the command "globalvars()" to set your main parameters.
//			2. Use the command "kpfmv()" to activate the Keithley and set the bias voltage
//			3. Use the command "inc()" to increment the output voltage by the amount specified after running globalvars()
//			4. *** Always use "stop()"*** to kill all global variables created by "globalvars()" and turn the Keithley off.

// For more help, type 'help()' in the command window.  
// The steps in usage can be viewed by typing 'process()' once this proceedure file is loaded properly.


Function kpfmv()
// Main Function:  Tell keithley to turn on and output voltage "vout" (global variable)
// After changing voltage, wait time specified by (global variable) "delay" before continuing.
	Variable /G start_volt, end_volt, stepsize, delay, vout, iter  // acquire this global variable for use in this function
	printf "voltage output level = %3.4f\r", vout
	Variable session_ID, instr
	viOpenDefaultRM(session_ID)
	//Printf "session ID=%d\r",  session_ID
	//Printf "Note that the session ID can be passed to viOpen to open an insturment session. \r"
	 
	String resource_name = "GPIB0::24::INSTR"
	//Printf "Resource Name=%s\r",  resource_name
	Variable status
	status = viOpen(session_ID, resource_name, 0, 0, instr)
	 
	VISAWrite instr, ":*RST" // Restore GPIB default conditions
	VISAWrite instr, ":*ESE 0" // Program the Standard Event Enable Register
	VISAWrite instr, ":*CLS" // Clears all event registers and Error Queue
	VISAWrite instr, ":FORM:SREG BIN" // Format register to binary
	 
	VISAWrite instr, ":TRAC:FEED:CONT NEVER" // Disable any residual data collection in buffer
	VISAWrite instr, ":TRAC:CLE" // Clear buffer
	
	VISAWrite instr, ":SOUR:FUNC:MODE VOLT" // Select voltage source mode
	VISAWrite instr, ":SOUR:VOLT:MODE FIX" // Select voltage source to fixed mode (output constant value)
	VISAWrite instr, ":SOUR:DEL:AUTO OFF" // Source auto delay off (use DELAY to program delay between source and measure)
	VISAWrite instr, ":SOUR:DEL 0" // No source delay 
	
	// take inputted global variable "vout" and turn into string
	//concatenate string for sending via SCPI command to keithley
	String outvstr = ":SOUR:VOLT:LEV " + num2str(vout)
	
	VISAWrite instr, outvstr 	// (now send the command)  set the output to THIS level (in volts) 
	VISAWrite instr, ":SENS:CURR:PROT 1E-5"  // 10mA compliance
	VISAWrite instr, ":SOUR:VOLT:RANG 100"	// select source range
	
	VISAWrite instr, ":OUTP ON"
	 
	 viClose(session_ID)
	 sleep/s/C=0 delay //make the program wait "delay" (global variable) seconds while the keithley adjusts it's voltage
	  
	  
	  // a little extra
	  if (iter ==3)
	  	print "\rEverything appears to be working properly!!\r\r"
	   elseif (iter ==25)
	  	print "\rYep.  25 iterations.  This end looks good.  How does the image look?  I'm sure you'll check it soon enough.\r\r"
	  elseif (iter ==50)
	  	print "\rYep.  50 iterations.  This end looks good.  How does the image look?  I'm sure you'll check it soon enough.\r\r"
	  elseif (iter ==100) 
	  	print "\rHow do you like that!? 100 iterations! Take that world...\r\r"
	  elseif (iter ==200)
	  	print "\rAlright, I don't know what else to say.  It works, (iteration 200) this is it for me.\r   -Aubrey \r\r"
	  elseif (iter >200)
	  	if(mod(iter, 50) ==0)
	  		String iteralert = "\rFYI iteration " + num2str(iter) + " is being scanned next.\r\r"
	  		print iteralert
	  	endif
	  endif
	  
end


Function stop()
// turns of keithley output and releases global variable vout
	killvariables /Z vout, iter, start_volt, end_volt, stepsize, delay
	printf "killvariables = success\r"
	Variable session_ID, instr
	viOpenDefaultRM(session_ID)
	String resource_name = "GPIB0::24::INSTR"
	viOpen(session_ID, resource_name, 0, 0, instr)
	VISAWrite instr, ":OUTP OFF"
	viClose(session_ID)
end




Function globalvars(start_volt1, end_volt1, stepsize1, delay1)
	// declare global variable "vout" for the voltage level output for the keithley device
	Variable start_volt1, end_volt1, stepsize1, delay1
	Variable/G start_volt = start_volt1, end_volt = end_volt1, stepsize = stepsize1, delay =delay1, iters = 0
	Variable/G vout
	vout = start_volt
	Printf "Start Voltage = %d\r", start_volt
	Printf "End Voltage = %d\r", end_volt
	Printf "Voltage step size = %d\r", stepsize
	Printf "delay time before scan = %d\r", delay
end


Function inc()
	Variable /G vout, stepsize, iter
	vout = vout + stepsize
	iter +=1
end


Function/S DateTimeStamp()
	String dstr, tstr
 
	Variable timestamp = DateTime
	String sep_char = "."
 
	tstr = Secs2Time(timestamp, 3)
	dstr = Secs2Date(timestamp, -2, sep_char)
 
	// Replace numeric month with text abbreviation.
	String months = "Jan;Feb;Mar;Apr;May;Jun;Jul;Aug;Sep;Oct;Nov;Dec;"
	String month_abbreviation = StringFromList(str2num(StringFromList(1, dstr, sep_char)) - 1, months, ";")
	dstr = RemoveListItem(1, dstr, sep_char)
	dstr = AddListItem(month_abbreviation, dstr, sep_char, 1)
	dstr = RemoveEnding(dstr, sep_char)
	return (dstr + "|" + tstr)
end

//////////////////////////////////////////////////////////////////////////////////////////
//// HELP SECTION
Function help()
	// Print what functions are avalible with this proceedure file
	print "\rThe following are functions avalible with the kpfmv_2.0 proceedure file. Type 'helps()' for the short list or 'process()' \r for the process to implement them.\r\r"
	print "globalvars(start_volt, end_volt, stepsize, delay) - This function is used to declare global variables 'start voltage, \r end voltage, voltage stepsize, delay)' which are used by the function 'kpfmv()'.\r\r"
	print "kpfmv() - This function tells the connected Keithely 2400 SourceMeter (on channel GPIB 24 \r using SCPI commands) to output a voltage specificed by global variable 'vout.'  If 'vout' is set by 'globalvars()' \r the function defaults to 0 volts.\r\r"
	print "inc() - This function increments the global variable 'vout' by its given input parameter."
	print "stop() - This function turns off the Keithley output and releases global variables.\r\r"
	print "DateTimeStamp() - This function returns the date and time.  Type 'Print DateTimeStamp()' in the \r command window.\r\r"
end

Function helps()
	print "Short list of functions: \r globalvars(start_volt, end_volt, stepsize, delay), kpfmv(), inc(), stop(),  DateTimeStamp() \r\r Global variables:\r start_volt, end_volt, stepsize, delay, iter, vout\r"
end

Function process()
	print "This is the process your should use when setting up your macro in the AFM software."
	print "1. Use the command 'globalvars()' to set your main parameters. \r"
	print "2. Use the command 'kpfmv()' to activate the Keithley and set the bias voltage.\r"
	print "3. Use the command 'inc()' to increment the output voltage by the amount specified after running globalvars().\r"
	print "4. *** Always use 'stop()' *** to kill all global variables created by 'globalvars()' and turn the Keithley off.\r"
end