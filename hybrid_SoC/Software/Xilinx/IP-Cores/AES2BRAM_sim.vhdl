----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/09/2024 03:58:38 PM
-- Design Name: 
-- Module Name: top_aes_gcm_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
use work.gcm_pkg.all;
use work.aes_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_aes_gcm_tb is
--  Port ( );
end top_aes_gcm_tb;

architecture Behavioral of top_aes_gcm_tb is
       
    
    signal rst_i                           : std_logic := '0';
    signal clk_i                           : std_logic := '0';
    signal aes_gcm_mode_i                  : std_logic_vector(1 downto 0);
    signal aes_gcm_enc_dec_i               : std_logic;
    signal aes_gcm_pipe_reset_i            : std_logic;
    signal aes_gcm_key_word_val_i          : std_logic_vector(3 downto 0);
    signal aes_gcm_key_word_i              : std_logic_vector(AES_256_KEY_WIDTH_C-1 downto 0);
    signal aes_gcm_iv_val_i                : std_logic;
    signal aes_gcm_iv_i                    : std_logic_vector(GCM_ICB_WIDTH_C-1 downto 0);
    signal aes_gcm_icb_start_cnt_i         : std_logic;
    signal aes_gcm_icb_stop_cnt_i          : std_logic;
    signal aes_gcm_ghash_pkt_val_i         : std_logic;
    signal aes_gcm_ghash_aad_bval_i        : std_logic_vector(NB_STAGE_C-1 downto 0);
    signal aes_gcm_ghash_aad_i             : std_logic_vector(GCM_DATA_WIDTH_C-1 downto 0);
    signal aes_gcm_data_in_bval_i          : std_logic_vector(NB_STAGE_C-1 downto 0);
    signal aes_gcm_data_in_i               : std_logic_vector(AES_DATA_WIDTH_C-1 downto 0);
    signal aes_gcm_ready_o                 : std_logic;
    signal aes_gcm_data_out_val_o          : std_logic;
    signal aes_gcm_data_out_bval_o         : std_logic_vector(NB_STAGE_C-1 downto 0);
    signal aes_gcm_data_out_o              : std_logic_vector(AES_DATA_WIDTH_C-1 downto 0);
    signal aes_gcm_ghash_tag_val_o         : std_logic;
    signal aes_gcm_ghash_tag_o             : std_logic_vector(GCM_DATA_WIDTH_C-1 downto 0);
    signal aes_gcm_icb_cnt_overflow_o      : std_logic;
    signal y_q_o_debug                     : std_logic_vector(GCM_DATA_WIDTH_C-1 downto 0);
    signal gf_y_debug                      : std_logic_vector(GCM_DATA_WIDTH_C-1 downto 0);
    signal ct_val_o_debug                  : std_logic;
    signal bval_val_o_debug                : std_logic;
    signal ghash_aad_val_o_debug           : std_logic;
    signal ghash_ct_or_val_debug           : std_logic;
    signal ghash_data_in_debug             :  std_logic_vector(AES_DATA_WIDTH_C-1 downto 0);   
    signal ghash_ct_val_o_debug            : std_logic;
    

    component top_aes_gcm
        port(
            rst_i                           : in  std_logic;
            clk_i                           : in  std_logic;
            aes_gcm_mode_i                  : in  std_logic_vector(1 downto 0);
            aes_gcm_enc_dec_i               : in  std_logic;
            aes_gcm_pipe_reset_i            : in  std_logic;
            aes_gcm_key_word_val_i          : in  std_logic_vector(3 downto 0);
            aes_gcm_key_word_i              : in  std_logic_vector(AES_256_KEY_WIDTH_C-1 downto 0);
            aes_gcm_iv_val_i                : in  std_logic;
            aes_gcm_iv_i                    : in  std_logic_vector(GCM_ICB_WIDTH_C-1 downto 0);
            aes_gcm_icb_start_cnt_i         : in  std_logic;
            aes_gcm_icb_stop_cnt_i          : in  std_logic;
            aes_gcm_ghash_pkt_val_i         : in  std_logic;
            aes_gcm_ghash_aad_bval_i        : in  std_logic_vector(NB_STAGE_C-1 downto 0);
            aes_gcm_ghash_aad_i             : in  std_logic_vector(GCM_DATA_WIDTH_C-1 downto 0);
            aes_gcm_data_in_bval_i          : in  std_logic_vector(NB_STAGE_C-1 downto 0);
            aes_gcm_data_in_i               : in  std_logic_vector(AES_DATA_WIDTH_C-1 downto 0);
            aes_gcm_ready_o                 : out std_logic;
            aes_gcm_data_out_val_o          : out std_logic;
            aes_gcm_data_out_bval_o         : out std_logic_vector(NB_STAGE_C-1 downto 0);
            aes_gcm_data_out_o              : out std_logic_vector(AES_DATA_WIDTH_C-1 downto 0);
            aes_gcm_ghash_tag_val_o         : out std_logic;
            aes_gcm_ghash_tag_o             : out std_logic_vector(GCM_DATA_WIDTH_C-1 downto 0);
            aes_gcm_icb_cnt_overflow_o      : out std_logic;
            y_q_o_debug                     : out std_logic_vector(GCM_DATA_WIDTH_C-1 downto 0);
            gf_y_debug                      : out std_logic_vector(GCM_DATA_WIDTH_C-1 downto 0);
            ct_val_o_debug                  : out std_logic;
            bval_val_o_debug                : out std_logic;
            ghash_aad_val_o_debug           : out std_logic;
            ghash_ct_or_val_debug           : out std_logic;
            ghash_data_in_debug             : out std_logic_vector(AES_DATA_WIDTH_C-1 downto 0);
            ghash_ct_val_o_debug            : out std_logic);
    end component;

    type test_data_array is array (natural range <>) of std_logic_vector(127 downto 0);

--    signal test_key : std_logic_vector(255 downto 0) :=  x"123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0";
--    signal test_IV : std_logic_vector(95 downto 0) := x"1234567890ABCDEF12345678";
--    signal test_aad : std_logic_vector(127 downto 0) := x"00112233445566778899AABBCCDDEEFF";

                                                         
    signal test_key1 : std_logic_vector(127 downto 0) := x"11111111111111111111111111111111";
    signal test_key2 : std_logic_vector(127 downto 0) := x"11111111111111111111111111111111";
    
    signal test_IV : std_logic_vector(95 downto 0) := x"111111111111111111111111";
    signal test_aad : std_logic_vector(127 downto 0) := x"11111111111111111111111111111111";
    
    signal test_data : std_logic_vector(127 downto 0) := x"11111111111111111111111111111111";
    
    signal test_Assoc_len : std_logic_vector(15 downto 0) := x"0010";
    signal test_data_len : std_logic_vector(15 downto 0) := x"0030";
    

    type mem_array is array (0 to 199) of std_logic_vector(127 downto 0);
    signal temp_BRAM_PORT_dinb : mem_array := (others => (others => '0'));
    signal addr_temp : integer range 0 to 199 := 0; 
    signal loop_temp : integer range 0 to 199 := 0; 
   
    
    signal Crypt_len : std_logic_vector(15 downto 0):= (others => '0');
    signal Assoc_len : std_logic_vector(15 downto 0):= (others => '0');
    signal Data_size : std_logic_vector(15 downto 0):= (others => '0');
    signal Assoc_rest_len : std_logic_vector(15 downto 0):= (others => '0');
    signal Data_rest_len : std_logic_vector(15 downto 0):= (others => '0');


    signal AES_key : std_logic_vector(255 downto 0);
    signal AES_IV : std_logic_vector(95 downto 0);

    signal state     : std_logic_vector(7 downto 0) := (others => '0');

    signal internal_aes_gcm_icb_start_cnt : std_logic;
    

    -- BRAM ports
    signal BRAM_PORT_addrb :           STD_LOGIC_VECTOR (31 downto 0);
    signal BRAM_PORT_enb :             STD_LOGIC;
    signal BRAM_PORT_web :             STD_LOGIC_VECTOR (15 downto 0);
    signal BRAM_PORT_dinb :            STD_LOGIC_VECTOR (127 downto 0);
    signal BRAM_PORT_doutb :           STD_LOGIC_VECTOR (127 downto 0);
    
    signal signal_aes_gcm_ghash_tag_val: std_logic := '0';


    signal Data_ready_ext : std_logic;
    signal Encryption_finish_ext :     STD_LOGIC;
    
    signal addr        : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal Assoc_size : std_logic_vector(15 downto 0):= (others => '0');
    
    signal internal_aes_gcm_ghash_aad_bval : std_logic_vector(15 downto 0);
    signal internal_aes_gcm_data_in_bval : std_logic_vector(15 downto 0);

begin



clk_i <= not clk_i after 5ns;
rst_i <= '1', '0' after 100ns;

aes_gcm_mode_i                  <= "10";
        
  
uut: top_aes_gcm
        port map(
            rst_i                           => rst_i                     ,
            clk_i                           => clk_i                     ,
            aes_gcm_mode_i                  => aes_gcm_mode_i            ,
            aes_gcm_enc_dec_i               => aes_gcm_enc_dec_i         ,
            aes_gcm_pipe_reset_i            => aes_gcm_pipe_reset_i      ,
            aes_gcm_key_word_val_i          => aes_gcm_key_word_val_i    ,
            aes_gcm_key_word_i              => aes_gcm_key_word_i        ,
            aes_gcm_iv_val_i                => aes_gcm_iv_val_i          ,
            aes_gcm_iv_i                    => aes_gcm_iv_i              ,
            aes_gcm_icb_start_cnt_i         => aes_gcm_icb_start_cnt_i   ,
            aes_gcm_icb_stop_cnt_i          => aes_gcm_icb_stop_cnt_i    ,
            aes_gcm_ghash_pkt_val_i         => aes_gcm_ghash_pkt_val_i   ,
            aes_gcm_ghash_aad_bval_i        => aes_gcm_ghash_aad_bval_i  ,
            aes_gcm_ghash_aad_i             => aes_gcm_ghash_aad_i       ,
            aes_gcm_data_in_bval_i          => aes_gcm_data_in_bval_i    ,
            aes_gcm_data_in_i               => aes_gcm_data_in_i         ,
            aes_gcm_ready_o                 => aes_gcm_ready_o           ,
            aes_gcm_data_out_val_o          => aes_gcm_data_out_val_o    ,
            aes_gcm_data_out_bval_o         => aes_gcm_data_out_bval_o   ,
            aes_gcm_data_out_o              => aes_gcm_data_out_o        ,
            aes_gcm_ghash_tag_val_o         => aes_gcm_ghash_tag_val_o   ,
            aes_gcm_ghash_tag_o             => aes_gcm_ghash_tag_o       ,
            aes_gcm_icb_cnt_overflow_o      => aes_gcm_icb_cnt_overflow_o,
            y_q_o_debug                     => y_q_o_debug,
            gf_y_debug                      => gf_y_debug,
            ct_val_o_debug                  => ct_val_o_debug,
            bval_val_o_debug                => bval_val_o_debug,
            ghash_aad_val_o_debug           => ghash_aad_val_o_debug,
            ghash_ct_or_val_debug           => ghash_ct_or_val_debug,
            ghash_data_in_debug             => ghash_data_in_debug,
            ghash_ct_val_o_debug            => ghash_ct_val_o_debug
            );

-- asynchronus logic
aes_gcm_icb_start_cnt_i <= internal_aes_gcm_icb_start_cnt;
aes_gcm_ghash_aad_bval_i  <= internal_aes_gcm_ghash_aad_bval;
aes_gcm_data_in_bval_i    <= internal_aes_gcm_data_in_bval;
     
process(clk_i)
    begin
        if (rising_edge(clk_i)) then
            if(rst_i = '1') then                --go to reset handler
                state <= x"00";

            else
                case state is                       
                    when x"00" =>                   --wait for ready        
                        if(Data_ready_ext = '1') then      
                            BRAM_PORT_enb <= '1';
                              
                            state <= x"40";
                        end if;
    
    


                    when x"40" =>     --reset handler     
                        -- reset all BRAM signals
                        BRAM_PORT_enb <= '0';
                        BRAM_PORT_web <= (others => '0'); 
                        BRAM_PORT_addrb <= (others => '0');
                        BRAM_PORT_dinb <= (others => '0');
    
                        addr <= x"00000000";
                                
                        addr_temp <= 0; 
                        loop_temp <= 0; 
                            
                        -- reset all AES signals
                        aes_gcm_icb_stop_cnt_i <= '1';    
                        internal_aes_gcm_icb_start_cnt <= '0';
                        aes_gcm_key_word_val_i <= (others => '0');
                        aes_gcm_key_word_i <= (others => '0');
                        aes_gcm_iv_val_i <= '0';
                        aes_gcm_iv_i <= (others => '0');
                        aes_gcm_ghash_pkt_val_i <= '0';
                        internal_aes_gcm_ghash_aad_bval <= (others => '0');
                        aes_gcm_ghash_aad_i <= (others => '0');
                        aes_gcm_data_in_i <= (others => '0');
                        aes_gcm_enc_dec_i <= '0';
                        aes_gcm_mode_i <= "10";
                        internal_aes_gcm_data_in_bval <= (others => '0');
                                
                        state <= x"41";
    
                    when x"41" => 
                        aes_gcm_icb_stop_cnt_i <= '0';
                        aes_gcm_pipe_reset_i <= '1';
                        state <= x"42";
    
                    when x"42" =>
                        aes_gcm_pipe_reset_i <= '0';
                        state <= x"02";
    
                    when x"02" =>                   --Set BRAM_PORT_addrb: 10 addr: 20
    
                        BRAM_PORT_addrb <= x"00000010";
                        addr <= std_logic_vector(unsigned(addr) + 32);
                        
                        state <= x"03";
                                 
                    when x"03" =>                   --Set BRAM_PORT_addrb: 20 addr: 30
                        
                        BRAM_PORT_addrb <= addr;
                        addr <= std_logic_vector(unsigned(addr) + 16);
                                          
                        state <= x"04";
                                
                    when x"04" =>                   --get key 1, BRAM_PORT_addrb: 20 addr: 30    
                        
                        AES_key(127 downto 120) <= test_key1(7 downto 0);
                        AES_key(119 downto 112) <= test_key1(15 downto 8);
                        AES_key(111 downto 104) <= test_key1(23 downto 16);
                        AES_key(103 downto 96)  <= test_key1(31 downto 24);
                        AES_key(95 downto 88)   <= test_key1(39 downto 32);
                        AES_key(87 downto 80)   <= test_key1(47 downto 40);
                        AES_key(79 downto 72)   <= test_key1(55 downto 48);
                        AES_key(71 downto 64)   <= test_key1(63 downto 56);
                        AES_key(63 downto 56)   <= test_key1(71 downto 64);
                        AES_key(55 downto 48)   <= test_key1(79 downto 72);
                        AES_key(47 downto 40)   <= test_key1(87 downto 80);
                        AES_key(39 downto 32)   <= test_key1(95 downto 88);
                        AES_key(31 downto 24)   <= test_key1(103 downto 96);
                        AES_key(23 downto 16)   <= test_key1(111 downto 104);
                        AES_key(15 downto 8)    <= test_key1(119 downto 112);
                        AES_key(7 downto 0)     <= test_key1(127 downto 120);

                        BRAM_PORT_addrb <= addr;
                        addr <= std_logic_vector(unsigned(addr) + 16);
                                
                        state <= x"05";
                when x"05" =>                   --get key 2, BRAM_PORT_addrb: 40 addr: 50  

                
                    AES_key(255 downto 248) <= test_key2(7 downto 0);
                    AES_key(247 downto 240) <= test_key2(15 downto 8);
                    AES_key(239 downto 232) <= test_key2(23 downto 16);
                    AES_key(231 downto 224) <= test_key2(31 downto 24);
                    AES_key(223 downto 216) <= test_key2(39 downto 32);
                    AES_key(215 downto 208) <= test_key2(47 downto 40);
                    AES_key(207 downto 200) <= test_key2(55 downto 48);
                    AES_key(199 downto 192) <= test_key2(63 downto 56);
                    AES_key(191 downto 184) <= test_key2(71 downto 64);
                    AES_key(183 downto 176) <= test_key2(79 downto 72);
                    AES_key(175 downto 168) <= test_key2(87 downto 80);
                    AES_key(167 downto 160) <= test_key2(95 downto 88);
                    AES_key(159 downto 152) <= test_key2(103 downto 96);
                    AES_key(151 downto 144) <= test_key2(111 downto 104);
                    AES_key(143 downto 136) <= test_key2(119 downto 112);
                    AES_key(135 downto 128) <= test_key2(127 downto 120);
                
                    BRAM_PORT_addrb <= addr;
                    

                    state <= x"06";
                          
                when x"06" =>                   --assign key                           
                    aes_gcm_key_word_val_i <= x"f";
                    aes_gcm_key_word_i <= AES_key;

                    AES_IV(95  downto 88)  <= test_IV(7  downto 0);
                    AES_IV(87  downto 80)  <= test_IV(15 downto 8);
                    AES_IV(79  downto 72)  <= test_IV(23 downto 16);
                    AES_IV(71  downto 64)  <= test_IV(31 downto 24);
                    AES_IV(63  downto 56)  <= test_IV(39 downto 32);
                    AES_IV(55  downto 48)  <= test_IV(47 downto 40);
                    AES_IV(47  downto 40)  <= test_IV(55 downto 48);
                    AES_IV(39  downto 32)  <= test_IV(63 downto 56);
                    AES_IV(31  downto 24)  <= test_IV(71 downto 64);
                    AES_IV(23  downto 16)  <= test_IV(79 downto 72);
                    AES_IV(15  downto 8)   <= test_IV(87 downto 80);
                    AES_IV(7   downto 0)   <= test_IV(95 downto 88);
                                                            
                    Crypt_len  <= test_data_len;                     
                    Assoc_len  <= test_Assoc_len;
                                                
                    state <= x"07";
                            
                when x"07" =>                   --assign IV                             
                    aes_gcm_key_word_val_i <= x"0";
                    aes_gcm_key_word_i  <= (others => '0');

                    aes_gcm_iv_val_i <= '1';
                    aes_gcm_iv_i <= AES_IV;

                    Data_size <= std_logic_vector(unsigned(Crypt_len) +  x"0100");         
                    Assoc_len <= std_logic_vector(unsigned(Assoc_len) +  x"0040");                      
                        
                    state <= x"08";

                when x"08" =>                   --reset IV and start cnt, BRAM_PORT_addrb: 40 addr: 40 
                    aes_gcm_iv_val_i <= '0';
                    aes_gcm_iv_i <= (others => '0');

                    internal_aes_gcm_icb_start_cnt <= '1';                     

                    state <= x"09";                      
                    
                when x"09" =>                   --reset cnt and wait for ready, BRAM_PORT_addrb: 40 addr: 40
                    internal_aes_gcm_icb_start_cnt <= '0';     
                            
                    if(aes_gcm_ready_o = '1') then      
                        if unsigned(Assoc_len(15 downto 0)) > unsigned(addr(15 downto 0))  then
                            Assoc_rest_len <= std_logic_vector(unsigned(Assoc_len(15 downto 0)) - unsigned(addr(15 downto 0)));  
                        end if;

                        
                        BRAM_PORT_addrb <= std_logic_vector(unsigned(addr) + 16);
                        addr <= std_logic_vector(unsigned(addr) + 32);

                        state <= x"10";   
                    end if;   

                when x"10" =>                   -- send AAD, BRAM_PORT_addrb: 50 addr: 60 

                    
                aes_gcm_ghash_pkt_val_i <= '1';
                                     
                if unsigned(Assoc_rest_len(15 downto 0)) > x"0010" then

                    internal_aes_gcm_ghash_aad_bval <= x"FFFF";
                   
                    BRAM_PORT_addrb <= addr;
                    addr <= std_logic_vector(unsigned(addr) + 16);
                    
                    state <= x"10";
                                                              
                elsif unsigned(Assoc_rest_len(15 downto 0)) <= x"0010" and unsigned(Assoc_rest_len(15 downto 0)) > x"0000" then
                       
                    if Assoc_rest_len = x"0010" then
                        internal_aes_gcm_ghash_aad_bval <= x"FFFF";  
                        
                    elsif Assoc_rest_len = x"000F" then
                        internal_aes_gcm_ghash_aad_bval <= x"FFFE";  
                
                    elsif Assoc_rest_len = x"000E" then
                        internal_aes_gcm_ghash_aad_bval <= x"FFFC";

                    elsif Assoc_rest_len = x"000D" then
                        internal_aes_gcm_ghash_aad_bval <= x"FFF8";
                        
                    elsif Assoc_rest_len = x"000C" then
                        internal_aes_gcm_ghash_aad_bval <= x"FFF0";
                        
                    elsif Assoc_rest_len = x"000B" then
                        internal_aes_gcm_ghash_aad_bval <= x"FFE0";

                    elsif Assoc_rest_len = x"000A" then
                        internal_aes_gcm_ghash_aad_bval <= x"FFC0";
                       
                    elsif Assoc_rest_len = x"0009" then
                        internal_aes_gcm_ghash_aad_bval <= x"FF80";
                        
                    elsif Assoc_rest_len = x"0008" then
                        internal_aes_gcm_ghash_aad_bval <= x"FF00";
                            
                    elsif Assoc_rest_len = x"0007" then
                        internal_aes_gcm_ghash_aad_bval <= x"FE00";
                        
                    elsif Assoc_rest_len = x"0006" then
                        internal_aes_gcm_ghash_aad_bval <= x"FC00";
                        
                    elsif Assoc_rest_len = x"0005" then
                        internal_aes_gcm_ghash_aad_bval <= x"F800";
                        
                    elsif Assoc_rest_len = x"0004" then
                        internal_aes_gcm_ghash_aad_bval <= x"F000";
                        
                    elsif Assoc_rest_len = x"0003" then
                        internal_aes_gcm_ghash_aad_bval <= x"E000";
                          
                    elsif Assoc_rest_len = x"0002" then
                        internal_aes_gcm_ghash_aad_bval <= x"C000";
                       
                    elsif Assoc_rest_len = x"0001" then
                        internal_aes_gcm_ghash_aad_bval <= x"8000";
                        
                    end if;
                    
                    addr <= x"00000110";
                    BRAM_PORT_addrb <= x"00000100";

                    state <= x"11";
                else
                    addr <= x"00000110";
                    BRAM_PORT_addrb <= x"00000100";

                    internal_aes_gcm_ghash_aad_bval <= x"0000";
                    
                    state <= x"11";
                end if;
                                    
                
                aes_gcm_ghash_aad_i(127 downto 120) <= test_aad(7   downto 0);
                aes_gcm_ghash_aad_i(119 downto 112) <= test_aad(15  downto 8);
                aes_gcm_ghash_aad_i(111 downto 104) <= test_aad(23  downto 16);
                aes_gcm_ghash_aad_i(103 downto 96)  <= test_aad(31  downto 24);
                aes_gcm_ghash_aad_i(95  downto 88)  <= test_aad(39  downto 32);
                aes_gcm_ghash_aad_i(87  downto 80)  <= test_aad(47  downto 40);
                aes_gcm_ghash_aad_i(79  downto 72)  <= test_aad(55  downto 48);
                aes_gcm_ghash_aad_i(71  downto 64)  <= test_aad(63  downto 56);
                aes_gcm_ghash_aad_i(63  downto 56)  <= test_aad(71  downto 64);
                aes_gcm_ghash_aad_i(55  downto 48)  <= test_aad(79  downto 72);
                aes_gcm_ghash_aad_i(47  downto 40)  <= test_aad(87  downto 80);
                aes_gcm_ghash_aad_i(39  downto 32)  <= test_aad(95  downto 88);
                aes_gcm_ghash_aad_i(31  downto 24)  <= test_aad(103 downto 96);
                aes_gcm_ghash_aad_i(23  downto 16)  <= test_aad(111 downto 104);
                aes_gcm_ghash_aad_i(15  downto 8)   <= test_aad(119 downto 112);
                aes_gcm_ghash_aad_i(7   downto 0)   <= test_aad(127 downto 120);


                if unsigned(Assoc_len(15 downto 0)) >= (unsigned(addr(15 downto 0))-16)  then
                    Assoc_rest_len <= std_logic_vector(unsigned(Assoc_len(15 downto 0)) - (unsigned(addr(15 downto 0))-16));  
                 end if;                                                                                 
            when x"11" =>
                  
                   internal_aes_gcm_ghash_aad_bval <= x"0000";
      
                   BRAM_PORT_addrb <= addr;        --addr= 110
                        
                   state <= x"12";
                      
                when x"12" =>   
                       internal_aes_gcm_ghash_aad_bval <= x"0000";      
                    internal_aes_gcm_data_in_bval <= x"FFFF";
                
               
                        aes_gcm_data_in_i(127 downto 120) <= test_data(7 downto 0);
                        aes_gcm_data_in_i(119 downto 112) <= test_data(15 downto 8);
                        aes_gcm_data_in_i(111 downto 104) <= test_data(23 downto 16);
                        aes_gcm_data_in_i(103 downto 96)  <= test_data(31 downto 24);
                        aes_gcm_data_in_i(95 downto 88)   <= test_data(39 downto 32);
                        aes_gcm_data_in_i(87 downto 80)   <= test_data(47 downto 40);
                        aes_gcm_data_in_i(79 downto 72)   <= test_data(55 downto 48);
                        aes_gcm_data_in_i(71 downto 64)   <= test_data(63 downto 56);
                        aes_gcm_data_in_i(63 downto 56)   <= test_data(71 downto 64);
                        aes_gcm_data_in_i(55 downto 48)   <= test_data(79 downto 72);
                        aes_gcm_data_in_i(47 downto 40)   <= test_data(87 downto 80);
                        aes_gcm_data_in_i(39 downto 32)   <= test_data(95 downto 88);
                        aes_gcm_data_in_i(31 downto 24)   <= test_data(103 downto 96);
                        aes_gcm_data_in_i(23 downto 16)   <= test_data(111 downto 104);
                        aes_gcm_data_in_i(15 downto 8)    <= test_data(119 downto 112);
                        aes_gcm_data_in_i(7 downto 0)     <= test_data(127 downto 120);
                                       
                
                    if unsigned(Data_size(15 downto 0)) > (unsigned(addr(15 downto 0))) then
                        Data_rest_len <= std_logic_vector(unsigned(Data_size(15 downto 0)) - (unsigned(addr(15 downto 0))));  
                    end if;

                    BRAM_PORT_addrb <= std_logic_vector(unsigned(addr) + 16);   
                    addr <= std_logic_vector(unsigned(addr) + 32);              
                    

--                    state <= x"52";
--               when x"52" =>
--                     internal_aes_gcm_data_in_bval <= x"0000";
               
--                    BRAM_PORT_addrb <= std_logic_vector(unsigned(addr) + 16);   
--                    addr <= std_logic_vector(unsigned(addr) + 32);     
               
                   
                    state <= x"13";
            
                when x"13" =>                   --send data, BRAM_PORT_addrb: 110 addr: 130     
                                                       
                        if unsigned(Data_rest_len(15 downto 0)) > x"0010" then
                            internal_aes_gcm_data_in_bval <= x"FFFF";
                            
                            BRAM_PORT_addrb <= addr;
                            addr <= std_logic_vector(unsigned(addr) + 16);
                
                            state <= x"13";
                            
                        elsif unsigned(Data_rest_len(15 downto 0)) < x"0010" and unsigned(Data_rest_len(15 downto 0)) > x"0000" then
                                
                            if    Data_rest_len = x"000F" then
                                internal_aes_gcm_data_in_bval <= x"FFFE";       
                                                            
                            elsif Data_rest_len = x"000E" then
                                internal_aes_gcm_data_in_bval <= x"FFFC";
                        
                            elsif Data_rest_len = x"000D" then
                                internal_aes_gcm_data_in_bval <= x"FFF8";
                                
                            elsif Data_rest_len = x"000C" then
                                internal_aes_gcm_data_in_bval <= x"FFF0";
                            
                            elsif Data_rest_len = x"000B" then
                                internal_aes_gcm_data_in_bval <= x"FFE0";
                            
                            elsif Data_rest_len = x"000A" then
                                internal_aes_gcm_data_in_bval <= x"FFC0";
                            
                            elsif Data_rest_len = x"0009" then
                                internal_aes_gcm_data_in_bval <= x"FF80";
                            
                            elsif Data_rest_len = x"0008" then
                                internal_aes_gcm_data_in_bval <= x"FF00";
                            
                            elsif Data_rest_len = x"0007" then
                                internal_aes_gcm_data_in_bval <= x"FE00";
                            
                            elsif Data_rest_len = x"0006" then
                                internal_aes_gcm_data_in_bval <= x"FC00";
                                
                            elsif Data_rest_len = x"0005" then
                                internal_aes_gcm_data_in_bval <= x"F800";
                                
                            elsif Data_rest_len = x"0004" then
                                internal_aes_gcm_data_in_bval <= x"F000";
                                
                            elsif Data_rest_len = x"0003" then
                                internal_aes_gcm_data_in_bval <= x"E000";
                                
                            elsif Data_rest_len = x"0002" then
                                internal_aes_gcm_data_in_bval <= x"C000";
                                
                            elsif Data_rest_len = x"0001" then
                                internal_aes_gcm_data_in_bval <= x"8000";
                                
                            else
                                internal_aes_gcm_data_in_bval <= x"0000";
                                aes_gcm_ghash_pkt_val_i <= '0';
                            end if;
                                    
                            BRAM_PORT_addrb <= x"00000100";
                            addr <= x"00000100";

                            state <= x"14";
                        else
                            BRAM_PORT_addrb <= x"00000100";
                            addr <= x"00000100";
                            
                            state <= x"14"; 
                        end if;

                        aes_gcm_data_in_i(127 downto 120) <= test_data(7 downto 0);
                        aes_gcm_data_in_i(119 downto 112) <= test_data(15 downto 8);
                        aes_gcm_data_in_i(111 downto 104) <= test_data(23 downto 16);
                        aes_gcm_data_in_i(103 downto 96)  <= test_data(31 downto 24);
                        aes_gcm_data_in_i(95 downto 88)   <= test_data(39 downto 32);
                        aes_gcm_data_in_i(87 downto 80)   <= test_data(47 downto 40);
                        aes_gcm_data_in_i(79 downto 72)   <= test_data(55 downto 48);
                        aes_gcm_data_in_i(71 downto 64)   <= test_data(63 downto 56);
                        aes_gcm_data_in_i(63 downto 56)   <= test_data(71 downto 64);
                        aes_gcm_data_in_i(55 downto 48)   <= test_data(79 downto 72);
                        aes_gcm_data_in_i(47 downto 40)   <= test_data(87 downto 80);
                        aes_gcm_data_in_i(39 downto 32)   <= test_data(95 downto 88);
                        aes_gcm_data_in_i(31 downto 24)   <= test_data(103 downto 96);
                        aes_gcm_data_in_i(23 downto 16)   <= test_data(111 downto 104);
                        aes_gcm_data_in_i(15 downto 8)    <= test_data(119 downto 112);
                        aes_gcm_data_in_i(7 downto 0)     <= test_data(127 downto 120);
                        
                                                   
                    if unsigned(Data_size(15 downto 0)) > (unsigned(addr(15 downto 0))-16)  then
                        Data_rest_len <= std_logic_vector(unsigned(Data_size(15 downto 0)) - (unsigned(addr(15 downto 0))-16));  
                                         end if;

                    if(aes_gcm_data_out_val_o = '1') then      
                        temp_BRAM_PORT_dinb(addr_temp) <= aes_gcm_data_out_o;
                        addr_temp<=addr_temp+1;
                    end if;
                when x"14" =>                   
                    internal_aes_gcm_data_in_bval <= (others => '0');
                    internal_aes_gcm_ghash_aad_bval <= (others => '0');
                    aes_gcm_ghash_pkt_val_i <= '0';
                    
                    if(aes_gcm_data_out_val_o = '1') then
                        temp_BRAM_PORT_dinb(addr_temp) <= aes_gcm_data_out_o;
                        addr_temp<=addr_temp+1;
                       
                        state <= x"15";
                    end if;
                when x"15" => 
                    temp_BRAM_PORT_dinb(addr_temp) <= aes_gcm_data_out_o;
                    addr_temp<=addr_temp+1;
                   
                    state <= x"16";
                when x"16" =>                   --store data BRAM
                    
                
                    if addr_temp > loop_temp then
                        BRAM_PORT_web <= (others => '1');
                        
                        BRAM_PORT_dinb(127 downto 120) <= temp_BRAM_PORT_dinb(loop_temp)(7 downto 0);
                        BRAM_PORT_dinb(119 downto 112) <= temp_BRAM_PORT_dinb(loop_temp)(15 downto 8);
                        BRAM_PORT_dinb(111 downto 104) <= temp_BRAM_PORT_dinb(loop_temp)(23 downto 16);
                        BRAM_PORT_dinb(103 downto 96)  <= temp_BRAM_PORT_dinb(loop_temp)(31 downto 24);
                        BRAM_PORT_dinb(95 downto 88)   <= temp_BRAM_PORT_dinb(loop_temp)(39 downto 32);
                        BRAM_PORT_dinb(87 downto 80)   <= temp_BRAM_PORT_dinb(loop_temp)(47 downto 40);
                        BRAM_PORT_dinb(79 downto 72)   <= temp_BRAM_PORT_dinb(loop_temp)(55 downto 48);
                        BRAM_PORT_dinb(71 downto 64)   <= temp_BRAM_PORT_dinb(loop_temp)(63 downto 56);
                        BRAM_PORT_dinb(63 downto 56)   <= temp_BRAM_PORT_dinb(loop_temp)(71 downto 64);
                        BRAM_PORT_dinb(55 downto 48)   <= temp_BRAM_PORT_dinb(loop_temp)(79 downto 72);
                        BRAM_PORT_dinb(47 downto 40)   <= temp_BRAM_PORT_dinb(loop_temp)(87 downto 80);
                        BRAM_PORT_dinb(39 downto 32)   <= temp_BRAM_PORT_dinb(loop_temp)(95 downto 88);
                        BRAM_PORT_dinb(31 downto 24)   <= temp_BRAM_PORT_dinb(loop_temp)(103 downto 96);
                        BRAM_PORT_dinb(23 downto 16)   <= temp_BRAM_PORT_dinb(loop_temp)(111 downto 104);
                        BRAM_PORT_dinb(15 downto 8)    <= temp_BRAM_PORT_dinb(loop_temp)(119 downto 112);
                        BRAM_PORT_dinb(7 downto 0)     <= temp_BRAM_PORT_dinb(loop_temp)(127 downto 120);

                        loop_temp<=loop_temp+1;

                        BRAM_PORT_addrb <= addr;
                        addr <= std_logic_vector(unsigned(addr) + 16);

                        if addr_temp <= 5 then
                            signal_aes_gcm_ghash_tag_val<= '1';
                        end if;

                        state <= x"16";
                    else

                        BRAM_PORT_addrb <= addr;

                        if(signal_aes_gcm_ghash_tag_val = '0') then
                            addr <= std_logic_vector(unsigned(addr) + 16);
                        end if;

                        state <= x"17";

                    end if;

                when x"17" =>                   --store ghash 
                    BRAM_PORT_addrb <= addr;
                    
                    BRAM_PORT_dinb(127 downto 120) <= aes_gcm_ghash_tag_o(7 downto 0);
                    BRAM_PORT_dinb(119 downto 112) <= aes_gcm_ghash_tag_o(15 downto 8);
                    BRAM_PORT_dinb(111 downto 104) <= aes_gcm_ghash_tag_o(23 downto 16);
                    BRAM_PORT_dinb(103 downto 96)  <= aes_gcm_ghash_tag_o(31 downto 24);
                    BRAM_PORT_dinb(95 downto 88)   <= aes_gcm_ghash_tag_o(39 downto 32);
                    BRAM_PORT_dinb(87 downto 80)   <= aes_gcm_ghash_tag_o(47 downto 40);
                    BRAM_PORT_dinb(79 downto 72)   <= aes_gcm_ghash_tag_o(55 downto 48);
                    BRAM_PORT_dinb(71 downto 64)   <= aes_gcm_ghash_tag_o(63 downto 56);
                    BRAM_PORT_dinb(63 downto 56)   <= aes_gcm_ghash_tag_o(71 downto 64);
                    BRAM_PORT_dinb(55 downto 48)   <= aes_gcm_ghash_tag_o(79 downto 72);
                    BRAM_PORT_dinb(47 downto 40)   <= aes_gcm_ghash_tag_o(87 downto 80);
                    BRAM_PORT_dinb(39 downto 32)   <= aes_gcm_ghash_tag_o(95 downto 88);
                    BRAM_PORT_dinb(31 downto 24)   <= aes_gcm_ghash_tag_o(103 downto 96);
                    BRAM_PORT_dinb(23 downto 16)   <= aes_gcm_ghash_tag_o(111 downto 104);
                    BRAM_PORT_dinb(15 downto 8)    <= aes_gcm_ghash_tag_o(119 downto 112);
                    BRAM_PORT_dinb(7 downto 0)     <= aes_gcm_ghash_tag_o(127 downto 120);

                    signal_aes_gcm_ghash_tag_val<= '0';

                    state <= x"18";
                    
                when x"18" => 
                    Encryption_finish_ext <= '1';  

                    aes_gcm_icb_stop_cnt_i <= '1';
                    aes_gcm_pipe_reset_i <= '1';

                    state <= x"19";  
                when x"19" =>
                    addr <= x"00000000";

                    BRAM_PORT_web <= (others => '0');

                    aes_gcm_icb_stop_cnt_i <= '0';
    
                    BRAM_PORT_enb <= '0';
                            
                    BRAM_PORT_addrb <= (others => '0');
                    BRAM_PORT_dinb <= (others => '0');
   
                    aes_gcm_pipe_reset_i <= '0';
                    addr_temp <= 0; 
                    loop_temp <= 0; 

                    if(Data_ready_ext = '0') then      
                        
                        Encryption_finish_ext <= '0'; 
        
                        state <= x"00";

                    end if;








                when x"30" =>     --reset handler     
                    -- reset all BRAM signals
                    BRAM_PORT_enb <= '0';
                    BRAM_PORT_web <= (others => '0'); 
                    BRAM_PORT_addrb <= (others => '0');
                    BRAM_PORT_dinb <= (others => '0');

                    addr <= x"00000000";
                            
                    addr_temp <= 0; 
                    loop_temp <= 0; 
                        
                    -- reset all AES signals
                    aes_gcm_icb_stop_cnt_i <= '1';    
                    internal_aes_gcm_icb_start_cnt <= '0';
                    aes_gcm_key_word_val_i <= (others => '0');
                    aes_gcm_key_word_i <= (others => '0');
                    aes_gcm_iv_val_i <= '0';
                    aes_gcm_iv_i <= (others => '0');
                    aes_gcm_ghash_pkt_val_i <= '0';
                    internal_aes_gcm_ghash_aad_bval <= (others => '0');
                    aes_gcm_ghash_aad_i <= (others => '0');
                    aes_gcm_data_in_i <= (others => '0');
                    aes_gcm_enc_dec_i <= '0';
                    aes_gcm_mode_i <= "10";
                    internal_aes_gcm_data_in_bval <= (others => '0');
                            
                    state <= x"31";

                when x"31" => 
                    aes_gcm_icb_stop_cnt_i <= '0';
                    aes_gcm_pipe_reset_i <= '1';
                    state <= x"32";

                when x"32" =>
                    aes_gcm_pipe_reset_i <= '0';
                    
                    
                    state <= x"00";
                when others => 
                    state <= x"30";
                
            end case;
        end if;
    end if;  
end process;

end Behavioral;




