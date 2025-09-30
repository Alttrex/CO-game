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

    enemySpawnedMessage: .asciz "Enemy spawned at x: %ld, y: %ld. Index: %ld\n"

    # -------------------------------------------------------------

.text
.global main

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
    
    movq $0, -8(%rbp) # size of our array: -8(%rbp)
             # now we can address the i-th enemy with (enemy_array, i, enemy_size_in_bytes)

    # TEMP
    movq  $textNo, yesNoTextPointer

    movq $30, %rdi
    call SetTargetFPS

    movq $0, -16(%rbp) # frame counter: -16(%rbp)
    mainloop:
        incq -16(%rbp) # increment the frame counter

        ## if window should close, end loop (and program)
        call WindowShouldClose
        cmp  $1, %rax
        je   end

        call processInput

        call BeginDrawing
            
            # clear background with gray color
            movq  GRAY, %rdi
            call  ClearBackground

            # process enemies
            leaq -1600(%rbp), %rdi  # memory location of the enemy array
            movq -8(%rbp), %rsi # size of the array
            call processEnemies

            call GetFPS

            # spawn a new enemy every 2 seconds
            cmp $60, -16(%rbp) # compare 120 to the frame counter
            jl mainloop_spawnEnemyEnd # if it is less, skip the spawning
            
            mainloop_spawnEnemy:
                # print the FPS
                movq $printFPSMessage, %rdi
                movq %rax, %rsi
                call printf

                # spawn the enemy
                leaq -1600(%rbp), %rdi # the start of the enemy array as first parameter
                call spawnEnemy
                incq -8(%rbp) # increment size of the array
                movq $0, -16(%rbp)

               
            mainloop_spawnEnemyEnd:


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
        movq $displayTextBuffer, %rdi
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
