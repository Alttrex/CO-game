debugIntMessage: .asciz "%lu\n" # TEMP

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


    windowTitle: .asciz "Typper"


    word: .asciz "stupid"