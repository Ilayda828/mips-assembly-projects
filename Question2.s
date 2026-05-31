################################################################################
# MIPS String Manipulator: Special Operations
# 
# Description:
# - Reads a string and processes it character by character.
# - Lowercase letters (a-z) are appended to an accumulation buffer (accBuf).
# - Special characters trigger specific string operations:
#   '*' : Delete last character
#   '#' : Duplicate current string
#   '%' : Reverse current string
#   '!' : Remove all vowels (a, e, i, o, u)
#   '?' : Undo (Restore the string to its state before the last successful operation)
# - Displays the current string after each operation and the total operation count.
################################################################################

.data
promptStr:      .asciiz "Please enter the string: "
msgCurrent:     .asciiz "current string: "
msgTotal:       .asciiz "total number of special operation is "
newline:        .asciiz "\n"

# --- Buffers ---
inputBuf:       .space 256        # Raw user input
accBuf:         .space 256        # Accumulated string being manipulated
lastSpecialBuf: .space 256        # Backup for the 'Undo' (?) operation

# --- Global Variables ---
opCount:        .word 0           # Counter for successful special operations
hasLast:        .word 0           # Flag: Is there a state available to undo? (1=Yes, 0=No)

.text
.globl main

############################################################
# MAIN EXECUTION
############################################################
main:
    # --- Reset Globals and Buffers ---
    sw   $zero, opCount
    sw   $zero, hasLast
    sb   $zero, accBuf
    sb   $zero, lastSpecialBuf

    # --- Prompt User ---
    li   $v0, 4
    la   $a0, promptStr
    syscall

    # --- Read Input String ---
    li   $v0, 8
    la   $a0, inputBuf
    li   $a1, 256
    syscall

    la   $s0, inputBuf      # $s0 points to the current character in input

PROCESS_LOOP:
    lb   $t0, 0($s0)        # Load current character

    # Stop processing on Null-terminator or Newline
    beq  $t0, $zero, FINISH
    li   $t1, 10            # ASCII for \n
    beq  $t0, $t1, FINISH

    # --- Check if Character is a Lowercase Letter (a-z) ---
    li   $t1, 'a'
    li   $t2, 'z'
    blt  $t0, $t1, CHECK_SPECIAL
    bgt  $t0, $t2, CHECK_SPECIAL

    # Character is a letter: Append to accBuf
    move $t9, $t0           # Preserve char across function call
    la   $a0, accBuf
    jal  strlen
    move $t3, $v0           # Get current length

    la   $t4, accBuf
    add  $t4, $t4, $t3      # Find end of string
    sb   $t9, 0($t4)        # Store char
    sb   $zero, 1($t4)      # Maintain null terminator

    addi $s0, $s0, 1
    j    PROCESS_LOOP

CHECK_SPECIAL:
    # --- If accBuf is Empty, Skip Special Operations ---
    lb   $t1, accBuf
    beq  $t1, $zero, NEXT_CHAR

    # --- Identify Special Operation ---
    li   $t1, '*'
    beq  $t0, $t1, DO_DELETE

    li   $t1, '#'
    beq  $t0, $t1, DO_DUPLICATE

    li   $t1, '%'
    beq  $t0, $t1, DO_REVERSE

    li   $t1, '!'
    beq  $t0, $t1, DO_REMOVE_VOWELS

    li   $t1, '?'
    beq  $t0, $t1, DO_UNDO

    j    NEXT_CHAR

############################################################
# OPERATION '*' : Delete Last Character
############################################################
DO_DELETE:
    la   $a0, accBuf
    jal  strlen
    addi $t1, $v0, -1       # New length

    la   $t2, accBuf
    add  $t2, $t2, $t1
    sb   $zero, 0($t2)      # Set new null terminator at last-1

    jal  inc_opcount
    jal  save_last_special  # Save current state for future undo
    jal  print_current
    j    NEXT_CHAR

############################################################
# OPERATION '#' : Duplicate Current String (Concat to itself)
############################################################
DO_DUPLICATE:
    la   $a0, accBuf
    jal  strlen
    move $t1, $v0           # Original length
    li   $t2, 0             # Loop index

DUP_LOOP:
    beq  $t2, $t1, DUP_DONE
    la   $t3, accBuf
    add  $t4, $t3, $t2
    lb   $t5, 0($t4)        # Load char from original part

    add  $t6, $t3, $t1
    add  $t6, $t6, $t2      # Find target position (len + index)
    sb   $t5, 0($t6)        # Copy char

    addi $t2, $t2, 1
    j    DUP_LOOP

DUP_DONE:
    la   $t3, accBuf
    sll  $t7, $t1, 1        # New total length (len * 2)
    add  $t3, $t3, $t7
    sb   $zero, 0($t3)      # Terminate string

    jal  inc_opcount
    jal  save_last_special
    jal  print_current
    j    NEXT_CHAR

############################################################
# OPERATION '%' : Reverse Current String
############################################################
DO_REVERSE:
    la   $a0, accBuf
    jal  strlen
    move $t1, $v0           # length

    li   $t2, 0             # Left pointer
    addi $t3, $t1, -1       # Right pointer

REV_LOOP:
    bge  $t2, $t3, REV_DONE
    la   $t4, accBuf
    add  $t5, $t4, $t2
    add  $t6, $t4, $t3

    lb   $t7, 0($t5)        # Swap characters
    lb   $t8, 0($t6)
    sb   $t8, 0($t5)
    sb   $t7, 0($t6)

    addi $t2, $t2, 1
    addi $t3, $t3, -1
    j    REV_LOOP

REV_DONE:
    jal  inc_opcount
    jal  save_last_special
    jal  print_current
    j    NEXT_CHAR

############################################################
# OPERATION '!' : Remove All Vowels
############################################################
DO_REMOVE_VOWELS:
    la   $t1, accBuf        # Read pointer
    la   $t2, accBuf        # Write pointer

RMV_LOOP:
    lb   $t3, 0($t1)
    beq  $t3, $zero, RMV_DONE

    # Check for a, e, i, o, u
    li   $t4, 'a'
    beq  $t3, $t4, SKIP_CHAR
    li   $t4, 'e'
    beq  $t3, $t4, SKIP_CHAR
    li   $t4, 'i'
    beq  $t3, $t4, SKIP_CHAR
    li   $t4, 'o'
    beq  $t3, $t4, SKIP_CHAR
    li   $t4, 'u'
    beq  $t3, $t4, SKIP_CHAR

    # If not a vowel, keep char and move write pointer
    sb   $t3, 0($t2)
    addi $t2, $t2, 1

SKIP_CHAR:
    addi $t1, $t1, 1        # Always move read pointer
    j    RMV_LOOP

RMV_DONE:
    sb   $zero, 0($t2)      # Terminate processed string

    jal  inc_opcount
    jal  save_last_special
    jal  print_current
    j    NEXT_CHAR

############################################################
# OPERATION '?' : Undo (Restore Previous Result)
############################################################
DO_UNDO:
    lw   $t1, hasLast
    beq  $t1, $zero, NEXT_CHAR # If no backup exists, skip

    # Restore accBuf from lastSpecialBuf
    la   $a0, lastSpecialBuf
    la   $a1, accBuf
    jal  copy_string

    jal  inc_opcount        # Undo itself counts as an operation
    jal  print_current
    j    NEXT_CHAR

NEXT_CHAR:
    addi $s0, $s0, 1        # Move to next character in input string
    j    PROCESS_LOOP

FINISH:
    # --- Final Output: Total Operations ---
    li   $v0, 4
    la   $a0, msgTotal
    syscall

    li   $v0, 1
    lw   $a0, opCount
    syscall

    li   $v0, 4
    la   $a0, newline
    syscall

    # Exit Program
    li   $v0, 10
    syscall

############################################################
# UTILITY: strlen(a0=address) -> v0=length
############################################################
strlen:
    addi $sp, $sp, -16
    sw   $a0, 0($sp)
    sw   $a1, 4($sp)
    sw   $a2, 8($sp)
    sw   $a3, 12($sp)

    move $t0, $a0
    li   $v0, 0
STRLEN_LOOP:
    lb   $t1, 0($t0)
    beq  $t1, $zero, STRLEN_DONE
    addi $v0, $v0, 1
    addi $t0, $t0, 1
    j    STRLEN_LOOP
STRLEN_DONE:
    lw   $a0, 0($sp)
    lw   $a1, 4($sp)
    lw   $a2, 8($sp)
    lw   $a3, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

############################################################
# UTILITY: copy_string(a0=source, a1=destination)
############################################################
copy_string:
    addi $sp, $sp, -16
    sw   $a0, 0($sp)
    sw   $a1, 4($sp)
    sw   $a2, 8($sp)
    sw   $a3, 12($sp)

COPY_LOOP:
    lb   $t0, 0($a0)
    sb   $t0, 0($a1)
    beq  $t0, $zero, COPY_DONE
    addi $a0, $a0, 1
    addi $a1, $a1, 1
    j    COPY_LOOP
COPY_DONE:
    lw   $a0, 0($sp)
    lw   $a1, 4($sp)
    lw   $a2, 8($sp)
    lw   $a3, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

############################################################
# HELPER: Save current state to backup buffer
############################################################
save_last_special:
    addi $sp, $sp, -20
    sw   $ra, 0($sp)
    sw   $a0, 4($sp)
    sw   $a1, 8($sp)
    sw   $a2, 12($sp)
    sw   $a3, 16($sp)

    la   $a0, accBuf
    la   $a1, lastSpecialBuf
    jal  copy_string

    li   $t0, 1
    sw   $t0, hasLast       # Mark that a backup is now available

    lw   $ra, 0($sp)
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    lw   $a2, 12($sp)
    lw   $a3, 16($sp)
    addi $sp, $sp, 20
    jr   $ra

############################################################
# HELPER: Increment Operation Counter
############################################################
inc_opcount:
    addi $sp, $sp, -16
    sw   $a0, 0($sp)
    sw   $a1, 4($sp)
    sw   $a2, 8($sp)
    sw   $a3, 12($sp)

    lw   $t0, opCount
    addi $t0, $t0, 1
    sw   $t0, opCount

    lw   $a0, 0($sp)
    lw   $a1, 4($sp)
    lw   $a2, 8($sp)
    lw   $a3, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

############################################################
# HELPER: Print Current Accumulated String
############################################################
print_current:
    addi $sp, $sp, -16
    sw   $a0, 0($sp)
    sw   $a1, 4($sp)
    sw   $a2, 8($sp)
    sw   $a3, 12($sp)

    li   $v0, 4
    la   $a0, msgCurrent
    syscall

    li   $v0, 4
    la   $a0, accBuf
    syscall

    li   $v0, 4
    la   $a0, newline
    syscall

    lw   $a0, 0($sp)
    lw   $a1, 4($sp)
    lw   $a2, 8($sp)
    lw   $a3, 12($sp)
    addi $sp, $sp, 16
    jr   $ra