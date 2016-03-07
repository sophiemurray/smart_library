;C. Pugh Met Office summer project, S. Murray 2015-07-30
;Get a cropped region for hexa_data_prep to use
;First select what region you want from SMART detection, then output data and coordinates
;FLS: fits file to load
;CROP: data array of cropped region
;xrange: x boundaries of box in arcseconds
;yrange: x boundaries of box in arcseconds
;Example using HMI fits file:
;crop = get_box('latest_mag.fits', xrange = xrange, yrange = yrange)
;Test result:
;fits2map, 'latest_mag.fits', map
;window, 1
;plot_map, map, xrange = xrange, yrange = yrange, dmin = -500, dmax = 500


function get_box, magproc, params, xrange = xrange, yrange = yrange

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

;Grab position information (using my edited version)
posprop = ar_posprop(map = magproc, mask = thismask, $
                        cosmap = cosmap, params = params, $
                        outpos = outpos, outneg = outneg, $
                        /nosigned, status = posstatus, $
                        datafile = thisdatafile)        

;Plot regions to choose one
    loadct,0,/sil
        tmpmap = magproc 
        tmpmap.data = rot(magproc.data,-magproc.roll_angle)     ;correct for rotation   
            plot_map, tmpmap, dmin = -500, dmax = 500       
    setcolors,/sil,/sys
        tmpar = thisar
        tmpar.data = rot(tmpar.data,-magproc.roll_angle)
            plot_map, tmpar, /over, color = !blue, thick = 2
            plot_map, pslmap, /over, color = !cyan, thick = 1
                plots, (posprop.hcxbnd), (posprop.hcybnd), ps = 4, color = !black, thick = 4
                plots, (posprop.hcxbnd), (posprop.hcybnd), ps = 4, color = !red, thick = 1
                xyouts, (posprop.hcxbnd), (posprop.hcybnd), posprop.arid, $
                        color = !black, charthick = 4, charsize = 3, alignment = 0.75
                xyouts, (posprop.hcxbnd), (posprop.hcybnd), posprop.arid, $
                        color = !red, charthick = 1, charsize = 3, alignment = 0.75

;Define what active region you want based on what you just saw in the above plot!
response = 1
print, ''
jump1:print, 'What AR number would you like to crop? Choose from the numbers in the image. Please write an integer!'

read, response
IF VALID_NUM(response,/integer) NE 1 THEN GOTO, jump1

arno = float(response)
IF arno LT 1 THEN GOTO, jump1

i = arno - 1
 
extra = 20. ;How many extra pixels do you want?

xmin = posprop[i].xminbnd & ymin = posprop[i].yminbnd
xmax = posprop[i].xmaxbnd & ymax = posprop[i].ymaxbnd
boxdim = [(xmax - xmin) + extra, (ymax - ymin) + extra]
boxxyc = [posprop[i].xcenbnd, posprop[i].ycenbnd]

crop = ar_box(magproc.data, thismask, arno, $,
				boxxyc = boxxyc, boxdim = boxdim, $
				/plot, $
				outxxyy = outxxyy)

;So you have a cropped active region array (crop), 
;and also the corresponding boundaries from the original (outxxyy)
;But outxxyy in pixels! We need to convert to arseconds...

dx = magproc.dx & dy = magproc.dy
rsun = magproc.rsun
xc = magproc.xc &  yc = magproc.yc
sz = size(magproc.data, /dim)

xminmax = [outxxyy[0], outxxyy[2]]
yminmax = [outxxyy[1], outxxyy[3]]

px2hc, xminmax, yminmax, xrange, yrange, $
		dx = dx, dy = dy, xc = xc, yc = yc, xs = sz[0], ys = sz[1]

return, crop

end
