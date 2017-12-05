GOTO Root_Main

DATA KeyBoard_Cache 100 ;缓存当前未完成的输入的内容
DATA KeyBoard_Cache_P 1 ;记录缓存区下一个字符的地址

KeyBoard_Get
Root_Main:
  CALL VGA_MEM_INIT
  CALL Root_INIT
  CALL VGA_COM_PRINT
  Root_Main_Command_Input:
  LOAD_ADDR sys_root_path R0
  CALL printf
  RET

Root_Main_KeyBoard_Enter:   ;当按下键盘回车时应当处理的逻辑
  ;如果输入L，进入生命游戏
  Load_Data KeyBoard_Cache R0 0
  ADDIU R0 BF   ;R0-=ord(L)
  BEQZ R0 GOTO_LifeGame
  NOP
  ;均不为以上指令
  CALL next_cursor_line
  Load_Data KeyBoard_Cache_P R0 0
  LI R1 0
  SW R0 R1 0
  Load_Addr KeyBoard_Cache R0
  CALL printf
  Load_Addr sys_command_not_found R0
  CALL printf
  ;换行两行，输出"command not found.",并输出一个"A:\>"
  CALL next_cursor_line
  CALL next_cursor_line
  Load_Addr sys_root_path R0
  CALL printf
  RET

GOTO_NotePad:
  ;CALL NotePad
  GOTO Root_Main
GOTO_LifeGame:
  ;GOTO LifeGame_Main
  GOTO Root_Main
GOTO_RetroSnake:
  ;GOTO RetroSnake_Main
  GOTO Root_Main


set_cursor:     ;设置输入光标坐标为R0(16)位，用于系统文字输出
  DATA CURSOR_X 1
  DATA CURSOR_Y 1
  SW_SP R1 0
  ADDSP 1
  SRL R1 R0 0
  SAVE_DATA CURSOR_X R1 0
  SLL R0 R0 0
  SRL R0 R0 0
  SAVE_DATA CURSOR_Y R0 0
  ADDSP FF
  LW_SP R1 0
  RET

printf:       ;从R0指定的地址开始沿cursor输出字符，直到\0为止
  MOVE R5 R0   ;R5维持字符地址
  LW R5 R4 0 ;R4负责记录现在输出的字符是什么
  printf_loop1:
    LOAD_DATA CURSOR_X R0 0
    LOAD_DATA CURSOR_Y R1 0
    SLL R0 R0 0
    ADDU R0 R1 R0
    MOVE R1 R4
    CALL VGA_Draw_Block
    CALL next_cursor
    ADDIU R5 1
    LW R5 R4 0
    BNEZ R4 printf_loop1
    NOP
  RET

next_cursor:    ;光标右移一格，越界后到达下一行行首
  SAVE_REG
  LOAD_DATA CURSOR_X R0 0
  LOAD_DATA CURSOR_Y R1 0
  ADDIU R1 1
  LI R6 VGA_M
  CMP R1 R6
  BTNEZ next_cursor_ret
  NOP
    CALL next_cursor_line
    LOAD_REG
    RET
  next_cursor_ret:
    SAVE_DATA CURSOR_X R0 0
    SAVE_DATA CURSOR_Y R1 0
    LOAD_REG
    RET

next_cursor_line:    ;光标下移一行，越界后到达下一行行首，若超出屏幕则滚屏
  SW_SP R0 0
  SW_SP R1 1
  ADDSP 2
  LOAD_DATA CURSOR_X R0 0
  LOAD_DATA CURSOR_Y R1 0
  LI R1 0
  ADDIU R0 1
  LI R6 VGA_N
  CMP R1 R6
  BTNEZ next_cursor_line_ret
  NOP
  ADDIU R0 FF
  ;这是一个未完成的实现，理应刷新屏幕，下滚一行
  next_cursor_line_ret:
  SAVE_DATA CURSOR_X R0 0
  SAVE_DATA CURSOR_Y R1 0
  ADDSP FE
  LW_SP R0 0
  LW_SP R1 1
  RET


STRING sys_s1 "Preparing to start your computer."
STRING sys_s2 "This may take a few minuts. Please wait..."
STRING sys_s3 " "
STRING sys_s4 "The diagnostic tools were successfully loaded to drive G."
STRING sys_s5 " "
STRING sys_s6 "MSCDEX Version 2.25."
STRING sys_s7 "Copyright (C) Tsinghua University. 2017. All rights reserved."
STRING sys_s8 "       Drive H: = Driver MSCD001 unit 0"
STRING sys_s9 " "
STRING sys_s10 "To get help, type HELP and press ENTER."
STRING sys_root_path "A:\> "
STRING sys_command_not_found " command not found."

Root_INIT:     ;初始化的屏幕字符显示
  LI R0 0
  SAVE_DATA CURSOR_X R0 0
  SAVE_DATA CURSOR_Y R0 0
  LOAD_ADDR sys_s1 r0
  CALL printf
  CALL next_cursor_line
  LOAD_ADDR sys_s2 r0
  CALL printf
  CALL next_cursor_line
  LOAD_ADDR sys_s3 r0
  CALL printf
  CALL next_cursor_line
  LOAD_ADDR sys_s4 r0
  CALL printf
  CALL next_cursor_line
  LOAD_ADDR sys_s5 r0
  CALL printf
  CALL next_cursor_line
  LOAD_ADDR sys_s6 r0
  CALL printf
  CALL next_cursor_line
  LOAD_ADDR sys_s7 r0
  CALL printf
  CALL next_cursor_line
  LOAD_ADDR sys_s8 r0
  CALL printf
  CALL next_cursor_line
  LOAD_ADDR sys_s9 r0
  CALL printf
  CALL next_cursor_line
  LOAD_ADDR sys_s10 r0
  CALL printf
  CALL next_cursor_line
  CALL next_cursor_line
  RET


;——————————————————————————————————————————————————————————————VGA模块——————————————————————————————————————————————————————————
;VGA显示控制器，内置显存 
DEFINE VGA_N 1E  ;30行
DEFINE VGA_M 50  ;80列
DATA VGA_MEM 2400

VGA_COM_PRINT:   ;将VGA_MEM通过串口打印到终端，用于测试
  SAVE_REG
  LI R0 BF ;R0记录串口地址
  SLL R0 R0 0
  LOAD_ADDR VGA_MEM R5 ;R5扫描VGA_MEM地址
  LI R3 VGA_N ;R3是行循环变量
  VGA_COM_PRINT_L1:
    LI R4 VGA_M  ;R4是列循环变量
    VGA_COM_PRINT_L2:
      LW R5 R1 0
      BNEZ R1 2   ;如果字符是0的话输出'.'
      NOP
      LI R1 2E
      CALL COM_WRITE
      ADDIU R4 FF
      BNEZ R4 VGA_COM_PRINT_L2
      ADDIU R5 1
    LI R1 0A     ;换行符
    CALL COM_WRITE
    ADDIU R3 FF
    BNEZ R3 VGA_COM_PRINT_L1
    NOP
  LI R1 0A     ;换行符
  CALL COM_WRITE
  LOAD_REG
  RET
  
VGA_MEM_INIT:
  SAVE_REG
  LOAD_ADDR VGA_MEM R5 ;R5扫描VGA_MEM地址
  LI R2 0
  LI R3 VGA_N ;R3是行循环变量
  VGA_MEM_INIT_L1:
    LI R4 VGA_M  ;R4是列循环变量
    VGA_MEM_INIT_L2:
      SW R5 R2 0
      ADDIU R4 FF
      BNEZ R4 VGA_MEM_INIT_L2
      ADDIU R5 1
    ADDIU R3 FF
    BNEZ R3 VGA_MEM_INIT_L1
    NOP
  LOAD_REG
  RET

VGA_Multi80:    ;快速的*80，加速计算
  SLL R6 R0 6
  SLL R0 R0 4
  ADDU R0 R6 R0
  RET
  
VGA_Draw_Block:   ;绘图一个格子，R0用16位表示坐标，R1表示颜色等参数(约定前7位描述类型，后RGB各三位)
  SAVE_REG
  MOVE R2 R0  ;R2=R0
  MOVE R3 R1  ;R3=R1
  ;输出到真正的VGA显示地址
  LI R6 BF
  SLL R6 R6 0
  ADDUI R6 4
  SW R6 R0 0
  ADDIU R6 1
  SW R6 R1 0
  ;输出到本地虚拟显存
  SRL R0 R0 0 ;R0=R0>>8
  LI R1 VGA_M
  CALL MULTI
  SLL R1 R2 0
  SRL R1 R1 0
  ADDU R0 R1 R0
  LOAD_ADDR VGA_MEM R1
  ADDU R0 R1 R0
  SW R0 R3 0   ;写入VGA显存
  LOAD_REG
  RET
  
;——————————————————————————————————————————————————————————————————串口通信模块—————————————————————————————————————————————————————————————————
;串口接口函数集

WAIT_COM_W:  ;循环直至串口R0可写
  SW_SP R1 0
  LI R1 1
  LW R0 R6 0
  AND R6 R1
  BEQZ R6 WAIT_COM_W
  LW_SP R1 0
  RET

TEST_COM_R: ;返回串口R0是否可读
  LW R0 R0 0
  LI R6 2
  AND R0 R6
  SRL R0 R0 1
  RET

COM_WRITE:   ;向串口R0写入字节R1
  SW_SP R0 0
  ADDSP 1
  ADDIU R0 1
  CALL WAIT_COM_W
  ADDSP FF
  LW_SP R0 0
  SW R0 R1 0
  RET
  

COM_READ:  ;从串口R0读数据，无数据返回0，否则返回数据
  SW_SP R0 0
  ADDSP 1
  ADDIU R0 1
  CALL TEST_COM_R
  ADDSP FF
  BEQZ R0 COM_READ_RET
  NOP
  LW_SP R0 0
  LW R0 R0 0
  COM_READ_RET:
  RET
  
;---------------------------------------------------------------------------通用函数库---------------------------------------------------------------------------;
;通用函数库

MULTI:  ;布斯算法计算有符号16位整数乘法R0*R1,将LOW保存于R0，HIGH保存于R1
;R1(16bit)&R0(16bit)
;R0保留低16位
;R1保留高16位
;R2为R1最低位
;R3为R0最低位
;R4作为布斯算法的附加位
;R5作为循环变量
;R6保存R1副本
  SW_SP R2 0
  SW_SP R3 1
  SW_SP R4 2
  SW_SP R5 3
  ADDSP 4
  MOVE R6 R1
  LI R1 0
  LI R5 0F
  LI R4 0 
  MULTI_LOOP:
    LI R3 1
    AND R3 R0
    SLT R3 R4
    BTNEZ MULTI_PLUS_X
    SLT R4 R3
    BTNEZ MULTI_SUB_X
    NOP
    B MULTI_SHIFT
    NOP
    MULTI_PLUS_X: ;10 部分积+X
      ADDU R1 R6 R1
      B MULTI_SHIFT
      NOP
    MULTI_SUB_X: ;10 部分积-X
      SUBU R1 R6 R1
    MULTI_SHIFT: ;移位
      MOVE R4 R3
      LI R2 1
      AND R2 R1
      SRL R0 R0 1
      SRA R1 R1 1
      SLL R2 R2 0
      SLL R2 R2 7
      ADDU R0 R2 R0
    BNEZ R5 MULTI_LOOP
    ADDIU R5 FF
  ADDSP FC
  LW_SP R2 0
  LW_SP R3 1
  LW_SP R4 2
  LW_SP R5 3
  RET
  
DIVISION:  ;加减交替原码一位除法，R0/R1，商保存于R0，余数存于R1
  SW_SP R2 0
  SW_SP R3 1
  SW_SP R4 2
  ADDSP 3
  LI R2 0 ;R2计算除数有多少位
  MOVE R3 R1
  SRL R3 R3 1
  ADDIU R2 1
  BNEZ R3 FD
  NOP
  SUBU R3 R2 R2  ;R2=16-R2
  ADDIU R2 10
  MOVE R3 R1     ;R3保存移位的 除数
  SLLV R2 R3
  LI R4 1
  SLLV R2 R4      ;R4为1位
  MOVE R1 R0
  LI R0 0
  DIVISION_LOOP:
    SLTU R3 R1
    BTEQZ 3
    NOP
    ADDU R0 R4 R0
    SUBU R1 R3 R1
    SRL R4 R4 1
    SRL R3 R3 1
    BNEZ R2 DIVISION_LOOP
    ADDIU R2 FF
  ADDSP FD
  LW_SP R2 0
  LW_SP R3 1
  LW_SP R4 2
  RET

FastRAND:  ;快速的伪随机数发生器，将15位结果返回至寄存器R0
; x(n+1)=(3*x(n)+59)%65536
  DATA RANDOM_SEED 1
  LOAD_DATA RANDOM_SEED R0 0
  ADDU R0 R0 R6
  ADDU R0 R6 R0
  LI R6 3B
  ADDU R0 R6 R0
  SAVE_DATA RANDOM_SEED R0 0
  RET

RAND:  ;伪随机数发生器，将15位结果返回至寄存器R0
; x(n+1)=(123*x(n)+59)%65536
  DATA RANDOM_SEED 1
  SW_SP R1 0
  ADDSP 1
  LOAD_DATA RANDOM_SEED R0 0
  LI R1 7B
  CALL MULTI
  LI R1 3B
  ADDU R0 R1 R0
  SAVE_DATA RANDOM_SEED R0 0
  ADDSP FF
  LW_SP R1 0
  RET
  
;--------------------------------------------键盘控制程序--------------------------------------------
KeyBoard_Get:   ;从键盘读取当前内容到R0
  DATA KeyBoard_Last 1
  LI R0 BF
  SLL R0 R0 0
  ADDIU R0 6
  LW R0 R0 0
  SW_SP R1 0
  ADDSP 1
  LOAD_DATA KeyBoard_Last R1 0
  SAVE_DATA KeyBoard_Last R0 0
  CMP R0 R1
  BTNEZ 2 
  NOP
  LI R0 0
  ADDSP FF
  LW_SP R1 0
  RET