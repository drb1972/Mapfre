/* rexx */                                                              00000100
/*--------------------------------------------------------------------*/00000200
/*- Create Input file to migrate code in CA-Generol                  -*/00000300
/*-                                                                  -*/00000400
/*--------------------------------------------------------------------*/00000500
/*- What                                      Who           When     -*/00000600
/*--------------------------------------------------------------------*/00000700
/*- Created                                   Craig Rex     05/05/04 -*/00000800
/*--------------------------------------------------------------------*/00000900
 trace o
 x = msg(off)                                                           00001100
 tot = 0
 jcldsn = 'TTYY.GENEROL.MIGRATE.DATA'
                                                                        00001200
 "ISPEXEC DISPLAY PANEL(EVGENBL1)"                                      00004000
  prc = rc                                                              00004100
  if prc ^= 0 then return 0                                             00004500
   else do
   crno = substr(chgno,3,6)
   memnam = adteam || crno
"ISPEXEC VPUT (SGTLIB CHGNO ADTEAM SUBLIB CMPNAM CMPTYP CHGTYP) PROFILE"00004700
   ADDRESS TSO "ALLOC DA('"jcldsn"') SHR F(ISPFILE)"
   "ISPEXEC FTOPEN"
   "ISPEXEC FTINCL EVGENBL1"                                            00009000
   tot = tot + 1
  end

  do until prc ^= 0
    ocmp = cmpnam || cmptyp || sublib
  "ISPEXEC DISPLAY PANEL(EVGENBL2)"                                     00004000
   prc = rc
"ISPEXEC VPUT (SGTLIB CHGNO ADTEAM SUBLIB CMPNAM CMPTYP CHGTYP) PROFILE"00004700
    ncmp = cmpnam || cmptyp || sublib
    if prc = 0 & ocmp ^= ncmp then do
      "ISPEXEC FTINCL EVGENBL2"                                         00009000
      tot = tot + 1
    end
  else do
   if prc = 0 then do
   "ISPEXEC ADDPOP"
   "ISPEXEC DISPLAY PANEL(EVGENBLE)"
   "ISPEXEC REMPOP"
   end
   else nop
   end
  end
   "ISPEXEC FTCLOSE NAME("memnam")"                                     00015200
   ADDRESS TSO "FREE DD(ISPFILE)"                                       00016500
   "ISPEXEC EDIT DATASET('"jcldsn"("memnam")') MACRO(EVGENSRT)"         00015300
return 0                                                                00016600
