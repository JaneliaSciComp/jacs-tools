import numpy as np
from time import sleep
import sys
import nrrd

if (len(sys.argv) < 4):
    print 'Error: missing arguments!'
else:

    print 'Checking alignment for ', str(sys.argv[1]), ' against the template (', str(sys.argv[2]), ')...'
  
    sys.stdout.write('Calculating...\n (This may take a while)')
    sys.stdout.flush() 
    
    sleep(0.1)
       
    data1, header1 = nrrd.read(str(sys.argv[2]))
        
    data2, header2 = nrrd.read(str(sys.argv[1])) 
    
    if (data1.size <> data2.size):
        print '\n\nError: Images must be the same size!!'
    else:
    
        Nd1 = np.squeeze(np.asarray(data1.flat,dtype=np.float128))
        Nd2 = np.squeeze(np.asarray(data2.flat,dtype=np.float128))
        
        th = 0
        
        Ta = np.add(Nd1, Nd2)
        Os = len([x for x in Ta if x > th])
        
        Na1 = np.divide(np.sum(Nd1),Os)
        Na2 = np.divide(np.sum(Nd2),Os)
                                            
        r=np.sum(np.multiply(np.subtract(Nd1,Na1),np.subtract(Nd2,Na2)))/np.sqrt(np.multiply(np.sum(np.square(np.subtract(Nd1,Na1))),np.sum(np.square(np.subtract(Nd2,Na2)))))
        
        print 'The alignment has a Object Pearson\'s Coefficient r value of: %0.60f (1=perfect)'% r
        
        print 'Outputing results to ', str(sys.argv[3])
        
        with open(str(sys.argv[3]), "a") as myfile: 
            myfile.write('{0:.6f}'.format(r) + ', Object Pearson Coefficent, ' + str(sys.argv[1]) + ', ' + str(sys.argv[2]) + '\n')
        
        print 'Done.'
        
  
