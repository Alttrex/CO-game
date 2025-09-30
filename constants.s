    debugIntMessage: .asciz "%lu\n" # TEMP
    holySHIIIIT: .asciz "HOOOOLLY SHIT\n" # TEMP

    textYes: .asciz "Yes"
    textNo: .asciz "No"
    textNewLine: .asciz "\n"

    screenWidth: .quad 800
    screenHeight: .quad 600

    GRAY:
        .byte 130 # r
        .byte 130 # g
        .byte 130 # b
        .byte 255 # a

    RED:
        .byte 100 # r
        .byte 0 # g
        .byte 0 # b
        .byte 255 # a
    
    enemyWidth: .quad 100
    enemyHeight: .quad 50


    windowTitle: .asciz "Typper"


    word: .asciz "stupid"
