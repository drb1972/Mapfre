/* rexx - Generate IEBCOPY control cards from INCLUDE(OBJ) cards  */    00010000
/*        in a linkdeck      */                                         00020000
                                                                        00021000
arg element_name disp                                                   00021100
                                                                        00021200
/* Read ENDEVOR LINKCARD member  */                                     00021300
                                                                        00021400
'execio * diskr source (stem line. finis'                               00021500
                                                                        00021600
PUSH ' COPY I=(FROM1,FROM2,FROM3,FROM4,FROM5,FROM6),O=TO'               00021700
'execio 1 diskw cpycards'   /*  Write the 1st IEBCOPY statement  */     00021800
                                                                        00021900
members = 'no'                                                          00022000
                                                                        00022100
do i = 1 to line.0          /* Process each line  */                    00022200
                                                                        00023000
  data = STRIP(line.i)      /* strip leading blanks  */                 00024000
                                                                        00025000
  if WORD(data,1) = 'INCLUDE' &,                                        00026000
    SUBSTR(WORD(data,2),1,6) = 'OBJECT' then do                         00027000
                 /* line.i is an INCLUDE OBJECT card */                 00028000
                                                                        00029000
    open = POS('(',data)     /* Find left bracket   */                  00030000
    close = POS(')',data)    /* Find right Bracket  */                  00040000
                                                                        00050000
    member_name = SUBSTR(data,open+1,close-open-1)                      00060000
                                                                        00070000
    PUSH '  SELECT MEMBER='member_name                                  00080000
                                                                        00081000
    members = 'yes'                                                     00082000
                                                                        00090000
    'execio 1 diskw cpycards'  /*  Write an IEBCOPY statement  */       00100000
  end                                                                   00110000
  else do                                                               00111000
    PUSH line.i                                                         00112000
    'execio 1 diskw lnkcards'  /*  Write a Link statement asis   */     00113000
  end                                                                   00114000
end                                                                     00115000
                                                                        00116000
if disp ^= 'NEW' then do                                                00117000
    PUSH ' INCLUDE SYSLIB('element_name')'                              00118000
    'execio 1 diskw lnkcards'  /*  Write a Link statement    */         00119000
    end                                                                 00120000
                                                                        00130000
'execio 0 diskr cpycards (finis'    /* Close file  */                   00140000
'execio 0 diskr lnkcards (finis'    /* Close file  */                   00150000
                                                                        00160000
if members = 'yes' then exit 0                                          00170000
                   else exit 4                                          00180000
