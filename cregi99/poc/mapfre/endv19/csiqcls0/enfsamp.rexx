/* REXX */
ARG child_prm
msgid = WORD(child_prm,1)
prm1  = WORD(child_prm,2)
prm2  = WORD(child_prm,3)

ADDRESS ISPEXEC "LIBDEF ISPLLIB STACK DATASET ",
                    "ID('IPRFX.IQUAL.CSIQLOAD')"

/*Note* The length of a REXX generated message must be 2 bytes less*/
/*Note*  than the maximum 104 to account for the enclosing quotes  */
message= msgid||" A "||prm1||" OF "||prm2||" FAILED"
message=LEFT(message,102)
y=BC1PTRAP(message)
IF WORD(y,1)/="*-ok" THEN
   DO
   SAY "Return from BC1TRAP0 is "||WORD(y,1)
   SAY "Reason is "||WORD(y,2)
   END
ELSE
   SAY "Message successfully sent"

ADDRESS ISPEXEC "LIBDEF ISPLLIB"

EXIT
