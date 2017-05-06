class CreateLetsEncryptCertificates < ActiveRecord::Migration[5.1]
  def change
    create_table :lets_encrypt_certificates do |t|
      t.string :domain
      t.text :certificate, limit: 65535
      t.text :intermediaries, limit: 65535
      t.text :key, limit: 65535
      t.datetime :expires_at
      t.datetime :renew_after
      t.string :verification_path
      t.string :verification_string

      t.index :domain
      t.timestamps
    end
  end
end
