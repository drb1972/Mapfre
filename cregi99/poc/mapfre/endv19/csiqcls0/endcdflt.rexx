/* Rexx - reset columns to default */
address ISREDIT
"MACRO (PARMS)"
"CAPS OFF"
xrc = 0                                /* default Return Code */
ADDRESS ISPEXEC "VGET (CTLITRML VARPFX ZAPPLID) ASIS"
if VARPFX == '' then VARPFX = CSDQ     /* default to QuickEdit option prefix */
GetDflt: /* Get a copy of the default arrangement */
  ADDRESS ISPEXEC "FTOPEN TEMP"
  if rc <> 0 THEN SAY "FTOPEN Error" ZERRSM ZERRLM
  ADDRESS ISPEXEC "FTINCL ENMC"VARPFX" NOFT" /* Default arrangement skeleton */
  if rc <> 0 THEN SAY "FTINCL Error" ZERRSM ZERRLM
  ADDRESS ISPEXEC "FTCLOSE"
  if rc <> 0 THEN SAY "FTClose Error" ZERRSM ZERRLM
  ADDRESS ISPEXEC "VGET (ZTEMPF ZTEMPN)"
  if rc <> 0 THEN SAY "VGET Error" ZERRSM ZERRLM ZTEMPF ZTEMPN
/*
  Note: At this point we should have a temporary copy of the default column
  arrangement in the temporary file and we can just copy it in.  However if
  the ISPF temp fiLe is preallocated We can't just use it's name instead
  we need to read it into a stem variable and so long as we got some records
  can go ahead and delete the original content and isert from the stem vars
*/
address MVS "EXECIO * DISKR" ZTEMPN "(STEM DATA. FINIS"
IF RC ^= 0 | DATA.0 < 1 THEN
Do
  address ISPEXEC "SETMSG MSG(ENDE249E)"
  xrc = 16                               /* set bad RC */
  if DATA.0 < 1 then xrc = 12
  signal fini                            /* set message and exit */
end
DelOld:   /* Delete any old content left lying around */
"BUILTIN RESET"
"DEL NX ALL"
InsDflt:                        /* Insert all default layout lines */
do i = 1 to DATA.0
  if CTLITRML = "J" then do          /* if japanese ensure capital */
    newline = translate(data.i)
    newline = TRANSLATE(newline,'[','¦')
  end
  else newline = data.i
  ADDRESS ISREDIT "LINE_AFTER .ZLAST = DATALINE (NEWLINE)"
end
ShowNote:                     /* add a few notes to help new users */
"BUILTIN RESET"                                    /* insert notes */
if CTLITRML = "J" then "ENDCHELJ" /* If japanese Capital version   */
else "ENDCHELP"              /* English lower case */
fini:
return(xrc)
