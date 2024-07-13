/********************************************************************/  00010000
/* Read the stream member and create table adding datasets names    */  00020000
/********************************************************************/  00030000
readstrm:                                                               00040000
  arg streamid debug                                                    00050000
  if debug = 'DEBUG' then trace a                                       00060000
  address ISPEXEC "VGET (STRMDSN STRMENDV STRMBASE STRMENVT)"           00070000
  if sysdsn("'" || strmdsn || "(" || streamid || ")'") ^= 'OK' then do  00080000
    zedsmsg = streamid 'Not Found'                                      00090000
    zedlmsg = streamid 'Member Not In' strmdsn                          00100000
    address ISPEXEC "SETMSG MSG(ISRZ001)"                               00110000
    return 99                                                           00120000
  end                                                                   00130000
  address TSO                                                           00140000
  "ALLOC F(IN) REU DA('" || strmdsn || "(" || streamid || ")') SHR"     00150000
  "EXECIO * DISKR IN (STEM R. FINIS"                                    00160000
  "FREE F(IN)"                                                          00170000
  address ISPEXEC                                                       00180000
  "TBCREATE PPCTAB" ,                                                   00190000
            "KEYS(SYS TYPE SUBSYS STAGE)" ,                             00200000
            "NAMES(COUNT TOSTAGE" ,                                     00210000
                  "TESTDSN TRGTDSN PRODDSN OVERDSN" ,                   00220000
                  "NDVRDSND NDVRDSNF NDVRDSNP TYPENDVR)" ,              00230000
            "NOWRITE REPLACE"                                           00240000
  "TBSORT PPCTAB FIELDS(SYS,C,A,TYPE,C,A,SUBSYS,C,A,STAGE,C,A)"         00250000
  do i = 1 to r.0                                                       00260000
    if substr(r.i,1,1) = '*' then iterate                               00270000
    count   = i * 10                                                    00280000
    count   = right(count,4,'0')                                        00290000
    sys     = substr(r.i,1,2)                                           00300000
    type    = strip(substr(r.i,4,8))                                    00310000
    subsys  = substr(r.i,13,1)                                          00320000
    stage   = substr(r.i,15,1)                                          00330000
    trgtdsn = strip(substr(r.i,17,44))                                  00340000
    tostage = substr(r.i,70,1)                                          00350000
    if type = 'DBRM' then typendvr = 'DBRMLIB'                          00360000
                     else typendvr = type                               00370000
    testdsn = strmendv || '.' || stage||sys||subsys || '.' || typendvr  00380000
    proddsn = strmbase || sys || '.BASE.' || type                       00390000
    overdsn = strmenvt || sys || '.' || streamid || '.BASE.ENVT.' ||type00400000
    ndvrdsnd = ''                                                       00410000
    ndvrdsnf = ''                                                       00420000
    ndvrdsnp = ''                                                       00430000
    if tostage ^= 'X' then do                                           00440000
      select                                                            00450000
        when stage  = 'B' then do                                       00460000
          ndvrdsnd  = strmendv || '.D' || sys || subsys ||'.'||typendvr 00470000
          ndvrdsnf  = strmendv || '.F' || sys || subsys ||'.'||typendvr 00480000
          ndvrdsnp  = strmendv || '.P' || sys || '1'    ||'.'||typendvr 00490000
        end                                                             00500000
        when stage  = 'D' then do                                       00510000
          ndvrdsnf  = strmendv || '.F' || sys || subsys ||'.'||typendvr 00520000
          ndvrdsnp  = strmendv || '.P' || sys || '1'    ||'.'||typendvr 00530000
        end                                                             00540000
        otherwise do                                                    00550000
          ndvrdsnp  = strmendv || '.P' || sys || '1'    ||'.'||typendvr 00560000
        end                                                             00570000
      end                                                               00580000
      select                                                            00590000
        when tostage = 'B' then do                                      00600000
          ndvrdsnd  = ''                                                00610000
          ndvrdsnf  = ''                                                00620000
          ndvrdsnp  = ''                                                00630000
        end                                                             00640000
        when tostage = 'D' then do                                      00650000
          ndvrdsnf  = ''                                                00660000
          ndvrdsnp  = ''                                                00670000
        end                                                             00680000
        when tostage = 'F' then do                                      00690000
          ndvrdsnp  = ''                                                00700000
        end                                                             00710000
        otherwise nop                                                   00720000
      end                                                               00730000
    end                                                                 00740000
    "TBADD PPCTAB ORDER"                                                00750000
  end                                                                   00760000
  "TBTOP PPCTAB"                                                        00770000
/*call prttab*/                                                         00780000
return 00                                                               00790000
/********************************************************************/  00800000
/* TEST routine to display the ISPF table                           */  00810000
/* code 'call prttab' if required                                   */  00820000
/********************************************************************/  00830000
prttab:                                                                 00840000
  "FTOPEN TEMP"                                                         00850000
  "FTINCL PPCTAB"                                                       00860000
  "FTCLOSE"                                                             00870000
  "VGET (ZTEMPN ztempf) SHARED"                                         00880000
  "LMINIT DATAID(DATAID) DDNAME(" || ztempn || ")"                      00890000
  "BROWSE DATAID(" || dataid || ")"                                     00900000
  "LMFREE DATAID(" dataid ")"                                           00910000
return                                                                  00920000
