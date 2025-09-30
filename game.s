.data
    .include "constants.s"
    .include "List.s"
    varNum: .quad 6784
    
    # variables
    # ------------------------------------------------------------
    displayTextBuffer: 
        .zero 0x100 # allocate 100 zeros (null bytes)

    waitTimeValue: .double 1000.0
    
    displayTextBufferIndex: .quad 0

    yesNoTextPointer: .quad 0

    # -------------------------------------------------------------

.text
.global main

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
    
    movq $0, -8(%rbp) # size of our array: -8(%rbp)
             # now we can address the i-th enemy with (enemy_array, i, enemy_size_in_bytes)

    # create an enemy on (400, 300)
    leaq -1600(%rbp), %rdi # the start of the enemy array as first parameter
    movq -8(%rbp), %rsi # the number of enemies (index of the next enemy to create) as second parameter
    movq enemyStartX, %rdx # third parameter - x coordinate
    movq $300, %rcx # fourth parameter - y coordinate
    call createEnemyAtIndex
    incq -8(%rbp) # increment size of the array

    # create an enemy on (400, 100)
    leaq -1600(%rbp), %rdi # the start of the enemy array as first parameter
    movq -8(%rbp), %rsi # the number of enemies (index of the next enemy to create) as second parameter
    movq enemyStartX, %rdx # third parameter - x coordinate
    movq $100, %rcx # fourth parameter - y coordinate
    call createEnemyAtIndex
    incq -8(%rbp) # increment size of the array

    # create an enemy on (400, 200)
    leaq -1600(%rbp), %rdi # the start of the enemy array as first parameter
    movq -8(%rbp), %rsi # the number of enemies (index of the next enemy to create) as second parameter
    movq enemyStartX, %rdx # third parameter - x coordinate
    movq $200, %rcx # fourth parameter - y coordinate
    call createEnemyAtIndex
    incq -8(%rbp) # increment size of the array

    # create an enemy on (400, 400)
    leaq -1600(%rbp), %rdi # the start of the enemy array as first parameter
    movq -8(%rbp), %rsi # the number of enemies (index of the next enemy to create) as second parameter
    movq enemyStartX, %rdx # third parameter - x coordinate
    movq $400, %rcx # fourth parameter - y coordinate
    call createEnemyAtIndex
    incq -8(%rbp) # increment size of the array

    # TEMP
    movq  $textNo, yesNoTextPointer

    movq $60, %rdi
    call SetTargetFPS

    mainloop:
        ## if window should close, end loop (and program)
        call WindowShouldClose
        cmp  $1, %rax
        je   end

        call processInput

        call BeginDrawing
            
            # clear background with gray color
            movq  GRAY, %rdi
            call  ClearBackground

            //movq varNum, %r11
            //movq $words, %rsi
            //movq  (%rsi, %r11, 8), %rdi 
            // movq  $10, %rsi
            // movq  $250, %rdx
            // movq  $50, %rcx
            // movq  RED, %r8
            // call DrawText

            // movq  $displayTextBuffer, %rdi
            // movq  $10, %rsi
            // movq  $10, %rdx
            // movq  $50, %rcx
            // movq  RED, %r8
            // call DrawText

            // movq  yesNoTextPointer, %rdi
            // movq  $500, %rsi
            // movq  $10, %rdx
            // movq  $50, %rcx
            // movq  RED, %r8
            // call DrawText

            # process enemies
            leaq -1600(%rbp), %rdi  # memory location of the enemy array
            movq -8(%rbp), %rsi # size of the array
            call processEnemies

            # print the FPS
            call GetFPS
            movq $printFPSMessage, %rdi
            movq %rax, %rsi
            call printf

        call EndDrawing

        jmp  mainloop    

end:
    # close window and exit with code 0
    call  CloseWindow
    movq  $0, %rdi
    call  exit


# *************************************************************************************************************************
# * Subroutine: void processInput()                                                                                       *
# * Description: Processes all input related events. Should be called once during every iteration of main loop            *
# * Parameters: -                                                                                                         *
# *************************************************************************************************************************
processInput:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp

    # process characters
    call  processCharsPressed

    ## if enter is pressed, clear displayed string
    movq $257, %rdi # 257 = enter key
    call IsKeyPressed
    cmpb $0, %al   
    je  enterNotPressed

        # TEMP: check if strings are the same
        # --------------------------------------------------------------------
        movq varNum, %r11
        movq $words, %rsi
        movq (%rsi, %r11, 8), %rsi
        call  strcmp
        cmp   $0, %rax
        jne   setNo

        setYes:
            movq $textYes, yesNoTextPointer
            jmp  afterStringComparison

        setNo:
            movq $textNo, yesNoTextPointer

        afterStringComparison:
        # --------------------------------------------------------------------
    
        call clearDisplayBuffer
    
    enterNotPressed:    # if enter is not pressed, jumps here

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret


# *************************************************************************************************************************
# * Subroutine: void processCharsPressed()                                                                                *
# * Description: Processes all the chars pressed since last GetCharPressed call. Adds every char to displayTextBuffer     *
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
# * Description: adds a char to the end of string stored in displayTextBuffer     *
# * Parameters: toAdd - char that gets added to displayTextBuffer                 *
# *********************************************************************************
addCharToDisplayBuffer:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp


    # move the byte in %dil (toAdd) into displayTextBuffer at index displayTextBufferIndex
    movq  displayTextBufferIndex, %rbx   # move index into rbx
    leaq  displayTextBuffer, %rcx # move the address of displayTextBuffer into rcx
    movb  %dil, (%rbx, %rcx, 1) # move the char into address rbx + rcx*1 (indirect addressing)
    incq  displayTextBufferIndex # increment index

    # set the next character to null byte
    movq  displayTextBufferIndex, %rbx   # move index into rbx
    leaq  displayTextBuffer, %rcx # move the address of displayTextBuffer into rcx
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
    movq $0, displayTextBufferIndex(%rip)

    # move 0 into byte at displayTextB
    movq  $0, displayTextBuffer(%rip)

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

# struct Enemy {
#     long x;
#     long y;
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
    call DrawRectangle


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

