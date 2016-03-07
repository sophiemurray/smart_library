; IDL Version 7.1.1 (linux x86_64 m64)
; Journal File for smurray@eld264 (Sophie Murray)
; Working directory: /data/local/smurray/test_set
; Date: Tue Jun 23 13:37:06 2015

; Example of how you would prepare data to run with the HEXA code developed by Uni St. Andrews.
; Contact Duncan Mackay if you want the HEXA code!
; Dont forget to have all needed SMART code and run this under SSWIDL...

; Note, I have processed magnetograms with some codes from SMART (mainly ar_*.pro). All are in the SMART FCM trunk right now.
; Dont necessarily need to use these codes, could do something simpler like:
;   read_sdo, fls, ind, dat
;   index2map, ind, dat, map
;   map = rot_map(map, (-map.roll_angle))
; See SDO tutorials for more tips, e.g., http://helio.cfa.harvard.edu/trace/SSXG/ynsu/Ji/sdo_primer_V1.1.pdf

; I downloaded these 4096x4096 magnetograms from http://sdac.virtualsolar.org/cgi/search 
; Could also go to http://jsoc.stanford.edu/ajax/lookdata.html
; If the internal network here wasnt so aggravating I could use SSWIDL to do this instead! 
; VSO example:
;   result=vso_search('2015-03-17 00:00','2015-03-17 00:30',inst='hmi')
;   log=vso_get(result,out_dirir='data',/rice)                   
; Or connect to JSOC to get near-real-time data used by SMART:                                                          
;   ssw_jsoc_time2data,'12:00 10-jun-2010','13:45 10-jun-2010',index, KEY='wavelnth,exptime,img_type,t_obs, date__obs'
;   ssw_jsoc_time2data,'12:00 12-apr-2015','13:45 12-apr-2015',index, data, $
;        ds='hmi.Ic_noLimbDark_720s_nrt', max_files=1, locfiles= locfiles, outdir_top=temp_path

;28/08/2015 - C. Pugh
;Added code that produces a light curve from AIA 94 data for the 
;specified active region. This can be commented out if the AIA data hasn't been
;downloaded. A separate code to produce the light curves is called aia_lightcurves.pro.

;Using a 96 min cadence for HMI data, and a 12 min cadenece for AIA.
;Ensure the reference time used by drot_map (for HMI) and rot_xy (for AIA) is the time
;at which the AR is half way across the solar disk

pro hexa_data_prep

LOCAL_DIR = '/data/nwp1/cpugh/'

;Select an active region
;Note that this requires HMI data to already be downloaded
    ar = '12335'

ar = 'noaa'+ar

;Load fits files. Files in my local directory on eld264, in theory can use any!
    fls = file_search(LOCAL_DIR + ar + '/HMI/*.fits')
    ;fls = file_search('sftp://xcel00/data/d04/cpugh/' + ar + '/Extract/*.fits')

;Load some SMART settings   
    fparam = LOCAL_DIR + 'smart_library/ar_param_hmi.txt'   ;settings can be edited if create own copy of file
    params = ar_loadparam(fparam = fparam)

;Read in the first fits file (including WCS and full header)
    thismap = ar_readmag(fls[0])        

;Resize to 1024 as dont need 4096 (my computer will be happier)
    thismap = map_rebin(thismap, /rebin1k)

; ;Turn on median filtering due to the noise...              
; params.DOMEDIANFILT = 0
; params.DOCOSMICRAY = 0

;Process magnetogram
    magproc = ar_processmag(thismap, cosmap = cosmap, limbmask = limbmask, $
                params = params, /nofilter, /nocosmicray)

;Create array for other fits files
    magproc_arr = replicate(magproc, n_elements(fls))

;plot_map, magproc_arr, /limb

    for i = 1, n_elements(fls) -1 do begin

        print, i

        thismap = ar_readmag(fls[i])        
        thismap = map_rebin(thismap, /rebin1k)

        magproc = ar_processmag(thismap, cosmap = cosmap, limbmask = limbmask, $
                    params = params, /nofilter, /nocosmicray)
      
        magproc_arr[i] = magproc  

    endfor

;Define a time to rotate all files to, and rotate..
    midpoint  = n_elements(fls)/2
    ;midpoint = 215
    magrot_arr = magproc_arr

    for i = 0, n_elements(fls) -1 do begin

        magrot_arr[i] = drot_map(magproc_arr[i], time = magproc_arr[midpoint].time, /nolimb)

    endfor

;Get xrange and yrange to use to extract region of interest
    crop = get_box(magproc_arr[midpoint], params, xrange = xrng, yrange = yrng)

;Extract region of interest
    sub_map, magrot_arr, magsub_arr, xrange=xrng, yrange=yrng

;wdelete,0

xmovie, magsub_arr.data

;Create save file for HEXA
    data = magsub_arr.data
    ;data = magrot_arr.data
    save, data, file = LOCAL_DIR + ar + '/data.sav'

    time = magproc_arr.time
    save, time, file = LOCAL_DIR + ar + '/time.sav'

;Write xrng and yrng to a file
    OPENW, lun, LOCAL_DIR + ar + '/xyrange.txt', /GET_LUN
    PRINTF, lun, 'X range: ', xrng
    PRINTF, lun, 'Y range: ', yrng
    FREE_LUN, lun

;Write file names used to a file
    OPENW, lun, LOCAL_DIR + ar + '/hmi_filenames.txt', /GET_LUN
    FOR i=0, N_ELEMENTS(fls)-1 DO BEGIN
        PRINTF, lun, i, fls[i], FORMAT='(I, " ", A)'
    ENDFOR
    FREE_LUN, lun

;--------------------------------------------------------------------
; Producing an AIA light curve
;--------------------------------------------------------------------

;Which AIA wavelength is being used
    aia = '94'

;Load fits files
    fls = file_search(LOCAL_DIR+ar+'/AIA'+aia+'/*.fits')
    nf = N_ELEMENTS(fls)

;Read in the fits files (including WCS and full header)

    midpoint = N_ELEMENTS(fls)/2
    ;midpoint = 323

    read_sdo, fls[midpoint], iindex, idata
    aia_prep, iindex, idata, aindex, adata
    ;index2map, ind, dat, map_mid

    xcena = MEAN(xrng)
    ycena = MEAN(yrng)

    xrngp = intarr(n_elements(xrng))
        xrngp[0] = xrng[0]/aindex.cdelt1 + aindex.crpix1 - 1
        xrngp[1] = xrng[1]/aindex.cdelt1 + aindex.crpix1 - 1
    xsizep = abs(xrngp[1] - xrngp[0])
    yrngp = intarr(n_elements(yrng))
        yrngp[0] = yrng[0]/aindex.cdelt1 + aindex.crpix1 - 1
        yrngp[1] = yrng[1]/aindex.cdelt1 + aindex.crpix1 - 1
    ysizep = abs(yrngp[1] - yrngp[0])


    tref = aindex.date_obs


;Resize to 1024
    ;map_mid = map_rebin(map_mid, /rebin1k)
    ;map_mid = drot_map(map_mid, time=map_mid.time)

    ccube = DBLARR(ULONG(xsizep), ULONG(ysizep), nf)
    dcube = STRARR(nf)
    excube = DBLARR(nf)

;Do for the rest!
    FOR i=0, nf-1 DO BEGIN

        PRINT, i
        
        read_sdo, fls[i], cindex, cdata, /nodata
        npos = rot_xy(xcena, ycena, tstart=tref, tend=cindex.date_obs)
        ;Convert from arcseconds to pixels
        xcenp2 = npos(0)/cindex.cdelt1 + cindex.crpix1 - 1
	ycenp2 = npos(1)/cindex.cdelt2 + cindex.crpix2 - 1
	xlo = round(xcenp2 - xsizep/2.0)
	ylo = round(ycenp2 - ysizep/2.0)
	
        read_sdo, fls[i], cindex, cclip, xlo, ylo, xsizep, ysizep
        ;aia_prep, cindex, cclip, cind, cdat
	ccube(*,*,i) = cclip
	dcube(i) = cindex.date_obs
        excube(i) = cindex.exptime

    ENDFOR

    lc = DBLARR(nf)

;Average over each image to create a light curve
    FOR i=0, nf-1 DO BEGIN

        lc[i] = mean(ccube(*,*,i))

    ENDFOR


i = WHERE(excube EQ 0., count)
IF (count GT 0) THEN lc[i] = !values.f_nan
;print, count

good = WHERE(FINITE(lc) EQ 1)
lc[good] /= excube[good]

bad = WHERE(lc LE 0.0, count)
IF (count GT 0) THEN lc[bad] = !values.f_nan

mydevice = !D.NAME
SET_PLOT, 'ps'
DEVICE, filename=ar+'/'+ar+'_aia'+aia+'_lightcurve.eps'
DEVICE, /PORTRAIT, /ENCAPSULATED, /COLOR
DEVICE, XSIZE=6, YSIZE=4, /INCHES

    utplot, dcube, lc, YTITLE='Average Flux', XSTYLE=1

DEVICE, /CLOSE
SET_PLOT, mydevice


;Save time array for plotting later on
    aiatime = dcube
    SAVE, aiatime, file = LOCAL_DIR+ar+'/aiatime.sav'
;And write light curve to file
    OPENW, lun, LOCAL_DIR+ar+'/aia'+aia+'_lightcurve.txt', /GET_LUN
    FOR i=0, N_ELEMENTS(fls)-1 DO PRINTF, lun, lc[i], FORMAT='(E)'
    FREE_LUN, lun


end
