/* rexx - Generate walker error cards   */                              00010000
arg char                                                                00023000
                                                                        00030100
binnum = D2C(char,2)                                                    00030300
                                                                        00030700
                                                                        00030800
PUSH 'ORN      PN ®'                                                    00033000
'execio 1 diskw restore'  /*  Write the 1st statement  */               00034000
PUSH 'U**SSERR                           'binnum                        00034100
'execio 1 diskw restore'  /*  Write the 2nd statement  */               00034200
PUSH 'U**S1800                           'binnum                        00034300
'execio 1 diskw restore'  /*  Write the 3rd statement  */               00034400
                                                                        00035000
'execio 0 diskr restore (finis'   /* Close file  */                     00230000
