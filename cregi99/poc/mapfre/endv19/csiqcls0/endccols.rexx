/* REXX EDIT MACRO  */
ADDRESS ISPEXEC
"VGET (VARPFX VNTCCOLS ZCMD) SHARED"
"VGET (ZPANELID ZAPPLID) ASIS"        /* Get current panel (caller) */
MyPanel = ZPANELID
"VPUT (MYPANEL) SHARED"
/* First of all check if we are enabled. */
If VNTCCOLS = E then NOP
else do
 "SETMSG MSG(ENDE173E)"
 return 0
end
parse ARG Option TABLEID             /* get the passed options */
Option = translate(Option)

If Option /= 'NOEDIT' then do        /* CC command used */
 Allowedpanels= 'ENDIE250 ENDIE110'  /* From correct panel ?               */
 if WORDPOS(ZPANELID,Allowedpanels) = 0 then do
  address ISPEXEC "SETMSG MSG(ENDE241I)"
 return
 end
end
else do                              /* We are processing, if we are going to*/
 if WORDPOS(ZPANELID,'ENDIE900') > 0 then return 0 /*Copyelm just dont       */
end

if WORDPOS(ZPANELID,'ENDIE250') > 0 then
AUTOENTR = 'YES'                  /*   we can use Control non-displ enter */
else
AUTOENTR = 'NO'
"VPUT (AUTOENTR) SHARED"             /* Save state of flag for ENDCPARS */

VARPFX = CSDQ   /* default to QuickEdit option prefix */

if Option = 'HELP'
then do
 address ISPEXEC "SETMSG MSG(ENDE240I)"
 return 0
end

if Option = 'RES' then Option = 'RESET'
if Option = 'RESE' then Option = 'RESET'

If Option/='NOEDIT' & Option/='RESET' & OPTION/='' & OPTION/='XXXXX' then do
 xrc = 8
 address ISPEXEC "SETMSG MSG(ENDE248E)"
 return(xrc)
end
IF Option == 'NOEDIT' then do
 NOEDIT = 'YES'
 PX = 0 /*initiate the PX for CCOls one pannel support*/
end
else  NOEDIT = 'NO'

IF Option == 'RESET' then do
 NOEDIT = 'YES'
 RESETARG = 'YES'
end

  "VPUT (RESETARG NOEDIT VARPFX PX) SHARED"
  if TABLEID \= '' then "VPUT (TABLEID) SHARED"

  DSI_RC = LISTDSI("ISPPROF" "FILE")   /* find info on current PROFILE */
  If DSI_RC= 0 then MyProf = sysdsname /* if found we use that... */
  ELSE MyProf = ZUSER".ISPF.ISPPROF"   /* try a common default    */
  Mem = ZAPPLID||VARPFX
  "VPUT (MYPROF MEM) SHARED"
  address ISPEXEC CONTROL ERRORS RETURN
  "EDIT DATASET('"MYPROF"("ZAPPLID||VARPFX")')" ,
       "MACRO(ENDCIMAC) MIXED(NO)"
  If rc > 4  Then                /* Return codes                     */
    Do                           /*  4 - Data not saved (OK)         */
      Say "CCOLS ERROR RC:"rc "from Edit of PROFILE Member."
      Say ""MYPROF"("ZAPPLID||VARPFX")-"
      if RC = 12 then say '-LOCK specified'
      if RC = 14 then do
         say '-Member or sequential data set in use. Verify that the CCOLS'
         say ' edit session is not open in another session.'
         "SETMSG MSG(ENDE174E)"
      end
      if RC = 16 then say '-No members in library'
      if RC = 18 then say '-VSAM processing unavailable'
      if RC = 20 then say '-Severe error'
      RETURN 12  /* this RC will travel thrue ENDIE300 to Bc1Pflow */
    End                          /* 12 - LOCK specified              */
  Return 0                       /* 14 - Member or sequential        */
                                 /*      data set in use             */
                                 /* 16 - No members in library       */
                                 /* 18 - VSAM processing unavailable */
                                 /* 20 - Severe error                */
