/* rexx                                 */

    ADDRESS TSO

    "ALLOC F(LGNT$$$I) DUMMY"
    "ALLOC F(LGNT$$$O) DUMMY"
   "EXECIO * DISKR LGNT$$$I"
    cc=rc
    say rc
   "EXECIO * DISKR LGNT$$$O"
    cc=rc
    say rc
