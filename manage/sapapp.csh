#!/bin/csh
#
# Simple script to start and stop SAP & Diagnostic Agents from the CI 
# in a distributed environment
#
# Requirements:
# This scripts is written based on the following assumptions:
#   1) Diagnostics user is named *dadm.  
#      For example, smdadm for solution manager diagnostics agent.
#   2) Application server hostnames are the same as the CI with ap# appended.
#      For example, smprd is the CI, each app is smprdap#.
#   3) Each application server allows incoming SSH traffic from the CI
#   4) Each application server has a shared ssh key from the CI for <sid>adm
#       so remote SSH calls to each application server as <sid>adm does not
#       require a password.  Although this is not required, it is recommended.

# Check to make sure the SAP environment is set
if ($?ORACLE_SID) then
        set orasid = `echo $ORACLE_SID|tr "[A-Z]" "[a-z]"`adm
else
        set orasid = notorasid
        echo "\033[31mSAP Environment not properly set.  Make sure SAP is installed"
endif

# Only run this script if the user is <sid>adm
if ($USER == $orasid) then

        # Setting up environment variables
        set sidadm = $USER
        set sapexe = $SAPEXE
        set diagadm = `awk '/dadm/' /etc/passwd | awk '{split($0,array,""); print array[1] array[2] array[3] array[4] array[5] array[6]}'`
        set cihost = $HOSTNAME
	set operation = `echo $1|tr "[A-Z" "[a-z]"`

	# Check if user specified how many external application servers
	# should be started.  If value is not specified, 0 is assumed.
	if ($2) then 
		set appcount = $2
	else
		set appcount = 0
	endif

	# Execute process requested by user
	switch ("$operation")
	   case "start" 
		set count = 10
		while ($count > 0)
			echo "\033[36m **START** Operation selected.  SAP SYSTEM $SAPSYSTEMNAME will be STARTED in $count seconds \033[37m"
			@ count--
			sleep 1
		end
		echo "\033[32mStarting CI...\033[37m"
	        echo
        	$sapexe/startsap
		set appnum = $appcount 
		while ( $appnum > 0)
		    echo	
	    	    echo "\033[32mStarting App server ${appnum}...\033[37m"
	       	    ssh $sidadm@${cihost}ap${appnum} $sapexe/startsap
	       	    @ appnum--		
	       	end
		unset $appnum
		unset appnum
		echo
	        echo "\033[32mSAP Application is now started on the CI and App servers\033[37m"
	        echo 
		echo "\033[32mStarting Diagnostic Agent on CI...\033[37m"
		ssh $diagadm@localhost $SAPEXE/startsap SMDA97
                set appnum = $appcount
                while ( $appnum > 0)
                    echo
                    echo "\033[32mStarting Diagnostic Agent on App server ${appnum}...\033[37m"
                    ssh $diagadm@${cihost}ap${appnum} $sapexe/startsap
                    @ appnum--
                end
	        echo
	        echo "\033[32mDiagnostics Agents have been started on the CI and App servers\033[37m"
	        breaksw	
	   case "stop"
		set count = 10
                while ($count > 0)
                        echo "\033[31m\033[31m **STOP** Operation selected.  SAP SYSTEM $SAPSYSTEMNAME will be STOPPED in $count seconds \033[37m"
                        @ count--
                        sleep 1
                end

                set appnum = $appcount
                while ($appnum > 0)
                    echo
                    echo "\033[32mStopping App server ${appnum}...\033[37m"
                    ssh $sidadm@${cihost}ap${appnum} $sapexe/stopsap
                    @ appnum-- 
                end
		unset $appnum
		unset appnum
       		echo
	       	echo "\033[32mStopping CI...\033[37m"
	       	echo
	       	$sapexe/stopsap
       		echo
	       	echo "\033[32mSAP Application is now stopped on the CI and App servers\033[37m"
                set appnum = $appcount
                while ($appnum > 0)
                    echo
                    echo "\033[32mStopping Diagnostic Agent on App server ${appnum}...\033[37m"
                    ssh $diagadm@${cihost}ap${appnum} $sapexe/stopsap SMDA97
                    @ appnum--
                end
		unset appnum
                echo
		echo "\033[32mStopping Diagnostic Agent on CI...\033[37m"
		ssh $diagadm@localhost $SAPEXE/stopsap SMDA97
		echo
		echo "\033[32mDiagnostics Agents have been stopped on the CI and APP servers\033[37m"
                breaksw
	   case * 
		echo "\033[31mInvalid paramaters entered. \033[37m"
		echo "\033[31msyntax: sapapp [start|stop] [# of non-CI app servers] \033[37m"	
		breaksw
	   endsw
else
        echo "\033[31m You are $USER. This script is designed to be run with <sid>adm.  Switch to that user and try again. \033[37m"
endif

