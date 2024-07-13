          /***********************************************************/
          /**                                                       **/
          /**                          C1SPEDIT                     **/
          /**                                                       **/
          /**                     ISREDIT EDIT MACRO                **/
          /**                                                       **/
          /**                                                       **/
          /**                   CAUSE A CHANGE IN THE               **/
          /**                   EDIT DATASET SO AN END CMD          **/
          /**                   CAN BE DISTINGUISHED                **/
          /**                   FROM A CANCEL CMD.                  **/
          /**                                                       **/
          /***********************************************************/
          ISREDIT MACRO
          ISREDIT CHANGE P'=' P'=' FIRST
          ISREDIT FIND   P'='      FIRST
          ISREDIT RESET
          EXIT
