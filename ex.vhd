----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:44:23 11/15/2017 
-- Design Name: 
-- Module Name:    ex - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use WORK.DEFINES.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ex is
    Port ( rst : in  STD_LOGIC;
           alusel_i : in  STD_LOGIC_VECTOR(2 downto 0);
           aluop_i : in  STD_LOGIC_VECTOR(7 downto 0);
           reg1_i : in  STD_LOGIC_VECTOR(15 downto 0);
           reg2_i : in  STD_LOGIC_VECTOR(15 downto 0);
           wd_i : in  STD_LOGIC_VECTOR (2 downto 0);
           wreg_i : in  STD_LOGIC;
           wd_o : out  STD_LOGIC_VECTOR (2 downto 0);
           wreg_o : out  STD_LOGIC;
           wdata_o : out  STD_LOGIC_VECTOR (15 downto 0));
end ex;

architecture Behavioral of ex is
	signal logicout : std_logic_vector(15 downto 0);
begin

	calc: process(rst,aluop_i,reg1_i,reg2_i)
	begin
		if(rst = Enable) then
			logicout <= ZeroWord;
		else
			case aluop_i is
				when EXE_ADDIU3_OP =>
					logicout <= reg1_i + reg2_i;
				when others =>
					logicout <= ZeroWord;
			end case;
		end if;
	end process;
	
	sel: process(aluop_i,alusel_i,logicout,wd_i,wreg_i)
	begin
		wd_o <= wd_i;
		wreg_o <= wreg_i;
		case alusel_i is
			when EXE_RES_LOGIC =>
				wdata_o <= logicout;
			when others =>
				wdata_o <= ZeroWord;
		end case;
	end process;
end Behavioral;

