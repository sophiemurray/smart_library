;+
; IDL Version:      7.1.1 (linux x86_64 m64)
; Journal File for:     smurray@eld264
; Working directory:    /data/nwp1/smurray/SMART
; Updated:      2014-10-20
; Purpose:      Modified code originally by P. Higgins  (see run_ar_extract_template2.pro)
;               Detect AR 'Cores' in an HMI magnetogram using SMART2.
;               Use AR_DETECT.PRO to make 'classic' SMART detections.
;               Uses real time 1k images unlike original....
;-

DATA_FOLDER = '/data/nwp1/smurray/SMART/data/'
WEB_FOLDER = '/home/h05/smurray/public_html/SMART_images/'
SMART_FOLDER = '/home/h05/smurray/codes/SMART/trunk/smart_library/'

;Grab latest fits file obtained via python (my machine doesnt like jsoc but idl alternative below!)
fhmi = DATA_FOLDER + 'latest.fits'  ;fhmi='latest.fits'

;;Get latest 1024 x 1024 data set from web
;link = webget("http://jsoc.stanford.edu/data/hmi/fits/latest_fits_time")
;    link = link.text
;    link = STRMID(link, 10)
;    test = webget(link, copyfile = '/data/local/smurray/SMART/latest.fits')

;Set up parameters---------------------------------->

sys_time = systim(/utc)   ;system time
fparam = SMART_FOLDER + 'ar_param_hmi.txt'   ;settings can be edited
params = ar_loadparam(fparam = fparam) ;load settings
strcsvdet = {datafile:'', maskfile:'', date:'', tim:0l, nar:0, status:0}


;Start detecting ARs-------------------------------->

;Read in a fits file (including WCS and full header)
thismap = ar_readmag(fhmi, outindex = indhmi)  
;thismap = map_rebin(thismap,/rebin1k)                 
    imgsz = size(thismap.data)  
    original_time = indhmi.date_obs              
    thisdatafile = time2file(indhmi.date_obs)
;Turn on median filtering due to the noise...  
params.DOMEDIANFILT = 0
params.DOCOSMICRAY = 0

;Process magnetogram
magproc = ar_processmag(thismap, cosmap = cosmap, limbmask = limbmask, $
                        params = params, /nofilter, /nocosmicray)
;Create AR masks - will use core detections
thissm = ar_detect(magproc, params = params, status = smartstatus, $
                        cosmap = cosmap, limbmask = limbmask) ;prob dont need this? 
thisar = ar_detect_core(magproc, smartmask = thissm.data, $
                        cosmap = cosmap, limbmask = limbmask, pslmaskmap = pslmap, $
                        params = params, doplot = debug, $
                        status = corestatus)             
thismask = ar_core2mask(thisar.data, smartmask = coresmblob, $
                        coresmartmask = coresmblob_conn)
    nar = max(thismask) ; no. detections

;Grab position information
posprop = ar_posprop(map = magproc, mask = thismask, $
                        cosmap = cosmap, params = params, $
                        outpos = outpos, outneg = outneg, $
                        /nosigned, status = posstatus, $
                        datafile = thisdatafile)        

;Now calculate magnetic properties 
;Property list: x(y)cena, pos(neg)area, totarea, pos(neg)flx, totflx, bmin(max), bmean
magprop = ar_magprop(map = magproc, mask = thismask, cosmap = cosmap, $ 
                        params = params, fparam = fparam, $ 
                        datafile = thisdatafile, status = magstatus)
    areafrac = (magprop.posareabnd - magprop.negareabnd) / magprop.areabnd
    ;Convert area from Mm^2 to millionths of a solar hemisphere
    ;One millionth of the hemisphere is approximately 3 million square kilometres and 1 Mm^2 = 1e6 km^2 
    totarea_hemi = magprop.totarea / 3.

;Get PSL stuff, e.g., R value and total gradient along PSL
pslprop = ar_pslprop(magproc, thismask, fparam = fparam, param = params, $
                        doproj = 1,  projmaxscale = 1024);, outpslmask = outpslmask)

;;Print S, N, E, W tags for location
; lat_tag = strarr(n_elements(posprop.hglatbnd))   ;S,N
; lon_tag = strarr(n_elements(pospropr.hglonbnd))         ;E,W
; for i = 0, (n_elements(lat_tag) - 1) do begin
;     if (posprop.hglatbnd)(i) LT 0 then lat_tag(i) = 'S'
;     if (posprop.hglatbnd)(i) GT 0 then lat_tag(i) = 'N'
;     if (posprop.hglonbnd)(i) LT 0 then lon_tag(i) = 'E'
;     if (pospropr.hglonbnd)(i) GT 0 then lon_tag(i) = 'W'
; endfor

;For later tracking
thisstrcsvdet = strcsvdet
thisstrcsvdet.datafile = thisdatafile
thisstrcsvdet.maskfile = 'smart_core_'+time2file(indhmi.date_obs)+'.fits'
thisstrcsvdet.date = anytim(indhmi.date_obs,/vms)
thisstrcsvdet.tim = anytim(thisstrcsvdet.date)
thisstrcsvdet.nar = max(thismask)
thisstrcsvdet.status = corestatus


;Save file for later analysis--------------------------------->
save, thisstrcsvdet, thismap, pslmap, thisar, posprop, magprop, pslprop, indhmi, $
    file = DATA_FOLDER + thisdatafile + '.sav'

;Output the results--------------------------------->

;Plot masks - eps for science, jpg for operations!
set_plot, 'ps'  
    !p.charsize = 2
    !p.charthick = 3
    device, file = WEB_FOLDER + 'latest_mask.eps', $ 
                        /encapsulated, color = 1, bits_per_pixel = 8, $
                        xsize = 40, ysize = 40 
    loadct,0,/sil
        tmpmap = thismap 
        tmpmap.data = rot(tmpmap.data, -thismap.roll_angle)        ;correct for rotation   
            plot_map, tmpmap, dmin = -500, dmax = 500       
    setcolors,/sil,/sys
        tmpar = thisar
        tmpar.data = rot(tmpar.data, -thismap.roll_angle)
            plot_map, tmpar, /over, color = !blue, thick = 4
            plot_map, pslmap, /over, color = !cyan, thick = 1
                plots, (posprop.hcxbnd), (posprop.hcybnd), ps = 4, color = !black, thick = 6
                plots, (posprop.hcxbnd), (posprop.hcybnd), ps = 4, color = !red, thick = 3
                xyouts, (posprop.hcxbnd), (posprop.hcybnd), posprop.arid, $
                        color = !black, charthick = 6, charsize = 3, alignment = 0.75
                xyouts, (posprop.hcxbnd), (posprop.hcybnd), posprop.arid, $
                        color = !red, charthick = 3, charsize = 3, alignment = 0.75
;     sharpcorners, thick = 4
    device,/close

;Convert to jpg ;alternatively, could do x2png
spawn, 'convert ' + WEB_FOLDER + 'latest_mask.eps -quality 100 ' + WEB_FOLDER + 'latest_mask.jpg'

;Delete 'latest.fits'
spawn, 'rm ' DATA_FOLDER + 'latest.fits'

;Create a table of values
table = fltarr(9, n_elements(posprop.arid))
    table(0, *) = posprop.arid
    table(1, *) = posprop.hglatbnd
    table(2, *) = posprop.hglonbnd
    table(3, *) = magprop.totflx
    table(4, *) = magprop.totarea
    table(5, *) = magprop.bmin
    table(6, *) = magprop.bmax
    table(7, *) = pslprop.rvalue
    table(8, *) = pslprop.wlsg
header = ['AR', 'Lat', 'Lon', 'Flux_tot', 'Area_tot', 'B_min', 'B_max', 'R value', 'WL_sg']
units = ['#', '+ N', '+ W', 'Mx', 'Mm^2', 'G', 'G', 'Mx', 'G/Mm']
;units = ['#', '+ N', '+ W', 'Mx', 'm.s.h.', 'G', 'G', 'Mx', 'G/Mm']

openw, outunit, WEB_FOLDER + 'latest.txt', /get_lun
    printf, outunit, '-----------------------------------------------------------------------------------------------'
    printf, outunit, header,  FORMAT='((A6,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8))'
    printf, outunit, units,   FORMAT='((A6,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8))'
    printf, outunit, '-----------------------------------------------------------------------------------------------'
    printf, outunit, table,   FORMAT='((I6,   3X, F8.2, 3X, F8.2, 3X, E8.1, 3X, F8.0, 3X, F8.0,   3X, F8.0,   3X, E8.1, 3X, E8.1))'
    printf, outunit, '-----------------------------------------------------------------------------------------------'
    printf, outunit, ' '
    printf, outunit, ' '
    printf, outunit, 'Property description: Heliographic latitude and longitude [degrees]; '
    printf, outunit, '                      Total flux [Maxwell];'
    printf, outunit, '                      Total area [Megameters^2];'
    printf, outunit, '                      Minimum and maximum total field strength [Gauss]; '
    printf, outunit, '                      Schrijver R value [Maxwell];'
    printf, outunit, '                      Falconer''s WL_sg [G/Mm].'
    printf, outunit, ' '
close, outunit
    free_lun, outunit

;Print some stuff out
print, 'Computation time='
print, anytim(systim(/utc)) - anytim(sys_time), 's'

print, 'X,Y arcsecond positions of AR bounding box centers'
print, [transpose(posprop.hcxbnd), transpose(posprop.hcybnd)]


;Get file from 6 hours ago--------------------------------->
tmp_time = addtime(magproc.time, delta_min = -(6*60))
new_time = time2file(tmp_time)

restore, DATA_FOLDER + new_time + '.sav'

;Output the results--------------------------------->
;Save old image
set_plot, 'ps'  
    !p.charsize = 2
    !p.charthick = 3
    device, file = WEB_FOLDER + 'old_mask.eps', $ 
                    /encapsulated, color = 1, bits_per_pixel = 8, $
                    xsize = 40, ysize = 40 
    loadct,0,/sil
        tmpmap = thismap 
        tmpmap.data = rot(tmpmap.data, -thismap.roll_angle)        ;correct for rotation   
            plot_map, tmpmap, dmin = -500, dmax = 500       
    setcolors,/sil,/sys
        tmpar = thisar
        tmpar.data = rot(tmpar.data, -thismap.roll_angle)
            plot_map, tmpar, /over, color = !blue, thick = 4
            plot_map, pslmap, /over, color = !cyan, thick = 1
                plots, (posprop.hcxbnd), (posprop.hcybnd), ps = 4, color = !black, thick = 6
                plots, (posprop.hcxbnd), (posprop.hcybnd), ps = 4, color = !red, thick = 3
                xyouts, (posprop.hcxbnd), (posprop.hcybnd), posprop.arid, $
                            color = !black, charthick = 6, charsize = 3, alignment = 0.75
                xyouts, (posprop.hcxbnd), (posprop.hcybnd), posprop.arid, $
                            color = !red, charthick = 3, charsize = 3, alignment = 0.75
;     sharpcorners, thick = 4
    device,/close

;Convert to jpg 
spawn, 'convert ' + WEB_FOLDER + 'old_mask.eps -quality 100 ' + WEB_FOLDER + 'old_mask.jpg'

;Create table
table = fltarr(9, n_elements(posprop.arid))
    table(0, *) = posprop.arid
    table(1, *) = posprop.hglatbnd
    table(2, *) = posprop.hglonbnd
    table(3, *) = magprop.totflx
    table(4, *) = magprop.totarea
    table(5, *) = magprop.bmin
    table(6, *) = magprop.bmax
    table(7, *) = pslprop.rvalue
    table(8, *) = pslprop.wlsg
header = ['AR', 'Lat', 'Lon', 'Flux_tot', 'Area_tot', 'B_min', 'B_max', 'R value', 'WL_sg']
units = ['#', '+ N', '+ W', 'Mx', 'm.s.h.', 'G', 'G', 'Mx', 'G/Mm']

openw, outunit, '/home/h05/smurray/public_html/SMART_images/old.txt', /get_lun
    printf, outunit, '-----------------------------------------------------------------------------------------------'
    printf, outunit, header,  FORMAT='((A6,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8))'
    printf, outunit, units,   FORMAT='((A6,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8,   3X, A8))'
    printf, outunit, '-----------------------------------------------------------------------------------------------'
    printf, outunit, table,   FORMAT='((I6,   3X, F8.2, 3X, F8.2, 3X, E8.1, 3X, F8.0, 3X, F8.0,   3X, F8.0,   3X, E8.1, 3X, E8.1))'
    printf, outunit, '-----------------------------------------------------------------------------------------------'
    printf, outunit, ' '
    printf, outunit, ' '
    printf, outunit, 'Property description: Heliographic latitude and longitude [degrees]; '
    printf, outunit, '                      Total flux [Maxwell];'
    printf, outunit, '                      Total area [Megameters^2];'
    printf, outunit, '                      Minimum and maximum total field strength [Gauss]; '
    printf, outunit, '                      Schrijver R value [Maxwell];'
    printf, outunit, '                      Falconer''s WL_sg [G/Mm].'
    printf, outunit, ' '
close, outunit
    free_lun, outunit


;Now lets track from 6 hours ago till present time--------------------------------->
ar_evol, tmp_time, new_time

;Delete save file from 7 hours ago as wont need it again...
tmp_time = addtime(magproc.time, delta_min = -(7*60))
new_time = time2file(tmp_time)
spawn, 'rm ' + DATA_FOLDER + new_time + '.sav'

exit
