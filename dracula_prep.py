import sys
import string
import subprocess
import shutil
import numpy as np
import optparse

all_caps = list(string.ascii_uppercase)

def line_prepender(input_file, line):
    """
    Append specific lines to file of interest at the beginning of file
    """

    with open(input_file, 'r+') as f:
        content = f.read()
        f.seek(0, 0)
        f.write(line.rstrip('\r\n') + '\n' + content)


def add_jumps_and_gaps_unshuffled(input_file):
    """
    Add jumps and gaps sequentially 
    """

    with open(input_file) as f:
        data = f.readlines()
    cnt=0
    for i, line in enumerate(data):
        if i==0:
            mjd_day = int(float(line.split()[2]))
            mjd_day_float = float(line.split()[2])
        if int(float(line.split()[2])) == mjd_day:
            continue
        elif float(line.split()[2]) - mjd_day_float < 0.04167:
            continue
        else:
            mjd_day = int(float(line.split()[2]))
            mjd_day_float = float(line.split()[2])
            data.insert(i, "JUMP\n\nC GAP{}\n\nJUMP".format(all_caps[cnt]))
            cnt+=1

    f = open(input_file, "w")
    contents = "".join(data)
    f.write(contents)
    f.close()

def add_jumps_and_shuffle_gaps(input_file):
    """
    Shuffle the gaps
    """
    index_gaps=[]
    day_gaps=[]

    with open(input_file) as f:
        data = f.readlines()

    cnt=0

    for i, line in enumerate(data):
        if i==0:
            mjd_day = int(float(line.split()[2]))
            mjd_day_float = float(line.split()[2])
        if int(float(line.split()[2])) == mjd_day:
            continue
        elif float(line.split()[2]) - mjd_day_float < 0.04167:
            continue
        else:
            mjd_day = int(float(line.split()[2]))
            mjd_day_float = float(line.split()[2])
            index_gaps.append(i)
            day_gaps.append(float(line.split()[2])-float(data[i-1].split()[2]))    

    r_caps = all_caps[:len(index_gaps)]
    inds = np.argsort(np.array(day_gaps, dtype=float).argsort())  
    

    for i, line in enumerate(data):
        if i==0:
            mjd_day = int(float(line.split()[2]))
            mjd_day_float = float(line.split()[2])
        if int(float(line.split()[2])) == mjd_day:
            continue
        elif float(line.split()[2]) - mjd_day_float < 0.04167:
            continue
        else:
            mjd_day = int(float(line.split()[2]))
            mjd_day_float = float(line.split()[2])
            data.insert(i, "JUMP\n\nC GAP{}\n\nJUMP\n".format(np.array(r_caps)[inds][cnt]))
            cnt+=1
    
    
    f = open(input_file, "w")
    contents = "".join(data)
    f.write(contents)
    f.close()

if __name__ == "__main__":
    parser = optparse.OptionParser()
    parser.add_option('--input_tim', type=str, help = 'Input tim filename to make it  Dracula compatible', dest='input_tim')
    parser.add_option('--output_tim', type=str, help = 'Output tim filename ready for Dracula run', dest='output_tim', default='dracula_ready.tim')
    parser.add_option('--add_efac', type=str, help = 'Add EFAC value to tim file', dest='efac', default='0')
    parser.add_option('--shuffle', type=int, help = 'Shuffle the gaps such that closer spaced gaps are phase connected first', dest='shuffled', default=0)
    parser.add_option('--line_number', type=int, help = 'Line number to use as reference epoch to jump to', dest='line_number', default=1)
    opts, args = parser.parse_args()

    # Create a copy of the original tim file
    try:
        shutil.copy(opts.input_tim, opts.output_tim)
        print("Created copy of input tim file successfully.")
 
    # If source and destination are same
    except shutil.SameFileError:
        print("Source and destination represents the same file.")


    # Sort rows based on MJD chronologically
    subprocess.check_call("sort -k 3,3 {} > {}".format(opts.input_tim, opts.output_tim), shell=True)

    # Add jumps and gaps and shuffle if needed
    if opts.shuffled:
        print("Adding jumps and shuffling gaps..")
        subprocess.check_call("cat {}".format(opts.output_tim), shell=True)
        add_jumps_and_shuffle_gaps(opts.output_tim)
    else:
        print("Adding jumps and gaps sequentially..")
        add_jumps_and_gaps_unshuffled(opts.output_tim)     

    # Add Mode and first Jump to file
    if opts.efac=='0':
        line_prepender(opts.output_tim, "MODE 1\n\nJUMP")
    else:
        line_prepender(opts.output_tim, "MODE 1\n\nEFAC {}\n\nJUMP".format(opts.efac))

    # Append GAP0 and reference epoch to jump to
    with open(opts.input_tim,'r') as f:
        lines = f.readlines()
        ref_epoch = lines[opts.line_number-1] 
    f.close()
    with open(opts.output_tim, 'a') as f:
        f.write("JUMP\n\n{}\nC JUMP\n\nC GAP0\n\nC JUMP".format(ref_epoch))
    f.close()
