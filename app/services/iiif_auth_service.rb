class IiifAuthService
  def self.decrypt_cookie(encrypted_cookie_value)
    cipher_salt1 = 'some-random-salt-'
    cipher_salt2 = 'another-random-salt-'
    cipher = OpenSSL::Cipher.new('AES-128-ECB').decrypt
    cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(cipher_salt1, cipher_salt2, 20_000, cipher.key_len)
    decrypted = [encrypted_cookie_value].pack('H*').unpack('C*').pack('c*')
    cipher.update(decrypted) + cipher.final
  end
end
