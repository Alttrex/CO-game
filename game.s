.data
    .include "constants.s"
    .include "List.s"
    varNum: .quad 6784

    # ------------------------------------------------------------
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

    # TEMP
    movq  $textNo, yesNoTextPointer

    mainloop:
        # if window should close, end loop (and program)
        call WindowShouldClose
        cmp  $1, %rax
        je   end

        call processInput

        call BeginDrawing
            
            # clear background with gray color
            movq  WHITE, %rdi
            call  ClearBackground

            
            # draw text stored in displayTextBuffer
            movq varNum, %r11
            movq $words, %rsi
            movq  (%rsi, %r11, 8), %rdi
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

    # if enter is pressed, clear displayed string
    movq $257, %rdi # 257 = enter key
    call IsKeyPressed
    cmpb $0, %al   
    je  enterNotPressed

        # TEMP: check if strings are the same
        # --------------------------------------------------------------------


        movq $displayTextBuffer, %rdi
        movq varNum, %r11
        movq $words, %rsi
        movq (%rsi, %r11, 8), %rsi
        call strcmp
        cmp  $0, %rax
        jne  setNo

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
