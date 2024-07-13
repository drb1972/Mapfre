/* Rexx */                                                              00010000
/********************************************************************/  00020000
/* Generate JCL to Delete & Allocate TestStream Datasets            */  00030000
/********************************************************************/  00040000
arg debug .                                                             00050000
if debug = 'DEBUG' then trace a                                         00060000
call ppcinit                                                            00070013
address ISPEXEC                                                         00080000
"VGET (STREAMID LOGDSN STRMPRFX)"                                       00090000
"CONTROL ERRORS RETURN"                                                 00100000
/********************************************************************/  00110000
/* Get/Allocate the Log File                                        */  00120000
/********************************************************************/  00130000
call ppcloga logdsn || "." || streamid debug                            00140013
if result = 99 then exit 99                                             00150000
/********************************************************************/  00160000
/* Main Processing Loop                                             */  00170000
/********************************************************************/  00180000
"DISPLAY PANEL(PPCDALL)"                                                00190012
do while rc < 8                                                         00200000
  "VGET (TRACKER)"                                                      00210005
  startext = date() time() userid() 'Tracker ID' tracker                00220005
  "VPUT STARTEXT"                                                       00230005
  call ppclogw 'Delete & Allocate Started :' startext                   00240013
  if result = 99 then exit 99                                           00250015
  call ppclogw copies('*',80)                                           00260013
  if result = 99 then exit 99                                           00270015
  call ppclogw delalloc 'Selected'                                      00280013
  if result = 99 then exit 99                                           00290015
  call ppctab streamid debug                                            00300013
  call dedupe                                                           00310014
  call genjcl                                                           00320014
  call ppclogw 'JCL generated to sumbit job D0' || tracker              00330013
  if result = 99 then exit 99                                           00340015
  call ppclogw 'Delete & Allocate Ended   :'                            00350013
  if result = 99 then exit 99                                           00360015
                date() time() userid() ,                                00370005
                'Tracker ID' tracker                                    00380005
  "DISPLAY"                                                             00390000
end                                                                     00400000
/********************************************************************/  00410000
/* The End - Tidy up time                                           */  00420000
/********************************************************************/  00430000
"TBEND PPCTAB"                                                          00440013
address TSO                                                             00450000
"FREE F(LOG)"                                                           00460000
exit                                                                    00470000
/********************************************************************/  00480000
/* Generate the JCL                                                 */  00490000
/********************************************************************/  00500000
genjcl:                                                                 00510000
  "FTOPEN TEMP"                                                         00520000
  "FTINCL PPCDALLJ"                                                     00530011
  "FTINCL PPCDALLD"                                                     00540011
  if delalloc = 'ALLOCATE' then "FTINCL PPCDALLA"                       00550011
  "FTCLOSE"                                                             00560000
  "VGET (ZTEMPN ztempf) SHARED"                                         00570000
  "LMINIT DATAID(DATAID) DDNAME(" || ztempn || ")"                      00580000
  "EDIT DATAID(" || dataid || ")"                                       00590000
  "LMFREE DATAID(" dataid ")"                                           00600000
return                                                                  00610000
/********************************************************************/  00620014
/* Remove Target Dataset Name Duplicates                            */  00630014
/********************************************************************/  00640014
dedupe:                                                                 00650014
  address ISPEXEC                                                       00660014
  "TBCREATE PPCTABA KEYS(TRGTDSN) NAMES(PRODDSN TYPE) NOWRITE REPLACE"  00670014
  "TBSORT PPCTABA FIELDS(TRGTDSN,C,A)"                                  00680014
  "TBTOP PPCTAB"                                                        00690014
  "TBSKIP PPCTAB"                                                       00700014
  do while rc = 0                                                       00710014
    "TBADD PPCTABA ORDER"                                               00720014
    "TBSKIP PPCTAB"                                                     00730014
  end                                                                   00740014
  "TBTOP PPCTAB"                                                        00750014
  "TBTOP PPCTABA"                                                       00760014
return                                                                  00770014
