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
        
        --AES debug ports
        debug_state :               out STD_LOGIC_VECTOR (3 downto 0);
        debug_state_init :          out STD_LOGIC_VECTOR (3 downto 0);
        debug_state_send :          out STD_LOGIC_VECTOR (3 downto 0);
        debug_state_reset :         out STD_LOGIC_VECTOR (3 downto 0);
        
        -- BRAM ports
        BRAM_PORT_addrb :           out STD_LOGIC_VECTOR (31 downto 0);
        BRAM_PORT_enb :             out STD_LOGIC := '0';
        BRAM_PORT_web :             out STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
        BRAM_PORT_dinb :            out STD_LOGIC_VECTOR (127 downto 0);
        BRAM_PORT_doutb :           in STD_LOGIC_VECTOR (127 downto 0);
        

        debug_data_size :           out STD_LOGIC_VECTOR (31 downto 0);

        Data_ready_ext :            in STD_LOGIC_VECTOR (3 downto 0);
        Encryption_finish_ext :     out STD_LOGIC

    );
end BRAM2AES;

architecture Behavioral of BRAM2AES is  

    -- AES_signals
    signal test_key : std_logic_vector(255 downto 0) :=  x"123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0";
    signal test_IV : std_logic_vector(95 downto 0) := x"1234567890ABCDEF12345678";
    signal test_aad : std_logic_vector(127 downto 0) := x"00112233445566778899AABBCCDDEEFF";
    signal test_aad_bval : std_logic_vector(15 downto 0) := x"FFFF";
    signal test_bval_rd_data : std_logic_vector(15 downto 0) := x"0080";

    signal state     : std_logic_vector(3 downto 0) := (others => '0');
    signal state_init : std_logic_vector(3 downto 0) := (others => '0');
    signal state_send : std_logic_vector(3 downto 0) := (others => '0');
    signal state_reset : std_logic_vector(3 downto 0) := (others => '0');

    signal internal_aes_gcm_icb_start_cnt : std_logic;

    -- BRAM_signals
    signal addr : STD_LOGIC_VECTOR (31 downto 0):= (others => '0');
    
    signal Data_size : std_logic_vector(31 downto 0):= (others => '0');

    signal prev_data_ready_ext : STD_LOGIC_VECTOR (3 downto 0);

begin

    -- Asynchronus logic
    aes_gcm_icb_start_cnt <= internal_aes_gcm_icb_start_cnt;

    -- Synchronous logic
    process(clk)
    begin
        if (rising_edge(clk)) then
            if(rst = '0') then                --go to reset handler
                state <= x"2";
        else
            case state is                       
                when x"0" =>                    --init handler
                    debug_state <= state;
                    case state_init is
                        when x"0" => -- set key word
                            aes_gcm_key_word_val <= x"f";
                            aes_gcm_key_word <= test_key;
                            state_init <= x"1";
                            debug_state_init <= x"1";
                        when x"1" => -- set IV
                            aes_gcm_key_word_val <= x"0";
                            aes_gcm_key_word  <= (others => '0');
                            aes_gcm_iv_val <= '1';
                            aes_gcm_iv <= test_IV;
                            state_init <= x"2";
                            debug_state_init <= x"2";
                        when x"2" => -- start counter
                            aes_gcm_iv_val <= '0';
                            aes_gcm_iv <= (others => '0');
                            internal_aes_gcm_icb_start_cnt <= '1';
                            state_init <= x"3";
                            debug_state_init <= x"3";
                        when x"3" => -- reset start of counter and wait for ready
                            if(internal_aes_gcm_icb_start_cnt = '1') then
                                internal_aes_gcm_icb_start_cnt <= '0';
                            end if;
                                
                            if(aes_gcm_ready = '1') then                        
                                state_init <= x"4";
                                debug_state_init <= x"4";
                            end if;   
                        when x"4" => -- send AAD
                            aes_gcm_ghash_pkt_val <= '1';
                            aes_gcm_ghash_aad <= test_aad;
                            aes_gcm_ghash_aad_bval <= test_aad_bval;
                            state_init <= x"5";
                            debug_state_init <= x"5";
                        when x"5" => -- reset AAD bval and activte BRAM
                            aes_gcm_ghash_aad_bval <= x"0000";

                            BRAM_PORT_enb <= '1';
                            BRAM_PORT_web <= (others => '0');

                            state_init <= x"0";
                            state <= x"1";
                            debug_state_init <= x"0";
                        when others => 
                            state_init <= x"0";
                            debug_state_init <= x"0";
                            state <= x"2";
                    end case;

                when x"1" =>                    --send handler
                    debug_state <= state;
                    case state_send is
                        when x"0" =>  
                            if(prev_data_ready_ext = "1111" and Data_ready_ext = "0000") then
                                aes_gcm_ghash_pkt_val <= '1';
                                internal_aes_gcm_icb_start_cnt <= '1';
                                Encryption_finish_ext <= '0';    

                                Data_size <= BRAM_PORT_doutb(127 downto 96);
                                debug_data_size <= BRAM_PORT_doutb(127 downto 96);

                                BRAM_PORT_addrb <= addr; 

                                state_send <= x"1";
                                debug_state_send <= x"1";
                            end if;
                            prev_data_ready_ext <= Data_ready_ext;
                        when x"1" => 
                            addr <= std_logic_vector(unsigned(addr) + 16);
                            state_send <= x"2";
                            debug_state_send <= x"2";   
                        when x"2" => -- send plain text
                            internal_aes_gcm_icb_start_cnt <= '0';
                            if(aes_gcm_ready = '1') then  
                                aes_gcm_data_in <= BRAM_PORT_doutb;
                                aes_gcm_data_in_bval <= test_bval_rd_data;
                                
                                BRAM_PORT_web <= (others => '1');
                                if Data_size(31 downto 0) = std_logic_vector(unsigned(addr) + 16) then
                                    aes_gcm_ghash_pkt_val <= '0';
                                end if;
                                

                                state_send <= x"3";
                                debug_state_send <= x"3";
                            end if;
                        when x"3" => -- receive cypher text
                            if(aes_gcm_data_out_val = '1') then
                                BRAM_PORT_dinb <= aes_gcm_data_out;

                                state_send <= x"4";
                                debug_state_send <= x"4";
                            else
                                --BRAM_PORT_dinb <= (others => '0');
                            end if;    
                        when x"4" => 
                            BRAM_PORT_web <= (others => '0');  

                            state_send <= x"5";
                            debug_state_send <= x"5";                   
                        when x"5" => 
                            if Data_size(31 downto 0) = (std_logic_vector(unsigned(addr) + 16)) then
                                state_send <= x"6";  
                                debug_state_send <= x"6";
                                BRAM_PORT_addrb <= std_logic_vector(unsigned(addr) + 16);
                            else  
                                BRAM_PORT_addrb <= addr; 
                                state_send <= x"1";      
                                debug_state_send <= x"1";             
                            end if;           
                        when x"6" =>   
                            if(aes_gcm_ghash_tag_val = '1') then
                                BRAM_PORT_dinb <= aes_gcm_ghash_tag;
                                BRAM_PORT_web <= (others => '1');
                                aes_gcm_data_in_bval <= (others => '0');
                                        
                                aes_gcm_icb_stop_cnt <= '1';
        
                                state_send <= x"7";      
                                debug_state_send <= x"7";  
                             end if; 
                        when x"7" => 
                            Encryption_finish_ext <= '1';  
                            BRAM_PORT_web <= (others => '0');                  
                            aes_gcm_icb_stop_cnt <= '0';
                            aes_gcm_pipe_reset <= '1';
                            state_send <= x"8";  
                            debug_state_send <= x"8";
                        when x"8" =>
                            addr <= x"00000010";

                            BRAM_PORT_enb <= '0';
                            
                            BRAM_PORT_addrb <= (others => '0');
                            BRAM_PORT_dinb <= (others => '0');

                            
                            prev_data_ready_ext <= (others => '0');
                            aes_gcm_pipe_reset <= '0';
                            state_send <= x"0";
                            debug_state_send <= x"0";
                            state <= x"0";
                            
                        when others => 
                            state_send <= x"0";
                            debug_state_send <= x"0";
                            state <= x"2";
                    end case;

                when x"2" =>                    --reset handler
                    debug_state <= state;
                    case state_reset is         
                        when x"0" =>        
                            -- reset all BRAM signals
                            BRAM_PORT_enb <= '0';
                            BRAM_PORT_web <= (others => '0'); 
                            BRAM_PORT_addrb <= (others => '0');
                            BRAM_PORT_dinb <= (others => '0');

                            addr <= x"00000010";
                            
                            prev_data_ready_ext <= (others => '0'); 

                        
                            -- reset all AES signals
                            state_init <= x"0";
                            debug_state_init <= x"0";
                            state_send <= x"0";
                            debug_state_send <= x"0";

                            aes_gcm_icb_stop_cnt <= '1';    
                            internal_aes_gcm_icb_start_cnt <= '0';
                            aes_gcm_key_word_val <= (others => '0');
                            aes_gcm_key_word <= (others => '0');
                            aes_gcm_iv_val <= '0';
                            aes_gcm_iv <= (others => '0');
                            aes_gcm_ghash_pkt_val <= '0';
                            aes_gcm_ghash_aad_bval <= (others => '0');
                            aes_gcm_ghash_aad <= (others => '0');
                            aes_gcm_data_in <= (others => '0');
                            aes_gcm_enc_dec <= '0';
                            aes_gcm_mode <= "11";
                            aes_gcm_data_in_bval <= (others => '0');
                            
                            state_reset <= x"1";
                            debug_state_reset <= x"1";
                        when x"1" => 
                            aes_gcm_icb_stop_cnt <= '0';
                            aes_gcm_pipe_reset <= '1';
                            state_reset <= x"2";
                            debug_state_reset <= x"2";
                        when x"2" =>
                            aes_gcm_pipe_reset <= '0';
                            state_reset <= x"0";
                            debug_state_reset <= x"0";
                            state <= x"0";
                        when others => 
                            state_reset <= x"0";
                            debug_state_reset <= x"0";
                            state <= x"2";
                    end case;

                when others => 
                    state <= x"2";
            end case;
        end if;
    end if;  
end process;

end Behavioral;

