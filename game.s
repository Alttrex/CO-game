.data
    .include "constants.s"
    
    # variables
    # ------------------------------------------------------------
    displayTextBuffer: 
        .zero 0x100 # allocate 100 zeros (null bytes)
    
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
    movq -8(%rbp), %rdi # load the number of enemies (index of the next enemy to create)
    
    # multiply %rdi by 2, as enemy has 2 quads
    movq $2, %rax
    mul %rdi
    movq %rax, %rdi

    leaq -1600(%rbp), %rsi # load the memory address of the enemy array to rsi
    leaq (%rsi, %rdi, 8), %rdi # the address where to create the enemy as the first parameter
    movq $400, %rsi # first parameter - x coordinate
    movq $300, %rdx # second parameter - y coordinate
    call createEnemy

    # TEMP
    movq  $textNo, yesNoTextPointer

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

            # draw text stored in displayTextBuffer
            movq  $word, %rdi
            movq  $10, %rsi
            movq  $250, %rdx
            movq  $50, %rcx
            movq  RED, %r8
            call DrawText

            movq  $displayTextBuffer, %rdi
            movq  $10, %rsi
            movq  $10, %rdx
            movq  $50, %rcx
            movq  RED, %r8
            call DrawText

            movq  yesNoTextPointer, %rdi
            movq  $500, %rsi
            movq  $10, %rdx
            movq  $50, %rcx
            movq  RED, %r8
            call DrawText

            
            movq $0, %rdi # index of the enemy

            # multiply %rdi by 2, as enemy has 2 bytes
            movq $2, %rax
            mul %rdi
            movq %rax, %rdi
            
            leaq -1600(%rbp), %rsi # load the memory address of the enemy array to rsi
            leaq (%rsi, %rdi, 8), %rdi  # memory location of the enemy
            call drawEnemy


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
        movq  $displayTextBuffer, %rdi
        movq  $word, %rsi
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

    # if function returns 0, no char is left in pool and we end
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
