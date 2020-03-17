class IiifAuthService

  def self.decrypt_cookie(encrypted_cookie_value)
    cipher_salt1 = 'some-random-salt-'
    cipher_salt2 = 'another-random-salt-'
    cipher = OpenSSL::Cipher.new('AES-128-ECB').decrypt
    cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(cipher_salt1, cipher_salt2, 20_000, cipher.key_len)
    decrypted = [encrypted_cookie_value].pack('H*').unpack('C*').pack('c*')
    cipher.update(decrypted) + cipher.final
    rescue OpenSSL::Cipher::CipherError
      error_message = 'Either Lux and Curate are out of sync, or someone is trying to spoof the cookies'
      Rails.logger.error error_message
      false
    rescue => e
      Rails.logger.error e
      false
  end
end
