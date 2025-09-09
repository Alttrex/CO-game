.data
    debugIntMessage: .asciz "%lu\n" # TEMP

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


    windowTitle: .asciz "Typper"


    word: .asciz "stupid"

    
    displayTextBuffer: 
        .zero 0x100 # allocate 100 zeros

    
    displayTextBufferIndex:
        .quad 0

.text
.global main

main:
    # epilogue
    pushq %rbp
    movq  %rsp, %rbp

    # window creation
    movq  screenWidth,  %rdi
    movq  screenHeight, %rsi
    movq  $windowTitle, %rdx
    call  InitWindow

    mainloop:
        # if window should close, end loop
        call WindowShouldClose
        cmp  $1, %rax
        je   end

        call processCharsPressed
        call  isEnterDown

        call BeginDrawing
            
            # clear background with gray color
            movq  GRAY, %rdi
            call  ClearBackground

            # draw text stored in displayTextBuffer
            movq  $word, %rdi
            movq  $350, %rsi
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

            

        call EndDrawing
        jmp  mainloop    

end:
    # close window and exit with code 0
    call  CloseWindow
    movq  $0, %rdi
    call  exit


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

# 1 parameter - char to display
addCharToDisplayBuffer:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp


    # move the byte in %sil into displayTextBuffer at index displayTextBufferIndex
    movq  displayTextBufferIndex, %rbx   # move index into rbx
    leaq  displayTextBuffer(%rip), %rcx # move the address of displayTextBuffer into rcx
    movb  %dil, (%rbx, %rcx, 1) # move the char into address rbx + rcx*1 (indirect addressing)
    incq  displayTextBufferIndex(%rip) # increment index

    # move null byte after the last character
    movq  displayTextBufferIndex, %rbx   # move index into rbx
    leaq  displayTextBuffer(%rip), %rcx # move the address of displayTextBuffer into rcx
    movb  $0, (%rbx, %rcx, 1) # move the char into address rbx + rcx*1 (indirect addressing)

    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

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

# check if enter is pressed
isEnterDown:
    # prologue
    pushq %rbp
    movq  %rsp, %rbp


    movq $257, %rdi
    call IsKeyDown
    cmpb $0, %al
    je  enterNotPressed
    
    movq $debugIntMessage, %rdi
    movq $0, %rsi
    movb %al, %sil
    call printf
    
    call clearDisplayBuffer
    
    enterNotPressed:
    # epilogue
    movq  %rbp, %rsp
    popq  %rbp

    ret

# TODO
compareStrings:


