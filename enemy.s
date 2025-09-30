# struct Enemy {
#     long x;
#     long y;
#     long isAlive;
# }
# size: 16 bytes

# ****************************************************************************
# * Subroutine: void createEnemy(Enemy *location, long x, long y)            *
# * Description: Creates an enemy object at the specified memory location    *
# * Parameters: location - memory address where to place the data            *
# ****************************************************************************
createEnemy:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp
    
    movq %rsi, 0(%rdi)  # move x to offset 0
    movq %rdx, 8(%rdi)  # move y to offset 8
    movq $1, 16(%rdi)  # set the enemy to be alive

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret


# ****************************************************************************
# * Subroutine: long findAvailableIndex(Enemy *array)                        *
# * Description: Finds the index of the first enemy that is not alive        *
# ****************************************************************************
findAvailableIndex:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    movq $0, %rsi # index
    # loop thorugh the array
    findAvailableIndex_loop:   
        # get the index multiplied by the enemy struct size
        movq %rsi, %rdx
        movq enemyStructSize, %rax
        mul %rdx 

        ## if the enemy is dead, break
        cmpq $0, 16(%rdi, %rax, 8) # 16(%rdi, %rax, 8) -> isAlive property of the enemy at index rsi (ENEMY_SIZE*rsi=rax)
        je findAvailableIndex_loopEnd

        incq %rsi
        jmp findAvailableIndex_loop
    findAvailableIndex_loopEnd:

    movq %rsi, %rax # return the index
        

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret


# *****************************************************************************************
# * Subroutine: void createEnemyAtIndex(Enemy *enemyArray, long index, long x, long y)    *    
# * Description: Creates an enemy object at the specified index of the enemyArray         *
# * Parameters: enemyArray - start of the enemy array                                     *
# *             index - index of the array where to create the enemy                      * 
# *****************************************************************************************
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

    call createEnemy # create the enemy

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

# ****************************************************************************************************
# * Subroutine: void spawnEnemy(Enemy *enemyArray)                                                   *
# * Description: Creates an enemy off screen with a random y coordinate at the first available index *
# ****************************************************************************************************
spawnEnemy:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp
    
    pushq %rdi # store the enemyArray: -8(%rbp)
    pushq $0 # stack alignment: -16(%rbp)

    # get the first available index 
    call findAvailableIndex
    
    movq %rax, -16(%rbp) # store the index: -16(%rbp)

    # get a random value from the range of spawn heights
    movq ENEMY_START_Y_MIN, %rdi
    movq ENEMY_START_Y_MAX, %rsi
    call GetRandomValue
    
    pushq %rax # store the y coordinate: -24(%rbp)
    pushq $0 # stack alignment

    # print the spawn message
    movq $enemySpawnedMessage, %rdi
    movq enemyStartX, %rsi
    movq %rax, %rdx
    movq -16(%rbp), %rcx
    call printf

    popq %rcx
    popq %rcx # restore y coord from the stack

    popq %rsi # the index
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
    
    movq -8(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq enemyWidth, %rdx
    movq enemyHeight, %rcx
    movq RED, %r8
    call DrawRectangleLines


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

    movq (%rdi, %rsi, 8), %rdx # move the x coordinate of the enemy into %rdi
    subq ENEMY_MOVEMENT_SPEED, %rdx # increment the x coordinate by movement speed
    movq %rdx, (%rdi, %rsi, 8) # store the coordinate back to memory

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

# *****************************************************************************************
# * Subroutine: void processEnemies(Enemy *enemyArray, long enemyArraySize)               *    
# * Description: Loops thorugh the enemies and draws them (for now)                       *
# * Parameters: enemyArray - start of the enemy array                                     *
# *             index - index of the enemy                                                * 
# *****************************************************************************************
processEnemies:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    pushq %rsi # loop variable: -8(%rbp)
    pushq %rdi # enemyArray: -16(%rbp)

    processEnemies_loop:
        decq -8(%rbp) # decrement loop variable (as the first index is one lower than size)
        movq -16(%rbp), %rdi # enemy array as the first parameter
        movq -8(%rbp), %rsi # enemy index as the second parameter

        call drawEnemyAtIndex # draw the enemy

        movq -16(%rbp), %rdi # enemy array as the first parameter
        movq -8(%rbp), %rsi # enemy index as the second parameter
        call moveEnemyAtIndex
       
        ## if it is greater than zero, loop again
        cmpq $0, -8(%rbp)
        jg processEnemies_loop

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret