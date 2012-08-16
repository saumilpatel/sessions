#!/bin/bash
#  List of environment variables
#
#   $WORKPATH = Directory containing files for processing
#   $SUBID = Subject ID being processed (this is sometimes needed [but not included] in the path)  
#   $OUTPUTPATH = Matlab Logfile output path
#   $OUTPUT_FILE= Matlab Logfile
#   $LOGFILE = Script logfile
#   $1 .. $9 = Arguments specified in your list.txt file
#
################################ MODIFY ONLY BELOW THIS LINE #############################################


    # Execute MATLAB with no display and redirect output to the MATLAB output file
    # Running the command specified by '-r'.  Once that command is run, then exit MATLAB
    # Any output not associated with the logfile is dumped to /dev/null (nowhere)

	echod "Running inside: $0" >> $LOGFILE
	echod "Workpath: $WORKPATH" >> $LOGFILE

umask 000
matlab_R2011b -nodisplay -logfile "$OUTPUTPATH/$OUTPUT_FILE" -r "populateKalmanAutomatic('`cat $1`'); exit;" 2>&1 >/dev/null


############################## DO NOT MODIFY BELOW THIS POINT ############################################
