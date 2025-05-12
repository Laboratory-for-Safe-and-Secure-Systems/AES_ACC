from Crypto.Cipher import AES
import binascii

def swap_endianness_128bit(data):
    """ Swap endianness every 16 bytes (128 bits) in the given byte array """
    swapped = bytearray()
    for i in range(0, len(data), 16):
        block = data[i:i+16]
        swapped.extend(block[::-1])  # Reverse each 16-byte block
    return bytes(swapped)

def swap_endianness(hex_str):
    """Swap endianness by reversing byte order."""
    return hex_str[::-1]

# # AES-256 Key (32 bytes)
# key = b'\x11' * 32  # Equivalent to 32 bytes of 0x11

# Authentication Tag (ICV) - 16 bytes
tag = binascii.unhexlify(
    "50bbacffbeea83bf79d9b364a8d957e9"
)[:16]



ciphertext = binascii.unhexlify(
    "641b7205032a7c234ad05af5b128ee9c"
    "bd55d6a0ec4cadacca8b347423f23690"
    "5ffaff052250f202c330badf0096b3c0"
    "150280c7e7a03c4e46bf9190dd3336cf"
    "fd3b1eea7ca2ffc86e2fcdf130d9e413"
    "99733f1d0a34"
)

# Additional Authenticated Data (AAD)
aad = binascii.unhexlify(
    "5ad1ba8333d3e880881ff10c88e52c00"
    "00000090e880881ff10c0001"
)


iv = binascii.unhexlify("ffff00080e2cf000")
  

key = binascii.unhexlify(
    "1111111111111111111111111111111111111111111111111111111111111111"
)



# swaped_ciphertext = swap_endianness_128bit(ciphertext)
# Swap IV endianness
swaped_iv = swap_endianness(iv)

try:
    # Create AES-GCM cipher object
    cipher = AES.new(key, AES.MODE_GCM, nonce=swaped_iv)
    cipher.update(aad)  # Apply AAD

    # Try decryption and verify authentication tag
    plaintext = cipher.decrypt_and_verify(ciphertext, tag)
    print("Decrypted plaintext:", binascii.hexlify(plaintext).decode())

except ValueError:
    print("Warning: Authentication failed! Proceeding with decryption anyway.")

    # Create a new AES-GCM cipher instance
    cipher_no_auth = AES.new(key, AES.MODE_GCM, nonce=iv)
    cipher_no_auth.update(aad)  # Re-apply AAD

    # Decrypt ciphertext without verifying tag
    plaintext = cipher_no_auth.decrypt(ciphertext)
    print("Decrypted (unchecked):", binascii.hexlify(plaintext).decode())
