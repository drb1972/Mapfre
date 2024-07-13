        /* --------------------  rexx procedure  -------------------- *
         * Name:      RNEWSCK                                         *
         *                                                            *
         * Function:  Check for new news items                        *
         *                                                            *
         *            1) test for SYSL.ISPF.TEST dataset in the       *
         *               current allocations.  If so then display     *
         *               new Systems news                             *
         *            2) Display new KPIT news items                  *
         *                                                            *
         * Syntax:    %rnewsck                                        *
         *                                                            *
         * Author:    Lionel B. Dyck                                  *
         *            Kaiser Permanente Information Technology        *
         *            Walnut Creek, CA 94598                          *
         *            (925) 926-5332                                  *
         *            Internet: lionel.b.dyck@kp.org                  *
         *                                                            *
         * History:                                                   *
         *            03/27/00 - creation                             *
         *                                                            *
         * ---------------------------------------------------------- */

        Address ISPExec "Vget (rnewsck) Profile"
        if rnewsck = date('b') then exit
        rnewsck = date('b')
        Address ISPExec "Vput (rnewsck) Profile"

        call outtrap "listalc."
        "listalc"
        call outtrap "off"

        found = 0

        do i = 1 to listalc.0
           if pos("SYSL.ISPF.TEST",listalc.i) > 0 then found = 1
           if found = 1 then leave
           end

        if found = 1 then do
           "%rnews KSYS NEW"
           end

        "%Rnews kpit new"
