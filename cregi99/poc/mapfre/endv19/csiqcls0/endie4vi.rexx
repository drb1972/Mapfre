/* REXX - QUICK EDIT Validate SCL Initial MACRO FOR ENDIE4VS(Validate)
          Used to setup the validate program macro and aliases.
          It can be tailored to add support for different profiles
          or other overrides (for example number mode std nondispl)
*/
ADDRESS ISREDIT
"MACRO (PARMS)"
SETCMDS:
"SETUNDO KEEP"                       /* Allow Undo if data saved     */
"DEFINE ENDIE4VS MACRO PGM"          /* DEFINE VALIDATE SCL MACRO    */
"DEFINE VALIDATE ALIAS ENDIE4VS"     /* DEFINE VALIDATE Alias        */
"DEFINE VAL      ALIAS ENDIE4VS"     /* ...and short version         */
