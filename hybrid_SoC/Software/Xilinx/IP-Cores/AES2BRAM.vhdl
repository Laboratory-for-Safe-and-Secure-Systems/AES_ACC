library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BRAM2AES is
    port (
        clk :                       in STD_LOGIC;
        rst :                       in STD_LOGIC;

        -- AES ports
        aes_gcm_ready :             in STD_LOGIC;
        aes_gcm_data_out_val :      in STD_LOGIC;
        aes_gcm_data_out_bval :     in STD_LOGIC_VECTOR (15 downto 0);
        aes_gcm_data_out :          in STD_LOGIC_VECTOR (127 downto 0);
        aes_gcm_ghash_tag_val :     in STD_LOGIC;
        aes_gcm_ghash_tag :         in STD_LOGIC_VECTOR (127 downto 0);
        aes_gcm_pipe_reset :        out std_logic;
        aes_gcm_enc_dec :           out std_logic;
        aes_gcm_key_word_val :      out STD_LOGIC_VECTOR (3 downto 0);
        aes_gcm_key_word :          out STD_LOGIC_VECTOR (255 downto 0);
        aes_gcm_iv_val :            out STD_LOGIC;
        aes_gcm_iv :                out STD_LOGIC_VECTOR (95 downto 0);
        aes_gcm_ghash_pkt_val :     out STD_LOGIC;
        aes_gcm_ghash_aad_bval :    out STD_LOGIC_VECTOR (15 downto 0);
        aes_gcm_ghash_aad :         out STD_LOGIC_VECTOR (127 downto 0);
        aes_gcm_data_in_bval :      out STD_LOGIC_VECTOR (15 downto 0);
        aes_gcm_data_in :           out STD_LOGIC_VECTOR (127 downto 0);
        aes_gcm_mode :              out STD_LOGIC_VECTOR (1 downto 0) := "10";
        aes_gcm_icb_start_cnt :     out STD_LOGIC;
        aes_gcm_icb_stop_cnt :      out STD_LOGIC;
        

        -- BRAM ports
        BRAM_PORT_addrb :           out STD_LOGIC_VECTOR (31 downto 0):= (others => '0');
        BRAM_PORT_enb :             out STD_LOGIC := '0';
        BRAM_PORT_web :             out STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
        BRAM_PORT_dinb :            out STD_LOGIC_VECTOR (127 downto 0);
        BRAM_PORT_doutb :           in STD_LOGIC_VECTOR (127 downto 0);

        -- External signals
        Data_ready_ext :            in STD_LOGIC;
        Encryption_finish_ext :     out STD_LOGIC;
        
        -- Debug ports
        debug_state :               out STD_LOGIC_VECTOR (7 downto 0);

        debug_data_size :           out STD_LOGIC_VECTOR (15 downto 0);
        debug_assoc_size :          out STD_LOGIC_VECTOR (15 downto 0);
        debug_assoc_rest:           out STD_LOGIC_VECTOR (15 downto 0);
        debug_data_rest:            out STD_LOGIC_VECTOR (15 downto 0);

        debug_addr_temp:            out STD_LOGIC_VECTOR (7 downto 0);
        debug_loop_temp:            out STD_LOGIC_VECTOR (7 downto 0)
        
    );
end BRAM2AES;

architecture Behavioral of BRAM2AES is  

    -- AES_signals
    signal AES_key : std_logic_vector(255 downto 0);
    signal AES_IV : std_logic_vector(95 downto 0);

    signal state     : std_logic_vector(7 downto 0) := (others => '0');
    signal internal_aes_gcm_icb_start_cnt : std_logic;
   
    --signal signal_aes_gcm_ghash_tag_val: std_logic := '0';

    -- BRAM_signals
    signal addr : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
    
    signal Crypt_len : std_logic_vector(15 downto 0):= (others => '0');
    signal Assoc_len : std_logic_vector(15 downto 0):= (others => '0');
    signal Data_size : std_logic_vector(15 downto 0):= (others => '0');
    signal Assoc_rest_len : std_logic_vector(15 downto 0):= (others => '0');
    signal Data_rest_len : std_logic_vector(15 downto 0):= (others => '0');

    type mem_array is array (0 to 199) of std_logic_vector(127 downto 0);
    signal temp_BRAM_PORT_dinb : mem_array := (others => (others => '0'));
    
    signal addr_temp : integer range 0 to 199 := 0; 
    signal loop_temp : integer range 0 to 199 := 0; 
    
    signal temp_aes_gcm_ghash_aad : mem_array := (others => (others => '0'));
 
    signal addr_temp_AAD : integer range 0 to 199 := 0; 
    signal loop_temp_AAD : integer range 0 to 199 := 0; 
    
    signal internal_aes_gcm_ghash_aad_bval : std_logic_vector(15 downto 0);
    signal internal_aes_gcm_data_in_bval : std_logic_vector(15 downto 0);


begin

    -- Asynchronus logic
    aes_gcm_icb_start_cnt   <= internal_aes_gcm_icb_start_cnt;
    aes_gcm_ghash_aad_bval  <= internal_aes_gcm_ghash_aad_bval;
    aes_gcm_data_in_bval    <= internal_aes_gcm_data_in_bval;
     
    -- Synchronous logic
    process(clk)
    begin
        if (rising_edge(clk)) then
            if(rst = '0') then                  --go to reset handler
                state <= x"30";

            else
                case state is                       
                    when x"00" =>                   --wait for ready        
                        if(Data_ready_ext = '1') then      
                                
                            state <= x"01";
                            debug_state <= x"01";
                        end if;
    
                   when x"01" =>     --reset handler     
                        -- reset all BRAM signals
                        BRAM_PORT_enb <= '0';
                        BRAM_PORT_web <= (others => '0'); 
                        BRAM_PORT_addrb <= (others => '0');
                        BRAM_PORT_dinb <= (others => '0');
    
                        addr <= x"00000000";
                                
                        addr_temp <= 0; 
                        loop_temp <= 0; 
                            
                        -- reset all AES signals
                        aes_gcm_icb_stop_cnt <= '1';    
                        internal_aes_gcm_icb_start_cnt <= '0';
                        aes_gcm_key_word_val <= (others => '0');
                        aes_gcm_key_word <= (others => '0');
                        aes_gcm_iv_val <= '0';
                        aes_gcm_iv <= (others => '0');
                        aes_gcm_ghash_pkt_val <= '0';
                        internal_aes_gcm_ghash_aad_bval <= (others => '0');
                        aes_gcm_ghash_aad <= (others => '0');
                        aes_gcm_data_in <= (others => '0');
                        aes_gcm_enc_dec <= '0';
                        aes_gcm_mode <= "10";
                        internal_aes_gcm_data_in_bval <= (others => '0');
                                
                        state <= x"41";
                        debug_state <= x"41";
    
                    when x"41" => 
                        aes_gcm_icb_stop_cnt <= '0';
                        aes_gcm_pipe_reset <= '1';
                        state <= x"42";
                        debug_state <= x"42";
    
                    when x"42" =>
                        aes_gcm_pipe_reset <= '0';
                        
                        BRAM_PORT_enb <= '1';
                        
                        debug_state <= x"02";
                        state <= x"02";

                    when x"02" =>                   --Set BRAM_PORT_addrb: 10 addr: 20

                        BRAM_PORT_addrb <= x"00000010";
                        addr <= std_logic_vector(unsigned(addr) + 32);
                        
                        state <= x"03";
                        debug_state <= x"03";
                             
                    when x"03" =>                   --Set BRAM_PORT_addrb: 20 addr: 30
                        
                        BRAM_PORT_addrb <= addr;
                        addr <= std_logic_vector(unsigned(addr) + 16);
                                        
                        state <= x"04";
                        debug_state <= x"04";   
                                
                    when x"04" =>                   --get key 1, BRAM_PORT_addrb: 20 addr: 30    
                        
                        AES_key(127 downto 120) <= BRAM_PORT_doutb(7 downto 0);
                        AES_key(119 downto 112) <= BRAM_PORT_doutb(15 downto 8);
                        AES_key(111 downto 104) <= BRAM_PORT_doutb(23 downto 16);
                        AES_key(103 downto 96)  <= BRAM_PORT_doutb(31 downto 24);
                        AES_key(95 downto 88)   <= BRAM_PORT_doutb(39 downto 32);
                        AES_key(87 downto 80)   <= BRAM_PORT_doutb(47 downto 40);
                        AES_key(79 downto 72)   <= BRAM_PORT_doutb(55 downto 48);
                        AES_key(71 downto 64)   <= BRAM_PORT_doutb(63 downto 56);
                        AES_key(63 downto 56)   <= BRAM_PORT_doutb(71 downto 64);
                        AES_key(55 downto 48)   <= BRAM_PORT_doutb(79 downto 72);
                        AES_key(47 downto 40)   <= BRAM_PORT_doutb(87 downto 80);
                        AES_key(39 downto 32)   <= BRAM_PORT_doutb(95 downto 88);
                        AES_key(31 downto 24)   <= BRAM_PORT_doutb(103 downto 96);
                        AES_key(23 downto 16)   <= BRAM_PORT_doutb(111 downto 104);
                        AES_key(15 downto 8)    <= BRAM_PORT_doutb(119 downto 112);
                        AES_key(7 downto 0)     <= BRAM_PORT_doutb(127 downto 120);

                        BRAM_PORT_addrb <= addr;
                        addr <= std_logic_vector(unsigned(addr) + 16);
                                
                        state <= x"05";
                        debug_state <= x"05";   
                    when x"05" =>                   --get key 2, BRAM_PORT_addrb: 40 addr: 50  

                        
                        AES_key(255 downto 248) <= BRAM_PORT_doutb(7 downto 0);
                        AES_key(247 downto 240) <= BRAM_PORT_doutb(15 downto 8);
                        AES_key(239 downto 232) <= BRAM_PORT_doutb(23 downto 16);
                        AES_key(231 downto 224) <= BRAM_PORT_doutb(31 downto 24);
                        AES_key(223 downto 216) <= BRAM_PORT_doutb(39 downto 32);
                        AES_key(215 downto 208) <= BRAM_PORT_doutb(47 downto 40);
                        AES_key(207 downto 200) <= BRAM_PORT_doutb(55 downto 48);
                        AES_key(199 downto 192) <= BRAM_PORT_doutb(63 downto 56);
                        AES_key(191 downto 184) <= BRAM_PORT_doutb(71 downto 64);
                        AES_key(183 downto 176) <= BRAM_PORT_doutb(79 downto 72);
                        AES_key(175 downto 168) <= BRAM_PORT_doutb(87 downto 80);
                        AES_key(167 downto 160) <= BRAM_PORT_doutb(95 downto 88);
                        AES_key(159 downto 152) <= BRAM_PORT_doutb(103 downto 96);
                        AES_key(151 downto 144) <= BRAM_PORT_doutb(111 downto 104);
                        AES_key(143 downto 136) <= BRAM_PORT_doutb(119 downto 112);
                        AES_key(135 downto 128) <= BRAM_PORT_doutb(127 downto 120);
                    
                        BRAM_PORT_addrb <= addr;
                        

                        state <= x"06";
                        debug_state <= x"06";
                                
                    when x"06" =>                   --assign key                           
                        aes_gcm_key_word_val <= x"f";
                        aes_gcm_key_word <= AES_key;

                        AES_IV(95  downto 88)  <= BRAM_PORT_doutb(7  downto 0);
                        AES_IV(87  downto 80)  <= BRAM_PORT_doutb(15 downto 8);
                        AES_IV(79  downto 72)  <= BRAM_PORT_doutb(23 downto 16);
                        AES_IV(71  downto 64)  <= BRAM_PORT_doutb(31 downto 24);
                        AES_IV(63  downto 56)  <= BRAM_PORT_doutb(39 downto 32);
                        AES_IV(55  downto 48)  <= BRAM_PORT_doutb(47 downto 40);
                        AES_IV(47  downto 40)  <= BRAM_PORT_doutb(55 downto 48);
                        AES_IV(39  downto 32)  <= BRAM_PORT_doutb(63 downto 56);
                        AES_IV(31  downto 24)  <= BRAM_PORT_doutb(71 downto 64);
                        AES_IV(23  downto 16)  <= BRAM_PORT_doutb(79 downto 72);
                        AES_IV(15  downto 8)   <= BRAM_PORT_doutb(87 downto 80);
                        AES_IV(7   downto 0)   <= BRAM_PORT_doutb(95 downto 88);
                                                                
                        Crypt_len  <= BRAM_PORT_doutb(111 downto 96);                     
                        Assoc_len  <= BRAM_PORT_doutb(127 downto 112);
                                                    
                        state <= x"07";
                        debug_state <= x"07";
                                
                    when x"07" =>                   --assign IV                             
                        aes_gcm_key_word_val <= x"0";
                        aes_gcm_key_word  <= (others => '0');

                        aes_gcm_iv_val <= '1';
                        aes_gcm_iv <= AES_IV;

                        Data_size <= std_logic_vector(unsigned(Crypt_len) +  x"0100");         
                        Assoc_len <= std_logic_vector(unsigned(Assoc_len) +  x"0040");                      
                            
                        state <= x"08";
                        debug_state <= x"08";   

                    when x"08" =>                   --reset IV and start cnt, BRAM_PORT_addrb: 40 addr: 40 
                        aes_gcm_iv_val <= '0';
                        aes_gcm_iv <= (others => '0');

                        internal_aes_gcm_icb_start_cnt <= '1'; 

                        debug_data_size <= Data_size;   
                        debug_assoc_size <= Assoc_len;                       

                        state <= x"09";
                        debug_state <= x"09";                         
                        
                    when x"09" =>                  --reset cnt and wait for ready, BRAM_PORT_addrb: 40 addr: 40
                        internal_aes_gcm_icb_start_cnt <= '0';     
                                
                        if(aes_gcm_ready = '1') then      
                            if unsigned(Assoc_len(15 downto 0)) > unsigned(addr(15 downto 0))  then
                                Assoc_rest_len <= std_logic_vector(unsigned(Assoc_len(15 downto 0)) - unsigned(addr(15 downto 0)));  
                            end if;

                            
                            BRAM_PORT_addrb <= std_logic_vector(unsigned(addr) + 16);
                            addr <= std_logic_vector(unsigned(addr) + 32);

                            state <= x"10";
                            debug_state <= x"10";    
                        end if;   

                    when x"10" =>                   -- send AAD, BRAM_PORT_addrb: 50 addr: 60 
    
                        aes_gcm_ghash_pkt_val <= '1';
                                            
                        if unsigned(Assoc_rest_len(15 downto 0)) > x"0010" then

                            internal_aes_gcm_ghash_aad_bval <= x"FFFF";
                        
                            BRAM_PORT_addrb <= addr;
                            addr <= std_logic_vector(unsigned(addr) + 16);
                             
                            state <= x"10";
                            debug_state <= x"10";                    
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
                            debug_state <= x"11";  
                        else
                            addr <= x"00000110";
                            BRAM_PORT_addrb <= x"00000100";

                            
                            state <= x"11";
                            debug_state <= x"11";  
                        end if;
                                            
                
                        aes_gcm_ghash_aad(127 downto 120) <= BRAM_PORT_doutb(7   downto 0);
                        aes_gcm_ghash_aad(119 downto 112) <= BRAM_PORT_doutb(15  downto 8);
                        aes_gcm_ghash_aad(111 downto 104) <= BRAM_PORT_doutb(23  downto 16);
                        aes_gcm_ghash_aad(103 downto 96)  <= BRAM_PORT_doutb(31  downto 24);
                        aes_gcm_ghash_aad(95  downto 88)  <= BRAM_PORT_doutb(39  downto 32);
                        aes_gcm_ghash_aad(87  downto 80)  <= BRAM_PORT_doutb(47  downto 40);
                        aes_gcm_ghash_aad(79  downto 72)  <= BRAM_PORT_doutb(55  downto 48);
                        aes_gcm_ghash_aad(71  downto 64)  <= BRAM_PORT_doutb(63  downto 56);
                        aes_gcm_ghash_aad(63  downto 56)  <= BRAM_PORT_doutb(71  downto 64);
                        aes_gcm_ghash_aad(55  downto 48)  <= BRAM_PORT_doutb(79  downto 72);
                        aes_gcm_ghash_aad(47  downto 40)  <= BRAM_PORT_doutb(87  downto 80);
                        aes_gcm_ghash_aad(39  downto 32)  <= BRAM_PORT_doutb(95  downto 88);
                        aes_gcm_ghash_aad(31  downto 24)  <= BRAM_PORT_doutb(103 downto 96);
                        aes_gcm_ghash_aad(23  downto 16)  <= BRAM_PORT_doutb(111 downto 104);
                        aes_gcm_ghash_aad(15  downto 8)   <= BRAM_PORT_doutb(119 downto 112);                    
                        aes_gcm_ghash_aad(7   downto 0)   <= BRAM_PORT_doutb(127 downto 120);


                        if unsigned(Assoc_len(15 downto 0)) >= (unsigned(addr(15 downto 0))-16)  then
                            Assoc_rest_len <= std_logic_vector(unsigned(Assoc_len(15 downto 0)) - (unsigned(addr(15 downto 0))-16));  
                            debug_assoc_rest <= std_logic_vector(unsigned(Assoc_len(15 downto 0)) - (unsigned(addr(15 downto 0))-16));  
                        end if;     

                    when x"11" =>
                        
                        internal_aes_gcm_ghash_aad_bval  <= (others => '0');
                        
                        BRAM_PORT_addrb <= addr;        --addr= 110
                    
                        state <= x"12";
                        debug_state <= x"12";         
                    when x"12" =>                   
                        internal_aes_gcm_data_in_bval <= x"FFFF";

                        aes_gcm_data_in(127 downto 120) <= BRAM_PORT_doutb(7 downto 0);
                        aes_gcm_data_in(119 downto 112) <= BRAM_PORT_doutb(15 downto 8);
                        aes_gcm_data_in(111 downto 104) <= BRAM_PORT_doutb(23 downto 16);
                        aes_gcm_data_in(103 downto 96)  <= BRAM_PORT_doutb(31 downto 24);
                        aes_gcm_data_in(95 downto 88)   <= BRAM_PORT_doutb(39 downto 32);
                        aes_gcm_data_in(87 downto 80)   <= BRAM_PORT_doutb(47 downto 40);
                        aes_gcm_data_in(79 downto 72)   <= BRAM_PORT_doutb(55 downto 48);
                        aes_gcm_data_in(71 downto 64)   <= BRAM_PORT_doutb(63 downto 56);
                        aes_gcm_data_in(63 downto 56)   <= BRAM_PORT_doutb(71 downto 64);
                        aes_gcm_data_in(55 downto 48)   <= BRAM_PORT_doutb(79 downto 72);
                        aes_gcm_data_in(47 downto 40)   <= BRAM_PORT_doutb(87 downto 80);
                        aes_gcm_data_in(39 downto 32)   <= BRAM_PORT_doutb(95 downto 88);
                        aes_gcm_data_in(31 downto 24)   <= BRAM_PORT_doutb(103 downto 96);
                        aes_gcm_data_in(23 downto 16)   <= BRAM_PORT_doutb(111 downto 104);
                        aes_gcm_data_in(15 downto 8)    <= BRAM_PORT_doutb(119 downto 112);
                        aes_gcm_data_in(7 downto 0)     <= BRAM_PORT_doutb(127 downto 120);
                        
                                
                        if unsigned(Data_size(15 downto 0)) > (unsigned(addr(15 downto 0))) then
                            Data_rest_len <= std_logic_vector(unsigned(Data_size(15 downto 0)) - (unsigned(addr(15 downto 0))));  
                            debug_data_rest <= std_logic_vector(unsigned(Data_size(15 downto 0)) - (unsigned(addr(15 downto 0)))); 
                        end if;

                            
                        
                        BRAM_PORT_addrb <= std_logic_vector(unsigned(addr) + 16);   
                        addr <= std_logic_vector(unsigned(addr) + 32);              


                        state <= x"13";
                        debug_state <= x"13";  
                    when x"13" =>                   --send data, BRAM_PORT_addrb: 110 addr: 130     
                                                       
                        if unsigned(Data_rest_len(15 downto 0)) > x"0010" then
                            internal_aes_gcm_data_in_bval <= x"FFFF";
                            
                            BRAM_PORT_addrb <= addr;
                            addr <= std_logic_vector(unsigned(addr) + 16);
                    
                            state <= x"13";
                            debug_state <= x"13";
                            
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
                                
                            end if;
                                    
                            BRAM_PORT_addrb <= x"00000100";
                            addr <= x"00000100";

                            state <= x"14";
                            debug_state <= x"14";  
                        else
                            BRAM_PORT_addrb <= x"00000100";
                            addr <= x"00000100";
                                
                            state <= x"14";
                            debug_state <= x"14";  
                        end if;

                        aes_gcm_data_in(127 downto 120) <= BRAM_PORT_doutb(7 downto 0);
                        aes_gcm_data_in(119 downto 112) <= BRAM_PORT_doutb(15 downto 8);
                        aes_gcm_data_in(111 downto 104) <= BRAM_PORT_doutb(23 downto 16);
                        aes_gcm_data_in(103 downto 96)  <= BRAM_PORT_doutb(31 downto 24);
                        aes_gcm_data_in(95 downto 88)   <= BRAM_PORT_doutb(39 downto 32);
                        aes_gcm_data_in(87 downto 80)   <= BRAM_PORT_doutb(47 downto 40);
                        aes_gcm_data_in(79 downto 72)   <= BRAM_PORT_doutb(55 downto 48);
                        aes_gcm_data_in(71 downto 64)   <= BRAM_PORT_doutb(63 downto 56);
                        aes_gcm_data_in(63 downto 56)   <= BRAM_PORT_doutb(71 downto 64);
                        aes_gcm_data_in(55 downto 48)   <= BRAM_PORT_doutb(79 downto 72);
                        aes_gcm_data_in(47 downto 40)   <= BRAM_PORT_doutb(87 downto 80);
                        aes_gcm_data_in(39 downto 32)   <= BRAM_PORT_doutb(95 downto 88);
                        aes_gcm_data_in(31 downto 24)   <= BRAM_PORT_doutb(103 downto 96);
                        aes_gcm_data_in(23 downto 16)   <= BRAM_PORT_doutb(111 downto 104);
                        aes_gcm_data_in(15 downto 8)    <= BRAM_PORT_doutb(119 downto 112);
                        aes_gcm_data_in(7 downto 0)     <= BRAM_PORT_doutb(127 downto 120);
                        
                        if unsigned(Data_size(15 downto 0)) > (unsigned(addr(15 downto 0))-16)  then
                            Data_rest_len <= std_logic_vector(unsigned(Data_size(15 downto 0)) - (unsigned(addr(15 downto 0))-16));  
                            debug_data_rest <= std_logic_vector(unsigned(Data_size(15 downto 0)) - (unsigned(addr(15 downto 0))-16)); 
                        end if;

                        if(aes_gcm_data_out_val = '1') then      
                            temp_BRAM_PORT_dinb(addr_temp) <= aes_gcm_data_out;
                            addr_temp<=addr_temp+1;
                            debug_addr_temp <= std_logic_vector(to_unsigned(addr_temp, 8));   
                        end if;
                    when x"14" =>                   
                        internal_aes_gcm_data_in_bval <= (others => '0');
                        
                        aes_gcm_ghash_pkt_val <= '0';
                            
                        if(aes_gcm_data_out_val = '1') then
                            temp_BRAM_PORT_dinb(addr_temp) <= aes_gcm_data_out;
                            addr_temp<=addr_temp+1;
                            debug_addr_temp <= std_logic_vector(to_unsigned(addr_temp, 8));   

                            state <= x"15";
                            debug_state <= x"15"; 
                        end if;
                    when x"15" => 
                        temp_BRAM_PORT_dinb(addr_temp) <= aes_gcm_data_out;
                        addr_temp<=addr_temp+1;
                        debug_addr_temp <= std_logic_vector(to_unsigned(addr_temp, 8));   
                    
                        state <= x"16";
                        debug_state <= x"16";
                    when x"16" =>                   --store data BRAM
                            
                        debug_addr_temp <= std_logic_vector(to_unsigned(addr_temp, 8));   
                        debug_loop_temp <= std_logic_vector(to_unsigned(loop_temp, 8));   
                            
                        
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

--                            if addr_temp <= 5 then
--                                signal_aes_gcm_ghash_tag_val<= '1';
--                            end if;

                            state <= x"16";
                            debug_state <= x"16"; 
                        else

                            BRAM_PORT_addrb <= addr;

--                            if(signal_aes_gcm_ghash_tag_val = '0') then
--                                addr <= std_logic_vector(unsigned(addr) + 16);
--                            end if;

                            state <= x"17";
                            debug_state <= x"17"; 

                        end if;

                    when x"17" =>                   --store ghash 
                        BRAM_PORT_addrb <= addr;
                 
                        BRAM_PORT_dinb(127 downto 120) <= aes_gcm_ghash_tag(7 downto 0);
                        BRAM_PORT_dinb(119 downto 112) <= aes_gcm_ghash_tag(15 downto 8);
                        BRAM_PORT_dinb(111 downto 104) <= aes_gcm_ghash_tag(23 downto 16);
                        BRAM_PORT_dinb(103 downto 96)  <= aes_gcm_ghash_tag(31 downto 24);
                        BRAM_PORT_dinb(95 downto 88)   <= aes_gcm_ghash_tag(39 downto 32);
                        BRAM_PORT_dinb(87 downto 80)   <= aes_gcm_ghash_tag(47 downto 40);
                        BRAM_PORT_dinb(79 downto 72)   <= aes_gcm_ghash_tag(55 downto 48);
                        BRAM_PORT_dinb(71 downto 64)   <= aes_gcm_ghash_tag(63 downto 56);
                        BRAM_PORT_dinb(63 downto 56)   <= aes_gcm_ghash_tag(71 downto 64);
                        BRAM_PORT_dinb(55 downto 48)   <= aes_gcm_ghash_tag(79 downto 72);
                        BRAM_PORT_dinb(47 downto 40)   <= aes_gcm_ghash_tag(87 downto 80);
                        BRAM_PORT_dinb(39 downto 32)   <= aes_gcm_ghash_tag(95 downto 88);
                        BRAM_PORT_dinb(31 downto 24)   <= aes_gcm_ghash_tag(103 downto 96);
                        BRAM_PORT_dinb(23 downto 16)   <= aes_gcm_ghash_tag(111 downto 104);
                        BRAM_PORT_dinb(15 downto 8)    <= aes_gcm_ghash_tag(119 downto 112);
                        BRAM_PORT_dinb(7 downto 0)     <= aes_gcm_ghash_tag(127 downto 120);

                        --signal_aes_gcm_ghash_tag_val<= '0';

                        state <= x"18";
                        debug_state <= x"18"; 
                    when x"18" => 
                        Encryption_finish_ext <= '1';  

                        aes_gcm_icb_stop_cnt <= '1';
                        aes_gcm_pipe_reset <= '1';

                        state <= x"19";  
                        debug_state <= x"19";
                    when x"19" =>
                        addr <= x"00000000";

                        BRAM_PORT_web <= (others => '0');

                        aes_gcm_icb_stop_cnt <= '0';
        
                        BRAM_PORT_enb <= '0';
                                
                        BRAM_PORT_addrb <= (others => '0');
                        BRAM_PORT_dinb <= (others => '0');
    
                        aes_gcm_pipe_reset <= '0';
                        addr_temp <= 0; 
                        loop_temp <= 0; 

                        if(Data_ready_ext = '0') then      
                            
                            Encryption_finish_ext <= '0'; 
            
                            state <= x"00";
                            debug_state <= x"00"; 

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
                        aes_gcm_icb_stop_cnt <= '1';    
                        internal_aes_gcm_icb_start_cnt <= '0';
                        aes_gcm_key_word_val <= (others => '0');
                        aes_gcm_key_word <= (others => '0');
                        aes_gcm_iv_val <= '0';
                        aes_gcm_iv <= (others => '0');
                        aes_gcm_ghash_pkt_val <= '0';
                        internal_aes_gcm_ghash_aad_bval <= (others => '0');
                        aes_gcm_ghash_aad <= (others => '0');
                        aes_gcm_data_in <= (others => '0');
                        aes_gcm_enc_dec <= '0';
                        aes_gcm_mode <= "10";
                        internal_aes_gcm_data_in_bval <= (others => '0');
                                            
                        state <= x"31";
                        debug_state <= x"31";

                    when x"31" => 
                        aes_gcm_icb_stop_cnt <= '0';
                        aes_gcm_pipe_reset <= '1';
                    
                        state <= x"32";
                        debug_state <= x"32";

                    when x"32" =>
                        aes_gcm_pipe_reset <= '0';
                        
                            
                        debug_state <= x"00";
                        state <= x"00";
                    when others => 
                        debug_state <= x"30";
                        state <= x"30";
                
            end case;
        end if;
    end if;  
end process;

end Behavioral;




