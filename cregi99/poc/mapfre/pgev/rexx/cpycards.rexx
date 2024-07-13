/* rexx - Generate IEBCOPY control cards from INCLUDE(OBJ) cards  */    00010001
/*        in a linkdeck      */                                         00020001
                                                                        00021006
/* Read ENDEVOR LINKCARD member  */                                     00022006
                                                                        00023010
'execio * diskr source (stem line. finis'                               00030002
                                                                        00030108
PUSH ' COPY I=(FROM1,FROM2,FROM3,FROM4,FROM5,FROM6),O=TO'               00030211
'execio 1 diskw cpycards'   /*  Write the 1st IEBCOPY statement  */     00030308
                                                                        00031006
do i = 1 to line.0          /* Process each line  */                    00040006
                                                                        00050006
  data = STRIP(line.i)      /* strip leading blanks  */                 00060006
                                                                        00061006
  if WORD(data,1) = 'INCLUDE' &,                                        00070003
    SUBSTR(WORD(data,2),1,6) = 'OBJECT' then do                         00080000
                 /* line.i is an INCLUDE OBJECT card */                 00090006
                                                                        00091006
    open = POS('(',data)     /* Find left bracket   */                  00100006
    close = POS(')',data)    /* Find right Bracket  */                  00110006
                                                                        00111006
    member_name = SUBSTR(data,open+1,close-open-1)                      00120000
                                                                        00121006
    PUSH '  SELECT MEMBER='member_name                                  00130008
                                                                        00130106
    'execio 1 diskw cpycards'  /*  Write an IEBCOPY statement  */       00131006
  end                                                                   00140000
  else do                                                               00150004
    PUSH line.i                                                         00160000
    'execio 1 diskw lnkcards'  /*  Write a Link statement asis   */     00170006
  end                                                                   00180000
end                                                                     00190000
                                                                        00191006
'execio 0 diskr cpycards (finis'    /* Close file  */                   00200006
'execio 0 diskr lnkcards (finis'    /* Close file  */                   00210006
