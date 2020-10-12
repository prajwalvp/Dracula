# DRACULA - Determining the Rotation Count of Pulsars
A pulsar phase connection method

Code written by Paulo Freire. 

Paper with description of concepts is now online: https://arxiv.org/abs/1802.07211

Updates and instructions by Paulo Freire, based on initial description by Erik Madsen.
Major update (on Oct. 10. 2020): The automatic version of sieve.sh, dracula.sh !

### Instructions (which assume familiarity with TEMPO)

You should have an initial ephemeris (parfile) and set of TOAs (timfile). Place JUMPs around every epoch (each comprising of a group of TOAs) except one. If your initial parfile is reasonable, you should be able to run TEMPO on this and get pretty flat residuals.

Beware of gropups of TOAs close to rotational phase 0.5, some of those can appear at rotational phase -0.5. In that case TEMPO is assuming the wrong rotation count, whenever it happens it cannot converge on an accurate solution. This can be fixed by using PHASE +1 or PHASE -1 statements, as I do in the example timfiles.

If necessary, put an EFAC in your timfile such that this step also results in a reduced chi-squared (henceforce "chi2") of ~1.

Epochs can be joined together by removing JUMPs from the timfile. Try doing this between nearby epochs, while inserting a "PHASE N" (where N is some integer number of phase wraps) between them. Some value of N (maybe 0) will hopefully result in a chi2 ~1, and if this value is unique, changing N by +/-1 should give a chi2 that is considerably larger than 1. In this case, you have unambiguous solution, i.e., you connected that gap. In this case, move to another gap where you feel you can now get a unique (or unambiguous) solution.

Once you reach a stage where, for all unconnected gaps between (connected) TOA sets, you have multiple PHASE wraps giving acceptable fits, you have only ambiguous gaps: in this case you cannot proceed with manual connection. Then you need to use one of the scripts below.

******* First script: sieve.sh *******

Edit sieve.sh. First, enter your TEMPO, basedir, rundir, timfile, and parfile information at the top of the file. Then edit with prev_labels ="0" and next_label="A". Also, edit the threshold for an acceptable solution (2.0 is a reasonable number).
Write "PHASEA" in your TOA list where you have the shortest ambiguous gap, also removing the JUMPs around it, like in this example:

...

JUMP


JUMP

7               1390.000 51582.2548632839670   13.657                 0.00000

7               1390.000 51582.3201388983131   25.329                 0.00000

7               1390.000 51582.3850678691313   16.834                 0.00000

C JUMP

PHASEA

C JUMP

7               1390.000 51589.2534739821375   29.849                 0.00000

7               1390.000 51589.3336799053180   28.445                 0.00000

JUMP


JUMP

...

Run the script. This will find all the acceptable integers for the gap tagged with PHASEA. These are written in file WRAPs.dat, which that tabulates the chi2 for each of these combinations. These are then automatically sorted into a new acc_WRAPs.dat file (the starting acc_WRAPs.dat file, generated automatically and consisting of a single 0). This acc_WRAPs.dat file is copied to acc_WRAPs_A.dat as a record.

Now, in the TOA file, include the tag PHASEB in the nest shortest gap, commenting out the JUMPs around it. Then edit sieve.sh, with prev_labels="0 A" and next_label="B". Run sieve.sh again. Every acceptable combination of PHASEA that was in your acc_WRAPs.dat file will be tested along with a range of PHASEB values. These are determined by finding the minimum of the chi2 parabola in each case. The resulting list of acceptable solutions is sorted into a new version of file acc_WRAPs.dat (this is copied automatically to acc_WRAPs_B.dat).

This is an iterative process. For your third run, prev_labels="0 A B" and next_label="C". With each additional run, these will 'increment' (on the fourht run, they will be " 0 A B C" and "D").

You might find that early on you have relatively few 'acceptable' solutions might balloons out to thousands upon thousands. That's probably OK. Hopefully after a few rounds (which are of the same order as the number of parameters in your initial solution) the number of solutions will stop growing. If the numbers are millions, you can set the chi2 threshold lower, to (for instance) 1.6 instead of 2.0 just so you don't have to wait all day for this to run, you will suddenly see a sharp decrease in the number of solutions.

You might also find that somewhere along the way you need to start fitting an additional parameter in order to keep getting any acceptable solutions. That's simply an edit of your starting parfile.

******* Second script: dracula.sh *******

Using the previous script is a good idea if the number of possible solutions is a few thousands. If it is millions instead, then you have a problem. 
Also, using the previous script requires some manual operation. 

To do things automatically, you can use instead dracula.sh. To use this, you have to edit the names of all the gaps between groups of TOAs in advance in your .tim file, as I did in file 47TucAA.tim - just write C PHASEA in between a pair of JUMPs. Note that the JUMP statements around each PHASE statement should be offset by two lines, because that is what the dracula.sh script assumes, so that it can comment them out properly when needed.

After that, list those gaps in the dracula.sh file. Then, enter your TEMPO, basedir, rundir, timfile, and parfile information at the top of the script (as in the sieve.sh script). Then specify if you're starting from scratch, or if you're using an acc_WRAPs.dat file from a previous run (either made with sieve.sh or with dracula.sh - the formats are 100% compatible). If you're continuing work from sieve.sh, please beware of the required format for the dracula timfile, where all JUMPs are uncommented and all the gap names to which the rotation numbers refer to are commented. Then, finally, make it run!

The dracula.sh routine is superior to sieve.sh in several ways:
- The writing is simpler, more transparent, and overall the script is easier to follow. Part of this is because of the improved logic, and in particular the use of trial.tim as an intermediate file.
- As noted before, it is automatic, very little manual intervention is needed. For each solution, the script not only changes the C PHASEN into PHASE +N statements, but it also comments out the JUMP statements around it as needed. For this, the use of the intermediate file (trial.tim) is very useful. 
- However, the more important improvement, which is pretty fundamental, is to always prioritize the partial solutions with the lowest chi2, no matter how many gaps they connect. This means that, generally, we get to the timing solution much faster, since the partial solutions with low chi2 are statistically more likely. Indeed, if you run this script with 47TucAA.tim and 47TucAA.par, you should see the solution emerge at the 89th tempo call, not after more than 400 tempo calls.

This idea was already described in Freire & Ridolfi (2018), in the last paragraph of section 4.3, the delay in the implementation has to do with the fact that only now did a really simple implementation occur to me.

Two notes about this:
- You don't need to name all the gaps between TOAs in advance, just enough that you think you might get a unique solution. The file 47TucAA.tim is an example of this.
- Note that after determining the solution, the script will keep running. This will determine whether the solution is unique or not. If it is not, then that means you need to name more gaps between TOA groups, and restart from scratch.

The script has three disadvantages relative to sieve.sh:
- If the number of allowed solutions grows a lot, your machine might spend a lot of time with the sorting command.
- With sieve.sh, you know at which phase connection you have reached a unique solution. With dracula.sh, you don't know that in advance, so by deafult you can name all the gaps in your file, except one (the one that does not have two JUMP statements around it).
This is not a problem if connecting the whole data set does not get you outside the maximum chi2 threshold. Whether or not that happens is partly related to the next issue.
- With sieve.sh, you can see when your starting ephemeris might start to become inadequate: all solutions start having high chi2's. In such cases, you need to fit for more parameters that were not necessary in the initial stages (like, e.g., proper motion). With dracula.sh, you have to be pretty sure about the suitability of the set of parameters you're using from the start.

For these reasons, the dracula.sh script does not entirely supersede sieve.sh - both are useful tools with slightly different applications and advantages.

### Known issues

* chi2 can start to blow up to the point where tempo.lis just writes it as a bunch of asterisks, and this confuses the parsing of tempo.lis into sticking your directory listing into WRAPs.dat.
  This can be edited easily in your tempo source code. Search for the words that appear at the end of the tempo.lis in the code, that tells you which part of the code is writing that file. Then change the precision in the writing of the reduced chi2. 

* For sieve. sh there is some manual intervention in this process (editing in the PHASEA, PHASEB,... statements in the TOA list, editing the labels in sieve.sh). 
This issue is avoided by the use of the dracula.sh script.

* The tempo runs waste most of the time repeating many steps, like consulting the Earth rotation tables, solar system ephemerides, etc, until we get to the stage where we have the precise vectors between the telescope at the time of the TOA and the Solar System Barycentre. All of that only needs to be run once. My next step will be to use PINT to do these calculations separately.

* (Erik Madsen): Personally, I'd have written it in Python, but to each their own!
(Paulo Freire): why use python when very simple shell commands do so well??
 

