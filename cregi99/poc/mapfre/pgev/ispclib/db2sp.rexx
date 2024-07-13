/*--------------------------REXX----------------------------*\
 *  Create DB2 Stored Procedure definitions and add them    *
 *  to Endevor                                              *
 *                                                          *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
 *              July 2002                                   *
\*----------------------------------------------------------*/
trace n

call initialise

address ispexec
"display panel(db2sp)"
panel_rc  = rc
do while panel_rc <> 08
  call procvars
  "display panel(db2spv)"
  panel_rc  = rc
  do while panel_rc <> 08
    if wordpos(varname,varlist) > 0 then do /* check newvar not dup */
      err   = 'Y'
      msgid = 'DBSP000E'
      pmsg  = varname '- Duplicate variable name not added'
    end /* varname found */
    else
      call setvars
    "display panel(db2spv) cursor(varname) msg("msgid")"
    panel_rc  = rc
    pmsg  = ''
    msgid = ''
    err   = 'N'
  end /* do while panel_rc <> 8 */
  call writesp
  "display panel(db2sp) msg("msgid")"
  panel_rc  = rc
end /* do while panel_rc <> 08 */

exit

/* +--------------------------------------------------------------+ */
/* !  initialise - initialise global variables                    ! */
/* +--------------------------------------------------------------+ */
initialise:
 amsg    = ''
 pmsg    = ''
 msgid   = ''
 err     = 'N'
 splname  = ''
 spsub   = ''
 sprsets = ''
 spcomm  = 'N'
 spstyle = 'G'
 spwlm   = ''
 spov    = 'N'
 /* Get Endevor jobcard information for JCL submit */
 address ispexec
 'vget (C1BJC1)'
 'vget (C1BJC2)'
 'vget (C1BJC3)'
 'vget (C1BJC4)'
 if c1bjc1 = '' then do
   say 'RC=8:  Unable to read jobcard information'
   exit 8
 end /* c1bjcl = '' */
return

/* +--------------------------------------------------------------+ */
/* !  Procvars - Initial variables for each stored procedure      ! */
/* +--------------------------------------------------------------+ */
PROCVARS:
 spname  = substr(splname,1,8)
 varname = ''
 vartyp  = ''
 inout   = ''
 size    = ''
 pp      = ''
 ss      = ''
 tots    = 0
 toti    = 0
 totr    = 0
 totf    = 0
 totdp   = 0
 totd    = 0
 totc    = 0
 totvc   = 0
 totg    = 0
 totvg   = 0
 varlist  = ''
 varlist1 = ''
 varlist2 = ''
 count   = 0
return

/* +--------------------------------------------------------------+ */
/* !  Setvars                                                     ! */
/* +--------------------------------------------------------------+ */
setvars:
 varlist  = varlist varname
 varlist1 = substr(varlist,1,70)
 varlist2 = substr(varlist,71)
 count   = count + 1
 vartyp.count  = vartyp
 varname.count = varname
 inout.count   = inout
 size.count    = size
 pp.count      = pp
 ss.count      = ss
 interpret 'tot'vartyp '= tot'vartyp '+ 1'
 select
   when vartyp = 'S' then
     array.count = ""inout" "varname" SMALLINT "
   when vartyp = 'I' then
     array.count = ""inout" "varname" INTEGER  "
   when vartyp = 'R' then
     array.count = ""inout" "varname" REAL     "
   when vartyp = 'F' then
     array.count = ""inout" "varname" FLOAT    "
   when vartyp = 'DP' then
     array.count = ""inout" "varname" DOUBLE PRECISION  "
   when vartyp = 'D' then
     array.count = ""inout" "varname" DECIMAL("pp","ss") "
   when vartyp = 'C' then
     array.count = ""inout" "varname" CHARACTER("size")   "
   when vartyp = 'VC' then
     array.count = ""inout" "varname" VARCHAR("size") "
   when vartyp = 'G' then
     array.count = ""inout" "varname" GRAPHIC("size")  "
   when vartyp = 'VG' then
     array.count = ""inout" "varname" VARGRAPHIC("size")  "
   otherwise nop
 end /* select */
 pmsg = varname '- Added'

Return

/* +--------------------------------------------------------------+ */
/* !  Writesp: Wite Stored Procedure definiton & submit ADD SCL   ! */
/* +--------------------------------------------------------------+ */
writesp:
 if spstyle = 'G' then param = 'GENERAL'
 if spstyle = 'N' then param = 'GENERAL WITH NULLS'
 if spcomm  = 'Y' then cor   = 'YES'
 if spcomm  = 'N' then cor   = 'NO'
 sprsets = right(sprsets,3,0)
 spwlm   = right(spwlm,2,0)
 queue 'CREATE PROCEDURE' splname
 do a = 1 to count
   select
     when count = 1 then insert = "("array.a")"
     when a = 1     then insert = "("array.a","
     when a = count then insert =    array.a")"
     otherwise           insert =    array.a","
   end /* select */
   queue insert
 end /* do a = 1 to count */
 queue "DYNAMIC RESULT SETS" sprsets
 queue "EXTERNAL NAME" spname
 queue "PARAMETER STYLE" param
 queue "LANGUAGE COBOL"
 queue "COLLID #collid"
 queue "WLM ENVIRONMENT #db2suAE"spwlm
 queue "STAY RESIDENT YES"
 queue "PROGRAM TYPE SUB"
 queue "RUN OPTIONS"
 queue "'H(,,ANY),STAC(,,ANY,),STO(,,,20K),BE(4K,,),LIBS(4K,,)"
 queue ",RPTOPTS(OFF),ALL31(ON)'"
 queue "COMMIT ON RETURN" cor ";"
 queue ""

 address tso
 z = msg(off)
 "free f(db2sp)"
 z = msg(on)
 "alloc file(db2sp) space(1,1) tracks reuse lrecl(80)"
 "execio * diskw db2sp ( finis"
 address ispexec
 "lminit dataid(cid) ddname("db2sp")" /* initialise report for edit */
 "edit dataid(&cid) macro(db2spm)"
 "lmfree dataid(&cid)"

 "display panel(db2spc)"
 panel_rc = rc

 if zcmd ^= 'CAN' & zcmd ^= 'CANCEL' & panel_rc < 8 then do
   spsubsys = spsys || spsub
   queue C1BJC1
   if c1bjc2 <> '' then
     queue C1BJC2
   if c1bjc3 <> '' then
     queue C1BJC3
   if c1bjc4 <> '' then
     queue C1BJC4
   queue '//*'
   queue '//*  ADD SPDEF element' spname 'to Endevor'
   queue '//*'
   queue '//NDVRBAT  EXEC PGM=NDVRC1,DYNAMNBR=1500,             '
   queue '//  PARM='C1BM3000'                                   '
   queue '//SYSPRINT DD SYSOUT=*                                '
   queue '//PSPOFF   DD DUMMY                                   '
   queue '//SYSUDUMP DD SYSOUT=*                                '
   queue '//SORTWK01 DD SPACE=(CYL,(5,5))                       '
   queue '//SORTWK02 DD SPACE=(CYL,(5,5))                       '
   queue '//SORTWK03 DD SPACE=(CYL,(5,5))                       '
   queue '//SORTWK04 DD SPACE=(CYL,(5,5))                       '
   queue '//C1SORTIO DD SPACE=(CYL,(50,50)),                    '
   queue '//            RECFM=VB,LRECL=8296,BLKSIZE=8300        '
   queue '//C1TPDD01 DD SPACE=(CYL,5),RECFM=VB,LRECL=260,BLKSIZE=0'
   queue '//C1TPDD02 DD SPACE=(CYL,5),RECFM=VB,LRECL=260,BLKSIZE=0'
   queue '//C1TPLSIN DD SPACE=(CYL,5),RECFM=FB,LRECL=80,BLKSIZE=0'
   queue '//C1TPLSOU DD SPACE=(CYL,5)                           '
   queue '//C1PLMSGS DD SYSOUT=*                                '
   queue '//APIPRINT DD SYSOUT=*                                '
   queue '//HLAPILOG DD SYSOUT=*                                '
   queue '//C1MSGS1  DD SYSOUT=*                                '
   queue '//C1MSGS2  DD SYSOUT=*                                '
   queue '//C1PRINT  DD SYSOUT=*,RECFM=FBA,LRECL=121,BLKSIZE=0  '
   queue '//SYSABEND DD SYSOUT=*                                '
   queue '//SYSOUT   DD SYSOUT=*                                '
   queue '//BSTIPT01 DD *                                       '
   queue 'ADD ELEMENT 'spname
   queue '  FROM DDNAME SOURCE'
   queue '  TO   ENVIRONMENT 'spenv' SYSTEM 'spsys' SUBSYSTEM 'spsubsys
   queue '    TYPE SPDEF'
   queue '  OPTIONS CCID 'spccid 'UPDATE PROCESSOR GROUP' spprg
   if spov = 'Y' then
     queue '        OVERRIDE SIGNOUT'
   queue '          COMMENTS "'spcomnt'" .'
   queue '//SOURCE   DD *'
   address tso
   "execio * diskr db2sp ( finis"
   "free file(db2sp)"
   queue ''
   address tso
   z = msg(off)
   "free f(subjcl)"
   z = msg(on)
   "alloc file(subjcl) space(1,1) tracks reuse lrecl(80)"
   "execio * diskw subjcl ( finis"
   x = listdsi(subjcl file)
   if zcmd = 'EDIT' then
     call editjcl
   else
     "submit '"sysdsname"'"
   address tso
   "free file(subjcl)"
   amsg = spname ,
          '- Add to Endevor subsystem' spsubsys 'type SPDEF submitted'
 end /* zcmd ^= 'CAN' & zcmd ^= 'CANCEL' & panel_rc < 8 */
 else do
   amsg = spname '- Discarded'
   msgid = 'DBSP002E'
 end /* else */
 zcmd = ''

return

/* +--------------------------------------------------------------+ */
/* !  Editjcl: for testing instead of submit                      ! */
/* +--------------------------------------------------------------+ */
editjcl:
 address ispexec
 "lminit dataid(cid) ddname("subjcl")" /* initialise report for edit */
 "edit dataid(&cid) macro(db2spm)"
 "lmfree dataid(&cid)"
return
