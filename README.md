# DRACULA - Determining the Rotation Count of Pulsars
A pulsar phase connection method

Code written by Paulo Freire

Some minor updates (and these better-than-nothing instructions) by Paulo Freire, based on initial description by Erik Madsen.

### Instructions (which assume familiarity with TEMPO)

You should have an initial ephemeris (parfile) and set of TOAs (timfile). Place JUMPs around every epoch (each comprising of a group of TOAs) except for one. If your initial parfile is reasonable, you should be able to run TEMPO on this and get pretty flat residuals. Beware of gropups of TOAs close to rotational phase 0.5, some of those can appear at rotational phase -0.5. In that case TEMPO is assuming the wrong rotation count, whenever it happens it cannot converge on an accurate solution.

If necessary, put an EFAC in your timfile such that this step also results in a reduced chi-squared (henceforce "chi2") of ~1.

Epochs can be joined together by removing JUMPs from the timfile. Try doing this between nearby epochs, while inserting a "PHASE N" (where N is some integer number of phase wraps) between them. Some value of N (maybe 0) will hopefully result in a chi2 ~1, and if this value is unique, changing N by +/-1 should give a chi2 that is considerably larger than 1. In this case, you can keep adding more of these PHASE wraps to other gaps bewtween TOAs where you feel you can get a unique (or unambiguous) solution.

Once you reach a gap where, for all gaps between connected TOA sets, you have multiple PHASE wraps giving acceptable fits, you have an ambiguous gap: you cannot proceed with manual connection. Then you need to use the sieve.sh script.

Edit sieve.sh. First, enter your TEMPO, basedir, rundir, ephem, and parfile information at the top of the file. Then edit with prev_labels ="0" and next_label="A". Also, edit the threshold for an acceptable solution (2.0 is a reasonable number).
Write "PHASEA" in your TOA list where you have the shortest ambiguous gap, also removing the JUMPs around it.

Run the script. This will find all the acceptable integers for the gap tagged with PHASEA. These are written in file WRAPs.dat, which that tabulates the chi2 for each of these combinations. These are then automatically sorted into a new acc_WRAPs.dat file (the starting acc_WRAPs.dat file, generated automatically and consisting of a single 0). This acc_WRAPs.dat file is copied to acc_WRAPs_A.dat as a record.

Now, in the TOA file, include the tag PHASEB in the nest shortest gap, commenting out the JUMPs around it. Then edit sieve.sh, with prev_labels="0 A" and next_label="B". Run sieve.sh again. Every acceptable combination of PHASEA that was in your acc_WRAPs.dat file will be tested along with a range of PHASEB values. These are determined by finding the minimum of the chi2 parabola in each case. The resulting list of acceptable solutions is sorted into a new version of file acc_WRAPs.dat (this is copied automatically to acc_WRAPs_B.dat).

This is an iterative process. For your third run, prev_labels="0 A B" and next_label="C". With each additional run, these will 'increment' (on the fourht run, they will be " 0 A B C" and "D").

You might find that early on you have relatively few 'acceptable' solutions might balloons out to thousands upon thousands. That's probably OK. Hopefully after a few rounds (which are of the same order as the number of parameters in your initial solution) the number of solutions will stop growing. If the numbers are millions, you can set the chi2 threshold lower, to (for instance) 1.6 instead of 2 just so you don't have to wait all day for this to run, you will suddenly see a sharp decrease in the number of solutions.

You might also find that somewhere along the way you need to start fitting an additional parameter in order to keep getting any acceptable solutions. That's simply an edit of your starting parfile.

### Known issues

* chi2 can start to blow up to the point where tempo.lis just writes it as a bunch of asterisks, and this confuses the parsing of tempo.lis into sticking your directory listing into WRAPs.dat.

This is the time where you should start looking at your best solutions using the test_wraps.sh script.

This should be setup as the sieve.sh script. It uses the last acc_WRAPs.dat file. The only thing you need to change in the TOA.file is, instead of inserting a new label like PHASEN, insert a PHASE1 label (which is blind).

* There is a lot of manual intervention in this process that you will quickly realize could be automated quite easily. This is not a polished, final product. Feel free to make it more awesome.

* (Erik Madsen): Personally, I'd have written it in Python, but to each their own!
  (Paulo Freire - will do this soon)

### Unknown issues

* I really don't have a good sense of what the "right" chi2 cutoff is at any point in this process, especially when faced with tens of thousands of solutions with chi2 ranging from 0.97 to 1.03 and tens of thousands more above that.
