/* REXX - C1SPEDIT

      ISREDIT EDIT MACRO

    The old version of this macro used to make a dummy change to force
    a change so that a CANCEL could be detected, but at the cost of
    being unable to detect a real change.  This version uses zverb
    and the Edit panel includes the )panel statement.

    The new thing we can add is support for model SCL statements and
    SCL validation routines so there is now a model class and macro/
    alias definietions.

    Note: If you want to use ENDIE4VS outside of QuickEdit, you need
    to add an ISPLLIB pointint to .CSIQLOAD or better, run with
    Endevor in Linklst.

     */
 ADDRESS ISREDIT
 "MACRO (PARMS)"
 ADDRESS ISPEXEC "CONTROL ERRORS RETURN"   /* TRAP PANEL NOT MODIFIED*/
 "MODEL CLASS SCL"                         /* SUPPORT SCL MODELS     */
 "SETUNDO KEEP"                            /* ALLOW UNDO IF DATA SAVE*/
 "DEFINE ENDIE4VS MACRO PGM"               /* DEF VALIDATE SCL MACRO */
 "DEFINE VALIDATE ALIAS ENDIE4VS"          /* DEF VALIDATE ALIAS     */
 "DEFINE VAL      ALIAS ENDIE4VS"          /* ...AND SHORT VERSION   */
 ADDRESS ISPEXEC "CONTROL ERRORS CANCEL"   /* TURN OFF ERROR RETURN  */
 EXIT 0
