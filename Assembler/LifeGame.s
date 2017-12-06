; 这是一个生命游戏
GOTO LifeGame_Main


DEFINE LifeGame_MAP_N 1E  ;30行
DEFINE LifeGame_MAP_M 28  ;40列(两列为1格)
;DEFINE LifeGame_MAP_N 10  ;16行
;DEFINE LifeGame_MAP_M 10  ;16列(两列为1格)
DEFINE LifeGame_Alive_PictureL 1C   ;活着的状态图片ID Left
DEFINE LifeGame_Alive_PictureR 1D   ;活着的状态图片ID Left
DEFINE LifeGame_Dead_PictureL 20   ;死着的状态图片ID Left
DEFINE LifeGame_Dead_PictureR 20   ;死着的状态图片ID Right
DATA LifeGame_Map 1200  ;生命游戏的地图0/1表示生死
DATA LifeGame_Map_EndAddr 1 ;冗余位，标示MAP的尾地址
DATA LifeGame_Offset 8  ;16位八连通方向，16位表示坐标可以直接加法做偏移(其中非法格会产生行混淆) (1,0)(0,1)(-1,0)(0,-1)(1,1)(-1,1)(-1,-1)(1,-1)

LifeGame_Main:
  CALL VGA_MEM_INIT
  CALL LifeGame_INIT
  CALL VGA_COM_PRINT
  LI R5 0  ;R5记录是否Auto进行
  LifeGame_Main_Loop:
    CALL KeyBoard_Get
    BNEZ R5 2
    NOP
    BEQZ R0 LifeGame_Main_Loop
    NOP
    CALL LifeGame_OneStep
    CALL VGA_COM_PRINT
    MOVE R1 R0
    ADDIU R1 8F
    BEQZ R1 LifeGame_Main_RET ;如果按下Q则游戏结束
    NOP
    MOVE R1 R0
    ADDIU R1 8E
    BEQZ R1 LifeGame_Main ;如果按下R则重新开始
    NOP
    MOVE R1 R0
    ADDIU R1 9F
    BEQZ R1 LifeGame_Main_BeginAuto ;如果按下A则自动进行游戏
    NOP
    MOVE R1 R0
    ADDIU R1 8D
    BEQZ R1 LifeGame_Main_StopAuto ;如果按下S则停止自动进行
    NOP
    B LifeGame_Main_Loop
    NOP
    LifeGame_Main_BeginAuto:
      LI R5 1
      GOTO LifeGame_Main_Loop
    LifeGame_Main_StopAuto:
      LI R5 0
      GOTO LifeGame_Main_Loop
  LifeGame_Main_RET:
  LI R0 F0 ;标记程序运行结束
  RET

LifeGame_UnitTest:    ;单元测试逻辑，每次终端G的时候执行一步
  DATA LifeGame_isInit 1;是否初始化，为特殊值表示已经初始化过
  SAVE_REG
  LOAD_DATA LifeGame_isInit R0 0
  ADDIU R0 FF;特殊值
  BEQZ R0 LifeGame_UnitTest_OneStep
  NOP
  CALL VGA_MEM_INIT
  CALL LifeGame_INIT
  LifeGame_UnitTest_OneStep:
  CALL LifeGame_OneStep
  CALL VGA_COM_PRINT
  LOAD_REG
  RET

LifeGame_INIT:
  SAVE_REG
  ;计算逻辑参数
  LI R0 0
    ;计算八连通方向
    LI R0 1
    SAVE_DATA LifeGame_Offset R0 1    ;0001
    SLL R0 R0 0
    SAVE_DATA LifeGame_Offset R0 0  ;0100
    ADDIU R0 1
    SAVE_DATA LifeGame_Offset R0 4  ;0101
    LI R0 FF
    SLL R0 R0 0
    SAVE_DATA LifeGame_Offset R0 2  ;FF00
    ADDIU R0 1
    SAVE_DATA LifeGame_Offset R0 5  ;FF01
    LI R1 2
    SUBU R0 R1 R1
    SAVE_DATA LifeGame_Offset R1 6  ;FEFF
    LI R1 FE
    ADDU R0 R1 R0
    SAVE_DATA LifeGame_Offset R0 3  ;FFFF
    LI R0 FF
    SAVE_DATA LifeGame_Offset R0 7  ;00FF
  CALL LifeGame_RandomMapAndPring
  LOAD_REG
  RET

LifeGame_RandomMapAndPring:   ;随机产生初始地图并显示
  SAVE_REG
  LI R4 LifeGame_MAP_N ;R4是行循环变量
  ADDIU R4 FF
  LifeGame_RandomMapAndPring_L1:
    LI R5 LifeGame_MAP_M  ;R5是列循环变量
    ADDIU R5 FF
    LifeGame_RandomMapAndPring_L2:
      ;主循环体
      CALL FastRAND
      SRL R1 R0 0
      SRL R1 R1 7  ;R1记录1/2概率死活
      SLL R0 R4 0
      ADDU R0 R5 R0
      CALL LifeGame_Change
      BNEZ R5 LifeGame_RandomMapAndPring_L2
      ADDIU R5 FF
    BNEZ R4 LifeGame_RandomMapAndPring_L1
    ADDIU R4 FF
  LOAD_REG
  RET

LifeGame_Check_Point:   ;检测(R0,R1)是否合法
  SAVE_REG
  LI R2 0    ;越界判定
  SLT R0 R2
  BTNEZ LifeGame_Check_Point_FalseReturn
  SLT R1 R2
  BTNEZ LifeGame_Check_Point_FalseReturn
  LI R2 LifeGame_MAP_N
  SLT R0 R2
  BTEQZ LifeGame_Check_Point_FalseReturn
  LI R2 LifeGame_MAP_M
  SLT R1 R2
  BTEQZ LifeGame_Check_Point_FalseReturn
  NOP        ;越界判定结束
  LifeGame_Check_Point_TrueReturn:
    LOAD_REG
    LI R0 1
    RET
  LifeGame_Check_Point_FalseReturn:
    LOAD_REG
    LI R0 0
    RET

LifeGame_Multi40: ;将R0的数字快速*40，因为地图大小硬编码列宽40
  MOVE R6 R0
  SLL R0 R0 5
  SLL R6 R6 3
  ADDU R0 R6 R0
  RET

LifeGame_MapAddr:  ;将R0的16位表示坐标转换为MAP下标
  SW_SP R1 0
  ADDSP 1
  SLL R1 R0 0
  SRL R1 R1 0
  SRL R0 R0 0
  MOVE R6 R0
  SLL R0 R0 5
  SLL R6 R6 3
  ADDU R0 R6 R0 ;R0=x*40,R1=y
  ADDU R0 R1 R1
  LOAD_ADDR LifeGame_Map R0
  ADDU R0 R1 R0
  ADDSP FF
  LW_SP R1 0
  RET

LifeGame_OneStep:   ;进行一步计算，并显示结果，约定高8位记录下一回合的结果，低8位为这一回合的结果
  SAVE_REG
  ;第一次循环刷新状态
  LI R4 LifeGame_MAP_N ;R4是行循环变量
  ADDIU R4 FF
  LifeGame_OneStep_L1:
    LI R5 LifeGame_MAP_M  ;R5是列循环变量
    ADDIU R5 FF
    LifeGame_OneStep_L2:
      ;主循环体
      SLL R3 R4 0
      ADDU R3 R5 R3 ;现在R3是中心点16位坐标
      LI R1 0   ;枚举8个方向计算和置于R1
      ;R0是当前枚举的Addr
      
      LifeGame_OneStep_CASE0:    ;--枚举0方向
          MOVE R2 R1
          LOAD_DATA LifeGame_Offset R0 0 ;先检测是否有越界
          ADDU R0 R3 R0
          SLL R1 R0 0
          SRL R1 R1 0
          SRL R0 R0 0
          CALL LifeGame_Check_Point
          BEQZ R0 LifeGame_OneStep_CASE1
          MOVE R1 R2
          LOAD_DATA LifeGame_Offset R0 0
          ADDU R0 R3 R0
          CALL LifeGame_MapAddr
          LW R0 R2 0
          SLL R2 R2 0
          SRL R2 R2 0 ;现在R2是目标格子的死活状态
          ADDU R1 R2 R1
      
      LifeGame_OneStep_CASE1:    ;--枚举1方向
          MOVE R2 R1
          LOAD_DATA LifeGame_Offset R0 1 ;先检测是否有越界
          ADDU R0 R3 R0
          SLL R1 R0 0
          SRL R1 R1 0
          SRL R0 R0 0
          CALL LifeGame_Check_Point
          BEQZ R0 LifeGame_OneStep_CASE2
          MOVE R1 R2
          LOAD_DATA LifeGame_Offset R0 1
          ADDU R0 R3 R0
          CALL LifeGame_MapAddr
          LW R0 R2 0
          SLL R2 R2 0
          SRL R2 R2 0 ;现在R2是目标格子的死活状态
          ADDU R1 R2 R1
      
      LifeGame_OneStep_CASE2:    ;--枚举2方向
          MOVE R2 R1
          LOAD_DATA LifeGame_Offset R0 2 ;先检测是否有越界
          ADDU R0 R3 R0
          SLL R1 R0 0
          SRL R1 R1 0
          SRL R0 R0 0
          CALL LifeGame_Check_Point
          BEQZ R0 LifeGame_OneStep_CASE3
          MOVE R1 R2
          LOAD_DATA LifeGame_Offset R0 2
          ADDU R0 R3 R0
          CALL LifeGame_MapAddr
          LW R0 R2 0
          SLL R2 R2 0
          SRL R2 R2 0 ;现在R2是目标格子的死活状态
          ADDU R1 R2 R1
      
      LifeGame_OneStep_CASE3:    ;--枚举3方向
          MOVE R2 R1
          LOAD_DATA LifeGame_Offset R0 3 ;先检测是否有越界
          ADDU R0 R3 R0
          SLL R1 R0 0
          SRL R1 R1 0
          SRL R0 R0 0
          CALL LifeGame_Check_Point
          BEQZ R0 LifeGame_OneStep_CASE4
          MOVE R1 R2
          LOAD_DATA LifeGame_Offset R0 3
          ADDU R0 R3 R0
          CALL LifeGame_MapAddr
          LW R0 R2 0
          SLL R2 R2 0
          SRL R2 R2 0 ;现在R2是目标格子的死活状态
          ADDU R1 R2 R1
      
      LifeGame_OneStep_CASE4:    ;--枚举4方向
          MOVE R2 R1
          LOAD_DATA LifeGame_Offset R0 4 ;先检测是否有越界
          ADDU R0 R3 R0
          SLL R1 R0 0
          SRL R1 R1 0
          SRL R0 R0 0
          CALL LifeGame_Check_Point
          BEQZ R0 LifeGame_OneStep_CASE5
          MOVE R1 R2
          LOAD_DATA LifeGame_Offset R0 4
          ADDU R0 R3 R0
          CALL LifeGame_MapAddr
          LW R0 R2 0
          SLL R2 R2 0
          SRL R2 R2 0 ;现在R2是目标格子的死活状态
          ADDU R1 R2 R1
      
      LifeGame_OneStep_CASE5:    ;--枚举5方向
          MOVE R2 R1
          LOAD_DATA LifeGame_Offset R0 5 ;先检测是否有越界
          ADDU R0 R3 R0
          SLL R1 R0 0
          SRL R1 R1 0
          SRL R0 R0 0
          CALL LifeGame_Check_Point
          BEQZ R0 LifeGame_OneStep_CASE6
          MOVE R1 R2
          LOAD_DATA LifeGame_Offset R0 5
          ADDU R0 R3 R0
          CALL LifeGame_MapAddr
          LW R0 R2 0
          SLL R2 R2 0
          SRL R2 R2 0 ;现在R2是目标格子的死活状态
          ADDU R1 R2 R1
      
      LifeGame_OneStep_CASE6:    ;--枚举6方向
          MOVE R2 R1
          LOAD_DATA LifeGame_Offset R0 6 ;先检测是否有越界
          ADDU R0 R3 R0
          SLL R1 R0 0
          SRL R1 R1 0
          SRL R0 R0 0
          CALL LifeGame_Check_Point
          BEQZ R0 LifeGame_OneStep_CASE7
          MOVE R1 R2
          LOAD_DATA LifeGame_Offset R0 6
          ADDU R0 R3 R0
          CALL LifeGame_MapAddr
          LW R0 R2 0
          SLL R2 R2 0
          SRL R2 R2 0 ;现在R2是目标格子的死活状态
          ADDU R1 R2 R1
      
      LifeGame_OneStep_CASE7:    ;--枚举7方向
          MOVE R2 R1
          LOAD_DATA LifeGame_Offset R0 7 ;先检测是否有越界
          ADDU R0 R3 R0
          SLL R1 R0 0
          SRL R1 R1 0
          SRL R0 R0 0
          CALL LifeGame_Check_Point
          BEQZ R0 LifeGame_OneStep_CASE8
          MOVE R1 R2
          LOAD_DATA LifeGame_Offset R0 7
          ADDU R0 R3 R0
          CALL LifeGame_MapAddr
          LW R0 R2 0
          SLL R2 R2 0
          SRL R2 R2 0 ;现在R2是目标格子的死活状态
          ADDU R1 R2 R1
          
      LifeGame_OneStep_CASE8:
      
      ;初步版本将自己的死活态变为下方的死活态
      MOVE R0 R3
      CALL LifeGame_MapAddr
      LW R0 R3 0  ;R3现在是中心点数据
      SLL R1 R1 0
      ADDU R1 R3 R1
      SW R0 R1 0
      
      BEQZ R5 LifeGame_OneStep_NoJumpL2
      ADDIU R5 FF
      GOTO LifeGame_OneStep_L2
      LifeGame_OneStep_NoJumpL2:
    BEQZ R4 LifeGame_OneStep_NoJumpL1
    ADDIU R4 FF
    GOTO LifeGame_OneStep_L1
    LifeGame_OneStep_NoJumpL1:
    
  ;第二次循环写回
  LI R4 LifeGame_MAP_N ;R4是行循环变量
  ADDIU R4 FF
  LifeGame_OneStep_L3:
    LI R5 LifeGame_MAP_M  ;R5是列循环变量
    ADDIU R5 FF
    LifeGame_OneStep_L4:
      ;主循环体
      SLL R3 R4 0
      ADDU R3 R5 R3 ;现在R3是16位坐标
      MOVE R0 R3
      CALL LifeGame_MapAddr ;R0现在是中心点内存地址
      LW R0 R1 0
      SLL R2 R1 0
      SRL R2 R2 0  ;R2现在是原来的死活状态
      SRL R1 R1 0 ;现在R1是中心格子的邻居数量
      ;计算下一回合的状态
      LI R6 2
      CMP R1 R6
      BTEQZ LifeGame_OneStep_Keep  ;若为2则保持
      LI R6 3
      CMP R1 R6
      BTEQZ LifeGame_OneStep_Appear  ;若为3则新生
      NOP
      LifeGame_OneStep_Dead:
          LI R1 0 ;其余情况为消亡
          B LifeGame_OneStep_Change
          NOP
      LifeGame_OneStep_Keep:
          MOVE R1 R2 ;保持之前状态
          B LifeGame_OneStep_Change
          NOP
      LifeGame_OneStep_Appear:
          LI R1 1 ;新生
          B LifeGame_OneStep_Change
          NOP
      LifeGame_OneStep_Change:
          MOVE R0 R3
          CALL LifeGame_Change
      BNEZ R5 LifeGame_OneStep_L4
      ADDIU R5 FF
    BNEZ R4 LifeGame_OneStep_L3
    ADDIU R4 FF
  LOAD_REG
  RET

LifeGame_Change:  ;将R0(16位地址)的死活更改为R1,并维护显示
  SAVE_REG
  CALL LifeGame_Print
  Load_Addr LifeGame_Map R2
  SLL R6 R0 0
  SRL R6 R6 0
  ADDU R2 R6 R2
  SRL R0 R0 0
  CALL LifeGame_Multi40
  ADDU R0 R2 R2   ;R2现在是MAP中对应的内存地址
  SW R2 R1 0
  LOAD_REG
  RET

LifeGame_Print:   ;R0为16位坐标,R1为0/1描述死/生,该函数控制写入的内容并调用VGA显示函数
  SAVE_REG
  SRL R3 R0 0 ;R3保存行号
  SLL R4 R0 0
  SRL R4 R4 7 ;R4保存列号*2（双图模式）
  SLL R3 R3 0
  ADDU R3 R4 R0 ;现在R0位16位地址(左半部分)
  BNEZ R1 LifeGame_Print_1
  NOP
  LifeGame_Print_0:
    LI R1 LifeGame_Dead_PictureL
    CALL VGA_Draw_Block
    ADDIU R0 1
    LI R1 LifeGame_Dead_PictureR
    CALL VGA_Draw_Block
    B LifeGame_Print_RET
  LifeGame_Print_1:
    LI R1 LifeGame_Alive_PictureL
    CALL VGA_Draw_Block
    ADDIU R0 1
    LI R1 LifeGame_Alive_PictureR
    CALL VGA_Draw_Block
    ;B LifeGame_Print_RET
  LifeGame_Print_RET:
    LOAD_REG
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
  
;——————————————————————————————————————————————————————————————VGA模块——————————————————————————————————————————————————————————
;VGA显示控制器，内置显存 
DEFINE VGA_N 1E  ;30行
DEFINE VGA_M 50  ;80列
DATA VGA_MEM 2400

VGA_COM_PRINT:   ;将VGA_MEM通过串口打印到终端，用于测试
RET ;在连接真机的时候不输出串口
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
  ADDIU R3 FF
  VGA_MEM_INIT_L1:
    LI R4 VGA_M  ;R4是列循环变量
    ADDIU R4 FF
    VGA_MEM_INIT_L2:
      ;SW R5 R2 0
      SLL R0 R3 0
      ADDU R0 R4 R0
      LI R1 20 ;打印空格
      CALL VGA_Draw_Block
      ADDIU R5 1
      BNEZ R4 VGA_MEM_INIT_L2
      ADDIU R4 FF
    BNEZ R3 VGA_MEM_INIT_L1
    ADDIU R3 FF
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
  ADDIU R6 4
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
  
;---------------------------------------------------------------------------串口控制模块---------------------------------------------------------------------------;
  
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