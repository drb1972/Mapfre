/********************************************************************/  00010000
/* Create a temporary ISPF table of dataset and member name         */  00020001
/********************************************************************/  00030000
temptab:                                                                00040000
  arg streamid cntldsn debug                                            00050000
  if debug = 'DEBUG' then trace a                                       00060000
  address TSO                                                           00070000
  "ALLOC F(IN) REU DA(" || cntldsn || ") SHR"                           00080000
  "EXECIO * DISKR IN (STEM R. FINIS"                                    00090000
  "FREE F(IN)"                                                          00100000
  address ISPEXEC                                                       00110000
  "TBCREATE PPCTTTB KEYS(DATADSN MEMBER) NOWRITE REPLACE"               00120000
  "TBSORT   PPCTTTB FIELDS(DATADSN,C,A,MEMBER,C,A)"                     00130000
  do i = 1 to r.0                                                       00140000
    if substr(r.i,1,1) = '*' then iterate                               00150000
    system  = substr(r.i,3,2)                                           00160000
    type    = strip(substr(r.i,lastpos('.',r.i)+1,8))                   00170000
    member  = strip(substr(r.i,50,8))                                   00180000
    datadsn = strip(substr(r.i,1,44))                                   00190000
    "TBADD PPCTTTB ORDER"                                               00200000
  end                                                                   00210000
  "TBTOP PPCTTTB"                                                       00220000
/*call prttab*/                                                         00230000
return 00                                                               00240000
/********************************************************************/  00250000
/* TEST routine to display the ISPF table                           */  00260000
/* code 'call prttab' if required                                   */  00270000
/********************************************************************/  00280000
prttab:                                                                 00290000
  "FTOPEN TEMP"                                                         00300000
  "FTINCL PPCTTTB"                                                      00310000
  "FTCLOSE"                                                             00320000
  "VGET (ZTEMPN) SHARED"                                                00330000
  "LMINIT DATAID(DATAID) DDNAME(" || ztempn || ")"                      00340000
  "BROWSE DATAID(" || dataid || ")"                                     00350000
  "LMFREE DATAID(" dataid ")"                                           00360000
return                                                                  00370000
