/* Rexx */ /*trace a*/                                                  00010002
/********************************************************************/  00020001
/* Edit Macro to expand 'ALL' and populate target dataset names     */  00030001
/********************************************************************/  00040001
address ISREDIT                                                         00050001
"MACRO"                                                                 00060001
call ppcinit                                                            00070006
address ISPEXEC "CONTROL ERRORS RETURN"                                 00080001
address ISPEXEC "VGET (ID SYSTMDSN STRMTLQ)"                            00090001
"SORT"                                                                  00100001
"EXCLUDE '*' 1 ALL"                                                     00110001
/********************************************************************/  00120001
/* Expand any types 'ALL'                                           */  00130001
/********************************************************************/  00140001
"FIND P'=' 1 NX FIRST"                                                  00150001
do while rc = 0                                                         00160001
  "(LINE) = LINE .ZCSR"                                                 00170001
  "(LINENUM) = LINENUM .ZCSR"                                           00180002
  sys = substr(line,1,2)                                                00190001
  type = strip(substr(line,4,8))                                        00200001
                                                                        00210001
  line_prefix = substr(line,01,03)                                      00220001
  type        = substr(line,04,08)                                      00230001
  line_mid1   = substr(line,12,05)                                      00240001
  target_dsno = substr(line,17,44)                                      00250001
  line_mid2   = substr(line,61,09)                                      00260001
  optnl_endvr = substr(line,70,01)                                      00270001
  line_suffix = substr(line,71)                                         00280001
                                                                        00290001
  systmdsn_m =  "'" || systmdsn || "(" || sys || ")'"                   00300001
  if sysdsn(systmdsn_m) = 'MEMBER NOT FOUND' then do                    00310001
    zedsmsg = sys 'Not Found'                                           00320001
    zedlmsg = sys 'Member Not Found In' systmdsn                        00330001
    address ISPEXEC "SETMSG MSG(ISRZ001)"                               00340001
    exit 3                                                              00350001
  end                                                                   00360001
  address TSO                                                           00370001
  "ALLOC F(IN) REU DA(" || systmdsn_m || ") SHR"                        00380001
  "EXECIO * DISKR IN (STEM T. FINIS"                                    00390004
  "FREE F(IN)"                                                          00400001
  j = 0                                                                 00410004
  do i = 1 to t.0                                                       00420004
    if substr(t.i,1,1) = '*' then iterate                               00430004
    j = j + 1                                                           00440004
    r.j = t.i                                                           00450004
  end                                                                   00460004
  r.0 = j                                                               00470004
  address ISREDIT                                                       00480002
                                                                        00490001
/********************************************************************/  00500001
/* Expand any types 'ALL'                                           */  00510001
/********************************************************************/  00520001
  if substr(line,4,3) = 'ALL' then call expand                          00530001
/********************************************************************/  00540001
/* Mark Any Optional Endevor Daasets (Column 70 'O')                */  00550001
/********************************************************************/  00560001
  if substr(line,70,1) = ' ' then call optional                         00570001
/********************************************************************/  00580001
/* Populate blank target dataset names                              */  00590001
/********************************************************************/  00600001
  if substr(line,17,1) = ' ' then do                                    00610001
    call target                                                         00620001
    line = overlay(target_dsn,line,17,44)                               00630001
    "LINE" linenum "= '" || line || "'"                                 00640002
  end                                                                   00650001
  "FIND P'=' 1 NX"                                                      00660001
end                                                                     00670001
"SORT NX"                                                               00700007
"RENUM"                                                                 00710002
"RESET"                                                                 00710107
"LOCATE .ZFIRST"                                                        00711007
zedsmsg = ''                                                            00720003
zedlmsg = "Expanded Special Type 'ALL'" ,                               00730001
          "and Populated Blank Target Dataset Names.       " ,          00740001
          "Hit PF3 To Exit."                                            00750001
address ISPEXEC "SETMSG MSG(ISRZ001)"                                   00760001
exit 1                                                                  00770001
expand:                                                                 00780001
/********************************************************************/  00790001
/* Use the systems PDS to expand the 'ALL's                         */  00800001
/********************************************************************/  00810001
  address ISREDIT                                                       00820001
  "DELETE .ZCSR"                                                        00830001
  do i = 1 to r.0                                                       00840001
    type  = substr(r.i,01,08)                                           00850001
    if target_dsno = '' then call target                                00860001
                        else target_dsn = target_dsno                   00870001
    call asslign                                                        00880001
    "LINE_AFTER" (linenum - 1) "= DATALINE '"line"'"                    00890002
  end                                                                   00900001
  "CURSOR =" linenum "1"                                                00910002
return                                                                  00920001
optional:                                                               00930001
/********************************************************************/  00940001
/* Use the systems PDS to populate any optional Endevor datasets    */  00950001
/********************************************************************/  00960001
  address ISREDIT                                                       00970001
  do i = 1 to r.0                                                       00980001
    type_ref = substr(r.i,01,08)                                        00990001
    if type_ref = type then leave                                       01000001
  end                                                                   01010001
  if i <= r.0 then do                                                   01020001
    optnl_endvr = substr(r.i,10,01)                                     01030001
    call asslign                                                        01040001
    "LINE" linenum "= '" || line || "'"                                 01050002
  end                                                                   01060001
return                                                                  01070001
target:                                                                 01080001
  target_dsn = strmtlq  || sys || '.' || id || '.BASE.' || type         01090001
return                                                                  01100001
asslign:                                                                01110001
  line = line_prefix || ,                                               01120001
         type        || ,                                               01130001
         line_mid1   || ,                                               01140001
         target_dsno || ,                                               01150001
         line_mid2   || ,                                               01160001
         optnl_endvr || ,                                               01170001
         line_suffix                                                    01180001
return                                                                  01190001
