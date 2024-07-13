        /* This Rexx Exec will select panel KPRINTM which allows users to */
        /* edit, browse, copy, email or print datasets.  (Utility Panel)   */

        Address ISPEXEC

        arg in_dsn opt

        if length(in_dsn) > 0 then do
           wdsn = in_dsn
           "Vput (Wdsn) Profile"
           end

        if length(opt) > 0 then do
           kprcmd = opt
           "Vput (kprcmd) Shared"
        /*   "Control Nondispl Enter" */
           end

        "Select Panel(KPRINTM)"

        exit
