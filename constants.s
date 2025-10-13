    #debug stuff
    debugIntMessage: .asciz "%ld\n" # TEMP
    holySHIIIIT: .asciz "HOOOOLLY SHIT\n" # TEMP

    textYes: .asciz "Yes"
    textNo: .asciz "No"
    textNewLine: .asciz "\n"

    printFPSMessage: .asciz "FPS: %lu\n"


    #window dimensions
    screenWidth: .quad 800
    screenHeight: .quad 600
    windowTitle: .asciz "Typper"

    #colors
    BLACK:
        .byte 0 # r
        .byte 0 # g
        .byte 0 # b
        .byte 255 # a

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

    BLUE:
        .byte 0 # r
        .byte 0 # g
        .byte 100 # b
        .byte 255 # a

    GREEN:
        .byte 0 # r
        .byte 100 # g
        .byte 0 # b
        .byte 255 # a

    PURPLE:
        .byte 100 # r
        .byte 0   # g
        .byte 100 # b
        .byte 255 # a


    WHITE:
        .byte 255 # r
        .byte 255 # g
        .byte 255 # b
        .byte 255 # a
    
    #enemy constants
    enemyWidth: .quad 100
    enemyHeight: .quad 50

    enemyStartX: .quad 810

    ENEMY_START_Y_MIN: .quad 100
    ENEMY_START_Y_MAX: .quad 500

    enemyFontSize: .quad 30

    ENEMY_FINISH_LINE: .quad -100 # after enemy crosses this x, the game is over

    ENEMY_FRAMES_PER_MOVEMENT: .quad 20 # every X frames, the enemy moves
    ENEMY_MOVEMENT_SPEED:      .quad 2 # how many pixels the enemy moves every movement

    ENEMY_DEFAULT_MOVEMENT_SPEED: .quad 2
    ENEMY_DEFAULT_FRAMES_PER_MOVEMENT: .quad 20

    ENEMY_FRAMES_PER_SPAWN:    .quad 720 # every X frames, spawn a new enemy
    
    #FPS
    FPS:                       .quad 240 #frames per second
    
    #Messages
    deathMessage: .asciz "You Died! Play Again?\nPress Y to play again"
    welcomeMessage: .asciz "Welcome to Typper!\nPress to start"
    
    HIGH_SCORE_FILE_NAME:          .asciz "high_score"
    HIGH_SCORE_FILE_OPEN_FLAGS_READ:     .asciz "r"
    HIGH_SCORE_FILE_OPEN_FLAGS_WRITE:     .asciz "w"
    HIGH_SCORE_FILE_CONTENT_FORMAT: .asciz "%lu"

    #file
    imagePath: .asciz "start.png"
