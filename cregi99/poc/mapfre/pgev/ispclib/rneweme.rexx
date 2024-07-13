        /*  Rexx ISPF Edit Macro                                       */

        /* ----------------------------------------------------------- */
        /*                                                             */
        /*  This ISPF Edit Macro is used as an Alias for the ISPF EDIT */
        /*  'END' command by the RISCNEWS exec.                        */
        /*                                                             */
        /* ----------------------------------------------------------- */
        Address ISREDIT
        "MACRO (PARM) NOPROCESS"

        "(NUMVAL) = NUMBER"
        if numval = "ON" then do
           smsg = ""
           lmsg = "You must UNNUMBER prior to saving this entry..."
           Address ISPEXEC "SETMSG MSG(RNEW000)"
           exit 0
           end

        "DEFINE END RESET"     /* reset END back to normal */
        "DEFINE CANCEL RESET"  /* reset CANCEL back to normal */

        "SAVE"
        "END"

        rnewsend = "END"
        Address ISPEXEC "VPUT (rnewsend)"
