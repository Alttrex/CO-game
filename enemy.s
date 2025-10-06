# struct Enemy {
#     long x;                       # offset: 0
#     long y;                       # offset: 8
#     long framesSinceLastMovement: # offset: 16
#     char *word;                   # offset: 24
# }
# size: 24 bytes (4 quads)

# ****************************************************************************************
# * Subroutine: void createEnemy(Enemy *location, long x, long y, char* word)            *
# * Description: Creates an enemy object at the specified memory location                *
# * Parameters: location - memory address where to place the data                        *
# ****************************************************************************************
createEnemy:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp
    
    movq %rsi, 0(%rdi)   # move x to offset 0
    movq %rdx, 8(%rdi)   # move y to offset 8
    movq $0, 16(%rdi)    # framesSinceLastMovement = 0
    movq %rcx, 24(%rdi)  # move the word to offset 24

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret


# ***************************************************************************************************
# * Subroutine: void createEnemyAtIndex(Enemy *enemyArray, long index, long x, long y, char* word)  *    
# * Description: Creates an enemy object at the specified index of the enemyArray                   *
# * Parameters: enemyArray - start of the enemy array                                               *
# *             index - index of the array where to create the enemy                                * 
# ***************************************************************************************************
createEnemyAtIndex:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp
    
    pushq %rdx  # push x coordinate: -8(%rbp)
    pushq %rcx  # push y coordinate: -16(%rbp)

    # multiply index by enemy size in quads
    movq enemyStructSize, %rax
    mul %rsi
    mov %rax, %rsi

    leaq (%rdi, %rsi, 8), %rdi # load the memory address of where to store enemy to %rdi
    popq %rdx # load y coordinate
    popq %rsi # load x coordinate
    movq %r8, %rcx # the word

    call createEnemy # create the enemy

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

# ****************************************************************************************************
# * Subroutine: void spawnEnemy(Enemy *enemyArray, char* word, quad enemyAmount)                     *
# * Description: Creates an enemy off screen with a random y coordinate at the first available index *
# ****************************************************************************************************
spawnEnemy:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp
    
    pushq %rdi # store the enemyArray: -8(%rbp)
    pushq %rsi # store the word:       -16(%rbp)
    
    pushq %rdx  # store the index: -24(%rbp)
    pushq $0    # stack alignment: -32(%rbp)

    # get a random value from the range of spawn heights
    movq ENEMY_START_Y_MIN, %rdi
    movq ENEMY_START_Y_MAX, %rsi
    call GetRandomValue
    
    movq %rax, -32(%rbp) # store the y coordinate: -32(%rbp)

    # print the spawn message
    movq $enemySpawnedMessage, %rdi
    movq enemyStartX, %rsi  # x
    movq %rax, %rdx         # y
    movq -16(%rbp), %rcx    # the word
    movq -24(%rbp), %r8     # the index
    call printf

    popq %rcx # restore y coord from the stack

    popq %rsi # the index
    popq %r8  # the word
    popq %rdi # the array pointer
    movq enemyStartX, %rdx # starting x coordinate
    call createEnemyAtIndex # create the enemy

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret


# ****************************************************************************
# * Subroutine: void drawEnemy(Enemy *location)                              *
# * Description: draws the enemy on (location) onto the screen               *
# * Parameters: location - memory address of the enemy                       *
# ****************************************************************************
drawEnemy:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    pushq 0(%rdi)  # push x coordinate: -8(%rbp)
    pushq 8(%rdi)  # push y coordinate: -16(%rbp)
    pushq 24(%rdi) # push the conatining word: -24(%rbp)
    pushq $0 # stack alignment
    
    # draw the enemy rectangle
    movq -8(%rbp), %rdi # x
    movq -16(%rbp), %rsi # y
    movq enemyWidth, %rdx
    movq enemyHeight, %rcx
    movq RED, %r8
    call DrawRectangleLines

    # draw the word
        # raylib takes in the left upper corner of the text
        # so first, we calculate the left x coord of the text -> enemy_x + enemy_width/2 - text_width/2
    

    movq -24(%rbp), %rdi # the text to measure
    movq enemyFontSize, %rsi # font size
    call MeasureText # reylib function -> returns text_width

    movq $0, %rdx
    movq $2, %r8
    divq %r8 # rax = text_width/2
    movq %rax, %rsi # rsi = text_width/2
    movq -8(%rbp), %rdi # enemy_x
    movq enemyWidth, %rax
    divq %r8 # rax = enemyWidth//2
    addq %rax, %rdi # rdi = enemy_x + enemeyWidth/2
    subq %rsi, %rdi # rdi = enemy_x + enemy_width/2 - text_width/2 = text_x
    
    
        # next, we calculate the top y coord. That is a little easier -> text_y = enemy_y + enemy_height/2 - font_size/2
    movq enemyFontSize, %rax
    movq $2, %r8
    divq %r8 # rax = font_size/2
    movq %rax, %rsi # rsi = font_size/2
    movq enemyHeight, %rax
    divq %r8 # rax = enemyHeight//2
    movq -16(%rbp), %rdx # enemy_y
    addq %rax, %rdx # rdx = enemy_y + enemyHeight/2
    subq %rsi, %rdx # rdx = enemy_y + enemy_height/2 - font_size/2 = text_y
    # y already in rdx -> third argument

    movq %rdi, %rsi # text_x as the second argument   
    movq -24(%rbp), %rdi # the word to draw
    movq enemyFontSize, %rcx # font size
    movq RED, %r8 # color
    call DrawText     


    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

# *****************************************************************************************
# * Subroutine: void drawEnemyAtIndex(Enemy *enemyArray, long index)                      *    
# * Description: Draws the enemy object at the specified index of the enemyArray          *
# * Parameters: enemyArray - start of the enemy array                                     *
# *             index - index of the array                                                * 
# *****************************************************************************************
drawEnemyAtIndex:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp
    
    # multiply index by enemy size
    movq enemyStructSize, %rax
    mul %rsi
    mov %rax, %rsi

    leaq (%rdi, %rsi, 8), %rdi # load the memory address of where to store enemy to %rdi

    call drawEnemy # create the enemy

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

# *****************************************************************************************
# * Subroutine: void moveEnemyAtIndex(Enemy *enemyArray, long index)                      *    
# * Description: Moves the enemy - should be called on every enemy every frame once       *
# * Parameters: enemyArray - start of the enemy array                                     *
# *             index - index of the enemy                                                * 
# *****************************************************************************************
moveEnemyAtIndex:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    # multiply index by enemy size
    movq enemyStructSize, %rax
    mul %rsi
    mov %rax, %rsi

    # increment the framesSinceLastMovement variable
    incq 16(%rdi, %rsi, 8)
    movq 16(%rdi, %rsi, 8), %r8 # move framesSinceLastMovement into r8

    ## if framesSinceLastMovement < ENEMY_FRAMES_PER_MOVEMENT, skip movement
    cmpq ENEMY_FRAMES_PER_MOVEMENT, %r8
    jl  moveEnemyAtIndex_end

    # move
    movq (%rdi, %rsi, 8), %rdx # move the x coordinate of the enemy into %rdx
    subq ENEMY_MOVEMENT_SPEED, %rdx # decrement the x coordinate by movement speed
    movq %rdx, (%rdi, %rsi, 8) # store the coordinate back to memory
    movq $0, 16(%rdi, %rsi, 8) # reset framesSinceLastMovement

    moveEnemyAtIndex_end:

    incq 16(%rdi, %rsi, 8) # increment framesSinceLastMovement

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

# *****************************************************************************************
# * Subroutine: quad processEnemies(Enemy *enemyArray, long enemyArraySize)               *    
# * Description: Loops thorugh the enemies and draws them (for now)                       *
# * Parameters: enemyArray - start of the enemy array                                     *
# *****************************************************************************************
processEnemies:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    pushq %rsi # loop variable: -8(%rbp)
    pushq %rdi # enemyArray: -16(%rbp)

    processEnemies_loop:
        decq -8(%rbp) # decrement loop variable (as the first index is one lower than size)
        ## if it is lower than zero, break
        cmpq $0, -8(%rbp)
        jl processEnemies_loopEnd

        movq -16(%rbp), %rdi # enemy array as the first parameter
        movq -8(%rbp), %rsi # enemy index as the second parameter

        call drawEnemyAtIndex # draw the enemy

        movq -16(%rbp), %rdi # enemy array as the first parameter
        movq -8(%rbp), %rsi # enemy index as the second parameter
        call moveEnemyAtIndex
    
        jmp processEnemies_loop

    processEnemies_loopEnd:

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret


# ************************************************************************************************
# * Subroutine: void killEnemyAtIndex(Enemy *enemyArray, long index, long arraySize)             *    
# * Description: Removes the enemy from the array and shifts all the other ones one to the left  *
# ************************************************************************************************
killEnemyAtIndex:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    # LOOP: shift all the elements after index one to the left
    killEnemyAtIndex_loop:
        ## if index >= arraySize (as the last index does not need to be overwritten), break
        cmpq %rdx, %rsi
        jge killEnemyAtIndex_loopEnd

        pushq %rdx # rdx is overwritten by multiplication

        # multiply index by enemy size
        movq enemyStructSize, %rax
        mul %rsi
        mov %rax, %r8 # store the offset of current enemy in r8

        popq %rdx # restore rdx
        
        # store the offset of next enemy in r9
        movq %r8, %r9
        addq enemyStructSize, %r9
        # (%rdi, %r8, 8) -> current enemy
        # (%rdi, %r9, 8) ->  next enemy

        # move all the attributes of the next elements (at r9) to the current element (rsi)
        movq 0(%rdi, %r9, 8), %r10
        movq %r10, 0(%rdi, %r8, 8)

        movq 8(%rdi, %r9, 8), %r10
        movq %r10, 8(%rdi, %r8, 8)

        movq 16(%rdi, %r9, 8), %r10
        movq %r10, 16(%rdi, %r8, 8)

        movq 24(%rdi, %r9, 8), %r10
        movq %r10, 24(%rdi, %r8, 8)
        
        incq %rsi # increment index
        jmp killEnemyAtIndex_loop

    killEnemyAtIndex_loopEnd:

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

# ******************************************************************************************************************************
# * Subroutine: long findEnemyWithWord(Enemy *enemyArray, long arraySize, char *word)                                          *
# * Description: returns the index of the first enemy that contains the word. Returns -1 if no such enemy exists               *
# ******************************************************************************************************************************
findEnemyWithWord:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    pushq %rdi # the array pointer:  -8(%rbp)
    pushq %rsi # the array size:    -16(%rbp)
    pushq %rdx # the word:          -24(%rbp)

    movq $-1, %rsi # index
    # loop thorugh the array
    findEnemyWithWord_loop:
        incq %rsi # increment index
        ## if index >= arraySize, return -1
            cmpq -16(%rbp), %rsi
            jge findEnemyWithWord_returnNegativeOne

        # get the index multiplied by the enemy struct size
        movq %rsi, %rdx
        movq enemyStructSize, %rax
        mul %rdx 

        movq -8(%rbp), %rdi # load the array pointer back to rdi

        ##if the enemy's word matches, break
            pushq %rsi # store rsi
            movq 24(%rdi, %rax, 8), %rsi # enemy's word
            movq -24(%rbp), %rdi # our word            

            call strcmp # returns 0 if the strings are equal

            popq %rsi # restore rsi

            cmpq $0, %rax
            je  findEnemyWithWord_loopEnd
        ## else, go to the next iteration
            jmp findEnemyWithWord_loop
    findEnemyWithWord_loopEnd:

    movq %rsi, %rax # return the index
    jmp findEnemyWithWord_epilogue

    findEnemyWithWord_returnNegativeOne:
        movq $-1, %rax

    findEnemyWithWord_epilogue:

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

# **************************************************************************************************************
# * Subroutine: boolean isGameOver(Enemy *enemyArray, long arraySize)                                          *
# * Description: returns 1, if an enemy has crossed the finish line and the game is over                       *
# **************************************************************************************************************
isGameOver:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    movq $0, %r8 # enemy index in r8
    isGameOver_loop:
        ## if index >= arraySize than zero, break
        cmpq %rsi, %r8
        jge isGameOver_loopEnd

        # multiply index by enemy size
        movq enemyStructSize, %rax
        mul %r8
        mov %rax, %rsi

        ## if the x coordinate of the enemy is lower than finish line, return true
        movq 0(%rdi, %r8, 8), %r10 # the x coordinate
        cmpq ENEMY_FINISH_LINE, %r10
        ## else, loop again
        jge isGameOver_loop    

        # return true
        movq $1, %rax
        jmp isGameOver_end

        incq %r8 # increment loop variable (as the first index is one lower than size)

    isGameOver_loopEnd:
        # return false -> no enemy is behind finish line
        movq $0, %rax
        jmp isGameOver_end 

    isGameOver_end:


    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret