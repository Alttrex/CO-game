.global main

.data
    .include "constants.s"
    .include "List.s"
    wordNumber: .quad 0
    scoreMessage: .asciz "Score: %ld"
    highScoreMessage: .asciz "High Score: %ld"
    score: .quad 0
    highScore: .quad 0

    maxWordIndex: .quad 200
    
    # variables
    # ------------------------------------------------------------
    typedTextBuffer: 
        .zero 0x100 # allocate 100 zeros (null bytes)
    
    typedTextBufferIndex: .quad 0

    enemySpawnedMessage: .asciz "Enemy spawned at x: %ld, y: %ld with the word '%s'. Index: %ld\n"

    highScoreBuffer: .quad 0

    enemyAmount: .quad 0

    # -------------------------------------------------------------

.include "enemy.s"


main:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    # window creation
    movq  screenWidth,  %rdi
    movq  screenHeight, %rsi
    movq  $windowTitle, %rdx
    call  InitWindow



    subq $800, %rsp # reserve 100 quads for variables
                    # -800(%rbp) -> -8(%rbp)
    
    subq $800, %rsp # reserve another 100 quads for Enemy array
                    # that is gonna be our Enemy array
                    # -1600(%rbp) -> -808(%rbp)

    # clear the array
    leaq -1600(%rbp), %rdi # the start of the enemy array as first parameter
    movq $800, %rsi # size of the array - 100 bytes
    call clearMemory
    
    movq $20, -8(%rbp) # size of our array: -8(%rbp)
             # now we can address the i-th enemy with (enemy_array, i, enemy_size_in_bytes)

    # read the high score from file
    movq $HIGH_SCORE_FILE_NAME, %rdi
    call readScoreFromFile
    movq %rax, highScore

    movq FPS, %rdi
    call SetTargetFPS

    movq $0, -16(%rbp) # frame counter: -16(%rbp)

    startScreenLoop:
        call BeginDrawing
        
            movq WHITE, %rdi    #make BG white
            call ClearBackground

            movq $welcomeMessage, %rdi
            movq $130, %rsi
            movq $200, %rdx
            movq $50, %rcx
            movq BLACK, %r8
            call DrawText   # draw welcome message


            movq $300, %rdi
            movq $350, %rsi
            movq $200, %rdx
            movq $50, %rcx
            movq RED, %r8
            call DrawRectangle  # draw start button rectangle
                                #TODO: add text
            call EndDrawing

        
        movq $0, %rdi
        call IsMouseButtonPressed # 0 = left mouse button, check if pressed 

        cmpb $1, %al
        je  mousePressed # if pressed, check if inside rectangle


        call WindowShouldClose # check if window should close
        cmpq $1, %rax
        je   end

        jmp startScreenLoop #repeat the start screen loop

    mainloop:
        incq -16(%rbp) # increment the frame counter

        ## if window should close, end loop (and program)
        call WindowShouldClose
        cmpq $1, %rax
        je   end

        ## if the game is over -> enemies crossed the finish line, the game is over
        leaq -1600(%rbp), %rdi
        movq enemyAmount, %rsi
        call isGameOver
        cmpq  $1, %rax
        je   deathScreen

        ### MAINLOOP ###

        ## if the score is higher than highScore, highScore = score
        movq score, %rax
        cmpq highScore, %rax
        jle  mainloop_afterScoreSetting

        # highScore = score
        movq score, %rax
        movq %rax, highScore

        mainloop_afterScoreSetting:

        leaq -1600(%rbp), %rdi  # memory location of the enemy array
        movq -8(%rbp), %rsi # size of the array
        call processInput

        ## if score is higher than high score, chang e

        call BeginDrawing
            
            # clear background with gray color
            movq  GRAY, %rdi
            call  ClearBackground

            movq  $typedTextBuffer, %rdi
            movq  $10, %rsi
            movq  $10, %rdx
            movq  $50, %rcx
            movq  RED, %r8
            call DrawText   # draw the typed text buffer, which is what we are typing

            # draw score
            movq  $scoreMessage, %rdi
            movq  score, %rsi
            call TextFormat
            movq  %rax, %rdi
            movq  $10, %rsi
            movq  $530, %rdx
            movq  $30, %rcx
            movq  RED, %r8
            call DrawText   # draw the score

            # draw high score
            movq  $highScoreMessage, %rdi
            movq  highScore, %rsi
            call TextFormat
            movq  %rax, %rdi
            movq  $10, %rsi
            movq  $560, %rdx
            movq  $30, %rcx
            movq  RED, %r8
            call DrawText

            # process enemies
            leaq -1600(%rbp), %rdi  # memory location of the enemy array
            movq enemyAmount, %rsi # size of the array
            call processEnemies

            call GetFPS

            # spawn a new enemy every 2 seconds
            movq -16(%rbp), %r8
            cmpq ENEMY_FRAMES_PER_SPAWN, %r8 # compare ENEMY_FRAMES_PER_SPAWN to the frame counter
            jl mainloop_spawnEnemyEnd # if it is less, skip the spawning
            
            mainloop_spawnEnemy:    #debugging? I guess
                # print the FPS
                movq $printFPSMessage, %rdi
                movq %rax, %rsi
                call printf
                

                # divide score by 100
                movq $0, %rdx
                movq score, %rax
                movq $100, %r8
                divq %r8

                imulq   $95, %rax, %rdi

                cmp $9577, %rdi
                jl RandomWordGO
                jmp ItsToBig
                ItsToBig:
                    movq $9577, %rdi
                    jmp RandomWordGO

                RandomWordGO:
                    call getRandomWord
                    movq %rax, %rsi # the random word as the second parameter

                # spawn the enemy
                leaq -1600(%rbp), %rdi # the start of the enemy array as first parameter
                movq enemyAmount, %rdx # enemy amount as third parameter
                call spawnEnemy
                incq enemyAmount # increment enemy amount
                movq $0, -16(%rbp)  # set frame counter to 0        
            mainloop_spawnEnemyEnd:


        call EndDrawing

        jmp  mainloop    

deathScreen:
    ## if the highScore is equal to score, we beat it and it needs to be saved
    movq $HIGH_SCORE_FILE_NAME, %rdi
    call writeHighScoreToFile

    leaq -1600(%rbp), %rdi # the start of the enemy array as first parameter
    movq $800, %rsi # size of the array - 100 bytes
    call clearMemory    # clear the enemy array, so nothing is drawn and happeinging in the background

    movq $0, enemyAmount # reset enemy amount to 0
    movq $0, score # reset score to 0
    
    call BeginDrawing
    
    movq  BLACK, %rdi
    call ClearBackground

    movq $50, %rsi
    call MeasureText


    movq  $deathMessage, %rdi
    movq  $130, %rsi
    movq  $200, %rdx
    movq  $50, %rcx
    movq  WHITE, %r8
    call DrawText

    call EndDrawing

    movq $89, %rdi
    call IsKeyPressed
    cmpb $1, %al
        

    je   mainloop # if Y is pressed, restart the game

    call WindowShouldClose
    cmpq $1, %rax
    je   end

    jmp deathScreen

end:
    # close window and exit with code 0
    call  CloseWindow
    movq  $0, %rdi
    call  exit


# *************************************************************************************************************************
# * Subroutine: void processInput(Enemy *enemyArray, long arraySize)                                                      *
# * Description: Processes all input related events. Should be called once during every iteration of main loop            *
# * Parameters: -                                                                                                         *
# *************************************************************************************************************************
processInput:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    pushq %rdi # enemyArray
    pushq %rsi # arraySize

    # process characters
    call  processCharsPressed

    ## if enter is pressed, clear typedTextBuffer
    movq $257, %rdi # 257 = enter key
    call IsKeyPressed
    cmpb $0, %al   
    je  enterNotPressed
    ## if enter is pressed, clear typedTextBuffer and kill the enemy that contains the word
    movq -8(%rbp), %rdi # enemyArray
    movq enemyAmount, %rsi # enemy amount
    movq $typedTextBuffer, %rdx # the word to find
    call findEnemyWithWord

    ## if there exists such enemy (the function did not return -1, kill it)
    cmpq $-1, %rax
    je processInput_afterKillEnemy

    # kill the enemy
    movq -8(%rbp), %rdi
    movq %rax, %rsi
    movq enemyAmount, %rdx
    call killEnemyAtIndex # if the enemy was actually killed, returns 1 and 0 otehrwise
    # we can subtract the amount returned from enemyAmount
    subq %rax, enemyAmount

    processInput_afterKillEnemy:

    call clearDisplayBuffer # clear typedTextBuffer

    
    enterNotPressed:    # if enter is not pressed, jumps here

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret


# *************************************************************************************************************************
# * Subroutine: void processCharsPressed()                                                                                *
# * Description: Processes all the chars pressed since last GetCharPressed call. Adds every char to typedTextBuffer     *
# * Parameters: -                                                                                                         *
# *************************************************************************************************************************
processCharsPressed:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    beforeCharsProcessing:
    # get a char pressed from pool
    call  GetCharPressed

    ## if function returns 0, no char is left in pool and we end
    cmp   $0, %rax
    je    afterCharsProcessing

    # print the char code
    movq  %rax, %rdi
    call addCharToDisplayBuffer

    # process next char from pool
    jmp beforeCharsProcessing

    afterCharsProcessing:
    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret


# *********************************************************************************
# * Subroutine: void processCharsPressed(char toAdd)                              *
# * Description: adds a char to the end of string stored in typedTextBuffer     *
# * Parameters: toAdd - char that gets added to typedTextBuffer                 *
# *********************************************************************************
addCharToDisplayBuffer:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp


    # move the byte in %dil (toAdd) into typedTextBuffer at index typedTextBufferIndex
    movq  typedTextBufferIndex, %rbx   # move index into rbx
    leaq  typedTextBuffer, %rcx # move the address of typedTextBuffer into rcx
    movb  %dil, (%rbx, %rcx, 1) # move the char into address rbx + rcx*1 (indirect addressing)
    incq  typedTextBufferIndex # increment index

    # set the next character to null byte
    movq  typedTextBufferIndex, %rbx   # move index into rbx
    leaq  typedTextBuffer, %rcx # move the address of typedTextBuffer into rcx
    movb  $0, (%rbx, %rcx, 1) # move the char into address rbx + rcx*1 (indirect addressing)

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret


# *******************************************
# * Subroutine: void clearDisplayBuffer()   *
# * Description: Clear displayBuffer        *
# * Parameters: -                           *
# ******************************************
clearDisplayBuffer:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    # reset index
    movq $0, typedTextBufferIndex(%rip)

    # move 0 into byte at displayTextB
    movq  $0, typedTextBuffer(%rip)

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

# ****************************************************************************
# * Subroutine: void clearMemory(void *start, long amount)                   *
# * Description: Sets the 'amount' of bytes from the 'start' to zero         *
# ****************************************************************************
clearMemory:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    clearMemory_loop:    
        decq %rsi
        movb $0, (%rdi, %rsi, 1)

        ## if rsi is still above zero, loop again
        cmp $0, %rsi 
        jg clearMemory_loop
        

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

# **************************************************************************************************
# * Subroutine: char* getRandomWord(maxWord)                                                       *
# * Description: Returns a random word from the word list up to the one with index maxWord         *
# **************************************************************************************************
getRandomWord:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    # get a random index
    movq %rdi, %rsi
    movq $0, %rdi
    call GetRandomValue 

    movq $words, %rdi
    movq (%rdi, %rax, 8), %rax # return the word on the index

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

# **************************************************************************************************
# * Subroutine: int readScoreFromFile(char* fileName)                                              * 
# * Description: Read the score from the high score file and crea                                  *
# **************************************************************************************************
readScoreFromFile:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    pushq %rdi # -8(%rbp)
    pushq $0   # stack alignment

    # open the file in reading mode
    movq $HIGH_SCORE_FILE_OPEN_FLAGS_READ, %rsi
    call fopen

    movq %rax, -16(%rbp)

    movq %rax, %rdi # file pointer
    movq $HIGH_SCORE_FILE_CONTENT_FORMAT, %rsi # scanf format
    movq $highScoreBuffer, %rdx # high score variable
    call fscanf
    
    movq -16(%rbp), %rdi # file pointer
    call fclose # close the file

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    movq highScoreBuffer, %rax # return high score

    ret    

# **************************************************************************************************
# * Subroutine: void writeHighScoreToFile(char* fileName)                                          * 
# * Description: Write the high score to the file                                                  *
# **************************************************************************************************
writeHighScoreToFile:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    pushq %rdi # -8(%rbp)
    pushq $0   # stack alignment

    # open the file in reading mode
    movq $HIGH_SCORE_FILE_OPEN_FLAGS_WRITE, %rsi
    call fopen

    movq %rax, -16(%rbp) # file pointer

    movq %rax, %rdi # file pointer
    movq $HIGH_SCORE_FILE_CONTENT_FORMAT, %rsi # printf format
    movq highScore, %rdx
    call fprintf

    movq -16(%rbp), %rdi # file pointer
    call fclose # close the file

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret    

mousePressed:   #annoying
        call GetMouseX
        movq %rax, %rdi
        call GetMouseY
        movq %rax, %rsi

        # check if mouse is inside the rectangle
        cmpq $300, %rdi
        jl notInsideRect
        cmpq $500, %rdi
        jg notInsideRect

        cmpq $350, %rsi
        jl notInsideRect
        cmpq $400, %rsi
        jg notInsideRect

        jmp mainloop # if it is inside the rectangle, start the main loop

        notInsideRect:
            jmp startScreenLoop # if not, continue the start screen loop
