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
                                                                        00022300
  data = STRIP(line.i)      /* strip leading blanks  */                 00022400
                                                                        00022500
  if WORD(data,1) = 'INCLUDE' &,                                        00022600
    SUBSTR(WORD(data,2),1,6) = 'OBJECT' then do                         00022700
                 /* line.i is an INCLUDE OBJECT card */                 00022800
                                                                        00022900
    open = POS('(',data)     /* Find left bracket   */                  00023000
    close = POS(')',data)    /* Find right Bracket  */                  00024000
                                                                        00025000
    member_name = SUBSTR(data,open+1,close-open-1)                      00026000
                                                                        00027000
    PUSH '  SELECT MEMBER='member_name                                  00028000
                                                                        00029000
    members = 'yes'                                                     00030000
                                                                        00040000
    'execio 1 diskw cpycards'  /*  Write an IEBCOPY statement  */       00050000
  end                                                                   00060000
  else do                                                               00070000
     if WORD(data,1) ^= 'NAME' then do                                  00071001
        PUSH line.i                                                     00080001
        'execio 1 diskw lnkcards'  /* Write a Link statement asis */    00090001
     end                                                                00091001
     else nop                                                           00092003
  end                                                                   00100000
end                                                                     00110000
                                                                        00111000
if disp ^= 'NEW' then do                                                00112000
    PUSH ' INCLUDE SYSLIB('element_name')'                              00113000
    'execio 1 diskw lnkcards'  /*  Write a Link statement    */         00114000
    end                                                                 00115000
                                                                        00116000
'execio 0 diskr cpycards (finis'    /* Close file  */                   00117000
'execio 0 diskr lnkcards (finis'    /* Close file  */                   00118000
                                                                        00119000
if members = 'yes' then exit 0                                          00120000
                   else exit 4                                          00130000
