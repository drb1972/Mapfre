/* Rexx *******************************************************************/
/* ENDCIMAC is used in ENDCCOLS for editing the member CTLICSDQ in the    */
/* user.ISPF.ISPFPROF library.                                            */
/* Main goal is definition of programs, comands and the decision if we    */
/* to save the member or not.                                             */
/*                                                                        */
/* Called-via CCOLS command from the ISPF command table CTLICMDS          */
/*       -From ENDIE300 assembler where the ESL table buildup use to be.  */
/*                                                                     */
/**************************************************************************/
sa=  ENDCIMAC
address ISREDIT
"MACRO (PARMS)"
"BUILTIN RESET" /* reset any warnings  */
address ISPEXEC "VGET (NOEDIT RESETARG) SHARED"
address ISPEXEC "VGET (CTLITRML) ASIS"
if CTLITRML /= "J" then "HILITE OTHER"   /* If japanese Capital version   */
SetCmds:
"DEFINE  ENDCDFLT MACRO"                 /* Reset data to default values     */
"DEFINE  ENDCPARS MACRO"                 /* Main parser of CCOLS.            */
"DEFINE  ENDCHELP MACRO"                 /* Insertts NOTES to the edit sessio*/
"DEFINE  ENDCHELJ MACRO"                 /* Insertts NOTES to the edit sessio*/
"DEFINE 'END'     ALIAS ENDCPARS"        /* Call parser in the case of END   */
"DEFINE 'SAVE'    ALIAS ENDCPAR3"        /* Call parser via wrap in SAVE case*/
"DEFINE 'RESET'   ALIAS ENDCDFLT"        /* If reset cmd then use defaults   */
"DEFINE 'RES'     ALIAS ENDCDFLT"        /* If reset cmd then use defaults   */
"DEFINE 'RESE'    ALIAS ENDCDFLT"        /* If reset cmd then use defaults   */
/*address ISPEXEC CONTROL ERRORS RETURN    error handeling */
"(TOTLINES) = LINENUM .ZLAST"            /* get the number of lines */

if TOTLINES = 0 | RESETARG ='YES' then "ENDCDFLT"  /* Empty mem or restart ? */
/*****************************************************************************/
/* Next is save of memeber resolution.                                       */
/* If member does not exist -                                                */
/* and we are reseting or called from endie300                               */
/* dont want to save the member.                                             */
/* When we have been in edit session we want to save.                        */
/*                                                                           */
/* If member does exist -                                                    */
/* and we reset or edit we want to save                                      */
/* but if called from endie300 then we dont.                                 */
/*                                                                           */
/*                                                                           */
/*****************************************************************************/
noSave = 'NO'    /* initiate default to save */
IF noedit/='YES' | (totlines /= 0 & RESETARG = 'YES') THEN nop
 else do          /* as described above, this is sick condition right ? */
    noSave = 'YES'                         /* dont save */
 end
    ADDRESS ISPEXEC "VPUT (NOSAVE) SHARED" /*AND BROADCAST TO PARSER */

if CTLITRML = "J" then "ENDCHELJ" /* If japanese Capital version   */
else "ENDCHELP"                   /* English lower case */

if NOEDIT = 'YES' then do /* this is in the case we are coming from ENDIE300*/
  "AUTOSAVE OFF NOPROMPT" /* or reseting via cc RESET.                      */
  "END"
  exit
end
else do
address ISPEXEC "SETMSG MSG(ENDE244I)"
end
return
