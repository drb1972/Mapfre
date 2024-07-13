/* rexx */                                                              00000100
/*--------------------------------------------------------------------*/00000200
/*- Migrate generol components from SGTLIBs                          -*/00000300
/*--------------------------------------------------------------------*/00000500
/*- What                                      Who           When     -*/00000600
/*--------------------------------------------------------------------*/00000700
/*- Created                                   Craig Rex     14/05/04 -*/00000800
/*--------------------------------------------------------------------*/00000900
 arg target
 trace o

 select
  when target = 'SYST' then do
       inlib1 = 'TTLN.G1.VGENEROL.SGTLIB1'
       inlib2 = 'TTLN.G1.VGENEROL.SGTLIB2'
       outlib1 = 'TTLN.G2.VGENEROL.SGTLIB1'
       outlib2 = 'TTLN.G2.VGENEROL.SGTLIB2'
  end
  when target = 'ACPT' then do
       inlib1 = 'TTLN.G2.VGENEROL.SGTLIB1'
       inlib2 = 'TTLN.G2.VGENEROL.SGTLIB2'
       outlib1 = 'TTLN.G3.VGENEROL.SGTLIB1'
       outlib2 = 'TTLN.G3.VGENEROL.SGTLIB2'
  end
  otherwise nop
 end

 x = msg(off)                                                           00001100
 tot = 0
 cnt = 1
 newsgt = N
 uid = sysvar('sysuid')                                                 00002300
 pref= sysvar('syspref')                                                00002400
 timequal = time('N')                                                   00002900
 hr = substr(timequal,1,2)                                              00003000
 mn = substr(timequal,4,2)                                              00003100
 sc = substr(timequal,7,2)                                              00003200
 slq = 'T' || hr || mn || sc                                            00003300
 tempdsn1 = pref || "." || uid || "." || slq || "." || "TEMP2"          00003400
 "FREE DD(INFILE)"                                                      00003600
 "FREE DD(ISPFILE)"                                                     00003700

 top:
 "ISPEXEC VGET (CHGNO ADTEAM) PROFILE"                                  00004700
 "ISPEXEC DISPLAY PANEL(EVGENMIG)"                                      00004000
 prc = rc
 "ISPEXEC VPUT (CHGNO ADTEAM) PROFILE"                                  00004700
  if prc = 0 then do
   memnam = adteam || substr(chgno,3,6)
   indsn = 'TTYY.GENEROL.MIGRATE.DATA('memnam')'
   y = sysdsn("'"indsn"'")
   if y ^= 'OK' then do
     "ISPEXEC SETMSG MSG(EVGEN001)"
      y = ''
      signal top
    end
  else do
   "ALLOC DD(INFILE) DA('"indsn"') SHR"                                 00008200
    Say "Do you want to review the Migation control file (Y/N)?"
      pull ans                                                          00015500
      upper ans                                                         00015600
      if ans = "Y" then do                                              00015700
         x = msg(on)                                                    00015800
         "ISPEXEC EDIT DATASET('"indsn"')"
      end                                                               00016300

 "EXECIO * DISKR INFILE (STEM cmplist. FINIS)"                          00008300

 "ALLOC DD(ISPFILE) DA('"tempdsn1"')",                                  00007800
          "NEW SPACE(1,1) CYLINDERS REUSE",                             00007900
          "UNIT(SYSALLDA) CATALOG RECFM(F B) LRECL(80)"                 00008000

   "ISPEXEC FTOPEN"
   "ISPEXEC FTINCL EVGENMG1"                                            00009000

  do until cnt > cmplist.0                                              00009500
  parse var cmplist.cnt SGTLIB CHGNUM ADTEAM SUBLIB CMPNAM CMPTYP CHGTYP00009600
   sgtnam = "SGTLIB" || sgtlib

    if cnt = 1 then do
      "ISPEXEC FTINCL EVGENMG3"                                         00009000
      "ISPEXEC FTINCL EVGENMG0"                                         00009000
      end
    else do
       cnt2 = cnt - 1
       if sgtlib ^= substr(cmplist.cnt2,1,1) then do
         "ISPEXEC FTINCL EVGENMG3"                                      00009000
         "ISPEXEC FTINCL EVGENMG0"                                      00009000
       end
    end

     select
      when cmptyp = 'P' then gentyp = 'PROGRAM'
      when cmptyp = 'W' then gentyp = 'WORK   '
      when cmptyp = 'M' then gentyp = 'MAP    '
      when cmptyp = 'R' then gentyp = 'RECORD '
      when cmptyp = 'F' then gentyp = 'FILE   '
      otherwise nop
     end

     if sgtlib = '1' then do
        fromlib = 'FROMLIB1'
        tolib = 'TOLIB1'
     end
     if sgtlib = '2' then do
        fromlib = 'FROMLIB2'
        tolib = 'TOLIB2'
     end

     "ISPEXEC FTINCL EVGENMG2"                                          00009000

     select
       when  sublib = 'RESIDENT' then do
        sublib = 'NONRES'
        "ISPEXEC FTINCL EVGENMG2"
       end

       when  sublib = 'NONRES'  then do
        sublib = 'RESIDENT'
        "ISPEXEC FTINCL EVGENMG2"
       end
       otherwise
      end

     cnt = cnt + 1                                                      00010000
    end
   "ISPEXEC FTINCL EVGENMG4"
   "ISPEXEC FTCLOSE"                                                    00015200
   "ISPEXEC EDIT DATASET('"tempdsn1"')"
   say "Submit Gener/OL Migrate to SYST (Y/N)?"                         00015400
      pull ans                                                          00015500
      upper ans                                                         00015600
      if ans = "Y" then do                                              00015700
         x = msg(on)                                                    00015800
         x = outtrap("line.",1)                                         00015900
         "SUBMIT '"tempdsn1"'"                                          00016000
      end                                                               00016300
   address tso
   "DELETE '"tempdsn1"'"
  "FREE DD(INFILE)"                                                     00016500
  "FREE DD(ISPFILE)"                                                    00016500
  end
 end
 return 0                                                               00016600
