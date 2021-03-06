;Input a processed data map and mask
;cosine correction for magnetic field values should already be done
;The tot. area, pos. area, neg. area, and
;	total, signed, fractional signed, negative, and positive flux
;	are determined
;
;STATUS = output status array keyword (one status for each AR)
;		0: initialised value
;		7: Everything went swimmingly, and there should be valid magnetic properties for each AR
;		1: No ARs were present in the mask! Should only happen if a blank array was read in

function ar_magprop, map=inmap, mask=inmask, cosmap=incosmap, params=inparams, fparam=fparam, status=status, datafile=indatafile
status=0

mask=inmask
map=inmap

if data_type(inparams) eq 8 then params=inparams $
	else params=ar_loadparam(fparam=fparam) ;get the default SMART parameter list

if n_elements(incosmap) eq 0 then cosmap=ar_cosmap(map) $
	else cosmap=incosmap

pxmmsq=ar_pxscale(map,/mmsqr)
pxcmsq=ar_pxscale(map,/cmsqr)

if n_elements(indatafile) ne 0 then begin
	blankstr={datafile:indatafile[0],arid:0,areabnd:0., posareabnd:0., negareabnd:0., posarea:0., negarea:0., totarea:0., $
          bmax:0d, bmin:0d, bmean:0d, $
          totflx:0., imbflx:0., frcflx:0d, negflx:0., posflx:0.}
endif else begin
	blankstr={arid:0,areabnd:0., posareabnd:0., negareabnd:0., posarea:0., negarea:0., totarea:0., $
          bmax:0d, bmin:0d, bmean:0d, $
          totflx:0., imbflx:0., frcflx:0d, negflx:0., posflx:0.}
endelse


if data_type(mask) ne 8 then begin
   maskstr=map & maskstr.data=mask & mask=maskstr
endif
nmask=max(mask.data)

;Check that there are ARs present in the mask
if nmask eq 0 then begin 
	status=1
	return,blankstr
endif

strarr=replicate(blankstr,nmask)

for i=1,nmask do begin

	strarr[i-1].arid=i

;Zero pixels outside of detection boundary
   thismask=mask.data
   wzero=where(mask.data ne i)
   if wzero[0] ne -1 then $
      thismask[wzero]=0
   
   thisdat=map.data
   if wzero[0] ne -1 then $
      thisdat[wzero]=0

   thisabs=abs(thisdat)

;Where are values within the detection boundary
   wval=where(thismask eq i)
   if wval[0] eq -1 then continue
   
   thismask[wval]=1

   nothresh=0 & nopos=0 & noneg=0 & noposbnd=0 & nonegbnd=0

;stop

;Where values above mag threshold
   wthresh=where(thisabs ge params.magthresh)
   if wthresh[0] eq -1 then nothresh=1
;Where negative values above thresh
   wneg=where(thisdat lt 0 and thisabs ge params.magthresh)
   if wneg[0] eq -1 then noneg=1
;Where positive values above thresh
   wpos=where(thisdat gt 0 and thisabs ge params.magthresh)
   if wpos[0] eq -1 then nopos=1
;Where negative values in boundary
   wnegbnd=where(thisdat lt 0)
   if wnegbnd[0] eq -1 then nonegbnd=1
;Where positive values in boundary
   wposbnd=where(thisdat gt 0)
   if wposbnd[0] eq -1 then noposbnd=1

	strarr[i-1].arid=i

;Magnetic moments calculated for values within boundary [G]
   strarr[i-1].bmax=max(thisdat[wval])
   strarr[i-1].bmin=min(thisdat[wval])
   strarr[i-1].bmean=mean(thisdat[wval])

;Area of detection boundary [Mm^2]
   strarr[i-1].areabnd=total(cosmap*thismask*pxmmsq)
   if not noposbnd then strarr[i-1].posareabnd=total(cosmap[wposbnd]*thismask[wposbnd]*pxmmsq)
   if not nonegbnd then strarr[i-1].negareabnd=total(cosmap[wnegbnd]*thismask[wnegbnd]*pxmmsq)
   if not nopos then strarr[i-1].posarea=total(cosmap[wpos]*thismask[wpos]*pxmmsq)
   if not noneg then strarr[i-1].negarea=total(cosmap[wneg]*thismask[wneg]*pxmmsq)
   if not nothresh then strarr[i-1].totarea=total(cosmap[wthresh]*thismask[wthresh]*pxmmsq)

;Flux measurements [Mx = G cm^2]
   strarr[i-1].totflx=total(cosmap*thismask*pxcmsq*thisabs)
   strarr[i-1].imbflx=total(cosmap*thismask*pxcmsq*thisdat)
   if not noneg then strarr[i-1].negflx=total(cosmap[wneg]*thismask[wneg]*pxcmsq*thisabs[wneg])
   if not nopos then strarr[i-1].posflx=total(cosmap[wpos]*thismask[wpos]*pxcmsq*thisabs[wpos])
   strarr[i-1].frcflx=(strarr[i-1].posflx-strarr[i-1].negflx)/strarr[i-1].totflx



endfor


outstr=strarr

return,outstr

end
