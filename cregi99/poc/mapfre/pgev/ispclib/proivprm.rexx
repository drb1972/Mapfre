/* rexx */                                                              00010002
/*--------------------------------------------------------------------*/00020002
/*- Read output from Endevor LIST action and build PRO-IV parms      -*/00030002
/*- to be added back to Endevor                                      -*/00040002
/*--------------------------------------------------------------------*/00050002
/*- What                                      Who           When     -*/00060002
/*--------------------------------------------------------------------*/00070002
/*- Created                                   Craig Rex     23/06/01 -*/00080002
/*--------------------------------------------------------------------*/00090002
 arg memname                                                            00091014
 x = msg(on)                                                            00100016
                                                                        00110002
/* Display panel to receive user info */                                00140002
 getinfo:                                                               00150002
    uid = sysvar('sysuid')                                              00160002
    pref= sysvar('syspref')                                             00170002
    cnt = 1                                                             00180002
                                                                        00190002
 "EXECIO * DISKR FUNOUT (STEM FUNLIST. FINIS)"                          00200002
 "EXECIO * DISKR FILOUT (STEM FILLIST. FINIS)"                          00210002
 "EXECIO * DISKR GLGOUT (STEM GLGLIST. FINIS)"                          00220002
 "EXECIO * DISKR INTOUT (STEM INTLIST. FINIS)"                          00230002
 "EXECIO * DISKR GMSOUT (STEM GMSLIST. FINIS)"                          00230003
 "ISPEXEC FTOPEN"                                                       00240004
                                                                        00250002
/* Skip through the list of FUN types & create PRO4 parms for each */   00260002
/* element                                                         */   00270002
                                                                        00280002
       if funlist.0 ^= 0 then do                                        00290003
        do until cnt > funlist.0                                        00300002
         elerec = substr(funlist.cnt,6,19)                              00310002
         if elerec = "&&ACTION ELEMENT  '" then do                      00320002
            funname = substr(funlist.cnt,25,8)                          00330002
            funname = strip(funname)                                    00340010
            "ISPEXEC FTINCL PROIVS06"                                   00350002
         cnt = cnt + 1                                                  00360002
         end                                                            00370003
         else cnt = cnt + 1                                             00380003
        end                                                             00390003
       end                                                              00400003
       cnt = 1                                                          00410002
                                                                        00420002
/* Skip through the list of FIL types & create PRO4 parms for each */   00430002
/* element                                                         */   00440002
                                                                        00450002
       if fillist.0 ^= 0 then do                                        00460003
        do until cnt > fillist.0                                        00470002
         elerec = substr(fillist.cnt,6,19)                              00480002
         if elerec = "&&ACTION ELEMENT  '" then do                      00490002
            filname = substr(fillist.cnt,25,8)                          00500002
            filname = strip(filname)                                    00510010
            "ISPEXEC FTINCL PROIVS07"                                   00520002
         cnt = cnt + 1                                                  00530002
         end                                                            00540003
         else cnt = cnt + 1                                             00550003
        end                                                             00560003
       end                                                              00570003
                                                                        00580002
       cnt = 1                                                          00590002
                                                                        00600002
/* Skip through the list of GLG types & create PRO4 parms for each */   00610002
/* element                                                         */   00620002
                                                                        00630002
       if glglist.0 ^= 0 then do                                        00640011
        do until cnt > glglist.0                                        00650002
         elerec = substr(glglist.cnt,6,19)                              00660002
         if elerec = "&&ACTION ELEMENT  '" then do                      00670002
            glgname = substr(glglist.cnt,25,8)                          00680002
            glgname = strip(glgname)                                    00690010
            "ISPEXEC FTINCL PROIVS09"                                   00700002
         cnt = cnt + 1                                                  00710002
         end                                                            00720003
         else cnt = cnt + 1                                             00730003
        end                                                             00740003
       end                                                              00750003
                                                                        00760002
       cnt = 1                                                          00770002
                                                                        00780002
/* Skip through the list of INT types & create PRO4 parms for each */   00790002
/* element                                                         */   00800002
                                                                        00810002
       if intlist.0 ^= 0 then do                                        00820011
        do until cnt > intlist.0                                        00830002
         elerec = substr(intlist.cnt,6,19)                              00840002
         if elerec = "&&ACTION ELEMENT  '" then do                      00850002
            intname = substr(intlist.cnt,25,8)                          00860002
            intname = strip(intname)                                    00870010
            "ISPEXEC FTINCL PROIVS08"                                   00880002
         cnt = cnt + 1                                                  00890002
         end                                                            00900003
         else cnt = cnt + 1                                             00910003
        end                                                             00920003
       end                                                              00930003
                                                                        00930004
       cnt = 1                                                          00930005
                                                                        00930006
/* Skip through the list of GMS types & create PRO4 parms for each */   00930007
/* element                                                         */   00930008
                                                                        00930009
       if gmslist.0 ^= 0 then do                                        00930010
        do until cnt > gmslist.0                                        00930011
         elerec = substr(gmslist.cnt,6,19)                              00930020
         if elerec = "&&ACTION ELEMENT  '" then do                      00930030
            gmsname = substr(gmslist.cnt,25,8)                          00930040
            gmsname = strip(gmsname)                                    00930050
            "ISPEXEC FTINCL PROIVS11"                                   00930060
         cnt = cnt + 1                                                  00930070
         end                                                            00930080
         else cnt = cnt + 1                                             00930090
        end                                                             00930100
       end                                                              00930200
                                                                        00930300
       cnt = 1                                                          00930400
                                                                        00940002
     "ISPEXEC FTCLOSE NAME("memname")"                                  00950017
  exit                                                                  00960002
