# an ad-hoc assembler to translate assembly codes of risc-v rv32i into machine codes
import sys
import os
import re

use_calling_convention = False

calling_translation = {
  "ZERO": "X0", 
  "RA": "X1", 
  "SP": "X2", 
  "GP": "X3", 
  "TP": "X4",
  "T0": "X5", 
  "T1": "X6", 
  "T2": "X7", 
  "S0": "X8", 
  "S1": "X9",
  "A0": "X10", 
  "A1": "X11", 
  "A2": "X12", 
  "A3": "X13", 
  "A4": "X14",
  "A5": "X15", 
  "A6": "X16", 
  "A7": "X17", 
  "S2": "X18", 
  "S3": "X19",
  "S4": "X20", 
  "S5": "X21", 
  "S6": "X22", 
  "S7": "X23", 
  "S8": "X24",
  "S9": "X25", 
  "S10": "X26", 
  "S11": "X27", 
  "T3": "X28", 
  "T4": "X29",
  "T5": "X30", 
  "T6": "X31"
}

opcode_table = {
    "LUI": 55, "AUIPC": 23, "JAL": 111, "JALR": 103,
    "BEQ": 99, "BNE": 99, "BLT": 99, "BGE": 99,
    "BLTU": 99, "BGEU": 99, "LB": 3, "LH": 3,
    "LW": 3, "LBU": 3, "LHU": 3, "SB": 35,
    "SH": 35, "SW": 35, "ADDI": 19, "SLTI": 19,
    "SLTIU": 19, "XORI": 19, "ORI": 19, "ANDI": 19,
    "SLLI": 19, "SRLI": 19, "SRAI": 19, "ADD": 51,
    "SUB": 51, "SLL": 51, "SLT": 51, "SLTU": 51,
    "XOR": 51, "SRL": 51, "SRA": 51, "OR": 51,
    "AND": 51, "NOP": 0
}

load_funct3 = {"LB": 0, "LH": 1, "LW": 2, "LBU": 4, "LHU": 5}
branch_funct3 = {"BEQ": 0, "BNE": 1, "BLT": 4, "BGE": 5, "BLTU": 6, "BGEU": 7}
store_funct3 = {"SB": 0, "SH": 1, "SW": 2}
opimm_funct3 = {"ADDI": 0, "SLTI": 2, "SLTIU": 3, "XORI": 4, "ORI": 6,
                "ANDI": 7, "SLLI": 1, "SRLI": 5, "SRAI": 5}
opimm_funct7 = {"SLLI": 0, "SRLI": 0, "SRAI": 32}
op_funct3 = {"ADD": 0, "SUB": 0, "SLL": 1, "SLT": 2, "SLTU": 3, "XOR": 4,
             "SRL": 5, "SRA": 5, "OR": 6, "AND": 7}
op_funct7 = {"ADD": 0, "SUB": 32, "SLL": 0, "SLT": 0, "SLTU": 0, "XOR": 0,
             "SRL": 0, "SRA": 32, "OR": 0, "AND": 0}

hex2num = {
    "0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
    "A": 10, "B": 11, "C": 12, "D": 13, "E": 14, "F": 15
}

# srcfile = "rv32i_test6.asm"
srcfile = sys.argv[1] #take the source name from command line
HW_NOP_INSERTION = True #indicate if hardware will automatically insert nop(s) after branch and jump instructions
### clean up the source first
# remove all comment lines and empty lines
# insert nops after jump and branch instructions
# create a temporary file to store the clean code
tempfile = open("temp.asm", 'w')
numLines = 0
linecnt1 = 0
with open(srcfile, 'r') as tf:
  while True:
    line = tf.readline()
    #print(len(line))
    if line == "": break
    linecnt1 = linecnt1 + 1
    line = line.lstrip()
    line = line.rstrip()
    line = line.upper()
    if len(line)==0: continue # an empty line
    elif line[0]=="#": continue # a comment line
    else:
      words = line.split()
      words = [x.strip(",") for x in words]
      if not use_calling_convention:
        tempfile.write(line+"\n")
        numLines += 1
        if not HW_NOP_INSERTION:
          if words[0][-1]==":":
            if words[1]=="JAL": #programmer should add nop for JALR, and guarantee the offset's correctness
              tempfile.write("NOP\n")
              numLines += 1
            elif words[1]=="BEQ" or words[1]=="BNE" or words[1]=="BLT" or words[1]=="BGE" or words[1]=="BLTU" or words[1]=="BGEU":
              tempfile.write("NOP\nNOP\n")
              numLines += 2
          else:
            if words[0]=="JAL": #programmer should add nop for JALR, and guarantee the offset's correctness
              tempfile.write("NOP\n")
              numLines += 1
            elif words[0]=="BEQ" or words[0]=="BNE" or words[0]=="BLT" or words[0]=="BGE" or words[0]=="BLTU" or words[0]=="BGEU":
              tempfile.write("NOP\nNOP\n")
              numLines += 2
      else:
        numLines += 1
        if words[0][-1]==":": # this line has a label, instruction name is in words[1]
          if len(words)==1:
            print("Error in line", linecnt1, "- Label and instruction must be in the same line")
            assert False
          line_new = words[0] + " " + words[1]
          k1 = 2
          while k1<len(words) and words[k1][0]!="#":
            if ((k1==3) and (words[1] == "JALR" or words[1] == "LB" or words[1] == "LH" or words[1] == "LW" or words[1] == "LBU" or 
                             words[1] == "LHU" or words[1] == "SB" or words[1] == "SH" or words[1] == "SW")): # use () to enclose a line broken into multiple lines
              try:
                ext_name = words[k1][(words[k1].index("(")+1) : words[k1].index(")")] # for these instructions, a register is embedded in ()
              except:
                print("Error in line", linecnt1, "- Wrong format for the instruction")
                assert False
              if ext_name != "" and (ext_name in calling_translation):
                line_new = line_new + ", " + words[k1].replace(ext_name, calling_translation[ext_name])
              else:
                print("Error in line", linecnt1, "- Wrong name for the base register")
                assert False
            else:
              if words[k1] in calling_translation:
                if k1==2: line_new = line_new + " " + calling_translation[words[k1]]
                else: line_new = line_new + ", " + calling_translation[words[k1]]
              else:
                if k1==2: line_new = line_new + " " + words[k1]
                else: line_new = line_new + ", " + words[k1]

            k1 += 1
          tempfile.write(line_new + "\n")
        else: # this line has no label, instruction name is in words[0]
          line_new = words[0]
          k1 = 1
          while k1<len(words) and words[k1][0]!="#":
            if ((k1==2) and (words[0] == "JALR" or words[0] == "LB" or words[0] == "LH" or words[0] == "LW" or words[0] == "LBU" or 
                             words[0] == "LHU" or words[0] == "SB" or words[0] == "SH" or words[0] == "SW")): # use () to enclose a line broken into multiple lines
              try:
                ext_name = words[k1][(words[k1].index("(")+1) : words[k1].index(")")] # for these instructions, a register is embedded in ()
              except:
                print("Error in line", linecnt1, "- Wrong format for the instruction")
                assert False
              if ext_name != "" and (ext_name in calling_translation):
                line_new = line_new + ", " + words[k1].replace(ext_name, calling_translation[ext_name])
              else:
                print("Error in line", linecnt1, "- Wrong name for the base register")
                assert False
            else:
              if words[k1] in calling_translation:
                if k1==1: line_new = line_new + " " + calling_translation[words[k1]]
                else: line_new = line_new + ", " + calling_translation[words[k1]]
              else:
                if k1==1: line_new = line_new + " " + words[k1]
                else: line_new = line_new + ", " + words[k1]
            k1 += 1
          tempfile.write(line_new + "\n")            



tempfile.close()
print("Number of lines in the source file after preprocessing: " + str(numLines))

### create a temporary hex file, which might contain unresolved jump/branch targets
hexfile = open("temp.hex", 'w')

outputFileName = "rv32i_test.hex"
outputFileName2 = "rv32i_machine.hex"

labelAddr = dict() #label string as the key, address as the value

unresolvedJAL = dict()

unresolvedBranch = dict()

addrCnt = 0

def addLine(file, seq, addr):
  checksum = 4
  file.write(":04") #data length
  checksum += (addr//256)%256
  file.write(hex(((addr//256)%256)//16)[2].upper()) #address high byte
  file.write(hex(((addr//256)%256)%16)[2].upper())
  checksum += addr%256
  file.write(hex((addr%256)//16)[2].upper()) #address low byte
  file.write(hex((addr%256)%16)[2].upper())
  checksum += 0
  file.write(hex(0)[2].upper()) #data type
  file.write(hex(0)[2].upper())

  for i in range(4):
    currentByte = (seq//256**(3-i))%256
    checksum += currentByte
    file.write(hex(currentByte//16)[2].upper())
    file.write(hex(currentByte%16)[2].upper())

  checksum = checksum % 256
  checksum = (~checksum)%256 + 1
  checksum &= 255
  file.write(hex(checksum//16)[2].upper()) #check sum high hex digit
  file.write(hex(checksum%16)[2].upper()) #check sum low hex digit
  file.write("\x0d\n")

def addLine2(file, seq, addr):
  for i in range(4):
    currentByte = (seq//256**(3-i))%256
    file.write(hex(currentByte//16)[2].upper())
    file.write(hex(currentByte%16)[2].upper())
  file.write("\x0d\n")

bSuccess = True
bHasData = False

with open("temp.asm", 'r') as f:
  #outputFileName = "rv32i_test5.txt"
  #fd = open(outputFileName, "w")
  
  while True:
    line = f.readline()
    #print(len(line))
    if line == "": break
    line = line.lstrip()
    line = line.rstrip()
    line = line.upper()
    if len(line)==0: continue # an empty line
    elif line[0]=="#": continue # a comment line
    else:
      words = line.split()
      words = [x.strip(",") for x in words]
      if words[0]!=".WORD": # normal instructions
        if words[0][-1]==":": # read a label
          if words[0][0:-1] in labelAddr: # error: label already defined
            print("Error: label re-defined in line %d!"%(addrCnt+1))
            bSuccess = False
            break
          else:
            labelAddr[words[0][0:-1]] = addrCnt
            words = words[1:] #strip the label away from the current line
        #print(words)
        opcode = opcode_table[words[0]]
        #print(opcode)
        if opcode == 55: #LUI, example: LUI X1, 100
          binSeq = (int(words[2])<<12) + (int(words[1][1:])<<7) + opcode
          addLine(hexfile, binSeq, addrCnt)
        elif opcode == 23: #AUIPC, example: AUIPC X1, 100
          binSeq = (int(words[2])<<12) + (int(words[1][1:])<<7) + opcode
          addLine(hexfile, binSeq, addrCnt)
        elif opcode == 111: #JAL, example: JAL x1, 20
          if words[2] in labelAddr: #label already defined
            dist = (labelAddr[words[2]] - addrCnt)*2 #line difference multiply by 4 is the address difference, then divided by 2 
            binSeq = ((dist//(2**19))%2)<<31 #imm20
            binSeq += (dist%(2**10))<<21 #imm10-1
            binSeq += ((dist//(2**10))%2)<<20 #imm11
            binSeq += ((dist//(2**11))%(2**8))<<12 #imm19-12
            binSeq += (int(words[1][1:])<<7) + opcode
            addLine(hexfile, binSeq, addrCnt)
          else: #label not yet defined
            unresolvedJAL[addrCnt] = words[2] # add this label keyed by the addrCnt to unresolvedJAL table
            binSeq = (int(words[1][1:])<<7) + opcode # add rd and opcode anyway
            addLine(hexfile, binSeq, addrCnt)
        elif opcode == 103: #JALR, example: JALR X1, 100(X2)
          # programmer must correctly evaluate the offset value for JALR
          # assembler does not have the knowledge of X2's value
          # programmer must take into account the nops inserted by the assembler if not by hardware, which might affect
          # the correctness of the offset value!
          funct3 = 0
          #print(words)
          pos1 = words[2].find("(")
          pos2 = words[2].find(")")
          binSeq = (int(words[2][0:pos1])<<20) + ((int(words[2][(pos1+2):pos2]))<<15) + (funct3<<12) + (int(words[1][1:])<<7) + opcode
          # binSeq = (int(words[3])<<20) + (int(words[2][1:])<<15) + (0<<12) + (int(words[1][1:])<<7) + opcode
          addLine(hexfile, binSeq, addrCnt)
        elif opcode == 99: #BRANCH, example: BEQ X1, X2, -100
          if words[3] in labelAddr: #label already defined
            funct3 = branch_funct3[words[0]]
            dist = (labelAddr[words[3]] - addrCnt)*2 #line difference multiply by 4 then divide by 2 provides the offset
            binSeq = ((dist//(2**11))%2)<<31
            binSeq += ((dist//(2**4))%(2**6))<<25
            binSeq += (int(words[2][1:]))<<20
            binSeq += (int(words[1][1:]))<<15
            binSeq += funct3<<12 
            binSeq += (dist%(2**4))<<8
            binSeq += ((dist//(2**10))%2)<<7
            binSeq += opcode
            addLine(hexfile, binSeq, addrCnt)
          else: #label not yet defined
            unresolvedBranch[addrCnt] = words[3]
            #still have to add funct3, rs1, rs2 and opcode
            funct3 = branch_funct3[words[0]]
            binSeq = (int(words[2][1:]))<<20
            binSeq += (int(words[1][1:]))<<15
            binSeq += funct3<<12
            binSeq += opcode
            addLine(hexfile, binSeq, addrCnt) 
        elif opcode == 3: #LOAD, example: LB X1, 100(X2)
          funct3 = load_funct3[words[0]]
          #print(words)
          pos1 = words[2].find("(")
          pos2 = words[2].find(")")
          binSeq = (int(words[2][0:pos1])<<20) + ((int(words[2][(pos1+2):pos2]))<<15) + (funct3<<12) + (int(words[1][1:])<<7) + opcode
          addLine(hexfile, binSeq, addrCnt)
        elif opcode == 35: #STORE, example: SB X2, -100(X4) 
          funct3 = store_funct3[words[0]]
          pos1 = words[2].find("(")
          pos2 = words[2].find(")")
          #print(words)
          binSeq = ((int(words[2][0:pos1])//(2**5))%(2**7))<<25
          binSeq += (int(words[1][1:]))<<20
          binSeq += (int(words[2][(pos1+2):pos2]))<<15
          binSeq += funct3<<12 
          binSeq += (int(words[2][0:pos1])%(2**5))<<7
          binSeq += opcode
          addLine(hexfile, binSeq, addrCnt)
        elif opcode == 19: #OP-IMM, example: ADDI X1, X2, -100, SLLI X1, X2, 8
          funct3 = opimm_funct3[words[0]]
          funct7 = 0
          binSeq = 0
          if words[0]=="SLLI" or words[0]=="SRLI" or words[0]=="SRAI":
            #example: SLLI X1, X2, 8
            funct7 = opimm_funct7[words[0]]
            binSeq += funct7<<25
            binSeq += int(words[3])<<20
            binSeq += (int(words[2][1:]))<<15
            binSeq += funct3<<12 
            binSeq += (int(words[1][1:]))<<7
            binSeq += opcode
            addLine(hexfile, binSeq, addrCnt)
          else: #non-shift OP_IMM, example: ADDI X1, X2, -100
            binSeq += int(words[3])<<20
            binSeq += (int(words[2][1:]))<<15
            binSeq += funct3<<12 
            binSeq += (int(words[1][1:]))<<7
            binSeq += opcode
            addLine(hexfile, binSeq, addrCnt)
        elif opcode == 51: #OP, example: ADD X3, X1, X2
            funct7 = op_funct7[words[0]]
            funct3 = op_funct3[words[0]]
            binSeq = funct7<<25
            binSeq += (int(words[3][1:]))<<20
            binSeq += (int(words[2][1:]))<<15
            binSeq += funct3<<12 
            binSeq += (int(words[1][1:]))<<7
            binSeq += opcode
            addLine(hexfile, binSeq, addrCnt)
        elif opcode == 0: #NOP
            binSeq = 0
            addLine(hexfile, binSeq, addrCnt)
        else:
          print("Error: unrecognized opcode in line %d!"%(addrCnt+1))
          bSuccess = False
          break
      else: # a word to be stored in the instruction memory as a constant
        # it is recommended that constant words placed after the code
        addLine(hexfile, int(words[1]), addrCnt)
      addrCnt += 1
  hexfile.write(":00000001FF\x0d\n")
  hexfile.close()

def checkUnresolvedJALs(JALs, Addresses):
  for j in JALs:
    if JALs[j] not in Addresses: return j
  return -1

def checkUnresolvedBranches(Branches, Addresses):
  for b in Branches:
    if Branches[b] not in Addresses: return b
  return -1

def resolveJAL(outputFile, unresolvedJAL, labelAddr, hcnt, line):
  targetLabel = unresolvedJAL[hcnt]
  targetAddrCnt = labelAddr[targetLabel]
  dist = (targetAddrCnt - hcnt)*2
  binSeq = ((dist//(2**19))%2)<<31 #imm20
  binSeq += (dist%(2**10))<<21 #imm10-1
  binSeq += ((dist//(2**10))%2)<<20 #imm11
  binSeq += ((dist//(2**11))%(2**8))<<12 #imm19-12
  binSeq += hex2num[line[14]]<<8
  binSeq += (hex2num[line[15]]//8)<<7
  binSeq += 111
  addLine(outputFile, binSeq, hcnt)

def resolveJAL2(outputFile, unresolvedJAL, labelAddr, hcnt, line):
  targetLabel = unresolvedJAL[hcnt]
  targetAddrCnt = labelAddr[targetLabel]
  dist = (targetAddrCnt - hcnt)*2
  binSeq = ((dist//(2**19))%2)<<31 #imm20
  binSeq += (dist%(2**10))<<21 #imm10-1
  binSeq += ((dist//(2**10))%2)<<20 #imm11
  binSeq += ((dist//(2**11))%(2**8))<<12 #imm19-12
  binSeq += hex2num[line[14]]<<8
  binSeq += (hex2num[line[15]]//8)<<7
  binSeq += 111
  addLine2(outputFile, binSeq, hcnt)

def resolveBranch(outputFile, unresolvedBranch, labelAddr, hcnt, line):
  targetLabel = unresolvedBranch[hcnt]
  targetAddrCnt = labelAddr[targetLabel]
  dist = (targetAddrCnt - hcnt)*2
  binSeq = ((dist//(2**11))%2)<<31
  binSeq += ((dist//(2**4))%(2**6))<<25
  binSeq += hex2num[line[10]]<<24
  binSeq += hex2num[line[11]]<<20
  binSeq += hex2num[line[12]]<<16
  binSeq += hex2num[line[13]]<<12 
  binSeq += (dist%(2**4))<<8
  binSeq += ((dist//(2**10))%2)<<7
  binSeq += 99
  addLine(outputFile, binSeq, hcnt)

def resolveBranch2(outputFile, unresolvedBranch, labelAddr, hcnt, line):
  targetLabel = unresolvedBranch[hcnt]
  targetAddrCnt = labelAddr[targetLabel]
  dist = (targetAddrCnt - hcnt)*2
  binSeq = ((dist//(2**11))%2)<<31
  binSeq += ((dist//(2**4))%(2**6))<<25
  binSeq += hex2num[line[10]]<<24
  binSeq += hex2num[line[11]]<<20
  binSeq += hex2num[line[12]]<<16
  binSeq += hex2num[line[13]]<<12 
  binSeq += (dist%(2**4))<<8
  binSeq += ((dist//(2**10))%2)<<7
  binSeq += 99
  addLine2(outputFile, binSeq, hcnt)


if bSuccess:
  # check unresolved JALs
  resJALCheck = checkUnresolvedJALs(unresolvedJAL, labelAddr)
  resBranchCheck = checkUnresolvedBranches(unresolvedBranch, labelAddr)
  if resJALCheck!=-1:
    print("Error: unable to resolve the JAL label in line%d"%(resJALCheck))
  elif resBranchCheck!=-1:
    print("Error: unable to resolve the Branch label in line%d"%(resBranchCheck))
  else: #all labels can be resolved
    outputFile = open(outputFileName, 'w')
    outputFile2 = open(outputFileName2, 'w') # output a text with hex machine code only
    hcnt = 0
    with open("temp.hex") as mf:
      while True:
        line = mf.readline()
        extra = mf.readline()
        if line[0:3] == ":00": # reached the last line
          outputFile.write(line[0:-1]+"\x0d\n")
          break
        if hcnt in unresolvedJAL:
          resolveJAL(outputFile, unresolvedJAL, labelAddr, hcnt, line)
          resolveJAL2(outputFile2, unresolvedJAL, labelAddr, hcnt, line)
          hcnt+=1
        elif hcnt in unresolvedBranch:
          resolveBranch(outputFile, unresolvedBranch, labelAddr, hcnt, line)
          resolveBranch2(outputFile2, unresolvedBranch, labelAddr, hcnt, line)
          hcnt+=1
        else:
          outputFile.write(line[0:-1]+"\x0d\n")
          outputFile2.write(line[-11:-3]+"\x0d\n")
          hcnt+= 1
    outputFile.close()
    outputFile2.close()
    print("Done: hex file generated successfully!")

#print(unresolvedBranch)
#print(unresolvedJAL)    
#os.remove("temp.hex") #remove the temporary hex file

