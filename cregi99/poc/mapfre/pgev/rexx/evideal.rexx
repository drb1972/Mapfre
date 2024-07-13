/*rexx                                                               */
/* initialise variables                                              */
parse arg c1action tgt c1sy c1su c1ty c1element c1cci

if c1action = 'GENERATE' then c1action = 'ADD'
if c1action = 'TRANSFER' then c1action = 'MOVE'

say 'EVIDEAL:'
say 'EVIDEAL: Parms received'
say 'EVIDEAL: TGT       =' tgt
say 'EVIDEAL: C1SY      =' c1sy
say 'EVIDEAL: C1SU      =' c1su
say 'EVIDEAL: C1TY      =' c1ty
say 'EVIDEAL: C1ELEMENT =' c1element
say 'EVIDEAL: C1ACTION  =' c1action
say 'EVIDEAL: C1CCID    =' c1cci
say 'EVIDEAL: Temp file = TTEV.TMP.'c1sy'.'c1element'.TEMP'
say 'EVIDEAL:'

"EXECIO 1 DISKR SOURCE (STEM data. FINIS)" /* read source file       */
if rc ^= 0 then call exception rc 'DISKR of DDname SOURCE failed'

say 'EVIDEAL: Data read from source file:-'
say
say data.1
say

x = pos('VERSION',data.1)
x = x + 8

y = pos('SYSTEM',data.1)
y = y + 7

idlver = substr(data.1,x,3)
idlsys = substr(data.1,y,3)

say 'EVIDEAL: parms produced are :-'
say 'EVIDEAL:' c1action','tgt','c1sy','c1su','idlsys','c1ty','c1element','idlver

queue c1action','tgt','c1sy','c1su','idlsys','c1ty','c1element','idlver
/* userid & password                                                 */
queue 'ENDEVOR,ROVEDNE'
queue 'TTEV.TMP.'c1sy'.'c1element'.TEMP'

/* Write the cards to dataset */
"EXECIO * DISKW CPBD7781" /* Write the cards to dataset              */
if rc ^= 0 then call exception rc 'DISKW of DDname CPBD7781 failed'

queue c1action','tgt','c1su','idlsys','c1ty','c1element','idlver','c1cci

/* userid & password                                                 */
queue 'ENDEVOR,ROVEDNE'

"EXECIO * DISKW CPBD7779" /* Write the cards to dataset              */
if rc ^= 0 then call exception rc 'DISKW of DDname CPBD7779 failed'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
