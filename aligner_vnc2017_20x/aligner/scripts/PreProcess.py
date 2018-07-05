import numpy as np
import sys, os
import nrrd

if (len(sys.argv) < 3):
    print 'Error: missing arguments!' 
    print 'e.g. python PreProcess.py image_ch1.nrrd image_ch2.nrrd [C #]' # t or tC = test run with no save.
else:
            
    print 'Processing %s and %s...'% (str(sys.argv[1]), str(sys.argv[2]))
    data1, header1 = nrrd.read(str(sys.argv[1]))
    data2, header2 = nrrd.read(str(sys.argv[2]))
    size = np.array(data1.shape) -1
    print 'Image size is %s pixels.'% str(data2.shape)
    
    c = -1
    
    testrun = False
    
    if (len(sys.argv) > 3):
        if ('T' in str(sys.argv[3]).upper()):
            testrun = True
            print 'Test run...'
        if ('C' in str(sys.argv[3]).upper()):
            try:
                c = int(sys.argv[4])
            except ValueError:
                print 'Problem with given clipping threshold (must be an integer) using 0'
                c = 0 
        
            
    else:
        testrun = False
        
    
   
    
    s = 2
    h = s + 1
    d = 10
    
    d1 = int(round(size[0] / s))
    d2 = int(round(size[1] / s))
    d3 = int(round(size[2] / h))
 
    Rs1 = np.zeros([s])
    Rs2 = np.zeros([s])
    
    Rs1[0] = np.sum(data1[d1-d:d1+d,d2-d:d2+d,0:d3])
    Rs1[1] = np.sum(data1[d1-d:d1+d,d2-d:d2+d,s*d3:])
    Rs2[0] = np.sum(data2[d1-d:d1+d,d2-d:d2+d,0:d3])
    Rs2[1] = np.sum(data2[d1-d:d1+d,d2-d:d2+d,s*d3:])
    
    if testrun:
        print 'Results:'
        print Rs1
        print Rs2
    
    #Cliping edges below threashold value c     
    if (c > -1):     
        
        Cl = 0
        Cr = size[0]-1
        Ct = 0    
        Cb = size[1]-1
        Cv = 0
        Cd = size[2]-1  
        
        #left        
            
        for y in range(1,d1):
            if ((np.max(data1[0:y,0:,0:]) < c ) and (np.max(data2[0:y,0:,0:]) < c )): 
                Cl = y
            else:
                if testrun: print Cl
                break
        
        #right
        
        for y in range(size[0],d1,-1):
            if ((np.max(data1[y:,0:,0:]) < c ) and (np.max(data2[y:,0:,0:]) < c )): 
                Cr = y
            else:
                if testrun: print Cr
                break
        
        #top / anterior 
        
        for x in range(1,d2):
            if ((np.max(data1[0:,0:x,0:]) < c ) and (np.max(data2[0:,0:x,0:]) < c )): 
                Ct = x
            else:
                if testrun: print Ct
                break
        
        #bottom / posterior
        
        for x in range(size[1],d2,-1):
            if ((np.max(data1[0:,x:,0:]) < c ) and (np.max(data2[0:,x:,0:]) < c )): 
                Cb = x
            else:
                if testrun: print Cb
                break
                
        #ventral 
                
        for z in range(1,d3):
            if ((np.max(data1[0:,0:,0:z]) < c ) and (np.max(data2[0:,0:,0:z]) < c )): 
                Cv = z
            else:
                if testrun: print Cv
                break
        
        #dorsal
        
        for z in range(size[2],d3,-1):
            if ((np.max(data1[0:,0:,z:]) < c ) and (np.max(data2[0:,0:,z:]) < c )): 
                Cd = z
            else:
                if testrun: print Cd
                break
        
        data1c =data1[Cl:Cr,Ct:Cb,Cv:Cd]
        data2c =data2[Cl:Cr,Ct:Cb,Cv:Cd]
        
        if testrun:
            print 'Clipping both images from %s to %s...'% (str(data1.shape), str(data1c.shape))
            print 'Results saved to ClippedImageTestC[1,2].nrrd as test run...'
            nrrd.write('ClippedImageTestC1.nrrd', data1c, options=header1)
            nrrd.write('ClippedImageTestC2.nrrd', data2c, options=header2)
        else:
            print 'Clipping both images from %s to %s and saving...'% (str(data1.shape), str(data1c.shape))
            header1['sizes']=data1c.shape
            header2['sizes']=data2c.shape
            nrrd.write(str(sys.argv[1]), data1c, options=header1)
            nrrd.write(str(sys.argv[2]), data2c, options=header2)
            data1 = data1c
            data2 = data2c
    
    if ( ((Rs2[0] > Rs2[1]) and (np.sum(Rs1) <= (1.5 * np.sum(Rs2)))) or ((Rs1[0] > Rs1[1]) and (np.sum(Rs1) > (1.5 * np.sum(Rs2))))):
        print 'Flip required in Z axis'
        data1 = np.flipud(data1)
        data2 = np.flipud(data2)
        if not testrun:
            print 'Saving result to %s...'% str(sys.argv[1])
            nrrd.write(str(sys.argv[1]), data1, options=header1)
            print 'Saving result to %s...'% str(sys.argv[2])
            nrrd.write(str(sys.argv[2]), data2, options=header2)
            print 'Files saved - OK'
        else:
            print 'Changes not saved as just a test run.'
#       Recalculate signal values after flip to ensure accurate BG/SG choice    
        Rs1[0] = np.sum(data1[d1-d:d1+d,d2-d:d2+d,0:d3])
        Rs1[1] = np.sum(data1[d1-d:d1+d,d2-d:d2+d,s*d3:])
        Rs2[0] = np.sum(data2[d1-d:d1+d,d2-d:d2+d,0:d3])
        Rs2[1] = np.sum(data2[d1-d:d1+d,d2-d:d2+d,s*d3:])
    
    if (np.sum(Rs1) > (1.5 * np.sum(Rs2))):   #1.5 times bias required to swap from default
        print 'BG: C1\nSG: C2'
        if not testrun:
            os.rename(str(sys.argv[1]),str(sys.argv[1]).replace('_C1.nrrd','_BG.nrrd'))
            os.rename(str(sys.argv[2]),str(sys.argv[2]).replace('_C2.nrrd','_SG.nrrd'))
            print 'Files renamed - OK'
        else:
            print 'Changes not saved as just a test run.'
    else:
        print 'BG: C2\nSG: C1'
        if not testrun:
            os.rename(str(sys.argv[1]),str(sys.argv[1]).replace('_C1.nrrd','_SG.nrrd'))
            os.rename(str(sys.argv[2]),str(sys.argv[2]).replace('_C2.nrrd','_BG.nrrd'))
            print 'Files renamed - OK'
        else:
            print 'Changes not saved as just a test run.'

print 'Done.'
