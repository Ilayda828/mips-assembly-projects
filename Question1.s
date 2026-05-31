################################################################################
# MIPS Matrix Diagonal Processor
# 
# Description:
# - Processes an n x n matrix stored in memory.
# - Identifies anti-diagonals (sum of indices i + j = d).
# - Sorts non-zero elements within each diagonal (Ascending for even d, Descending for odd d).
# - Calculates diagonal sums and identifies the "largest" diagonal based on:
#   1. Maximum Sum, 2. Highest Non-Zero Count, 3. Smallest Index.
################################################################################

.data
.align 2
# Matrix representation: First word is n, followed by n*n elements
array:          .word 4, 8,1,5,0, 4,0,9,7, 2,7,9,2, 8,8,3,1

msgFinal:       .asciiz "Output: Final Matrix:\n"
msgDiag:        .asciiz "Diagonal sums:\n"
msgD:           .asciiz "d"
msgColon:       .asciiz ": "
msgLargest:     .asciiz "Largest diagonal is "
spaceStr:       .asciiz " "
newline:        .asciiz "\n"

.align 2
tempNZ:         .space 1600    # Temporary buffer for sorting non-zero elements

.align 2
diagSums:       .space 400     # Buffer to store sums of each diagonal

.align 2
diagNZCounts:   .space 400     # Buffer to store non-zero element counts per diagonal

.text
.globl main

############################################################
# MAIN EXECUTION
############################################################
main:
    # --- Load Matrix Dimensions and Base Address ---
    la   $t0, array
    lw   $s0, 0($t0)          # $s0 = n (dimension)
    addi $s1, $t0, 4          # $s1 = base address of matrix elements

    # --- Calculate Total Number of Anti-Diagonals (2n - 1) ---
    sll  $t1, $s0, 1
    addi $s2, $t1, -1         # $s2 = total diagonals

    # --- Initialize Best Diagonal Trackers ---
    li   $s3, 0               # $s3 = index of the best diagonal
    li   $s4, -2147483648     # $s4 = maximum sum (initialized to min int)
    li   $s5, -1              # $s5 = maximum non-zero count

    li   $t0, 0               # $t0 = d (current diagonal index iterator)

DIAG_LOOP:
    beq  $t0, $s2, PRINT_RESULTS

    ########################################################
    # Step 1: Collect Non-Zero Elements for Diagonal 'd'
    ########################################################
    li   $t1, 0               # $t1 = nzCount (non-zero counter)
    li   $t2, 0               # $t2 = row iterator

COLLECT_LOOP:
    beq  $t2, $s0, SORT_NZ

    sub  $t3, $t0, $t2        # col = d - row
    bltz $t3, NEXT_COLLECT    # col must be >= 0
    bge  $t3, $s0, NEXT_COLLECT # col must be < n

    # Get address of matrix[row][col]
    move $a0, $t2
    move $a1, $t3
    jal  elem_addr
    lw   $t4, 0($v0)          # Load element value

    beq  $t4, $zero, NEXT_COLLECT # Skip if zero

    # Store non-zero element in temp buffer
    la   $t5, tempNZ
    sll  $t6, $t1, 2
    add  $t5, $t5, $t6
    sw   $t4, 0($t5)

    addi $t1, $t1, 1          # Increment non-zero count

NEXT_COLLECT:
    addi $t2, $t2, 1
    j    COLLECT_LOOP

    ########################################################
    # Step 2: Sort Collected Non-Zero Elements
    # Logic: Even 'd' -> Ascending | Odd 'd' -> Descending
    ########################################################
SORT_NZ:
    li   $t7, 1
    ble  $t1, $t7, WRITE_BACK # Skip sorting if 0 or 1 element

    andi $t7, $t0, 1          # Check if d is odd or even
    beq  $t7, $zero, SORT_ASC
    j    SORT_DESC

SORT_ASC:
    li   $t2, 0               # Bubble sort outer loop
ASC_OUTER:
    addi $t7, $t1, -1
    bge  $t2, $t7, WRITE_BACK

    li   $t3, 0               # Inner loop
    sub  $t8, $t7, $t2

ASC_INNER:
    bge  $t3, $t8, ASC_NEXT_OUTER
    la   $t4, tempNZ
    sll  $t5, $t3, 2
    add  $t6, $t4, $t5
    lw   $t9, 0($t6)
    lw   $a2, 4($t6)
    ble  $t9, $a2, ASC_NO_SWAP
    sw   $a2, 0($t6)
    sw   $t9, 4($t6)
ASC_NO_SWAP:
    addi $t3, $t3, 1
    j    ASC_INNER
ASC_NEXT_OUTER:
    addi $t2, $t2, 1
    j    ASC_OUTER

SORT_DESC:
    li   $t2, 0               # Bubble sort outer loop
DESC_OUTER:
    addi $t7, $t1, -1
    bge  $t2, $t7, WRITE_BACK

    li   $t3, 0               # Inner loop
    sub  $t8, $t7, $t2

DESC_INNER:
    bge  $t3, $t8, DESC_NEXT_OUTER
    la   $t4, tempNZ
    sll  $t5, $t3, 2
    add  $t6, $t4, $t5
    lw   $t9, 0($t6)
    lw   $a2, 4($t6)
    bge  $t9, $a2, DESC_NO_SWAP
    sw   $a2, 0($t6)
    sw   $t9, 4($t6)
DESC_NO_SWAP:
    addi $t3, $t3, 1
    j    DESC_INNER
DESC_NEXT_OUTER:
    addi $t2, $t2, 1
    j    DESC_OUTER

    ########################################################
    # Step 3: Write Sorted Elements Back to Matrix
    ########################################################
WRITE_BACK:
    li   $t2, 0               # row = 0
    li   $t3, 0               # tempNZ index
    li   $t4, 0               # running diagonal sum

WRITE_LOOP:
    beq  $t2, $s0, STORE_DIAG_INFO

    sub  $t5, $t0, $t2        # col = d - row
    bltz $t5, NEXT_WRITE
    bge  $t5, $s0, NEXT_WRITE

    move $a0, $t2
    move $a1, $t5
    jal  elem_addr
    lw   $t6, 0($v0)

    beq  $t6, $zero, NEXT_WRITE

    # Write sorted value from tempNZ back to matrix
    la   $t7, tempNZ
    sll  $t8, $t3, 2
    add  $t7, $t7, $t8
    lw   $t9, 0($t7)

    sw   $t9, 0($v0)
    add  $t4, $t4, $t9        # Add to sum
    addi $t3, $t3, 1

NEXT_WRITE:
    addi $t2, $t2, 1
    j    WRITE_LOOP

    ########################################################
    # Step 4: Record Diagonal Statistics
    ########################################################
STORE_DIAG_INFO:
    la   $t5, diagSums
    sll  $t6, $t0, 2
    add  $t5, $t5, $t6
    sw   $t4, 0($t5)          # Store sum

    la   $t5, diagNZCounts
    add  $t5, $t5, $t6
    sw   $t1, 0($t5)          # Store non-zero count

    ########################################################
    # Step 5: Update Best Diagonal Tracker
    # Criteria: 1. Sum, 2. NZ Count, 3. Smallest Index
    ########################################################
    bgt  $t4, $s4, UPDATE_BEST
    bne  $t4, $s4, NEXT_DIAG

    # If sums are equal, check NZ count
    bgt  $t1, $s5, UPDATE_BEST
    blt  $t1, $s5, NEXT_DIAG

    # If NZ counts are equal, smaller index d wins (already handled by logic)
    blt  $t0, $s3, UPDATE_BEST
    j    NEXT_DIAG

UPDATE_BEST:
    move $s3, $t0
    move $s4, $t4
    move $s5, $t1

NEXT_DIAG:
    addi $t0, $t0, 1
    j    DIAG_LOOP

############################################################
# OUTPUT DISPLAY
############################################################
PRINT_RESULTS:
    # --- Print Sorted Matrix ---
    li   $v0, 4
    la   $a0, msgFinal
    syscall

    li   $t0, 0               # row = 0
PRINT_MATRIX_ROWS:
    beq  $t0, $s0, PRINT_DIAG_SUMS
    li   $t1, 0               # col = 0
PRINT_MATRIX_COLS:
    beq  $t1, $s0, END_MATRIX_ROW
    move $a0, $t0
    move $a1, $t1
    jal  elem_addr
    lw   $a0, 0($v0)
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, spaceStr
    syscall
    addi $t1, $t1, 1
    j    PRINT_MATRIX_COLS
END_MATRIX_ROW:
    li   $v0, 4
    la   $a0, newline
    syscall
    addi $t0, $t0, 1
    j    PRINT_MATRIX_ROWS

    # --- Print Individual Diagonal Sums ---
PRINT_DIAG_SUMS:
    li   $v0, 4
    la   $a0, msgDiag
    syscall

    li   $t0, 0               # d = 0
PRINT_DIAG_LOOP:
    beq  $t0, $s2, PRINT_LARGEST
    li   $v0, 4
    la   $a0, msgD
    syscall
    li   $v0, 1
    move $a0, $t0
    syscall
    li   $v0, 4
    la   $a0, msgColon
    syscall
    la   $t1, diagSums
    sll  $t2, $t0, 2
    add  $t1, $t1, $t2
    lw   $a0, 0($t1)
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, newline
    syscall
    addi $t0, $t0, 1
    j    PRINT_DIAG_LOOP

    # --- Print The Largest Diagonal Found ---
PRINT_LARGEST:
    li   $v0, 4
    la   $a0, msgLargest
    syscall
    li   $v0, 1
    move $a0, $s3
    syscall
    li   $v0, 4
    la   $a0, newline
    syscall

    li   $v0, 10
    syscall

############################################################
# SUBROUTINE: elem_addr(row, col)
# Input : $a0 = row, $a1 = col
# Output: $v0 = address of matrix[row][col]
# Preserves $t0 by using the stack
############################################################
elem_addr:
    addi $sp, $sp, -20
    sw   $t0, 0($sp)
    sw   $a0, 4($sp)
    sw   $a1, 8($sp)
    sw   $a2, 12($sp)
    sw   $a3, 16($sp)

    mul  $t0, $a0, $s0        # offset = row * n
    add  $t0, $t0, $a1        # offset = (row * n) + col
    sll  $t0, $t0, 2          # offset = offset * 4 (bytes)
    add  $v0, $s1, $t0        # v0 = base + offset

    lw   $t0, 0($sp)
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    lw   $a2, 12($sp)
    lw   $a3, 16($sp)
    addi $sp, $sp, 20
    jr   $ra