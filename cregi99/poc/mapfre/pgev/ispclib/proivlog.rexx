/* rexx */                                                              00000100
/*--------------------------------------------------------------------*/00000200
/*- Read PRO IV delivery file, build SCL and processor group         -*/00000300
/*- statements to add FUN,FIL,INT and GLG types to ENDEVOR           -*/00000400
/*--------------------------------------------------------------------*/00000500
/*- What                                      Who           When     -*/00000600
/*--------------------------------------------------------------------*/00000700
/*- Created                                   Craig Rex     10/04/01 -*/00000800
/*--------------------------------------------------------------------*/00000900
 arg debug                                                              00001000
 x = msg(off)                                                           00001100
                                                                        00001200
/* Debug Trace switch                                                 */00001300
  if debug = 'DEBUG' then do                                            00001400
     trace i                                                            00001500
  end                                                                   00001600
  else do                                                               00001700
     trace o                                                            00001800
  end                                                                   00001900
                                                                        00002000
/* Display panel to receive user info */                                00002100
 getinfo:                                                               00002200
    uid  = sysvar('sysuid')                                             00002300
    pref = sysvar('syspref')                                            00002400
    icnt = 1                                                            00002500
    ocnt = 1                                                            00002600
    prc = 0                                                             00002800
    timequal = time('N')                                                00002900
    hr = substr(timequal,1,2)                                           00003000
    mn = substr(timequal,4,2)                                           00003100
    sc = substr(timequal,7,2)                                           00003200
    slq = 'T' || hr || mn || sc                                         00003300
    tempdsn1 = pref || "." || uid || "." || slq || "." || "TEMP1"       00003400
    tempdsn2 = pref || "." || uid || "." || slq || "." || "TEMP2"       00003500
    "FREE DD(INFILE)"                                                   00003600
    "FREE DD(ISPFILE)"                                                  00003700
                                                                        00003800
 panel:                                                                 00003900
    "ISPEXEC DISPLAY PANEL(PROIVLOG)"                                   00004000
    prc = rc                                                            00004100

       if prc ^= 0 then exit                                            00004500

 "ISPEXEC VPUT (PROIVAPP INDSN PKGTYP C1CCID C1SUB ITTYPE ITNAME USAGE",
          "DB2 COMMENTS) PROFILE"

 "ALLOC DD(ISPFILE) DA('"tempdsn1"')",                                  00007800
          "NEW SPACE(1,1) CYLINDERS REUSE",                             00007900
          "UNIT(SYSALLDA) CATALOG RECFM(F B) LRECL(80)"                 00008000
                                                                        00008100
/* When the user has entered a valid dataset, process the   */          00008400
/* file                                                     */          00008500
     if pkgtyp = 'EMERGENCY' then c1env = 'PROD'                        00004420
     if pkgtyp = 'STANDARD' then c1env = 'UNIT'                         00004420
     if rc  = 0 then do                                                 00008700
        cnt = 1                                                         00008800
       "ISPEXEC FTOPEN"                                                 00008900
       "ISPEXEC FTINCL PROIVS01"                                        00009000
                                                                        00009100
/* Skip through the file and create an IEBUPDTE statement   */          00009200
/* for each record in the file                              */          00009300
                                                                        00009400
         proivrec = itname || ' ' || ittype || ' ' || db2               00009600
         c1ele    = itname                                              00009700
         c1ele  = strip(c1ele)                                          00009800
        "ISPEXEC FTINCL PROIVS02"                                       00009900
         cnt = cnt + 1                                                  00010000
                                                                        00010200
        "ISPEXEC FTINCL PROIVS03"                                       00010300
        cnt = 1                                                         00010400
                                                                        00010500
           type    = ittype                                             00010700
           c1ty    = ittype || proivapp                                 00010800
           c1ele   = itname                                             00010900
           c1ele  = strip(c1ele)                                        00011000
           usedb2  = db2                                                00011100
           runtype = usage                                              00011200
           c1com   = comments                                           00011200
                                                                        00011300
          select                                                        00011400
          when usedb2 = "Y" & runtype = "A"                             00011500
          then do                                                       00011600
                 c1prcgrp = "DXL2XXXA"                                  00011700
               end                                                      00011800
          when usedb2 = "Y" & runtype = "B"                             00011900
          then do                                                       00012000
                 c1prcgrp = "DXL2XXXB"                                  00012100
               end                                                      00012200
          when usedb2 = "Y" & runtype = "O"                             00012300
          then do                                                       00012400
                 c1prcgrp = "DXL2XXXO"                                  00012500
               end                                                      00012600
          when usedb2 = "N" & runtype = "A"                             00012700
          then do                                                       00012800
                 c1prcgrp = "XXL2XXXA"                                  00012900
               end                                                      00013000
          when usedb2 = "N" & runtype = "B"                             00013100
          then do                                                       00013200
                 c1prcgrp = "XXL2XXXB"                                  00013300
               end                                                      00013400
          when usedb2 = "N" & runtype = "O"                             00013500
          then do                                                       00013600
                 c1prcgrp = "XXL2XXXO"                                  00013700
               end                                                      00013800
          otherwise do                                                  00013900
                 c1prcgrp = c1ty                                        00014000
               end                                                      00014100
         end                                                            00014600
           "ISPEXEC VPUT (TYPE USEDB2 C1ENV) PROFILE"                   00014300
           "ISPEXEC FTINCL PROIVS12"                                    00014400
           cnt = cnt + 1                                                00014500
           "ISPEXEC FTINCL PROIVS05"                                    00014700
                                                                        00014800
/* Save the temporary dataset containing the job and        */          00014900
/* display the JCL for submission                           */          00015000
                                                                        00015100
     "ISPEXEC FTCLOSE"                                                  00015200
     "ISPEXEC EDIT DATASET('"tempdsn1"')"                               00015300
      say "Submit this JCL (Y/N)?"                                      00015400
      pull ans                                                          00015500
      upper ans                                                         00015600
      if ans = "Y" then do                                              00015700
         x = msg(on)                                                    00015800
         x = outtrap("line.",1)                                         00015900
         "SUBMIT '"tempdsn1"'"                                          00016000
         submsg = line.1                                                00016100
         say submsg                                                     00016200
      end                                                               00016300
     end                                                                00016400
 "FREE DD(ISPFILE)"                                                     00016500
  exit                                                                  00016600
