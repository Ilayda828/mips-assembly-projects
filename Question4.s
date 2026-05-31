################################################################################
# MIPS Matrix Game: Two Walkers (A and B)
# 
# Description:
# - Walker A starts at (0,0) and moves Right or Down.
# - Walker B starts at (m-1, n-1) and moves Left or Up.
# - The game runs for 't' steps.
# - Collisions are handled based on movement alternatives and scores.
################################################################################

.data
# --- Prompts and Messages ---
promptM:        .asciiz "Please enter the value of m: "
promptN:        .asciiz "Please enter the value of n: "
promptT:        .asciiz "Please enter the value of t: "
promptMatrix:   .asciiz "Please enter the matrix: "
invalidT:       .asciiz "INVALID T\n"

msgScoreA:      .asciiz "Final score of A: "
msgScoreB:      .asciiz "Final score of B: "
msgWinner:      .asciiz "The winner is "
msgA:           .asciiz "A\n"
msgB:           .asciiz "B\n"
msgTie:         .asciiz "Tie\n"

msgColl1:       .asciiz "Collision occurs in ("
msgComma:       .asciiz ", "
msgColl2:       .asciiz ").\n"
msgNoColl:      .asciiz "No collision occurs.\n"
newline:        .asciiz "\n"

# --- Global Game Variables ---
scoreA:         .word 0
scoreB:         .word 0
collCount:      .word 0         # Number of recorded collisions
collBase:       .word 0         # Base address for collision coordinate list
termFlag:       .word 0         # Termination flag if collision is unresolvable

# --- Temporary Move Selections ---
aselR:          .word 0         # A's selected row
aselC:          .word 0         # A's selected column
aaltR:          .word 0         # A's alternative row
aaltC:          .word 0         # A's alternative column
aAlt:           .word 0         # Flag: Does A have an alternative move? (1=Yes, 0=No)

bselR:          .word 0         # B's selected row
bselC:          .word 0         # B's selected column
baltR:          .word 0         # B's alternative row
baltC:          .word 0         # B's alternative column
bAlt:           .word 0         # Flag: Does B have an alternative move? (1=Yes, 0=No)

.text
.globl main

############################################################
# MAIN EXECUTION BLOCK
############################################################
main:
    # Initialize/Reset global variables
    sw   $zero, scoreA
    sw   $zero, scoreB
    sw   $zero, collCount
    sw   $zero, termFlag

    # --- Read Dimensions and Time ---
    li   $v0, 4
    la   $a0, promptM
    syscall
    li   $v0, 5
    syscall
    move $s0, $v0              # $s0 = m (rows)

    li   $v0, 4
    la   $a0, promptN
    syscall
    li   $v0, 5
    syscall
    move $s1, $v0              # $s1 = n (columns)

    li   $v0, 4
    la   $a0, promptT
    syscall
    li   $v0, 5
    syscall
    move $s2, $v0              # $s2 = t (steps)

    # --- Validate t (1 <= t <= m+n-2) ---
    li   $t0, 1
    blt  $s2, $t0, PRINT_INVALID
    add  $t1, $s0, $s1
    addi $t1, $t1, -2
    bgt  $s2, $t1, PRINT_INVALID

    # --- Dynamic Memory Allocation ---
    # Allocate Matrix: (m * n * 4) bytes
    mul  $t2, $s0, $s1         
    sll  $a0, $t2, 2           
    li   $v0, 9
    syscall
    move $s3, $v0              # $s3 = matrix base address

    # Allocate Collision List: (t * 8) bytes (pairs of x,y)
    sll  $a0, $s2, 3
    li   $v0, 9
    syscall
    sw   $v0, collBase

    # --- Read Matrix Elements ---
    li   $v0, 4
    la   $a0, promptMatrix
    syscall

    mul  $t2, $s0, $s1
    li   $t3, 0                # Counter

READ_MATRIX_LOOP:
    beq  $t3, $t2, READ_MATRIX_DONE
    li   $v0, 5
    syscall
    sll  $t4, $t3, 2
    add  $t5, $s3, $t4
    sw   $v0, 0($t5)
    addi $t3, $t3, 1
    j    READ_MATRIX_LOOP

READ_MATRIX_DONE:

    # --- Initialize Walker Positions ---
    li   $s4, 0                # A row (starts at 0)
    li   $s5, 0                # A col (starts at 0)
    addi $s6, $s0, -1          # B row (starts at m-1)
    addi $s7, $s1, -1          # B col (starts at n-1)

    # --- Process Starting Cells ---
    # A starting score from (0,0)
    li   $a0, 0
    li   $a1, 0
    jal  get_addr
    lw   $t0, 0($v0)
    lw   $t1, scoreA
    add  $t1, $t1, $t0
    sw   $t1, scoreA
    sw   $zero, 0($v0)         # Clear cell after picking up

    # B starting score from (m-1, n-1)
    move $a0, $s6
    move $a1, $s7
    jal  get_addr
    lw   $t0, 0($v0)
    lw   $t1, scoreB
    add  $t1, $t1, $t0
    sw   $t1, scoreB
    sw   $zero, 0($v0)         # Clear cell after picking up

    # --- Simulation Loop ---
    li   $t9, 0                # Step counter

SIM_LOOP:
    beq  $t9, $s2, SIM_DONE

    # --- 1. Choose Move for Walker A (Right or Down) ---
    addi $t0, $s5, 1           # Potential right column
    slt  $t1, $t0, $s1         # Is right valid?
    addi $t2, $s4, 1           # Potential down row
    slt  $t3, $t2, $s0         # Is down valid?

    sw   $zero, aAlt           # Default: no alternative

    and  $t4, $t1, $t3         # Both moves valid?
    bne  $t4, $zero, A_BOTH_VALID
    bne  $t1, $zero, A_ONLY_RIGHT

A_ONLY_DOWN:
    addi $t5, $s4, 1
    sw   $t5, aselR
    sw   $s5, aselC
    j    A_SELECT_DONE

A_ONLY_RIGHT:
    sw   $s4, aselR
    addi $t5, $s5, 1
    sw   $t5, aselC
    j    A_SELECT_DONE

A_BOTH_VALID:
    # Compare values of Right vs Down
    move $a0, $s4
    addi $a1, $s5, 1
    jal  get_addr
    lw   $t5, 0($v0)           # valRight

    addi $a0, $s4, 1
    move $a1, $s5
    jal  get_addr
    lw   $t6, 0($v0)           # valDown

    bge  $t6, $t5, A_CHOOSE_DOWN # If Down >= Right, pick Down

    # Pick Right, Alternative is Down
    sw   $s4, aselR
    addi $t7, $s5, 1
    sw   $t7, aselC
    addi $t8, $s4, 1
    sw   $t8, aaltR
    sw   $s5, aaltC
    li   $t0, 1
    sw   $t0, aAlt
    j    A_SELECT_DONE

A_CHOOSE_DOWN:
    addi $t7, $s4, 1
    sw   $t7, aselR
    sw   $s5, aselC
    sw   $s4, aaltR
    addi $t8, $s5, 1
    sw   $t8, aaltC
    li   $t0, 1
    sw   $t0, aAlt

A_SELECT_DONE:

    # --- 2. Choose Move for Walker B (Left or Up) ---
    slt  $t1, $zero, $s7       # Left valid if col > 0
    slt  $t3, $zero, $s6       # Up valid if row > 0

    sw   $zero, bAlt           # Default: no alternative

    and  $t4, $t1, $t3
    bne  $t4, $zero, B_BOTH_VALID
    bne  $t1, $zero, B_ONLY_LEFT

B_ONLY_UP:
    addi $t5, $s6, -1
    sw   $t5, bselR
    sw   $s7, bselC
    j    B_SELECT_DONE

B_ONLY_LEFT:
    sw   $s6, bselR
    addi $t5, $s7, -1
    sw   $t5, bselC
    j    B_SELECT_DONE

B_BOTH_VALID:
    # Compare values of Left vs Up
    move $a0, $s6
    addi $a1, $s7, -1
    jal  get_addr
    lw   $t5, 0($v0)           # valLeft

    addi $a0, $s6, -1
    move $a1, $s7
    jal  get_addr
    lw   $t6, 0($v0)           # valUp

    bge  $t6, $t5, B_CHOOSE_UP # If Up >= Left, pick Up

    # Pick Left, Alternative is Up
    sw   $s6, bselR
    addi $t7, $s7, -1
    sw   $t7, bselC
    addi $t8, $s6, -1
    sw   $t8, baltR
    sw   $s7, baltC
    li   $t0, 1
    sw   $t0, bAlt
    j    B_SELECT_DONE

B_CHOOSE_UP:
    addi $t7, $s6, -1
    sw   $t7, bselR
    sw   $s7, bselC
    sw   $s6, baltR
    addi $t8, $s7, -1
    sw   $t8, baltC
    li   $t0, 1
    sw   $t0, bAlt

B_SELECT_DONE:

    # --- 3. Collision Check and Resolution ---
    lw   $t0, aselR
    lw   $t1, aselC
    lw   $t2, bselR
    lw   $t3, bselC

    # If row and column targets are different, no collision
    bne  $t0, $t2, NO_COLLISION
    bne  $t1, $t3, NO_COLLISION

    # Both target the same cell
    lw   $t4, aAlt
    lw   $t5, bAlt

    # If neither has an alternative, game must terminate
    beq  $t4, $zero, CHECK_BOTH_NO_ALT
    j    COLLISION_RESOLVABLE

CHECK_BOTH_NO_ALT:
    beq  $t5, $zero, TERMINATE_NOW

COLLISION_RESOLVABLE:
    # Record collision coordinate
    lw   $t6, collCount
    lw   $t7, collBase
    sll  $t8, $t6, 3
    add  $t7, $t7, $t8
    sw   $t0, 0($t7)
    sw   $t1, 4($t7)
    addi $t6, $t6, 1
    sw   $t6, collCount

    # Resolution Priorities:
    # 1. If one lacks an alternative, they get priority
    # 2. If both have alternatives, the one with the lower current score gets priority
    beq  $t4, $zero, A_HAS_PRIORITY_NO_ALT
    beq  $t5, $zero, B_HAS_PRIORITY_NO_ALT

    lw   $t6, scoreA
    lw   $t7, scoreB
    blt  $t6, $t7, A_PRIORITY_BY_SCORE
    j    B_PRIORITY_BY_SCORE

A_HAS_PRIORITY_NO_ALT:
    # A stays, B moves to alternative
    lw   $t0, baltR
    lw   $t1, baltC
    sw   $t0, bselR
    sw   $t1, bselC
    j    NO_COLLISION

B_HAS_PRIORITY_NO_ALT:
    # B stays, A moves to alternative
    lw   $t0, aaltR
    lw   $t1, aaltC
    sw   $t0, aselR
    sw   $t1, aselC
    j    NO_COLLISION

A_PRIORITY_BY_SCORE:
    lw   $t0, baltR
    lw   $t1, baltC
    sw   $t0, bselR
    sw   $t1, bselC
    j    NO_COLLISION

B_PRIORITY_BY_SCORE:
    lw   $t0, aaltR
    lw   $t1, aaltC
    sw   $t0, aselR
    sw   $t1, aselC
    j    NO_COLLISION

TERMINATE_NOW:
    li   $t0, 1
    sw   $t0, termFlag
    j    SIM_DONE

NO_COLLISION:
    # --- 4. Finalize Movement and Update Scores ---
    # Update A
    lw   $a0, aselR
    lw   $a1, aselC
    jal  get_addr
    lw   $t0, 0($v0)
    lw   $t1, scoreA
    add  $t1, $t1, $t0
    sw   $t1, scoreA
    sw   $zero, 0($v0)
    lw   $s4, aselR
    lw   $s5, aselC

    # Update B
    lw   $a0, bselR
    lw   $a1, bselC
    jal  get_addr
    lw   $t0, 0($v0)
    lw   $t1, scoreB
    add  $t1, $t1, $t0
    sw   $t1, scoreB
    sw   $zero, 0($v0)
    lw   $s6, bselR
    lw   $s7, bselC

    addi $t9, $t9, 1           # Increment step counter
    j    SIM_LOOP

############################################################
# RESULTS DISPLAY
############################################################
SIM_DONE:
    # Print Final Score A
    li   $v0, 4
    la   $a0, msgScoreA
    syscall
    li   $v0, 1
    lw   $a0, scoreA
    syscall
    li   $v0, 4
    la   $a0, newline
    syscall

    # Print Final Score B
    li   $v0, 4
    la   $a0, msgScoreB
    syscall
    li   $v0, 1
    lw   $a0, scoreB
    syscall
    li   $v0, 4
    la   $a0, newline
    syscall

    # Determine Winner
    lw   $t0, scoreA
    lw   $t1, scoreB
    beq  $t0, $t1, PRINT_TIE
    bgt  $t0, $t1, PRINT_WINNER_A

PRINT_WINNER_B:
    li   $v0, 4
    la   $a0, msgWinner
    syscall
    li   $v0, 4
    la   $a0, msgB
    syscall
    j    PRINT_COLLISIONS

PRINT_WINNER_A:
    li   $v0, 4
    la   $a0, msgWinner
    syscall
    li   $v0, 4
    la   $a0, msgA
    syscall
    j    PRINT_COLLISIONS

PRINT_TIE:
    li   $v0, 4
    la   $a0, msgTie
    syscall

# --- Print Collision History ---
PRINT_COLLISIONS:
    lw   $t0, collCount
    beq  $t0, $zero, PRINT_NO_COLL

    li   $t1, 0                # Loop index
    lw   $t2, collBase

PRINT_COLL_LOOP:
    beq  $t1, $t0, EXIT_PROGRAM
    sll  $t3, $t1, 3
    add  $t4, $t2, $t3
    lw   $t5, 0($t4)           # Row
    lw   $t6, 4($t4)           # Col

    li   $v0, 4
    la   $a0, msgColl1
    syscall
    li   $v0, 1
    move $a0, $t5
    syscall
    li   $v0, 4
    la   $a0, msgComma
    syscall
    li   $v0, 1
    move $a0, $t6
    syscall
    li   $v0, 4
    la   $a0, msgColl2
    syscall

    addi $t1, $t1, 1
    j    PRINT_COLL_LOOP

PRINT_NO_COLL:
    li   $v0, 4
    la   $a0, msgNoColl
    syscall
    j    EXIT_PROGRAM

PRINT_INVALID:
    li   $v0, 4
    la   $a0, invalidT
    syscall

EXIT_PROGRAM:
    li   $v0, 10
    syscall

############################################################
# HELPER: get_addr(row, col)
# Input : $a0 = row, $a1 = col
# Output: $v0 = address of matrix[row][col]
# Logic: Base + (row * num_cols + col) * 4
############################################################
get_addr:
    addi $sp, $sp, -20
    sw   $a0, 0($sp)
    sw   $a1, 4($sp)
    sw   $a2, 8($sp)
    sw   $a3, 12($sp)
    sw   $ra, 16($sp)

    mul  $t0, $a0, $s1         # row * n
    add  $t0, $t0, $a1         # + col
    sll  $t0, $t0, 2           # * 4 (word size)
    add  $v0, $s3, $t0         # + base address

    lw   $ra, 16($sp)
    lw   $a0, 0($sp)
    lw   $a1, 4($sp)
    lw   $a2, 8($sp)
    lw   $a3, 12($sp)
    addi $sp, $sp, 20
    jr   $ra