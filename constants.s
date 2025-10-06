
    debugIntMessage: .asciz "%ld\n" # TEMP
    holySHIIIIT: .asciz "HOOOOLLY SHIT\n" # TEMP

    textYes: .asciz "Yes"
    textNo: .asciz "No"
    textNewLine: .asciz "\n"

    printFPSMessage: .asciz "FPS: %lu\n"

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

    enemyStartX: .quad 900

    ENEMY_START_Y_MIN: .quad 100
    ENEMY_START_Y_MAX: .quad 500


    windowTitle: .asciz "Typper"

    enemyStructSize: .quad 4 # in quads

    enemyFontSize: .quad 22

    ENEMY_FINISH_LINE: .quad -100 # after enemy crosses this x, the game is over

    ENEMY_FRAMES_PER_MOVEMENT: .quad 10
    ENEMY_MOVEMENT_SPEED:      .quad 1

    ENEMY_FRAMES_PER_SPAWN:    .quad 480
    FPS:                       .quad 120

