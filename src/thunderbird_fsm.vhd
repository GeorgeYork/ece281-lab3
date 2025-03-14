--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm.vhd
--| AUTHOR(S)     : Capt Phillip Warner, Capt Dan Johnson
--| CREATED       : 03/2017 Last modified 06/25/2020
--| DESCRIPTION   : This file implements the ECE 281 Lab 2 Thunderbird tail lights
--|					FSM using enumerated types.  This was used to create the
--|					erroneous sim for GR1
--|
--|					Inputs:  i_clk 	 --> 100 MHz clock from FPGA
--|                          i_left  --> left turn signal
--|                          i_right --> right turn signal
--|                          i_reset --> FSM reset
--|
--|					Outputs:  o_lights_L (2:0) --> 3-bit left turn signal lights
--|					          o_lights_R (2:0) --> 3-bit right turn signal lights
--|
--|					Upon reset, the FSM by defaults has all lights off.
--|					Left ON - pattern of increasing lights to left
--|						(OFF, LA, LA/LB, LA/LB/LC, repeat)
--|					Right ON - pattern of increasing lights to right
--|						(OFF, RA, RA/RB, RA/RB/RC, repeat)
--|					L and R ON - hazard lights (OFF, ALL ON, repeat)
--|					A is LSB of lights output and C is MSB.
--|					Once a pattern starts, it finishes back at OFF before it 
--|					can be changed by the inputs
--|					
--|
--|                 xxx State Encoding key
--|                 --------------------
--|                  State | Encoding
--|                 --------------------
--|                  OFF   | 
--|                  ON    | 
--|                  R1    | 
--|                  R2    | 
--|                  R3    | 
--|                  L1    | 
--|                  L2    | 
--|                  L3    | 
--|                 --------------------
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : None
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
 
entity thunderbird_fsm is 
    port (
    i_clk, i_reset  : in    std_logic;
    i_left, i_right : in    std_logic;
    o_lights_L      : out   std_logic_vector(2 downto 0);
    o_lights_R      : out   std_logic_vector(2 downto 0)
);
end thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is 

	type state_type is (sOFF, sON, R1, R2, R3, L1, L2, L3);
	signal state: state_type;
-- CONSTANTS ------------------------------------------------------------------
  
begin

	-- CONCURRENT STATEMENTS --------------------------------------------------------	
	
    ---------------------------------------------------------------------------------
	
	-- PROCESSES --------------------------------------------------------------------
    state_proces: process(i_clk)  
    begin
        if (rising_edge(i_clk)) then
            if (i_reset = '1') then 
                state <= sOFF;
            else 
                case state is
                    when sOFF =>
                        if ((i_left = '1') and (i_right = '1')) then state <= sOFF; end if;
                        if ((i_left = '0') and (i_right = '1')) then state <= R1; end if;
                        if ((i_left = '1') and (i_right = '1')) then state <= L1; end if;      
                    when sON => 
                        state <= sOFF; 
                    when R1 =>
                        state <= R2;
                    when R2 =>
                        state <= R3; 
                    when R3 =>
                        state <= sOFF; 
                    when L1 =>
                        state <= L2;
                    when L2 =>
                        state <= L3; 
                    when L3 =>
                        state <= sOFF;                             
                end case;
            end if;
        end if;
    end process;
    
    	-------------------------------------------------------------------------------
    --        CW        meaning
    --        [1,0]    RAM address counter
    --        [2]    enables write of RAM    
    -------------------------------------------------------------------------------
    output_process: process (state)
    begin
        case state is
            when sOFF => o_lights_L <= "000"; o_lights_R <= "000" ;
            when sON  => o_lights_L <= "111"; o_lights_R <= "111" ;
            when   R1 => o_lights_L <= "000"; o_lights_R <= "100" ;
            when   R2 => o_lights_L <= "000"; o_lights_R <= "110" ;
            when   R3 => o_lights_L <= "000"; o_lights_R <= "111" ;
            when   L1 => o_lights_L <= "001"; o_lights_R <= "000" ;
            when   L2 => o_lights_L <= "011"; o_lights_R <= "000" ;
            when   L3 => o_lights_L <= "111"; o_lights_R <= "000" ;
            when others =>  o_lights_L <= "000"; o_lights_R <= "000" ;
        end case;
    end process;
	-----------------------------------------------------					   
				  
end thunderbird_fsm_arch;