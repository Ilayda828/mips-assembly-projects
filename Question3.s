.data
    myString1:  .asciiz "Please enter the card number: "
    myString2:  .asciiz "Please enter the cards: "
    msgScore:   .asciiz "Total score is: "
    msgPairs:   .asciiz "Selected pairs: "
    msgUnpaired:.asciiz "Number of unpaired cards: "
    separator:  .asciiz " - "
    comma:      .asciiz ", "
    newline:    .asciiz "\n"
    cards:      .space 400
    paired:     .space 100
    .align 2
    pairA:      .space 400
    pairB:      .space 400

.text
main:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)            # $sp[0] = $ra

    li   $v0, 4
    la   $a0, myString1
    syscall                     # print myString1

    li   $v0, 5
    syscall
    move $t0, $v0              # $t0 = n

    li   $v0, 4
    la   $a0, myString2
    syscall                     # print myString2

    add  $s0, $zero, $zero     # $s0 = i = 0

InputLoop:
    sll  $t1, $s0, 2           # $t1 = i*4
    la   $t2, cards
    add  $t2, $t2, $t1         # $t2 = &cards[i]

    li   $v0, 8
    move $a0, $t2              # $a0 = &cards[i]
    li   $a1, 4                # $a1 = bufferSize = 4
    syscall                     # read cards[i]

    sb   $zero, 2($t2)         # cards[i][2] = 0
    sb   $zero, 3($t2)         # cards[i][3] = 0

    la   $t3, paired
    add  $t3, $t3, $s0         # $t3 = &paired[i]
    sb   $zero, 0($t3)         # paired[i] = 0

    addi $s0, $s0, 1           # i++
    bne  $s0, $t0, InputLoop   # if i != n goto InputLoop

    add  $s0, $zero, $zero     # $s0 = i = 0
    add  $s2, $zero, $zero     # $s2 = totalScore = 0
    addi $s3, $zero, -1        # $s3 = prevScore = -1
    add  $s4, $zero, $zero     # $s4 = pairCount = 0

OuterLoop:
    bge  $s0, $t0, EndOuter    # if i >= n goto EndOuter

    la   $t1, paired
    add  $t1, $t1, $s0         # $t1 = &paired[i]
    lb   $t1, 0($t1)           # $t1 = paired[i]
    bne  $t1, $zero, NextI     # if paired[i] != 0 goto NextI

    addi $s5, $zero, -1        # $s5 = bestJ = -1
    add  $s6, $zero, $zero     # $s6 = bestScore = 0

    sll  $t1, $s0, 2           # $t1 = i*4
    la   $t8, cards
    add  $t8, $t8, $t1         # $t8 = &cards[i]
    lb   $a2, 0($t8)           # $a2 = cards[i][0]
    lb   $a3, 1($t8)           # $a3 = cards[i][1]

    addi $s1, $s0, 1           # $s1 = j = i+1

InnerLoop:
    bge  $s1, $t0, EndInner    # if j >= n goto EndInner

    la   $t1, paired
    add  $t1, $t1, $s1         # $t1 = &paired[j]
    lb   $t1, 0($t1)           # $t1 = paired[j]
    bne  $t1, $zero, NextJ     # if paired[j] != 0 goto NextJ

    sll  $t1, $s1, 2           # $t1 = j*4
    la   $t2, cards
    add  $t2, $t2, $t1         # $t2 = &cards[j]
    lb   $t3, 0($t2)           # $t3 = cards[j][0]
    lb   $t4, 1($t2)           # $t4 = cards[j][1]

    add  $t5, $zero, $zero     # $t5 = score = 0

    bne  $a2, $t4, CheckRule2  # if cards[i][0] != cards[j][1] goto CheckRule2
    bne  $a3, $t3, CheckRule2  # if cards[i][1] != cards[j][0] goto CheckRule2
    addi $t5, $zero, 3         # $t5 = score = 3 (reverse match)
    j    ScoreCheck

CheckRule2:
    bne  $a2, $t3, CheckRule3  # if cards[i][0] != cards[j][0] goto CheckRule3
    addi $t5, $zero, 2         # $t5 = score = 2 (same first letter)
    j    ScoreCheck

CheckRule3:
    bne  $a3, $t4, ScoreCheck  # if cards[i][1] != cards[j][1] goto ScoreCheck
    addi $t5, $zero, 1         # $t5 = score = 1 (same second letter)

ScoreCheck:
    ble  $t5, $s6, NextJ       # if score <= bestScore goto NextJ
    move $s6, $t5              # $s6 = bestScore = score
    move $s5, $s1              # $s5 = bestJ = j

NextJ:
    addi $s1, $s1, 1           # j++
    j    InnerLoop

EndInner:
    beq  $s5, -1, NextI        # if bestJ == -1 goto NextI

    bne  $s3, $s6, NoBonus     # if prevScore != bestScore goto NoBonus
    addi $s2, $s2, 1           # totalScore++ (bonus)

NoBonus:
    add  $s2, $s2, $s6         # $s2 = totalScore += bestScore
    move $s3, $s6              # $s3 = prevScore = bestScore

    la   $t1, paired
    add  $t1, $t1, $s0         # $t1 = &paired[i]
    li   $t2, 1
    sb   $t2, 0($t1)           # paired[i] = 1

    la   $t1, paired
    add  $t1, $t1, $s5         # $t1 = &paired[bestJ]
    sb   $t2, 0($t1)           # paired[bestJ] = 1

    sll  $t1, $s4, 2           # $t1 = pairCount*4
    la   $t2, pairA
    add  $t2, $t2, $t1         # $t2 = &pairA[pairCount]
    sw   $s0, 0($t2)           # pairA[pairCount] = i

    la   $t2, pairB
    add  $t2, $t2, $t1         # $t2 = &pairB[pairCount]
    sw   $s5, 0($t2)           # pairB[pairCount] = bestJ

    addi $s4, $s4, 1           # pairCount++

NextI:
    addi $s0, $s0, 1           # i++
    j    OuterLoop

EndOuter:

    li   $v0, 4
    la   $a0, msgScore
    syscall                     # print "Total score is: "

    li   $v0, 1
    move $a0, $s2              # $a0 = totalScore
    syscall                     # print totalScore

    li   $v0, 4
    la   $a0, newline
    syscall                     # print "\n"

    li   $v0, 4
    la   $a0, msgPairs
    syscall                     # print "Selected pairs: "

    add  $s0, $zero, $zero     # $s0 = p = 0

PrintPairLoop:
    bge  $s0, $s4, EndPrintPair # if p >= pairCount goto EndPrintPair

    beq  $s0, $zero, NoPrefixComma # if p == 0 goto NoPrefixComma
    li   $v0, 4
    la   $a0, comma
    syscall                     # print ", "

NoPrefixComma:
    sll  $t1, $s0, 2           # $t1 = p*4
    la   $t2, pairA
    add  $t2, $t2, $t1         # $t2 = &pairA[p]
    lw   $t3, 0($t2)           # $t3 = pairA[p] = i

    sll  $t4, $t3, 2           # $t4 = i*4
    la   $t5, cards
    add  $t5, $t5, $t4         # $t5 = &cards[i]

    lb   $a0, 0($t5)           # $a0 = cards[i][0]
    li   $v0, 11
    syscall                     # print cards[i][0]
    lb   $a0, 1($t5)           # $a0 = cards[i][1]
    li   $v0, 11
    syscall                     # print cards[i][1]

    li   $v0, 4
    la   $a0, separator
    syscall                     # print " - "

    sll  $t1, $s0, 2           # $t1 = p*4
    la   $t2, pairB
    add  $t2, $t2, $t1         # $t2 = &pairB[p]
    lw   $t3, 0($t2)           # $t3 = pairB[p] = j

    sll  $t4, $t3, 2           # $t4 = j*4
    la   $t5, cards
    add  $t5, $t5, $t4         # $t5 = &cards[j]

    lb   $a0, 0($t5)           # $a0 = cards[j][0]
    li   $v0, 11
    syscall                     # print cards[j][0]
    lb   $a0, 1($t5)           # $a0 = cards[j][1]
    li   $v0, 11
    syscall                     # print cards[j][1]

    addi $s0, $s0, 1           # p++
    j    PrintPairLoop

EndPrintPair:
    li   $v0, 4
    la   $a0, newline
    syscall                     # print "\n"

    add  $s0, $zero, $zero     # $s0 = i = 0
    add  $s1, $zero, $zero     # $s1 = unpaired = 0

UnpairedLoop:
    bge  $s0, $t0, EndUnpaired # if i >= n goto EndUnpaired

    la   $t1, paired
    add  $t1, $t1, $s0         # $t1 = &paired[i]
    lb   $t1, 0($t1)           # $t1 = paired[i]
    bne  $t1, $zero, SkipUnpaired # if paired[i] != 0 goto SkipUnpaired
    addi $s1, $s1, 1           # unpaired++

SkipUnpaired:
    addi $s0, $s0, 1           # i++
    j    UnpairedLoop

EndUnpaired:
    li   $v0, 4
    la   $a0, msgUnpaired
    syscall                     # print "Number of unpaired cards: "

    li   $v0, 1
    move $a0, $s1              # $a0 = unpaired
    syscall                     # print unpaired

    li   $v0, 4
    la   $a0, newline
    syscall                     # print "\n"

    lw   $ra, 0($sp)           # $ra = $sp[0]
    addi $sp, $sp, 4           # restore $sp
    li   $v0, 10
    syscall                     # exit