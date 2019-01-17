            ADD R0,R0,#3
            JSR AGAIN
AGAIN       ADD R0,R0,#-1
            BRp AGAIN
            TRAP x25
