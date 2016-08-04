#pragma rtGlobals=1		// Use modern global access method.
#pragma version = 2.1
// This work supported by NSF Career Award DMR -1056861
// Primary Author : AK Apperson

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
	itercheck()  // make sure the user reset variables if they terminated the program early
	Variable /G start_volt, end_volt, stepsize, delay, vout, iter  // acquire this global variable for use in this function
	Variable session_ID, instr, status
	viOpenDefaultRM(session_ID)  // Find the default instrument and its session ID to pass viOpen to open an insturment session.
	String resource_name = "GPIB0::24::INSTR"
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
	printf "voltage output level = %3.4f\r", vout
	viClose(session_ID)
	sleep/s/C=0 delay //make the program wait "delay" (global variable) seconds while the keithley adjusts it's voltage
	  
	 
	// a little extra
	if (iter ==25)
		print "\rYep.  25 iterations.  This end looks good.  How does the image look?  I'm sure you'll check it soon enough.\r\r"
	elseif (iter ==50)
	  	print "\rYep.  50 iterations.  This end looks good.  How does the image look?  I'm sure you'll check it soon enough.\r\r"
	elseif (iter ==100) 
	  	print "\rHow do you like that!? 100 iterations! Take that world...\r\r"
	elseif (iter ==150)
	  	print "\rAlright, I don't know what else to say.  It works, (iteration 150) this is it for me.\r   -Aubrey \r\r"
	elseif (iter >150)
	  	if(mod(iter, 25) ==0)
	 		String iteralert = "FYI iteration " + num2str(iter) + " is being scanned next.\r"
	  		print iteralert
	  	endif
	endif
	
end


Function stop()
// turns off keithley output and releases global variable vout
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
	Variable/G start_volt = start_volt1, end_volt = end_volt1, stepsize = stepsize1, delay =delay1, iter = 0
	Variable/G vout
	
	// Check sign  //  check to make sure the user put the correct sign on stepsize (compared to where they want to start and end)
	printf "\r" // put some space command history window
	if ((end_volt-start_volt)<0)  // user wants to count DOWN from start to end THUS stepsize should be negative
		if (stepsize<0) // it's negative, they were a smart user
		elseif (stepsize>0) // they were not a smart user or made a mistake
			DoWindow/H
			printf "Hey, your start voltage is %d and your end voltage is %d, but your step size, %2.3f, is positive.\r", start_volt, end_volt, stepsize
			printf "Let me fix that for you.\r"
			stepsize=stepsize*(-1);
			printf "Now your step size is %2.3f\r No further action is required from you.\r\r", stepsize
		else // they set the step size to zero
			DoWindow/H
			printf "**Caution**    Step size is zero!! (But hey, I'm not stopping you.)\r"
		endif
	elseif ((end_volt-start_volt)>0)  // user wants to count UP from start to end THUS stepsize should be positive
		if (stepsize>0) // it's positive, they were a smart user
		elseif (stepsize<0) // they were not a smart user or made a mistake
			DoWindow/H
			printf "Hey, your start voltage is %d and your end voltage is %d, but your step size, %2.3f, is negative.\r", start_volt, end_volt, stepsize
			printf "Let me fix that for you.\r"
			stepsize=stepsize*(-1);
			printf "Now your step size is %2.3f\r No further action is required from you.\r\r", stepsize
		else // they set the step size to zero
			DoWindow/H
			printf "**Caution**    Step size is zero!! (But hey, I'm not stopping you.)\r"
		endif
	else  // the only other option is that start_volt = end_volt which makes absolutely no sense whatsoever.
		printf "You have the starting voltage and ending voltages set equal.\r"
		printf "That is not a valid option.  Aborting.\r\r"
		abort
	endif   //end check sign
	
	
	vout = start_volt
	Printf "Start Voltage = %d volts\r", start_volt
	Printf "End Voltage = %d volts \r", end_volt
	Printf "Voltage step size = %3.3f volts \r", stepsize
	Printf "delay time before scan = %d second(s)\r", delay
end


Function inc()
	Variable /G vout, stepsize, iter
	vout = vout + stepsize
	iter +=1
end


Function itercheck()  // this function resets the variable iter if the user runs the program, then exits without
//using the stop() command to reset iter.
	variable /G vout, iter, start_volt
	if ((vout ==start_volt) && (iter != 0))
		iter = 0
		printf "iter reset.  You didn't run stop() to reset variables.\r"
	endif
end


Function check(step)  // step number after the loop in the macro, program will be directed to that step when 
// the check fails.  Checks to see if vout is outside of the range vstart to vend
	Variable step
	Variable K = 0
	Variable/G vout, start_volt, end_volt // aquire global variables for checking.
	
	// remember there are two cases, we could be counting up from start to end or down from start to end
	if (vout<start_volt)
		if (vout>=end_volt)
		elseif (vout<end_volt)
			K = 1
		endif
	elseif (vout>start_volt)
		if (vout<=end_volt)
		elseif (vout>end_volt)
			K = 1
		endif
	endif     //other option is vout == start_voltage, so no issues
	
	
	if (K ==1)  // K is our break-out flag, create break command
		String gotostep = "GoToStep(" + num2str(step) +")"
		Execute/P gotostep
	endif
end