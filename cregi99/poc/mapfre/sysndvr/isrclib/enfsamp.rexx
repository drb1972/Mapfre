/* REXX */                                                              00001000
ARG child_prm                                                           00001100
msgid = WORD(child_prm,1)                                               00001200
prm1  = WORD(child_prm,2)                                               00001300
prm2  = WORD(child_prm,3)                                               00001400
                                                                        00002000
"ISPEXEC LIBDEF ISPLLIB DATASET ID('TSOXX4.ENDEVOR.V16.CSIQLOAD')"      00002601
                                                                        00003000
/*Note* The length of a REXX generated message must be 2 bytes less*/   00003100
/*Note*  than the maximum 104 to account for the enclosing quotes  */   00003200
message= msgid||" A "||prm1||" OF "||prm2||" FAILED"                    00003400
message=LEFT(message,102)                                               00003500
y=BC1PTRAP(message)                                                     00003602
IF WORD(y,1)/="*-ok" THEN                                               00003700
   DO                                                                   00003800
   SAY "Return from BC1TRAP0 is "||WORD(y,1)                            00003900
   SAY "Reason is "||WORD(y,2)                                          00004000
   END                                                                  00004100
ELSE                                                                    00004200
   SAY "Message successfully sent"                                      00004300
"ISPEXEC LIBDEF ISPLLIB"                                                00004400
EXIT                                                                    00005000
