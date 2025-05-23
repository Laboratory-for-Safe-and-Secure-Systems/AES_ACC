--------------------------------------------------------------------------------
--! @File name:     top_aes_gcm
--! @Date:          01/10/2019
--! @Description:   this module is the top entity
--! @Reference:     NIST Special Publication 800-38D, November, 2007
--! @Source:        https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-38d.pdf
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.gcm_pkg.all;
use work.aes_pkg.all;

-- This IP has been configured with:
--   AES Mode:    256
--   # rounds:    14
--   pipe stages: 7
--   gfmul IP:    1

--------------------------------------------------------------------------------
entity top_aes_gcm is
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
        aes_gcm_icb_cnt_overflow_o      : out std_logic);
end entity;

--------------------------------------------------------------------------------
architecture arch_top_aes_gcm of top_aes_gcm is

    component aes_gcm is
        generic(
            aes_gcm_mode_g                  : std_logic_vector(1 downto 0)  := AES_MODE_128_C;
            aes_gcm_n_rounds_g              : natural range 0 to NR_256_C   := NR_128_C;
            aes_gcm_split_gfmul             : natural range 0 to 1          := 0);
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
            aes_gcm_icb_cnt_overflow_o      : out std_logic);
    end component;

begin

    u_aes_gcm: aes_gcm
        generic map(
            aes_gcm_mode_g                  => AES_MODE_256_C,
            aes_gcm_n_rounds_g              => 14,
            aes_gcm_split_gfmul             => 0)
        port map(
            rst_i                           => rst_i,
            clk_i                           => clk_i,
            aes_gcm_mode_i                  => aes_gcm_mode_i,
            aes_gcm_enc_dec_i               => aes_gcm_enc_dec_i,
            aes_gcm_pipe_reset_i            => aes_gcm_pipe_reset_i,
            aes_gcm_key_word_val_i          => aes_gcm_key_word_val_i,
            aes_gcm_key_word_i              => aes_gcm_key_word_i,
            aes_gcm_iv_val_i                => aes_gcm_iv_val_i,
            aes_gcm_iv_i                    => aes_gcm_iv_i,
            aes_gcm_icb_start_cnt_i         => aes_gcm_icb_start_cnt_i,
            aes_gcm_icb_stop_cnt_i          => aes_gcm_icb_stop_cnt_i,
            aes_gcm_ghash_pkt_val_i         => aes_gcm_ghash_pkt_val_i,
            aes_gcm_ghash_aad_bval_i        => aes_gcm_ghash_aad_bval_i,
            aes_gcm_ghash_aad_i             => aes_gcm_ghash_aad_i,
            aes_gcm_data_in_bval_i          => aes_gcm_data_in_bval_i,
            aes_gcm_data_in_i               => aes_gcm_data_in_i,
            aes_gcm_ready_o                 => aes_gcm_ready_o,
            aes_gcm_data_out_val_o          => aes_gcm_data_out_val_o,
            aes_gcm_data_out_bval_o         => aes_gcm_data_out_bval_o,
            aes_gcm_data_out_o              => aes_gcm_data_out_o,
            aes_gcm_ghash_tag_val_o         => aes_gcm_ghash_tag_val_o,
            aes_gcm_ghash_tag_o             => aes_gcm_ghash_tag_o,
            aes_gcm_icb_cnt_overflow_o      => aes_gcm_icb_cnt_overflow_o);

end architecture;
