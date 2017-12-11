# phase-connect
A pulsar phase connection method

Code written by Paulo Freire

Some minor updates (and these better-than-nothing instructions) by Erik Madsen

### Instructions (which assume familiarity with TEMPO)

You should have an initial ephemeris (parfile) and set of TOAs (timfile). Place JUMPs around every epoch except for one. If your initial parfile is reasonable, you should be able to run TEMPO on this and get pretty flat residuals. If necessary, put an EFAC in your timfile such that this step also results in a reduced chi-squared (henceforce "chi2") of ~1.

Epochs can be joined together by removing JUMPs from the timfile. Try doing this between nearby epochs, while inserting a "PHASE N" (where N is some integer number of phase wraps) between them. Some value of N (maybe 0) will hopefully result in a chi2 ~1, and if this is unambiguous, changing N by +/-1 should give a chi2 that is considerably larger than 1. This should vary parabolically--the issue is whether this parabola is narrow enough to be unambiguous. If it is, keep adding more of these PHASE wraps wherever you feel you can do so unambiguously. Once you reach a point where a range of PHASE wraps at some point seem to give acceptable fits, you are ready to move onto using the script.

Insert "PHASEA" at the position of your ambiguous PHASE wrap and "PHASEB" at another position (always unJUMP-ing the connected epochs relative to one another). Experiment a few times to get a sense of the range of values for PHASE wraps in these two positions that give reasonable fits (chi2 close to 1) and put those ranges into initialize_wraps.sh, along with the required TEMPO information.

Run initialize_wraps.sh. This will run TEMPO with every combination of PHASEA and PHASEB in the specified ranges and output a file called WRAPs.dat that tabulates the chi2 for each of these combinations. Sort this on the chi2 column into a new file called acc_WRAPs.dat (ie, "acceptable wraps"). The command for this is "sort -nk 3 WRAPs.dat > acc_WRAPs.dat". Delete all lines below which chi2 is unacceptably large. This cutoff is up to you. Maybe 2 or 3. Search your soul.

Now we move onto the main script, update_wraps.sh. This is an iterative process. First, enter your TEMPO, basedir, rundir, ephem, and parfile information at the top of the file. Maybe you want to edit chi2_threshold now, maybe not. You might want to reduce it in future runs to speed things up. For your first run, prev_labels should be "A B" and next_label should be "C". With each additional run, these will 'increment' (on the second run, they will be "A B C" and "D").

In your timfile, leave PHASEA and PHASEB, and add a PHASEC (unJUMP-ing the connected epochs relative to one another). Now run update_wraps.sh. Every acceptable combination of PHASEA and PHASEB that was in your acc_WRAPs.dat file will be tested along with a range of PHASEC values. These are determined by finding the minimum of the chi2 parabola in each case. You will be left with a WRAPs.dat file that contains columns for the PHASEA/B/C values, a column with chi2 when using these values, and a final column with the previous chi2 when it was just the PHASEA/B values. Sort on this second-to-last column, save to acc_WRAPs.dat, dump everything beyond your current favourite chi2 cutoff, and go ahead and start working on PHASED (add PHASED into the timfile, increment the prev_labels and next_label).

You might find that early on you have relatively few 'acceptable' solutions and that this balloons out to thousands upon thousands. That's probably OK. There's a reason you've resorted to a brute-force method. Hopefully after a few rounds where the number of solutions seems to be getting exponentially larger and you're now cutting off at chi2 of (for instance) 1.03 instead of 2 just so you don't have to wait all day for this to run, you will suddenly see a sharp decrease in the number of solutions. This is good! Now or maybe a round or two from now you can take the updated parfile output by TEMPO as your new starting parfile, dump all the PHASE wraps from your timfile, and quite possibly finish the phase connection yourself.

You might also find that somewhere along the way you need to start fitting an additional parameter in order to keep getting any acceptable solutions. That's simply an edit of your starting parfile.

OK. Good luck!

### Known issues

I've only gone through this process once (and was successful!) so here's what I ran into, which probably isn't remotely exhaustive.
* chi2 can start to blow up to the point where tempo.lis just writes it as a bunch of asterisks, and this confuses the parsing of tempo.lis into sticking your directory listing into WRAPs.dat. I worked around this by using awk to filter out the lines that had the correct number of columns before sorting the results.
* There is a lot of manual intervention in this process that you will quickly realize could be automated quite easily. This is not a polished, final product. Feel free to make it more awesome. Personally, I'd have written it in Python, but to each their own!

### Unknown issues

* I really don't have a good sense of what the "right" chi2 cutoff is at any point in this process, especially when faced with tens of thousands of solutions with chi2 ranging from 0.97 to 1.03 and tens of thousands more above that. I didn't keep all my acc_WRAPs.dat files, so I don't know how far down the list the correct solution I finally found was at each step. I suspect it was fairly high in the list, though (among the lowest chi2).
