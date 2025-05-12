from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes
import binascii

def swap_endianness_128bit(data):
    """ Swap endianness every 16 bytes (128 bits) in the given byte array """
    swapped = bytearray()
    for i in range(0, len(data), 16):
        block = data[i:i+16]
        swapped.extend(block[::-1])  # Reverse each 16-byte block
    return bytes(swapped)


# 12-byte IV (Nonce) - In MACsec, this is usually derived from the SecTAG
def swap_endianness(hex_str):
    """Swap endianness by reversing byte order."""
    return hex_str[::-1]


# AES-256 Key (32 bytes)
#key = b'\x11' * 32  # Equivalent to 1111111111111111111111111111111111111111111111111111111111111111

#key = "1111111111111111111111111111111111111111111111111111111111111111"    

# key = binascii.unhexlify(
#     "11111111111111111111111111111111"
#     "11111111111111111111111111111111"
# )


key = binascii.unhexlify(
    "1111111111111111111111111111111111111111111111111111111111111111"
)



# Given IV and Plaintext
#iv = binascii.unhexlify("9686508b48a800010000006d")
iv = binascii.unhexlify("111111111111111111111111")
  
#3333000000169686508b48a888e52c00   ffff
#0000006d9686508b48a8000188e52c00   fff0
    
AAD = binascii.unhexlify(
     "11111111111111111111111111111111"
     #"11111111111111111111111111111111"
    #"3333000000169686508b48a888e52c00"
    #"0000006d9686508b48a80001"
)

#86dd6000000000240001000000000000   ffff
#00000000000000000000ff0200000000   ffff
#000000000000000000163a0005020000   ffff
#01008f0026570000000104000000ff02   ffff
#00000000000000000001ff8b48a8ff02   fffc


plaintext_86 = binascii.unhexlify(
     "11111111111111111111111111111111"
     "11111111111111111111111111111111"
     "11111111111111111111111111111111"
)

# plaintext_86 = binascii.unhexlify(
#     "86dd6000000000240001000000000000"
#     "00000000000000000000ff0200000000"
#     "000000000000000000163a0005020000"
#     "01008f0026570000000104000000ff02"
#     "00000000000000000001ff8b48a80000"
# )


AAD_Swap=swap_endianness(AAD)

key_swap=swap_endianness(key)

# Encrypt 86-byte plaintext
cipher_86 = AES.new(key, AES.MODE_GCM, nonce=iv)
cipher_86.update(AAD)
ciphertext_86, tag_86 = cipher_86.encrypt_and_digest(plaintext_86)

# Print full ciphertext and ICV for the 86-byte encryption
print("\n🔹 Full Ciphertext (86-byte message):")
print(binascii.hexlify(ciphertext_86).decode())

# Print Authentication Tag (ICV) for the 86-byte encryption
print("\n🔹 Authentication Tag (ICV) (86-byte message):")
print(binascii.hexlify(tag_86).decode())






# [  446.371800] Value 0x0100a8488b508696 written to address 0xa0000030
# [  446.377884] Value 0x001c004e6d000000 written to address 0xa0000038

# [  446.383883] Value 0x8696160000003333 written to address 0xa0000040
# [  446.390055] Value 0x002ce588a8488b50 written to address 0xa0000048
# [  446.396057] Value 0x8b5086966d000000 written to address 0xa0000050
# [  446.402234] Value 0x000000000100a848 written to address 0xa0000058

# [  446.407625] Value 0x240000000060dd86 written to address 0xa0000100
# [  446.413797] Value 0x0000000000000100 written to address 0xa0000108
# [  446.418840] Value 0x0000000000000000 written to address 0xa0000110
# [  446.423710] Value 0x0000000002ff0000 written to address 0xa0000118
# [  446.429102] Value 0x0000000000000000 written to address 0xa0000120
# [  446.433971] Value 0x00000205003a1600 written to address 0xa0000128
# [  446.439709] Value 0x00005726008f0001 written to address 0xa0000130
# [  446.445534] Value 0x02ff000000040100 written to address 0xa0000138
# [  446.451619] Value 0x0000000000000000 written to address 0xa0000140
# [  446.456489] Value 0x0000a8488bff0100 written to address 0xa0000148


# [  446.474407] Value 0x36f02364b65064d9 read to address 0xa0000100
# [  446.480318] Value 0x8c216ea9b5c89fc4 read to address 0xa0000108
# [  446.480322] Value 0x19b5365dfb219cad read to address 0xa0000110
# [  446.490142] Value 0x0352f931385a22bb read to address 0xa0000118
# [  446.490146] Value 0xd1a6926cbb1406a7 read to address 0xa0000120
# [  446.490150] Value 0xb06b488e78755bf6 read to address 0xa0000128
# [  446.517157] Value 0x330acaf903712224 read to address 0xa0000130
# [  446.523076] Value 0x9e730fedfa210ccd read to address 0xa0000138
# [  446.528993] Value 0x78b69b5e23c54f33 read to address 0xa0000140
# [  446.534905] Value 0xbce5c47eee3ba470 read to address 0xa0000148

# [  446.540816] Value 0xea3252101a7bdf0d read to address 0xa0000150
# [  446.546727] Value 0x3e71bc7932680b15 read to address 0xa0000158


# 0000   33 33 00 00 00 16 96 86 50 8b 48 a8 88 e5 2c 00
# 0010   00 00 00 6d 96 86 50 8b 48 a8 00 01 

#                                            8c 21 6e a9
# 0020   b5 c8 9f c4 36 f0 23 64 b6 50 64 d9 03 52 f9 31
# 0030   38 5a 22 bb 19 b5 36 5d fb 21 9c ad b0 6b 48 8e
# 0040   78 75 5b f6 d1 a6 92 6c bb 14 06 a7 9e 73 0f ed
# 0050   fa 21 0c cd 33 0a ca f9 03 71 22 24 bc e5 c4 7e
# 0060   ee 3b a4 70 78 b6 9b 5e 23 c5 

#                                      82 73 d9 52 84 f9
# 0070   64 60 05 2e 72 76 94 37 00 27

