/* rexx */                                                              00010002
/*--------------------------------------------------------------------*/00020002
/*- Remove backup statements from Generol Migration Input            -*/00030002
/*--------------------------------------------------------------------*/00050002
/*- What                                      Who           When     -*/00060002
/*--------------------------------------------------------------------*/00070002
/*- Created                                   Craig Rex     23/06/01 -*/00080002
/*--------------------------------------------------------------------*/00090002
                                                                        00110002
  cnt = 1                                                               00180002
  cnt2 = 1                                                              00180002
                                                                        00190002
 "EXECIO * DISKR INFILE (STEM SRCIN. FINIS)"                            00200002
                                                                        00250002
    do until cnt > srcin.0                                              00300002
      x = pos('TOLIB1     ',srcin.cnt)                                  00310002
      y = pos('TOLIB2     ',srcin.cnt)                                  00310002
      z = pos('HOLD',srcin.cnt)                                         00310002
      if x = 0 & y = 0 & z = 0 then do
        out.cnt2  = srcin.cnt                                           00360002
        cnt = cnt + 1                                                   00360002
        cnt2 = cnt2 + 1                                                 00360002
      end                                                               00370003
      else cnt = cnt + 1
    end                                                                 00370003

 "EXECIO * DISKW OUTFILE (STEM OUT. FINIS"                              00200002
                                                                        00420002
  exit                                                                  00960002
