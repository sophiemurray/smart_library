;+
; IDL Version:      7.1.1 (linux x86_64 m64)
; Journal File for:     smurray@eld264
; Working directory:    /data/nwp1/smurray/SMART
; Updated:      2015-05-21
; Purpose:      Tracking evolution of SMART masks over previous 6 hours.
;               First detect AR 'cores' in an HMI magnetogram using SMART2
;               with 'ar_extract_evol_cron.pro'
;               Above procedure calls this one for the evolution plots...
;-

pro ar_evol, tmp_time, new_time

DATA_FOLDER = '/data/nwp1/smurray/SMART/data/'
WEB_FOLDER = '/home/h05/smurray/public_html/SMART_images/'
HOURS = 6

;Load data--------------------------------->
for i = 0, HOURS do begin

    ;Move forward an hour in time
    if i eq 0 then tmp_time = addtime(tmp_time, delta_min = +(0*60)) $
        else tmp_time = addtime(tmp_time, delta_min = +(1*60))
    new_time = time2file(tmp_time) 
        print, new_time

    restore, DATA_FOLDER + new_time + '.sav'

    ;Create structures...
    if i eq 0 then hmiindarr = indhmi[i] $
        else hmiindarr = [hmiindarr, indhmi] 
    if n_elements(detstrarr) eq 0 then detstrarr = thisstrcsvdet $ 
        else detstrarr=[detstrarr, thisstrcsvdet]
    if i eq 0 then maskmaparr = thisar $
        else maskmaparr = [maskmaparr, thisar]
    if i eq 0 then magmaparr = thismap $
        else magmaparr = [magmaparr,thismap]
    if i eq 0 then pslmaparr = pslmap $
        else pslmaparr = [pslmaparr, pslmap]
    if i eq 0 then posproparr = posprop $
        else posproparr = [posproparr, posprop]
    if i eq 0 then magproparr = magprop $
        else magproparr = [magproparr, magprop]
    if i eq 0 then pslproparr = pslprop $
        else pslproparr = [pslproparr, pslprop]

endfor

arstrarr = ar_detstr2arstr(detstrarr, posproparr.datafile)
combine_structs, arstrarr, posproparr, smartmeta

; save, smartmeta, detstrarr, hmiindarr, $
;         maskmaparr, magmaparr, pslmaparr, $
;         posproparr, magproparr, pslproparr, $
;         file = 'save.sav'

;Make maps of the masks
maskdatarr = maskmaparr.data
maskdatarr = ar_core2mask(maskdatarr)
maskmaparr.data = maskdatarr

;Tracking using YAFTA code--------------------------------->
undefine,state
trackstr = ar_track_yafta(state, magstack = magmaparr.data, maskstack = maskmaparr.data, $
                    mdimeta = detstrarr, smartmeta = smartmeta, $
                    params = params, $
                    outsingle = outsingle) ;/doplot

;Unfortunately in Paul's original SMART code theres a specific folder defined in 'ar_setup.pro'
;For now I've replaced it with my path, but need to go back and add it as a keyword, e.g.,
;ar_path = '/data/nwp1/smurray/SMART/smart_library/')

;Start from first file...
narid = detstrarr[0].nar
nfile = 7

;First delete the old figures in case not all are produced
spawn, 'rm ' + WEB_FOLDER + 'evolution_plots/arid*.jpg'

;Loop through each tracked region and produce analysis--------------------------------->
for i = 0, narid - 1 do begin

    print, 'AR No. ', i
    
    arpxx = posproparr[i].XCENBND
    arpxy = posproparr[i].YCENBND
    
    ;Extract the ones I'll need 
    aridint=(maskmaparr[0].data)[arpxx,arpxy]
        arno = string(aridint, format = '(I02)')

    if aridint GT 0. then begin
        wthisarid=where(trackstr.arid eq aridint)
        thisyaftaid=trackstr[wthisarid[0]].YAFTAID
        wthisyaftaid=where(trackstr.YAFTAID eq thisyaftaid)
            arlat = string(posproparr[wthisyaftaid[0]].hglatbnd, format = '(I04)')
            arlon = string(posproparr[wthisyaftaid[0]].hglonbnd, format = '(I04)')
                print, posproparr[wthisyaftaid].xcenbnd
                print, posproparr[wthisyaftaid].ycenbnd

        ;Save plots for each tracked id--------------------------------->

        !p.multi = [0,1,3,0,0]

        ;Position [X1, Y1, X2, Y2] from 0.0 to 1.0
        p1 = [0.15, 0.7, 0.95, 0.95] 
        p2 = [0.15, 0.4, 0.95, 0.65]
        p3 = [0.15, 0.1, 0.95, 0.35]

        !p.thick = 3
        !p.charsize = 3
        !p.charthick = 3

        if n_elements (wthisyaftaid) GT 1. then begin

            set_plot, 'ps'  
            device, file = WEB_FOLDER + 'evolution_plots/' + 'arid_' + arno + '.eps', $ 
                    /encapsulated, color = 1, bits_per_pixel = 8 ;,$
 
                utplot, magmaparr[0:n_elements(wthisyaftaid)-1].time, magproparr[wthisyaftaid].totarea, $
                        /xst, psym = -2, $
                        yrange = [min(magproparr[wthisyaftaid].totarea) - 50, max(magproparr[wthisyaftaid].totarea) + 50], $
                        xTickformat = '(A1)', xtitle = '', ytitle = 'Total Area [Mm^2]', $
                        position = p1, $
                        yticks = 4, $
                        title = detstrarr[0].datafile + ' ' + 'AR No. ' + arno + ' at ' + $
                                arlat + 'N, ' + arlon + 'W'

                utplot, magmaparr[0:n_elements(wthisyaftaid)-1].time, magproparr[wthisyaftaid].totflx, $
                        /xst, psym = -2, $
                        yrange = [min(magproparr[wthisyaftaid].totflx) - 1e21, max(magproparr[wthisyaftaid].totflx) + 1e21], $
                        xTickformat = '(A1)', xtitle = '', ytitle = 'Total Flux [Mx]', $
                        position = p2, $
                        yticks = 4
    
                utplot, magmaparr[0:n_elements(wthisyaftaid)-1].time, pslproparr[wthisyaftaid].rvalue, $
                        /xst, psym = -2, $
                        yrange = [min(pslproparr[wthisyaftaid].rvalue) - 1e3, max(pslproparr[wthisyaftaid].rvalue) + 1e3], $
                        ytitle = textoidl('R Value [Mx]'), $
                        position = p3, $
                        yticks = 4
            device,/close
            set_plot, 'x'

        ;Convert to .jpg
        spawn, 'convert ' + WEB_FOLDER + 'evolution_plots/' + 'arid_' + arno + $
                '.eps -quality 100 ' + WEB_FOLDER + 'evolution_plots/' + 'arid_' + arno + '.jpg'

        endif else begin
            print, 'Skipping, not enough to plot something...'
        endelse

        !p.multi = 0
        
    endif else begin
            print, 'Nothing to track'
    endelse

endfor

;Remove .eps files
spawn, 'rm ' + WEB_FOLDER + 'evolution_plots/arid*.eps'

end

