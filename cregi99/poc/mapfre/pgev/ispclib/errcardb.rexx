/* rexx - Generate walker error cards   */                              00010000
arg char                                                                00023000
                                                                        00030100
binnum = D2C(char,2)                                                    00030300
                                                                        00030700
PUSH 'OBN      PN _'                                                    00033000
'execio 1 diskw backup'   /*  Write the 1st statement  */               00034000
PUSH 'B**SSERR           'binnum                                        00034100
'execio 1 diskw backup'   /*  Write the 2nd statement  */               00034200
PUSH 'B**S1800           'binnum                                        00034300
'execio 1 diskw backup'   /*  Write the 3rd statement  */               00034400
                                                                        00035000
'execio 0 diskr backup (finis'    /* Close file  */                     00230000
