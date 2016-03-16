#!/bin/sh

### This must be run first, before update_wraps.sh
### Your .tim file must have a "PHASEA" and a "PHASEB" in it
### See the README for more info

# specify version of TEMPO we're using
# path to $TEMPO directory, which contains tempo.cfg, obsys.dat, etc.
TEMPO=
# path to tempo executable
alias tempo=

# Define here wrap limits for JUMPs

# a1 and a2 are the lower and upper limits of the range of trial integer
# phase wraps for PHASEA
a1=
a2=

# b1 and b2 are the lower and upper limits of the range of trial integer
# phase wraps for PHASEB
b1=
b2=

##### YOU SHOULD NOT NEED TO EDIT BEYOND THIS LINE



rm -rf WRAPs.dat

a="$a1"

l=0

while [ "$a" -lt "$a2" ]  # this is loop1
do
   b="$b1"
   while [ "$b" -lt "$b2" ]  # this is loop2
   do
	
      # Make a script for replacing the JUMP flags
      echo "sed 's/PHASEA/PHASE "$a"/' J1913+06.tim  | sed 's/PHASEB/PHASE "$b"/' > trial.tim " > edtim
      # Execute it
      sh edtim
      # Run tempo on this file
      tempo trial.tim -f J1913+06.par -w 
      chi2=`cat tempo.lis | tail -1 | awk '{print $5}'` 
      echo $a $b $chi2 >> WRAPs.dat 

      l=`expr $l + 1`

      b=`expr $b + 1`
   done
   a=`expr $a + 1`
done

sort -nr -k3 WRAPs.dat | grep -v post
echo Made a total of $l trials

exit

