import os
import numpy as np
import shutil

dict_funct = {'ADD':'000','ADDU':'001','SUB':'010','SUBU':'011','SLT':'100','AND':'101','OR':'110','JR':'111'}
dict_OP = {'ADDI':'1000','SUBI':'1001','ANDI':'1010','ORI':'1011','LW':'1100','SW':'1101','BEQ':'1110','BNE':'1111','J':'0100','JAL':'0101'}
dict_reg = {'R0':'000','R1':'001','R2':'010','R3':'011','R4':'100','R5':'101','R6':'110','R7':'111'}

sort_I = {'ADDI','SUBI','ANDI','ORI','LW','SW','BEQ','BNE'}
sort_J = {'J','JAL'}
mif = open('D:\\test.txt',"w")
text = open('D:\\instruction.txt',"r")
str_temp = text.readlines()
addr = 0
for i in str_temp:
    temp = i.split()
    machine = []
    if temp[0] in dict_funct:
        if temp[0] != 'JR':
            machine.append('0000')
            machine.append(dict_reg[temp[1]])
            machine.append(dict_reg[temp[2]])
            machine.append(dict_reg[temp[3]])
            machine.append(dict_funct[temp[0]])
        else:
            machine.append('0000')
            machine.append(dict_reg[temp[1]])
            machine.append('000')
            machine.append('000')
            machine.append('111')
    elif temp[0] in sort_I:
        machine.append(dict_OP[temp[0]])
        machine.append(dict_reg[temp[1]])
        machine.append(dict_reg[temp[2]])
        imm = str(bin(int(temp[3]))).strip().split('0b')[-1]
        while len(imm) < 6:
            imm = '0' + imm
        machine.append(imm)
    elif temp[0] in sort_J:
        machine.append(dict_OP[temp[0]])
        data_addr = str(bin(int(temp[1]))).strip().split('0b')[-1]
        while len(data_addr) < 12:
            data_addr = '0' + data_addr
        machine.append(data_addr)
    else:
        print("\n\nerror!\n\n")
    string = ''
    for j in machine:
        string = string + j
    print(string)
    hex1 = 0
    hex2 = 0
    for j in range(0,8):
        hex1 = hex1 + ( (int(string[j])) << (7-j) )
    for j in range(8,16):
        hex2 = hex2 + ( (int(string[j])) << (15-j) )
    print("%x,%x"%(hex1,hex2))

    mif.writelines(str(hex(hex1)).strip().split('0x'))
    mif.writelines('\n')
    addr = addr + 1

    mif.writelines(str(hex(hex2)).strip().split('0x'))
    mif.writelines('\n')
    addr = addr + 1

for addr in range(addr,4096):
    mif.writelines("00\n")

print('finish')
