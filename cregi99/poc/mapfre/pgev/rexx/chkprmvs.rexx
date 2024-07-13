/* rexx */                                                              00010000
/*--------------------------------------------------------------------*/00020000
/*- Read output from PROMVS to see if extract worked                 -*/00030000
/*- if not the write a dummy record to the output file so that       -*/00031000
/*  the processor doesnt abend with a S013-18                        -*/00031100
/*--------------------------------------------------------------------*/00032000
/*- What                                      Who           When     -*/00033000
/*--------------------------------------------------------------------*/00034000
/*- Created                                   Craig Rex     14/04/01 -*/00035000
/*--------------------------------------------------------------------*/00036000
 trace o                                                                00060007
                                                                        00110000
 "EXECIO 4 DISKR INFILE (STEM inlist. FINIS)"                           00470000
  promsg = substr(inlist.4,2,8)                                         00500004
                                                                        00501000
  if promsg = '@BATSTAT' then nop                                       00502000
  else do                                                               00503000
   outlist.1 = 'PRO4 COBOL GENERATION FAILED FOR THIS ELEMENT'          00504003
   "EXECIO 1 DISKW OUTFILE (STEM outlist. FINIS)"                       00505003
  end                                                                   00506000
  exit                                                                  01210000
