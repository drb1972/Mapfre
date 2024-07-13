/* REXX */
 parse arg function
 address ispexec
 "VGET (VAREVNME)"
 "VGET (SYS)"
 "VGET (SBS)"
 "VGET (CIELM)"
 "VGET (TYPEN)"
 "VGET (D)"
 "VGET (E)"
 "VGET (ENV2)"
 "VGET (ELM2)"
 "VGET (APIDSN)"
 "VGET (C1BJC1)"
 "VGET (C1BJC2)"
 "VGET (C1BJC3)"
 "VGET (C1BJC4)"
 apidsn = strip(apidsn,,"'")
 type = 'ALELM'
 path       = ' '
 retern     = ' '
 search     = ' '
 unused     = ' '
 request  = left(type,5)  ,
         || left(path,1) ,
         || left(retern,1) ,
         || left(search,1) ,
         || left(unused,1) ,
         || left(varevnme,8) ,
         || left(d,1) ,
         || left(sys,8) ,
         || left(sbs,8) ,
         || left(CIELM,10) ,
         || left(typen,8) ,
         || left(env2,8) ,
         || left(e,1) ,
         || left(elm2,10)
 status = msg('off')
 address tso
 'alloc fi(ispfile) recfm(f b)',
 'unit(vio) space(1 1) track lrecl(80) blksize(27920) new reus'
 status = msg('on')
 address ispexec
 'ftopen'
 'ftincl EVAPIJOB'
 'ftclose'
 'lminit dataid(did) ddname(ispfile)'
 'edit dataid('did')'
 'lmclose dataid('did')'
 'lmfree  dataid('did')'
 address tso
 'free f(ispfile)'
