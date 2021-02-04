; This script aims to:
;   1. Create monthly climatologies of each cal-adj simulation
;   2. Compute differences in these climatologies from the piControl climatology
;   3. Regrid each climate difference onto a 1x1 grid
;   4. Combine into an ensemble file

; Required metadata to be taken from each file:
;   tracking_id of piControl file
;   tracking_id of expt file
;   name of model
;   X resolution of model
;   Y resolution of model


DATA_DIR="/data/CMIP/curated_ESGF_replica"
monClim_DIR="../netcdfs/monClim"
annClim_DIR="../netcdfs/annClim"

; Start by creating climatologies on the native grids...
expt_names="lgm-cal-adj piContol lig127k-cal-adj midHolocene-cal-adj midPliocene-eoi400"
var_i="tas pr"

do expt_i = 0,dimsizes(expt_names)-1
  ; determine relevant directories
  dirs=systemfunc("ls -d /data/CMIP/curated_ESGF_replica/*/"+expt_names(expt_i))
  gcm_names=dirs ;set up a holding array of the write size/type
  climo_names=dirs
  ; identify model names
  do gcm_i=0,dimsizes(gcm_names)-1
    str_frags=str_split(dirs(gcm_i),"/")
    gcm_names(gcm_i)=str_frags(3)
    delete(str_frags)
  end do
  ; create monthly climatology
  do gcm_i=0,dimsizes(gcm_names)-1
    fils=systemfunc("ls "+dirs(gcm_i)+"/"+var_i+"*nc")
    ann_fils=str_sub_str(fils,"-cal-adj","")
    print("Working on "+gcm_names(gcm_i))
    print(" files: "+fils)
    print(" ")
    if .not.all(ismissing(fils)) then
      n_files=dimsizes(fils)
      if n_files.ge.2 then
        str_frags=str_split(fils(0),"/")
        f1=str_frags(5)
        climo_names(gcm_i)=str_sub_str(f1,"Amon","annClim")
        climo_names(gcm_i)=str_sub_str(climo_names(gcm_i),"-cal-adj_","_")
        f1_c=stringtocharacter(f1)
        end_yr_f1=tostring(f1_c(str_index_of_substr(f1,".nc", -1)-6:str_index_of_substr(f1,".nc", -1)-1))
        str_frags=str_split(fils(n_files-1),"/")
        fn_c=stringtocharacter(str_frags(5))
        end_yr_fn=tostring(fn_c(str_index_of_substr(str_frags(5),".nc", -1)-6:str_index_of_substr(str_frags(5),".nc", -1)-1))
        climo_names(gcm_i)=str_sub_str(climo_names(gcm_i),end_yr_f1,end_yr_fn)
        system("ncrcat -O "+str_concat(ann_fils+" ")+" "+annClim_DIR+"/"+climo_names(gcm_i)+".all.nc")
        system("ncwa -O -a time "+" "+annClim_DIR+"/"+climo_names(gcm_i)+".all.nc "+annClim_DIR+"/"+climo_names(gcm_i))
        system("rm "+annClim_DIR+"/"+climo_names(gcm_i)+".all.nc")
        climo_names(gcm_i)=str_sub_str(climo_names(gcm_i),"annClim","monClim")
        delete(str_frags)
        system("ncks -O -d time,0,11 "+fils(0)+" "+monClim_DIR+"/"+climo_names(gcm_i))
        infil=addfiles(fils,"r")
        outfil=addfile(monClim_DIR+"/"+climo_names(gcm_i),"w")
        monthly=infil[:]->$var_i$
        monClim=clmMonTLL(monthly)
        outfil->$var_i$=(/monClim/)
        delete([/infil,outfil,monthly,monClim,f1,f1_c,fn_c,end_yr_f1,end_yr_fn/])
      else  
        str_frags=str_split(fils,"/")
        climo_names(gcm_i)=str_sub_str(str_frags(5),"Amon","annClim")
        climo_names(gcm_i)=str_sub_str(climo_names(gcm_i),"-cal-adj_","_")
        system("ncwa -O -a time "+ann_fils+" "+annClim_DIR+"/"+climo_names(gcm_i))
        climo_names(gcm_i)=str_sub_str(climo_names(gcm_i),"annClim","monClim")
        delete(str_frags)
        system("ncks -O -d time,0,11 "+fils+" "+monClim_DIR+"/"+climo_names(gcm_i))
        infil=addfile(fils,"r")
        outfil=addfile(monClim_DIR+"/"+climo_names(gcm_i),"w")
        monthly=infil->$var_i$
        monClim=clmMonTLL(monthly)
        outfil->$var_i$=(/monClim/)
        delete([/infil,outfil,monthly,monClim/])
      end if
    end if
    delete([/fils,ann_fils/])
  end do
end do



;ncecat line
;ncks line to add model name as dimension