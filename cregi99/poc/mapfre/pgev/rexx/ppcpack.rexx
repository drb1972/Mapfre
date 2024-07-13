/* Rexx */                                                              00010000
/********************************************************************/  00020000
/* Update TestStream with Package                                   */  00030025
/********************************************************************/  00040000
arg chngdsn debug .                                                     00050000
if debug = 'DEBUG' then trace all                                       00060000
if sysdsn(chngdsn) ^= 'OK' then exit 1                                  00070006
address ISPEXEC                                                         00080000
call ppcinit                                                            00090039
"VGET (STREAMID LOGDSN STRMPRFX STRMENDV)"                              00100032
"CONTROL ERRORS RETURN"                                                 00110000
/********************************************************************/  00120000
/* Get/Allocate the Log File                                        */  00130000
/********************************************************************/  00140000
call ppcloga logdsn || "." || streamid debug                            00150039
if result = 99 then exit 99                                             00160041
tracker = substr(chngdsn,(pos('.F0',chngdsn)+3),6)                      00170027
startext = date() time() userid() 'TRACKER' tracker                     00180008
"VPUT (TRACKER STARTEXT)"                                               00190008
call ppclogw 'Package Update Started :' startext                        00200039
if result = 99 then exit 99                                             00210041
call ppclogw copies('*',80)                                             00220039
if result = 99 then exit 99                                             00230041
/********************************************************************/  00240000
/* Main Process                                                     */  00250000
/********************************************************************/  00260000
call ppctab streamid debug                                              00270039
address TSO                                                             00280000
"ALLOC F(IN) DA(" || chngdsn || ") REUSE SHR"                           00290002
"EXECIO * DISKR IN (STEM R. FINIS"                                      00300000
"FREE F(IN)"                                                            00310000
address ISPEXEC                                                         00320000
"TBCREATE PACKAGE KEYS(PKGEDSN) NAMES(TESTDSN TYPE TRGTDSN OVERDSN)" ,  00330014
                  "NOWRITE REPLACE"                                     00340012
"TBSORT PACKAGE FIELDS(PKGEDSN)"                                        00350014
errmsgs  = 0                                                            00360044
warnmsgs = 0                                                            00370044
"VPUT (ERRMSGS WARNMSGS)"                                               00371044
del_step = 'N'                                                          00380015
do i = 1 to r.0                                                         00390002
  pkgedsn = strip(substr(r.i,1,44))                                     00400014
  if pos('DELETE.INFO',PKGEDSN) ^= 0 then do                            00410014
    call delinfo PKGEDSN                                                00420014
    del_step = 'Y'                                                      00430015
    iterate                                                             00440010
  end                                                                   00450010
  ndvrsubs = substr(pkgedsn,(pos('.F0',pkgedsn)-4),4)                   00460026
  ndvrtype = substr(pkgedsn,(lastpos('.',pkgedsn)+1))                   00470026
  testdsn = strmendv || '.' || ndvrsubs || '.' || ndvrtype              00480033
  "TBTOP PPCTAB"                                                        00490039
  "TBSCAN PPCTAB ARGLIST(TESTDSN)"                                      00500039
  select                                                                00510030
    when rc = 0 then do                                                 00520030
      call chkthem                                                      00530030
    end                                                                 00540030
    otherwise do                                                        00550030
      call ppclogw 'ERROR   :' pkgedsn 'FOR ENDEVOR OUTPUT LIBRARY'     00560039
      if result = 99 then exit 99                                       00570041
      call ppclogw '        :' testdsn 'NOT FOUND IN' streamid ,        00580039
                    'STREAM DEFINITION'                                 00590030
      if result = 99 then exit 99                                       00600042
      errmsgs = errmsgs + 1                                             00610044
      iterate                                                           00620030
    end                                                                 00630030
  end                                                                   00640027
  "TBADD PACKAGE ORDER"                                                 00650011
end                                                                     00660000
"VIEW DATASET('"logdsn"."streamid"') MACRO(PPCEM02)"                    00670039
"VGET (ERRMSGS WARNMSGS)"                                               00671044
if errmsgs = 0 then do                                                  00680044
  "TBTOP PACKAGE"                                                       00690011
  "FTOPEN TEMP"                                                         00700000
  "FTINCL PPCPKGE"                                                      00710038
  if del_step = 'Y' then do                                             00720027
    "FTINCL PPCPKGEC"                                                   00730038
    "FTINCL PPCPKGED"                                                   00740038
  end                                                                   00750027
  "FTCLOSE"                                                             00760000
  "VGET (ZTEMPN ztempf) SHARED"                                         00770000
  "LMINIT DATAID(DATAID) DDNAME(" || ztempn || ")"                      00780027
  "EDIT DATAID(" || dataid || ")"                                       00790027
  "LMFREE DATAID(" dataid ")"                                           00800027
end                                                                     00810000
call ppclogw 'Package Update Ended   :' ,                               00820039
if result = 99 then exit 99                                             00830041
              date() time() userid() 'TRACKER' tracker                  00840027
/********************************************************************/  00850000
/* The End - Tidy up time                                           */  00860000
/********************************************************************/  00870000
"TBEND PPCTAB"                                                          00880039
"TBEND PACKAGE"                                                         00890012
address TSO                                                             00900000
"FREE F(LOG)"                                                           00910000
exit                                                                    00920000
/********************************************************************/  00930006
/* Check Datasets Required To Apply The Package                     */  00940030
/********************************************************************/  00950006
chkthem:                                                                00960030
  call ppcchkds 'ERROR  ' pkgedsn                                       00970043
  call ppcchkds 'ERROR  ' trgtdsn                                       00980043
  call ppcchkds 'WARNING' overdsn                                       00990043
  if result = 0 then do                                                 01000030
    call chkover                                                        01010030
  end                                                                   01020030
return                                                                  01030030
/********************************************************************/  01040030
/* Check for conflicts between override library and package update  */  01050030
/* library                                                          */  01060030
/********************************************************************/  01070030
chkover:                                                                01080030
  address ISPEXEC                                                       01090006
  "LMINIT DATAID(DATAID) DATASET('" || pkgedsn || "') ENQ(SHR) ORG(ORG)"01100014
  "LMOPEN DATAID(" dataid ") OPTION(INPUT)"                             01110006
  member = ''                                                           01120006
  "LMMLIST DATAID(" dataid ") OPTION(LIST) MEMBER(MEMBER)"              01130006
  do while rc = 0                                                       01140006
    pdsmem = "'" || overdsn || "(" || strip(member) || ")'"             01150008
    memmsg = sysdsn(pdsmem)                                             01160006
    select                                                              01170006
      when memmsg = 'MEMBER NOT FOUND' then do                          01180006
      end                                                               01190006
      when memmsg = 'OK' then do                                        01200006
        call ppclogw 'ERROR   :' member 'IN' pkgedsn                    01210039
        if result = 99 then exit 99                                     01220041
        call ppclogw '        : EXISTS   IN' overdsn                    01230039
        if result = 99 then exit 99                                     01240041
        errmsgs = errmsgs + 1                                           01250044
      end                                                               01260006
      otherwise                                                         01270006
    end                                                                 01280006
    "LMMLIST DATAID(" dataid ") MEMBER(MEMBER)"                         01290006
  end                                                                   01300006
  "LMCLOSE DATAID(" dataid ")"                                          01310006
  "LMFREE  DATAID(" dataid ")"                                          01320006
return                                                                  01330006
/********************************************************************/  01340010
/* Create Skeletal Member for .DELETE.INFO JCL                      */  01350010
/********************************************************************/  01360010
delinfo:                                                                01370010
  arg dsn                                                               01380015
  address TSO                                                           01390015
  "ALLOC F(IN) DA('" || dsn || "') REUSE SHR"                           01400010
  "EXECIO * DISKR IN (STEM D. FINIS"                                    01410010
  "FREE F(IN)"                                                          01420010
  "ALLOC F(OUT) DA('" || strmprfx || ".SLIB(PPCPKGED)') REUSE SHR"      01430038
  "EXECIO * DISKW OUT (STEM D. FINIS"                                   01440010
  "FREE F(OUT)"                                                         01450010
  address ISPEXEC                                                       01460015
  "EDIT DATASET('" || strmprfx || ".SLIB(PPCPKGED)') MACRO(PPCEM03)"    01470038
  if rc ^= 0 then errmsgs = errmsgs + 1                                 01480044
return                                                                  01490010
