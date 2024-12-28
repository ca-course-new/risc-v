# A demo program to connect the RV32I soft processor with Wi-Fi
# A network device send strings to the processor in Telnet

main: jal zero, start

# wifi module handShake: AT
# offset 0, length 4, starting address 4
# .byte 41 54 0D 0A
# As RISC-V is little endian, the decimal value below is actually equal to 0x0A0D5441
.word 168645697

# wifi IP address check: AT+CIFSR
# offset 4, length 10, starting address 8
# .byte 41 54 2B 43 49 46 53 52 0D 0A (00 00)
.word 1126913089
.word 1381189193
.word 2573

# wifi CWMODE = 1 setting command: AT+CWMODE=1
# offset 16, length 13, starting address 20
# .byte 41 54 2B 43 57 4D 4F 44 45 3D 31 0D 0A (00 00 00)
.word 1126913089
.word 1146047831
.word 221330757
.word 10

# wifi CIPMUX = 1 setting command: AT+CIPMUX=1
# offset 32, length 13, starting address 36
# .byte 41 54 2B 43 49 50 4D 55 58 3D 31 0D 0A (00 00 00)
.word 1126913089
.word 1431130185
.word 221330776
.word 10

# wifi CIPCLOSE = 0 setting command: AT+CIPCLOSE=0
# offset 48, length 15, starting address 52
# .byte 41 54 2B 43 49 50 43 4C 4F 53 45 3D 30 0D 0A (00)
.word 1126913089
.word 1279479881
.word 1027953487
.word 658736

# wifi CIPSERVER=0 setting command: AT+CIPSERVER=0
# offset 64, length 16, starting address 68
# .byte 41 54 2B 43 49 50 53 45 52 56 45 52 3D 30 0D 0A
.word 1126913089
.word 1163087945
.word 1380275794
.word 168636477

# wifi disconnect command: AT+CWQAP
# offset 80, length 10, starting address 84
# .byte 41 54 2B 43 57 51 41 50 0D 0A (00 00)
.word 1126913089
.word 1346457943
.word 2573

# wifi list signals command: AT+CWLAP
# offset 92, length 10, starting address 96
# .byte 41 54 2B 43 57 4C 41 50 0D 0A (00 00)
.word 1126913089
.word 1346456663
.word 2573

# wifi CIPSEND = 0,4 setting command: AT+CIPSEND=0,4
# offset 104, length 16, starting address 108
# .byte 41 54 2B 43 49 50 53 45 4E 44 3D 30 2C 34 0D 0A
.word 1126913089
.word 1163087945
.word 809321550
.word 168637484

# wifi CIPSERVER = 1,25710 setting command: AT+CIPSERVER=1,25710
# offset 120, length 22, starting address 124
# .byte 41 54 2B 43 49 50 53 45 52 56 45 52 3D 31 2C 32 35 37 31 30 0D 0A (00 00)
.word 1126913089
.word 1163087945
.word 1380275794
.word 841756989
.word 808531765
.word 2573

# wifi connection command: AT+CWJAP="wifi-name","wifi-passcode"
# offset 144, length 42, starting address 148
# .byte 41 54 2B 43 57 4A 41 50 3D 22 54 54 54 54 54 54 54 54 54 54 54 54 22 2C 22 52 52 52 52 52 52 52 52 30 30 30 30 30 30 22 0D 0A (00 00)
.word 1126913089
.word 1346456151
.word 1347691069
.word 1852394541
.word 826498923
.word 740443202
.word 1936675362
.word 1918987621
.word 808530297
.word 573977143
.word 2573


start: lui sp, 12 # set stack pointer at address 49152
lui gp, 9 # set global pointer at address 36864 
lui t1, 917504 #LOAD UPPER IMM WITH E0000
ori t1, t1, 14 #LOAD LOWER 12-BIT WITH 00E, AS A RESULT t1=E000000E, REFERRING TO LCD CURRENT STATE REGISTER
lui t2, 917520 #LOAD UPPER IMM WITH E0010
ori t2, t2, 0 #LOAD LOWER 12-BIT WITH 000, AS A RESULT t2=E0010000, REFERRING TO LED DIODE CONTROL REGISTER. NOTE: THE ONLY LED ON FPGA2.PCB IS AT THE LSB
addi t3, zero, 5 #AFTER AUTOMATIC INITIATION, THE LCD MODULE SHOULD BE IN STATE 5 (101)
CHECKLCD: lw t4, 0(t1)
bne t4, t3, CHECKLCD #WAIT UNTIL LCD IS DONE WITH INTIALIZATION
sw t4, 0(t2) # TURN ON LED SINCE t4=5 AND ITS LOWEST BIT IS 1
# HERE: JAL zero, HERE

## PRINT INITIALIZATION
PRINT: addi tp, zero, 1 # USE zero TO WRITE A LOW LEVEL 0, AND tp TO WRITE A HIGH LEVEL 1
# SET LCD WRITE MODE
lui t2, 917504
ori t2, t2, 10 #LOAD t2 = E000000A TO ADDRESS LCD_READ_ENABLE SIGNAL
sh zero, 0(t2) #LCD_READ_ENABLE = 0, I.E. SET LCD IN WRITE MODE SO THAT IT WILL ONLY RECEIVE COMMANDS FROM CPU
# LOWER LCD_CS TO SELECT THE LCD
lui t2, 917504
ori t2, t2, 0
sh zero, 0(t2) #LCD_CS = 0

## DELAY FOR 1S
jal ra, DELAY1S

## Disp "Wi-Fi Demo"
addi a2, zero, 0
addi a3, zero, 60
addi a4, zero, 87
jal ra, DISP
addi a2, zero, 0
addi a3, zero, 72
addi a4, zero, 105
jal ra, DISP
addi a2, zero, 0
addi a3, zero, 84
addi a4, zero, 45
jal ra, DISP
addi a2, zero, 0
addi a3, zero, 96
addi a4, zero, 70
jal ra, DISP
addi a2, zero, 0
addi a3, zero, 108
addi a4, zero, 105
jal ra, DISP
addi a2, zero, 0
addi a3, zero, 120
addi a4, zero, 32
jal ra, DISP
addi a2, zero, 0
addi a3, zero, 132
addi a4, zero, 68
jal ra, DISP
addi a2, zero, 0
addi a3, zero, 144
addi a4, zero, 101
jal ra, DISP
addi a2, zero, 0
addi a3, zero, 156
addi a4, zero, 109
jal ra, DISP
addi a2, zero, 0
addi a3, zero, 168
addi a4, zero, 111
jal ra, DISP

########## WiFi demo starts here
#### Setting global parameters
## Mem[gp-4] stores the pixel index of the current displayed row
addi t0, zero, 32
sw t0, -4(gp) 
## Mem[gp-8] stores the high 16 bits of the time-out setting register 
addi t0, zero, 128
sw t0, -8(gp)
## Mem[gp-12] stores the low 16 bits of the time-out setting register
lui t0, 6
addi t0, t0, 1024
sw t0, -12(gp)

# delay 12 seconds for ESP8266 to finish initialization
addi a0, zero, 12
tloop: beq a0, zero, clearRBUF
jal ra, DELAY1S
addi a0, a0, -1
jal zero, tloop

#### perform reading on UART receive buffer until it is empty
clearRBUF: lui t2, 917561 #address 0xE0039008 to check the UART status bit3 sempty, bit2 sfull, bit1 rempty, bit0 rfull
ori t2, t2, 8
lw t1, 0(t2)
addi t0, zero, 2
and t3, t1, t0 #only keep the rEmpty bit
beq t3, zero, readOneByte
jal zero, cleared
readOneByte: lui t2, 917561
ori t2, t2, 4 #address 0xE0039004 is the receive buffer address
lw t3, 0(t2)
jal zero, clearRBUF

cleared: addi a2, zero, 16
addi a4, zero, 45
addi a3, zero, 0
barLoop: slti t0, a3, 240
beq t0, zero, handShake
jal ra, DISP
addi a3, a3, 12
jal zero, barLoop


handShake: addi a2, zero, 4
addi a3, zero, 4
jal ra, sndCmd
addi a2, zero, 2
addi a3, zero, 2
jal ra, delay
addi t0, zero, 128
sw t0, -8(gp)
lui t0, 6
ori t0, t0, 1024
sw t0, -12(gp)
lw a2, -4(gp)
addi a3, zero, 0
jal ra, printResp

getIP: addi a2, zero, 8
addi a3, zero, 10
jal ra, sndCmd
addi a2, zero, 2
addi a3, zero, 2
jal ra, delay # delay a short while for response to be received
addi t0, zero, 256
sw t0, -8(gp)
lui t0, 6
ori t0, t0, 1024
sw t0, -12(gp)
lw a2, -4(gp)
addi a3, zero, 0
jal ra, printResp

connectToWIFI: addi a2, zero, 148
addi a3, zero, 42
jal ra, sndCmd
addi a2, zero, 2
addi a3, zero, 2
jal ra, delay # delay a short while for response to be received
addi t0, zero, 768
sw t0, -8(gp)
lui t0, 6
ori t0, t0, 1024
sw t0, -12(gp)
lw a2, -4(gp)
addi a3, zero, 0
jal ra, printResp

getIPAgain: addi a2, zero, 8
addi a3, zero, 10
jal ra, sndCmd
addi a2, zero, 2
addi a3, zero, 2
jal ra, delay # delay a short while for response to be received
addi t0, zero, 256
sw t0, -8(gp)
lui t0, 6
ori t0, t0, 1024
sw t0, -12(gp)
lw a2, -4(gp)
addi a3, zero, 0
jal ra, printResp 

setCWMODE: addi a2, zero, 20
addi a3, zero, 13
jal ra, sndCmd
addi a2, zero, 2
addi a3, zero, 2
jal ra, delay # delay a short while for response to be received
addi t0, zero, 128
sw t0, -8(gp)
lui t0, 6
ori t0, t0, 1024
sw t0, -12(gp)
lw a2, -4(gp)
addi a3, zero, 0
jal ra, printResp 

setCIPMUX: addi a2, zero, 36
addi a3, zero, 13
jal ra, sndCmd
addi a2, zero, 2
addi a3, zero, 2
jal ra, delay # delay a short while for response to be received
addi t0, zero, 128
sw t0, -8(gp)
lui t0, 6
ori t0, t0, 1024
sw t0, -12(gp)
lw a2, -4(gp)
addi a3, zero, 0
jal ra, printResp

setSERVER: addi a2, zero, 124
addi a3, zero, 22
jal ra, sndCmd
addi a2, zero, 2
addi a3, zero, 2
jal ra, delay # delay a short while for response to be received
addi t0, zero, 256
sw t0, -8(gp)
lui t0, 6
ori t0, t0, 1024
sw t0, -12(gp)
lw a2, -4(gp)
addi a3, zero, 0
jal ra, printResp

loopForever: addi t0, zero, 1
sw t0, -8(gp)
lui t0, 6
ori t0, t0, 1024
sw t0, -12(gp)
lw a2, -4(gp)
addi a3, zero, 0
jal ra, printResp
jal zero, loopForever


################ procedure to display a 32-bit register ##############
#### A2 stores the 32-bit to be displayed
#### A3 specifies the row to display (0-304, step size 16)
#### A4 specifies the column position of the first character (0-224, step size 12)
DISPREG: addi sp, sp, -36
sw ra, 0(sp)
sw a2, 4(sp)
sw a3, 8(sp)
sw a4, 12(sp)
sw s0, 16(sp)
sw s1, 20(sp)
sw s2, 24(sp)
sw s3, 28(sp)
sw s4, 32(sp)
ADDI s0, zero, 8 #loop variable
CLOOP: BEQ s0, zero, DONE
ADDI s1, zero, 15
ADDI s2, s0, -1
SLLI s2, s2, 2
SLL s1, s1, s2
lw a2, 4(sp)
AND s1, s1, a2
SRL s2, s1, s2
lw a2, 8(sp) #prepare a2 for DISP procedure
lw a3, 12(sp) #prepare a3 for DISP procedure
ADDI s1, zero, 10 #test if greater than 10. If so, display as A, B, C, D, E, F. Otherwise, as 0~9
SLT s1, s2, s1
BEQ s1, zero, DISPL
ADDI a4, s2, 48 #display a numerical symbol
JAL ra, DISP
ADDI s0, s0, -1
ADDI a4, a3, 12
SW a4, 12(sp)
JAL zero, CLOOP
DISPL: ADDI a4, s2, 55 # display a letter symbol. Example: if the hex digit is 10, then 10+55=65 to display an A
JAL ra, DISP
ADDI s0, s0, -1
ADDI a4, a3, 12
SW a4, 12(sp)
JAL zero, CLOOP
DONE: lw ra, 0(sp)
lw s0, 16(sp)
lw s1, 20(sp)
lw s2, 24(sp)
lw s3, 28(sp)
lw s4, 32(sp)
addi sp, sp, 36
JALR zero, 0(ra)

################ PROCEDURE TO DISPLAY AN ASCII CHARACTER ###############
#### A2 STORES THE STARTING ROW PIXEL COUNT AND A3 STORES THE STARTING COLUMN PIXEL COUNT
#### THE STARTING POSITION IS THE UPPERLEFT CORNER OF THE CHARACTER
#### A4 STORES THE ASCII VALUE OF THE CHARACTER TO BE PRINTED
## SET ROW RANGE, WHICH DOES NOT CHANGE FOR EACH COLUMN. PIXEL WRITING WILL BE PERFORMED IN A COLUMN MAJOR ORDER
# LOWER LCD_CD TO SEND COMMAND
DISP: LUI t2, 917504
ORI t2, t2, 2 # LOAD t2 = E0000002 TO ADDRESS LCD_CD SIGNAL
SH zero, 0(t2)
# WRITE COMMAND WORD 2B TO CONFIGURE THE ROW (0-319)
LUI t2, 917504
ORI t2, t2, 12 # LOAD t2 = E000000C TO ADDRESS LCD DATA PORT
ADDI t3, zero, 43 # 2B, PREPARE COMMAND WORD: ILI9341_PAGEADDRSET 0X2B
SH t3, 0(t2)
# ISSUE AN LCD_WR LOW
LUI t2, 917504
ORI t2, t2, 4 # LOAD t2 = E0000004 TO ADDRESS LCD_WR SIGNAL
SH zero, 0(t2)
# ISSUE AN LCD_WR HIGH
SH tp, 0(t2)
# RAISE LCD_CD TO HIGH TO SEND DATA
LUI t2, 917504
ORI t2, t2, 2
SH tp, 0(t2)
# START ROW ADDRESS - HIGH BYTE
LUI t2, 917504
ORI t2, t2, 12
ADDI t3, a2, 0
SRLI t3, t3, 8
SH t3, 0(t2)
# WRITE A LOW TO HIGH TRANSITION TO LCD_WR
LUI t2, 917504
ORI t2, t2, 4
SH zero, 0(t2)
SH tp, 0(t2)
# START ROW ADDRESS - LOW BYTE
LUI t2, 917504
ORI t2, t2, 12
SH a2, 0(t2) # WRITE LOW BYTE OF THE START ROW, a2[7:0] ARE EFFECTIVE SINCE THE DATA PORT OF THE LCD IS 8-BIT WIDE
# WRITE A LOW TO HIGH TRANSITION TO LCD_WR
LUI t2, 917504
ORI t2, t2, 4
SH zero, 0(t2)
SH tp, 0(t2)
# END ROW ADDRESS - HIGH BYTE
LUI t2, 917504
ORI t2, t2, 12
ADDI t3, a2, 15
SRLI t3, t3, 8
SH t3, 0(t2)
# WRITE A LOW TO HIGH TRANSITION TO LCD_WR
LUI t2, 917504
ORI t2, t2, 4
SH zero, 0(t2)
SH tp, 0(t2)
# END ROW ADDRESS - LOW BYTE
LUI t2, 917504
ORI t2, t2, 12
ADDI t3, a2, 15
SH t3, 0(t2) # WRITE LOW BYTE OF THE END ROW, t3[7:0] ARE EFFECTIVE SINCE THE DATA PORT OF THE LCD IS 8-BIT WIDE
# WRITE A LOW TO HIGH TRANSITION TO LCD_WR
LUI t2, 917504
ORI t2, t2, 4
SH zero, 0(t2)
SH tp, 0(t2)
## 12 COLUMNS TO WRITE
ADDI t4, zero, 12 #SET COLUMN LOOP VARIABLE (OUTER)
COLUMNLOOP: BEQ t4, zero, EXIT
NEXTCOLUMN: ADDI t4, t4, -1
# LOWER LCD_CD TO SEND COMMAND FIRST
LUI t2, 917504
ORI t2, t2, 2
SH zero, 0(t2)
# WRITE COMMAND 0X2A TO CONFIGURE COLUMN ADDRESS (0-239)
LUI t2, 917504
ORI t2, t2, 12
ADDI t3, zero, 42 # PREPARE COMMAND WORD: ILI9341_COLADDRSET 0X2A
SW t3, 0(t2)
# WRITE A LOW TO HIGH TRANSITION TO LCD_WR
LUI t2, 917504
ORI t2, t2, 4
SH zero, 0(t2)
SH tp, 0(t2)
# RAISE LCD_CD TO SEND DATA NEXT
LUI t2, 917504
ORI t2, t2, 2
SH tp, 0(t2)
# START COLUMN ADDRESS - HIGH BYTE
LUI t2, 917504
ORI t2, t2, 12
ADD t3, a3, t4
SRLI t3, t3, 8
SH t3, 0(t2)
LUI t2, 917504
ORI t2, t2, 4
SH zero, 0(t2)
SH tp, 0(t2)
# START COLUMN ADDRESS - LOW BYTE
LUI t2, 917504
ORI t2, t2, 12
ADD t3, a3, t4
SH t3, 0(t2) # t3[7:0] ARE EFFECTIVE
LUI t2, 917504
ORI t2, t2, 4
SH zero, 0(t2)
SH tp, 0(t2)
# END COLUMN ADDRESS - HIGH BYTE
LUI t2, 917504
ORI t2, t2, 12
ADD t3, a3, t4
SRLI t3, t3, 8
SH t3, 0(t2)
LUI t2, 917504
ORI t2, t2, 4
SH zero, 0(t2)
SH tp, 0(t2)
# END COLUMN ADDRESS - LOW BYTE
LUI t2, 917504
ORI t2, t2, 12
ADD t3, a3, t4
SH t3, 0(t2) # t3[7:0] ARE EFFECTIVE
LUI t2, 917504
ORI t2, t2, 4
SH zero, 0(t2)
SH tp, 0(t2)
## READ THE FONT RAM TO GET THE COLUMN WORD INTO t5
LUI t2, 917505
SLLI t3, a4, 5
ADD t2, t2, t3 
SLLI t3, t4, 1
ADD t2, t2, t3
LHU t5, 0(t2) # THE 16-BIT PIXEL WORD IN t5
## 16 PIXELS TO WRITE
LUI t2, 917504
ORI t2, t2, 2
SH zero, 0(t2) # LCD_CD = 0 FOR COMMAND
LUI t2, 917504
ORI t2, t2, 12
ADDI t3, zero, 44 # PREAPRE COMMAND 0X2C (FILL IN PIXEL DATA)
SH t3, 0(t2)
LUI t2, 917504
ORI t2, t2, 4 # WRITE A LOW-TO-HIGH TRANSITION TO LCD_WR
SH zero, 0(t2)
SH tp, 0(t2)
LUI t2, 917504
ORI t2, t2, 2
SH tp, 0(t2) # LCD_CD = 1 FOR DATA
ADDI t6, zero, 16 # PIXEL COUNTER IN t6
SLLI t1, tp, 15 # PREPARE THE MASK REGISTER t1, INITIALLY SET TO ENABLE THE TESTING OF BIT15 OF THE READ PIXEL WORD
PIXELLOOP: BEQ t6, zero, COLUMNLOOP
AND t3, t5, t1 #USE MASK REGISTER TO MASK IRRELEVANT BITS
SRLI t1, t1, 1 #PREPARE TO MASK THE NEXT BIT
ADDI t6, t6, -1 #UPDATE PIXEL LOOP VARIABLE
BEQ t3, zero, WRITE0
# WRITE 1 WITH 16'd65535: A WHITE PIXEL (RGB565)
# COLOR HIGH BYTE
WRITE1: LUI t2, 917504
ORI t2, t2, 12
ADDI t3, zero, 255
SH t3, 0(t2)
LUI t2, 917504
ORI t2, t2, 4
SH zero, 0(t2)
SH tp, 0(t2)
# COLOR LOW BYTE
LUI t2, 917504
ORI t2, t2, 12
ADDI t3, zero, 255
SH t3, 0(t2)
LUI t2, 917504
ORI t2, t2, 4
SH zero, 0(t2)
SH tp, 0(t2)
JAL zero, PIXELLOOP
# WRITE 0 WITH 16'd31: BLUE PIXEL
# COLOR HIGH BYTE
WRITE0: LUI t2, 917504
ORI t2, t2, 12
ADDI t3, zero, 0
SH t3, 0(t2)
LUI t2, 917504
ORI t2, t2, 4
SH zero, 0(t2)
SH tp, 0(t2)
# COLOR LOW BYTE
LUI t2, 917504
ORI t2, t2, 12
ADDI t3, zero, 31
SH t3, 0(t2)
LUI t2, 917504
ORI t2, t2, 4
SH zero, 0(t2)
SH tp, 0(t2)
JAL zero, PIXELLOOP 
EXIT: JALR zero, 0(ra) # EQUIVALENT TO JR $RA IN MIPS SINCE ra CONTAINS RETURN ADDRESS AND OFFSET IS SET 0
#### DISP FUNCTION BODY ENDS HERE ####

############# delay procedure ############
## input a2: outer loop total, a3: inner loop total
delay: addi sp, sp, -8
sw s0, 0(sp)
sw s1, 4(sp) 
add s0, a2, zero
add s1, a3, zero 
inner: add a3, s1, zero 
more: addi a3, a3, -1
beq a3, zero, updates0
jal zero, more
updates0: addi a2, a2, -1
beq a2, zero, rtn
jal zero, inner
rtn: add a2, s0, zero
add a3, s1, zero
lw s0, 0(sp)
lw t1, 4(sp)
addi sp, sp, 8
jalr zero, 0(ra) 

######### delay procedure ends here ######

############# DELAY1S PROCEDURE ###########
DELAY1S: addi sp, sp, -12
sw s0, 0(sp)
sw s1, 4(sp)
sw s2, 8(sp)
lui s0, 3535
srli s0, s0, 12
lui s1, 0
or s1, s1, s0
INNER2B: lui s0, 3535
srli s0, s0, 12
lui s2, 0
or s2, s2, s0
INNER1B: addi s2, s2, -1
bne s2, zero, INNER1B
addi s1, s1, -1
bne s1, zero, INNER2B
lw s0, 0(sp)
lw s1, 4(sp)
lw s2, 8(sp)
addi sp, sp, 12
jalr zero, 0(ra) 
### DELAY1S PROCEDURE ENDS HERE ###########

################# sndCmd Procedure starts #####################
## This procedure writes a complete AT command to the UART send buffer, which relays the command to the Wi-Fi module
## This procedure should be used when the Wi-Fi module is configured
## input: a2 start address of the byte sequence of the AT command, a3 length of the command
## no output
sndCmd: addi sp, sp, -16
sw s0, 0(sp)
sw s1, 4(sp)
sw s2, 8(sp)
sw s3, 12(sp)

addi s0, zero, 0
sendNext: slt s1, s0, a3
beq s1, zero, sendDone
checkS: lui s3, 917561 #set address E0039008
ori s3, s3, 8
lw s3, 0(s3) #read the UART status register 
andi s1, s3, 4 #check if the send buffer of the UART is full by reading the sbufFull bit
beq s1, zero, sendOneByte #send buffer not full, so send one byte
jal zero, checkS
sendOneByte: add s3, a2, s0 #byte address of the current byte to write into the UART send buffer
lbu s1, 0(s3)
lui s2, 917561 #set address E0039000
ori s2, s2, 0
sw s1, 0(s2) #write the loaded byte into the UART send buffer
addi s0, s0, 1
jal zero, sendNext

sendDone: lw s0, 0(sp)
lw s1, 4(sp)
lw s2, 8(sp)
lw s3, 12(sp)
addi sp, sp, 16
jalr zero, 0(ra)
################# sndCmd Procedure ends #####################


################# printResp procedure starts ###############
#### procedure with 1s time-out setting to read and display received UART data
## a2: display starting row
## a3: display starting column
printResp: addi sp, sp, -16
sw ra, 0(sp)
sw a2, 4(sp)
sw a3, 8(sp)
sw a4, 12(sp)

addi s0, zero, 0 #s0 to count the number of words received
nextRead: lw s2, -8(gp) #load higher 32-bit of the timeout constant
resetT1: lw s1, -12(gp) #load lower 32-bit of the timeout constant
testAgain: lui a4, 917561 #set address E0039008
ori a4, a4, 8 
lw a4, 0(a4) # read UART status
addi s4, zero, 2
and s4, a4, s4
beq s4, zero, readOneWord
beq s1, zero, decT2
addi s1, s1, -1
jal zero, testAgain
decT2: beq s2, zero, showWords
addi s2, s2, -1
jal zero, resetT1
readOneWord: lui s4, 917561 #set address E0039004
ori s4, s4, 4
lw s4, 0(s4) # read UART receive buffer
addi s5, zero, 360 # save at most 360 words in memory, larger message won't fit the LCD screen. However, reading the rbuf is always performed
slt s5, s0, s5
beq s5, zero, incS0
add s5, gp, s0 # save received byte into the dynamic region with gp pointing to the bottom
sb s4, 0(s5)
incS0: addi s0, s0, 1
jal zero, nextRead
showWords: beq s0, zero, exit9 # if received 0 bytes, exit
add s6, zero, zero #s6 to count displayed symbols
nextShow: slt s4, s6, s0 # Loop to show all stored ASCII symbols. Display at most s0 symbols.
beq s4, zero, rtn8
slti s4, s6, 360 # display at most 360 symbols in case received more than 360
beq s4, zero, rtn8
add s4, gp, s6
lbu s1, 0(s4) # load the stored ASCII
add a4, s1, zero # copy to a4 for later call of disp procedure
addi s4, zero, 32
slt s4, s1, s4
bne s4, zero, showSpace
addi s4, zero, 128
bge s1, s4, showSpace
jal zero, show1
showSpace: addi a4, zero, 32 # all invisible characters with ascii less than 32 will be shown as a space with ascii value of 32
show1: jal ra, disp # disp's a2 and a3 are the same as this function's input a2 and a3, so no need to set them for the first character
addi s6, s6, 1
addi a3, a3, 12 # update column position for the next character
slti s4, a3, 240
beq s4, zero, colRollBack # need to continue displaying in the next line, so column position rolls back to 0
jal zero, nextShow # otherwise, just continue to display the next symbol
colRollBack: add a3, zero, zero # column reset
addi a2, a2, 16 # row position updated to the next row
slti s4, a2, 320 # row may also need to rollback to the beginning if already exceeding the bottom of the LCD
beq s4, zero, rowRollBack
jal zero, nextShow
rowRollBack: addi a2, zero, 32 # display starts from the 3rd row 
jal zero, nextShow
rtn8: beq a3, zero, updateRow
rowClearLoop: slti s1, a3, 240
beq s1, zero, rtn9
addi a4, zero, 32
jal ra, disp
addi a3, a3, 12
jal zero, rowClearLoop
rtn9: addi a2, a2, 16
slti s4, a2, 320
beq s4, zero, rowFlip
jal zero, updateRow
rowFlip: addi a2, zero, 32
updateRow: sw a2, -4(gp) # update the global display row parameter

exit9: lw ra, 0(sp)
lw a2, 4(sp)
lw a3, 8(sp)
lw a4, 12(sp)
addi sp, sp, 16
jalr zero, 0(ra)
################# printResp procedure ends #################