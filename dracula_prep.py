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

def get_output_list(ref_ind, no_of_gaps):
   """
   Generate gap list based on reference index starting point and going sequentially on either side
   """
   r_caps = all_caps[:no_of_gaps]  
   new_seq = list(r_caps)
   
   # Fill reference point in new sequence array
   new_seq[ref_ind] = r_caps[0]  
   ref_cnt=1
   ptr=1
   sign=1
   # Now alternate back and forth about this point till all gaps are used
   for i in range(len(new_seq)):
       sign=1
       if ref_ind < ref_cnt:
          sign=sign*-1
          new_seq[ref_ind-sign*ref_cnt] = r_caps[ptr]
          print('ul',ref_ind-sign*ref_cnt, ptr)
          if ptr+1==len(new_seq):
              break
          for ll in (ptr+1, len(new_seq)):
              ref_cnt+=1
              #new_seq[ref_ind-sign*ref_cnt] = r_caps[l]         
              #print('ul_loop', ref_ind-sign*ref_cnt, ll)
          break   
                       
       try:
           new_seq[ref_ind-sign*ref_cnt] = r_caps[ptr]
           #print("t", ref_ind-sign*ref_cnt, ptr)
           ptr+=1
           if ptr==len(new_seq):
               break
           try:
               sign=sign*-1
               
               new_seq[ref_ind-sign*ref_cnt] = r_caps[ptr]
               #print('tt', ref_ind-sign*ref_cnt, ptr)
               ptr+=1
           except IndexError:
               sign=sign*-1
               ref_cnt+=1
               new_seq[ref_ind-sign*ref_cnt] = r_caps[ptr]
               #print('tte', ref_ind-sign*ref_cnt, ptr)
               if ptr+1==len(new_seq):
                   break
               for j in range(ptr+1, len(new_seq)):
                   ref_cnt+=1
                   new_seq[ref_ind-sign*ref_cnt] = r_caps[j]         
                   #print('tte_loop', ref_ind-sign*ref_cnt, j)
               break
       except IndexError:
           sign=sign*-1
           new_seq[ref_ind-sign*ref_cnt] = r_caps[ptr]
           #print('e', ref_ind-sign*ref_cnt, ptr)
           if ptr+1==len(new_seq):
               break           
           for k in range(ptr+1,len(new_seq)):
               ref_cnt+=1
               new_seq[ref_ind-sign*ref_cnt] = r_caps[k]
               #print('e_loop', ref_ind-sign*ref_cnt, k)
           break

       ref_cnt+=1
        

   return new_seq

def add_jumps_and_gaps_from_ref(input_file):
    """
    After jumps, add gaps back and forth about a reference point selected based on closest spaced epochs
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

    ref_ind = np.argmin(day_gaps)
    no_of_gaps = len(index_gaps)
   
    # Generate necessary sequence from reference
    new_seq = get_output_list(ref_ind, no_of_gaps)       

    gap_cnt=0
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
            data.insert(i, "JUMP\n\nC GAP{}\n\nJUMP\n".format(new_seq[gap_cnt]))
            gap_cnt+=1

    f = open(input_file, "w")
    contents = "".join(data)
    f.write(contents)
    f.close()
 
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
            data.insert(i, "JUMP\n\nC GAP{}\n\nJUMP\n".format(all_caps[cnt]))
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
    parser.add_option('--output_tim', type=str, help = 'Output tim filename ready for Dracula run (Default: dracula_ready.tim)', dest='output_tim', default='dracula_ready.tim')
    parser.add_option('--add_efac', type=str, help = 'Add EFAC value to tim file (Default: No EFAC will be added)', dest='efac', default='0')
    parser.add_option('--optimise', type=int, help = 'Choose either 0,1,2.\n 0. No optimisation, put gaps sequentially \n 1. Shuffle the gaps such that closer spaced gaps are phase connected first  \n 2. Add gaps back and forth about reference epoch   (Default 0)', dest='optimise', default=0)
    parser.add_option('--line_number', type=int, help = 'Line number of input tim to use as reference epoch to jump to (Default 1)', dest='line_number', default=1)
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

    # Add jumps and gaps based on selected option
    if opts.optimise==0:
        print("Adding jumps and gaps sequentially..")
        add_jumps_and_gaps_unshuffled(opts.output_tim)     
    elif opts.optimise==1:
        print("Adding jumps and inserting gaps in ascending order of close spaced epochs....")
        #subprocess.check_call("cat {}".format(opts.output_tim), shell=True)
        add_jumps_and_shuffle_gaps(opts.output_tim)
    elif opts.optimise==2:
        print("Adding jumps. Gaps will be back and forth around the closest spaced epoch")
        #subprocess.check_call("cat {}".format(opts.output_tim), shell=True)
        add_jumps_and_gaps_from_ref(opts.output_tim)
    else:
        raise Exception("Invalid option. Choose either 0,1 or 2")

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
        f.write("JUMP\n\n{}C JUMP\n\nC GAP0\n\nC JUMP".format(ref_epoch))
    f.close()
