/* rexx - Generate IEBCOPY control cards from INCLUDE(OBJ) cards  */    00010000
/*        in a linkdeck      */                                         00020000
                                                                        00021000
arg disp element_name                                                   00021100
                                                                        00021200
/* Read ENDEVOR LINKCARD member  */                                     00022000
                                                                        00023000
'execio * diskr source (stem line. finis'                               00024000
                                                                        00025000
PUSH ' COPY I=(FROM1,FROM2,FROM3,FROM4,FROM5,FROM6),O=TO'               00026000
'execio 1 diskw cpycards'   /*  Write the 1st IEBCOPY statement  */     00027000
                                                                        00028000
do i = 1 to line.0          /* Process each line  */                    00029000
                                                                        00030000
  data = STRIP(line.i)      /* strip leading blanks  */                 00040000
                                                                        00050000
  if WORD(data,1) = 'INCLUDE' &,                                        00060000
    SUBSTR(WORD(data,2),1,6) = 'OBJECT' then do                         00070000
                 /* line.i is an INCLUDE OBJECT card */                 00080000
                                                                        00090000
    open = POS('(',data)     /* Find left bracket   */                  00100000
    close = POS(')',data)    /* Find right Bracket  */                  00110000
                                                                        00111000
    member_name = SUBSTR(data,open+1,close-open-1)                      00112000
                                                                        00113000
    PUSH '  SELECT MEMBER='member_name                                  00114000
                                                                        00115000
    'execio 1 diskw cpycards'  /*  Write an IEBCOPY statement  */       00116000
  end                                                                   00117000
  else do                                                               00118000
    PUSH line.i                                                         00119000
    'execio 1 diskw lnkcards'  /*  Write a Link statement asis   */     00120000
  end                                                                   00130000
end                                                                     00140000
                                                                        00150000
if disp ^= 'NEW' then do                                                00151001
    PUSH ' INCLUDE SYSLIB('element_name')'                              00152000
    'execio 1 diskw lnkcards'  /*  Write a Link statement    */         00153000
    end                                                                 00154000
                                                                        00155000
'execio 0 diskr cpycards (finis'    /* Close file  */                   00160000
'execio 0 diskr lnkcards (finis'    /* Close file  */                   00170000
