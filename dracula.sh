#!/bin/sh

##### (1) Entries that must be updated each time this script is run

# These include the total list of phase gap identifiers used the .tim file. One could grep them from there, but the order is important.
echo PHASE0 > gaps.txt
echo PHASEA >> gaps.txt
echo PHASEB >> gaps.txt
echo PHASEC >> gaps.txt
echo PHASED >> gaps.txt
echo PHASEE >> gaps.txt
echo PHASEF >> gaps.txt
echo PHASEG >> gaps.txt
echo PHASEH >> gaps.txt
echo PHASEI >> gaps.txt
echo PHASEJ >> gaps.txt
echo PHASEK >> gaps.txt
echo PHASEL >> gaps.txt
echo PHASEM >> gaps.txt


n_gaps=`wc -l < gaps.txt`
# add 1, because we start counters below at 1*/
number_gaps=`expr $n_gaps + 1`

##### (2) Entries that can optionally be updated each time this script is run

# inner loops continue as long as chi2 is below this value
chi2_threshold="2.0"

##### (3) Entries that only need to be set at the beginning

# specify version of TEMPO we're using
# path to $TEMPO directory, which contains tempo.cfg, obsys.dat, etc.
TEMPO=/homes/pfreire/tempo_M2/tempo
# path to tempo executable
alias tempo=$TEMPO/tempo_m2

# specify where we are--this is the directory where we want to write our results.
# Default the directory where script is. This directory must contain the ephemeris, TOA list and acc_WRAPs.dat
basedir=$PWD

# specify where we want to run this (RAM disk, like '/dev/shm/timing/')
rundir=/dev/shm/AA

# specify the files we are going to work with
# (.par and .tim file names--these files should be in your basedir) - DON'T name it "trial.tim"
# Examples given of TOA file and initial ephemeris are given in this repository
ephem=47TucAA.par
timfile=47TucAA.tim
# Name the resulting ephemeris (the top of the previous ephem file, plus .par)
rephem=J0024-7205AA.par

# To start, you must have a acc_WRAPs.dat. If you don't, that means you're starting from scratch. In that case, just make one containing 3 zeros in a line.

n=`wc -l < acc_WRAPs.dat`

##### YOU SHOULD NOT NEED TO EDIT BEYOND THIS LINE

# remove previous rundir, make new one, copy files there and start calculations there

rm -rf $rundir
mkdir $rundir
cp gaps.txt $ephem $timfile $rundir
cp acc_WRAPs.dat $rundir/acc_WRAPs.dat


# go to rundir and start calculation

cd $rundir

start=`date`

#
touch F1_positives.dat

# set the total counter for the number of tempo runs
t=0
# set total counter for the number of tempo runs with chi2 better than the margin
l=0
# set number of solutions found
s=0

# Arbitrary positions we're sampling for finding new solutions
z1=-5
z2=5

if [ "$n" -gt 0 ]
      # this is the outer loop, where we cycle through the acceptable solutions.
      # We'll keep doing this until there is only one solution left
then

    # Let's now find out how many lines we want to do in a row. 1% of the lines is a good target, I think.
    # This will reduce the number of sorts by a factor k. However, it could slightly delay finding the solution.
    if [ "$n" -gt 100000 ]
    then
	k=1000
	k2=1001
    else
	if [ "$n" -gt 10000 ]
	then
	    k=100
	    k2=101
	else
	    if [ "$n" -gt 1000 ]
	    then
		k=10
		k2=11
	    else
		k=1
		k2=2
	    fi	
	fi
    fi

    kc=0

    # *****  decapitate acc_WRAPs.dat by k, so that the first k combinations are not processed again
    tail -n +$k2 acc_WRAPs.dat > WRAPs.dat

    # make smaller file with first k lines

    head -$k acc_WRAPs.dat > top_acc_WRAPs.dat
    
    # Let's now process these k combinations, which are still in acc_WRAPs.dat
    
    while [ "$kc" -lt "$k" ]
    do
	kc=`expr $kc + 1`
	l=`expr $l + 1`

	# ***** First step: read the first line, the one with the lowest chi2
	head -$kc top_acc_WRAPs.dat | tail -1 > line_complete.txt
	
	# Take out two last values to make list with phase numbers only
	awk '{$NF=""; print $0}' line_complete.txt | awk '{$NF=""; print $0}' > line.txt
	
	# Store this in an env. variable
	acc_combination=`cat line.txt`
		
	# *****  Third step: see how long it is.
	length=`wc line.txt | awk '{print $2}'`
	# add 1, because we start counter below at 1*/
	length=`expr $length + 1`
	
	# get the previous chi2 here
	chi2_prev=`awk '{print $'$length'}' line_complete.txt`

	echo Iteration $l, $kc: processing solution $acc_combination, with chi2 = $chi2_prev
	
	# *****  Fourth step: a loop, dictated by the number above, where we replace PHASEA with PHASE +l, and replace the JUMP statements above and below by nothing
	
	# We must start with a clean slate: a trial.tim file that still has all the JUMPs uncommented, and all the PHASEA statements commented
	cp $timfile trial.tim
	
	# Start the loop
	i=1
	while [ "$i" -lt "$length" ]
	do
	    # First, find out which expression is to be replaced 
	    ex_to_replace=`head -$i gaps.txt | tail -1`
	    
	    # Second, find out where it appears in trial.tim file
	    line=`sed -n '/'$ex_to_replace'/=' trial.tim`
	    
	    # Third: get, from line.txt, the phase number to insert
	    phase_number=`awk '{print $'$i'}' line.txt`
	    
	    # For each element in the loop, replace the comented PHASEA statement by an uncommented statement saying PHASE $phase_number
	    # echo Replacing C $ex_to_replace with PHASE $phase_number
	    
	    sed -i 's/C '$ex_to_replace'/PHASE '$phase_number'/g' trial.tim
	    
	    # Now, for two lines before and two lines after, we need to comment the JUMP statements
	    line_jump=`expr $line + 2`
	    sed -i $line_jump's/.*/C JUMP/' trial.tim
	    
	    line_jump=`expr $line - 2`
	    sed -i $line_jump's/.*/C JUMP/' trial.tim
	    
	    # Update the counter #
	    i=`expr $i + 1`	  
	done
		    
	# Now, let's find more gaps for the next phase number. The syntax here is the same as above.
	
	# First, find out which expression is to be replaced 
	ex_to_replace=`head -$i gaps.txt | tail -1`
	
	# Second, find out where it appears in trial.tim file
	line=`sed -n '/'$ex_to_replace'/=' trial.tim`
	
	# Now, uncomment the JUMPs around this
	line_jump=`expr $line + 2`
	sed -i $line_jump's/.*/C JUMP/' trial.tim
	
	line_jump=`expr $line - 2`
	sed -i $line_jump's/.*/C JUMP/' trial.tim
	
	# The trial.tim file is ready. This will be the one we will be repeatedly editing over the next few lines.
	# This will be done into a new file (trial_new.tim), otherwise confusion will reign.
	
	# First, we will test the new gap in 3 points (0, +z, -z). From these three chi2s, we will derive the positions for the best solutions
	
	# ***** Now, calculate the chi2 for PHASE +0
	sed 's/C '$ex_to_replace'/PHASE 0/g' trial.tim > trial_new.tim
	tempo trial_new.tim -f $ephem -w > /dev/null
	t=`expr $t + 1`
	chi2_0=`cat tempo.lis | tail -1 | awk -F= '{print $2}' | awk '{print $1}'`
	
	# Do the same for PHASE $z1
	sed 's/C '$ex_to_replace'/PHASE '$z1'/g' trial.tim > trial_new.tim	
	tempo trial_new.tim -f $ephem -w > /dev/null 
	t=`expr $t + 1`
	chi2_1=`cat tempo.lis | tail -1 | awk -F= '{print $2}' | awk '{print $1}'`
	
	# Do the same for PHASE $z2
	sed 's/C '$ex_to_replace'/PHASE '$z2'/g' trial.tim > trial_new.tim	
	tempo trial_new.tim -f $ephem -w > /dev/null
	t=`expr $t + 1`
	chi2_2=`cat tempo.lis | tail -1 | awk -F= '{print $2}' | awk '{print $1}'`
	
	# determine position of minimum (this should be reasonably accurate) by estimating minimum of parabola defined by 0, z1, z2
	
	min=`echo 'scale=0 ; ( '$z2'^2 *('$chi2_0' - '$chi2_1') + '$z1'^2*(-'$chi2_0' + '$chi2_2')) / (2.*('$z2'*('$chi2_0' - '$chi2_1') + '$z1'*(-'$chi2_0' + '$chi2_2'))) / 1.0 ' | bc -l`
	
	# Now, let's calculate the chi2 for the best (minimum) phase
	
	sed 's/C '$ex_to_replace'/PHASE '$min'/g' trial.tim > trial_new.tim
        tempo trial_new.tim -f $ephem -w > /dev/null 
	t=`expr $t + 1`
        chi2=`cat tempo.lis | tail -1 | awk -F= '{print $2}' | awk '{print $1}'`
	# check whether the F1 is negative to more than 2 sigma
	# f=`grep F1 $rephem | awk '{print $2"/"$4" < 2.0"}' | bc -l`
	# Line commented out, because we are in a GC
	f=1
	
	# Comparison between two real numbers
	chi=`echo $chi2' < '$chi2_threshold | bc -l`
	
	# If chi2 is smaller than threshold, write to WRAPs.dat
	if [ "$chi" -eq "1" ]
	then
	    if [ "$f" -eq "1" ]
	    then
		
		# If the number of gaps connected by new solution is the same as the number of gaps, then notify user of the solution
		if [ "$i" -eq "$n_gaps" ]
		then
		    echo $acc_combination $min $chi2 $chi2_prev > $basedir/solution_$l.$min.dat
		    cp $rephem $basedir/solution_$l.$min.par
		    # Let user know a solution has been found
		    echo "" | mail -s "Solution found" pfreire@mpifr-bonn.mpg.de -A $rephem
		    s=`expr $s + 1`
		else
		    # If number of connections is smaller, then just write solution to WRAPs.dat
		    echo $acc_combination, $min : chi2 = $chi2
		    echo $acc_combination $min $chi2 $chi2_prev >> WRAPs.dat
		fi
		
	    else
		echo "F1 is positive to more than 2 sigma"
		echo $acc_combination $z $chi2 $chi2_prev >> F1_positives.dat
	    fi
	    
        else
	    echo "chi2 too large"
        fi
	
	# **************** Do cycle going up in phase count
	
	z=`expr $min + 1`
	chi=1
	while [ "$chi" -eq 1 ]
	do
	    
	    sed 's/C '$ex_to_replace'/PHASE '$z'/g' trial.tim > trial_new.tim	    
	    tempo trial_new.tim -f $ephem -w > /dev/null
	    t=`expr $t + 1`
	    chi2=`cat tempo.lis | tail -1 | awk -F= '{print $2}' | awk '{print $1}'`
	    # check whether the F1 is negative to more than 2 sigma
	    # f=`grep F1 $rephem | awk '{print $2"/"$4" < 2.0"}' | bc -l`
	    # Line commented out, because we are in a GC
	    f=1
	    
	    # comparison between two real numbers
	    chi=`echo $chi2' < '$chi2_threshold | bc -l` 
	    
	    # If chi2 is smaller than threshold, write to WRAPs.dat
	    if [ "$chi" -eq "1" ]
	    then
		if [ "$f" -eq "1" ]
		then
		    # If the number of gaps connected by new solution is the same as the number of gaps, then notify user of the solution
		    if [ "$i" -eq "$n_gaps" ]
		    then
			echo $acc_combination $z $chi2 $chi2_prev > $basedir/solution_$l.$z.dat
			cp $rephem $basedir/solution_$l.$z.par
			# Let user know a solution has been found
			echo "" | mail -s "Solution found" pfreire@mpifr-bonn.mpg.de -A $rephem
			s=`expr $s + 1`
		    else
			# If number of connections is smaller, then just write solution to WRAPs.dat
			echo $acc_combination, $z : chi2 = $chi2
			echo $acc_combination $z $chi2 $chi2_prev >> WRAPs.dat
		    fi			
		    
		else
		    echo "F1 is positive to more than 2 sigma"
		    echo $acc_combination $z $chi2 $chi2_prev >> F1_positives.dat;
		fi
	    else
		echo "chi2 too large"
	    fi
	    
	    z=`expr $z + 1`
	done
	
	# **************** Do cycle going down in phase count
	
	z=`expr $min - 1`
	chi=1   
	while [ "$chi" -eq 1 ]
	do	 
	    
	    sed 's/C '$ex_to_replace'/PHASE '$z'/g' trial.tim > trial_new.tim	    
	    tempo trial_new.tim -f $ephem -w > /dev/null
	    t=`expr $t + 1`
	    chi2=`cat tempo.lis | tail -1 | awk -F= '{print $2}' | awk '{print $1}'`
	    # check whether the F1 is negative to more than 2 sigma
	    # f=`grep F1 $rephem | awk '{print $2"/"$4" < 2.0"}' | bc -l`
	    # Line commented out, because we are in a GC
	    f=1
	    
	    # Comparison between two real numbers
	    chi=`echo $chi2' < '$chi2_threshold | bc -l`
	    
	    # If chi2 is smaller than threshold, write to WRAPs.dat
	    if [ "$chi" -eq "1" ]
	    then
		if [ "$f" -eq "1" ]
		then
		    # If the number of gaps connected by new solution is the same as the number of gaps, then notify user of the solution
		    if [ "$i" -eq "$n_gaps" ]
		    then
			echo $acc_combination $z $chi2 $chi2_prev > $basedir/solution_$l.$z.dat
			cp $rephem $basedir/solution_$l.$z.par
			# Let user know a solution has been found
			echo "" | mail -s "Solution found" pfreire@mpifr-bonn.mpg.de -A $rephem
			s=`expr $s + 1`
		    else
			# If number of connections is smaller, then just write solution to WRAPs.dat
			echo $acc_combination, $z : chi2 = $chi2
			echo $acc_combination $z $chi2 $chi2_prev >> WRAPs.dat
		    fi			
		    
		else
		    echo "F1 is positive to more than 2 sigma"
		    echo $acc_combination $z $chi2 $chi2_prev >> F1_positives.dat
		fi
	    else
		echo "chi2 too large"
	    fi
	    
	    z=`expr $z - 1`
	done
	
    done
    
    # re-make acc_WRAPs.dat for next k cycle.
    # This is done by sorting on the penultimate column, which has the chi2 from the previous work

    awk '{print $(NF-1)" "$0}' WRAPs.dat | sort -n | cut -f2- -d' '  > acc_WRAPs.dat

    echo Did the sort.

    # The file is built by sorting WRAPs.dat, which has the partial solutions not processed in the previous loop,
    # plus the new solutions found during the last loop.

    # Let's now save one's work, in case there are problems with the computer
    if [ "$k" -gt "10" ]
    then
	cp acc_WRAPs.dat $basedir
    fi

    # Update n with number of remaining solutions
    
    n=`wc -l < acc_WRAPs.dat`
else
    echo "Your file acc_WRAPs.dat is empty"
fi

end=`date`

# At this stage, acc_WRAPs.dat should be empty. What we can do is to make a new one from the solution(s) found, in order to continue work
# Either with extra gap tags in same data set, or with new ones around a new data set. 
cat solution_*dat | awk '{print $(NF-1)" "$0}' | sort -n | cut -f2- -d' ' > acc_WRAPs.dat

# cd report on what's been done

echo Made a total of $t trials
echo Of those, a total of $l unique solutions had reduced chi2s smaller than $chi2_threshold,
echo  which for that were stored and processed further.
echo Found $s solution
echo Started $start
echo Ended $end

exit

