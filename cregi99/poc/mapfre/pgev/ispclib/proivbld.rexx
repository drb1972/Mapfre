/* rexx */                                                              00010000
/*--------------------------------------------------------------------*/00020000
/*- Create a PRO-IV BOOTS and PARMS file which will then be added    -*/00030000
/*- to Endevor for inclusion in the package being shipped to PROD    -*/00040000
/*--------------------------------------------------------------------*/00050000
/*- What                                      Who           When     -*/00060000
/*--------------------------------------------------------------------*/00070000
/*- Created                                   Craig Rex     25/06/01 -*/00080000
/*--------------------------------------------------------------------*/00090000
 arg debug                                                              00100000
 x = msg(off)                                                           00110000
                                                                        00120000
/* Debug Trace switch                                                 */00130000
  if debug = 'DEBUG' then do                                            00140000
     trace i                                                            00150000
  end                                                                   00160000
  else do                                                               00170000
     trace o                                                            00180000
  end                                                                   00190000
                                                                        00200000
/* Display panel to receive user info */                                00210000
 getinfo:                                                               00220000
    uid  = sysvar('sysuid')                                             00230000
    pref = sysvar('syspref')                                            00240000
    icnt = 1                                                            00250000
    ocnt = 1                                                            00260000
    pmsg =                                                              00270000
    prc = 0                                                             00280000
    timequal = time('N')                                                00290000
    hr = substr(timequal,1,2)                                           00300000
    mn = substr(timequal,4,2)                                           00310000
    sc = substr(timequal,7,2)                                           00320000
    slq = 'T' || hr || mn || sc                                         00330000
    tempdsn1 = pref || "." || uid || "." || slq || "." || "TEMP1"       00340000
    tempdsn2 = pref || "." || uid || "." || slq || "." || "TEMP2"       00350000
    "FREE DD(INFILE)"                                                   00360000
    "FREE DD(ISPFILE)"                                                  00370000
                                                                        00380000
 "ALLOC DD(ISPFILE) DA('"tempdsn1"')",                                  00381002
          "NEW SPACE(1,1) CYLINDERS REUSE",                             00382002
          "UNIT(SYSALLDA) CATALOG RECFM(F B) LRECL(80)"                 00383002
                                                                        00384002
 panel:                                                                 00390000
    "ISPEXEC DISPLAY PANEL(PROIVBLD)"                                   00400000
    prc = rc                                                            00410000
       if prc ^= 0 then exit                                            00420000
       else do                                                          00430000
       "ISPEXEC VPUT (PROIVAPP C1SUB C1CCID PKGTYP) PROFILE"            00440001
                                                                        00440102
       if pkgtyp = 'STANDARD' then do                                   00441006
          deltype = 'PRODEV'                                            00442006
          env     = 'ACPT'                                              00442106
          stg     = 'VF'                                                00442206
          sid     = 'F'                                                 00442207
       end                                                              00442306
                                                                        00442406
       if pkgtyp = 'EMERGENCY' then do                                  00442506
          deltype = 'HOTFIX'                                            00442606
          env     = 'PROD'                                              00442706
          stg     = 'VO'                                                00442806
          sid     = 'O'                                                 00442807
       end                                                              00442906
                                                                        00444002
     if rc  = 0 then do                                                 00450000
        cnt = 1                                                         00460000
       "ISPEXEC FTOPEN"                                                 00470002
       "ISPEXEC FTINCL PROIVS10"                                        00480007
       "ISPEXEC FTCLOSE"                                                01100001
       "ISPEXEC EDIT DATASET('"tempdsn1"')"                             01110002
      say "Submit this JCL (Y/N)?"                                      01120000
      pull ans                                                          01130000
      upper ans                                                         01140000
      if ans = "Y" then do                                              01150000
         x = msg(on)                                                    01160000
         x = outtrap("line.",1)                                         01170000
         "SUBMIT '"tempdsn1"'"                                          01180002
         submsg = line.1                                                01190000
         say submsg                                                     01200000
      end                                                               01210000
     end                                                                01220000
 "FREE DD(ISPFILE)"                                                     01230000
  exit                                                                  01240000
