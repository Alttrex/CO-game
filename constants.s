    debugIntMessage: .asciz "%lu\n" # TEMP
    holySHIIIIT: .asciz "HOOOOLLY SHIT\n" # TEMP

    textYes: .asciz "Yes"
    textNo: .asciz "No"
    textNewLine: .asciz "\n"

    screenWidth: .quad 800
    screenHeight: .quad 600

    WHITE:
        .byte 250 # r
        .byte 250 # g
        .byte 250 # b
        .byte 255 # a

    RED:
        .byte 100 # r
        .byte 0 # g
        .byte 0 # b
        .byte 255 # a


    windowTitle: .asciz "Typper"
    
    
    TestWord: .asciz "Test"





    