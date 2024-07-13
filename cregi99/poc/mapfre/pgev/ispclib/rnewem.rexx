        /* rexx exec */

        Address ISREDIT

        "MACRO"
        if length(subject) = 0 then do
           "RESET"
           "(BOT) = LINENUM .ZLAST"
           if bot = 0 then "TENTER .ZF"
           end

        "RESET"
        "PROFILE UNLOCK"
        "RECOVERY ON"
        "NUMBER OFF"
        "CAPS OFF"
        "NULL ON"
        "AUTOLIST OFF"
        "PACK OFF"
        "HEX OFF"
        "AUTOSAVE ON"
        "AUTONUM OFF"
        "BOUNDS = 1 80"
        "DEFINE rneweme MACRO CMD"
        "DEFINE rnewemc MACRO CMD"
        "DEFINE END ALIAS rneweme"
        "DEFINE CANCEL ALIAS rnewemc"
