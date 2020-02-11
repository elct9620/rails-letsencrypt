# frozen_string_literal: true

# :nodoc:
class CreateLetsencryptCertificates < ActiveRecord::Migration[5.2]
  def change
    create_table :letsencrypt_certificates do |t|
      t.string   :domain
      t.text     :certificate, limit: 65535
      t.text     :intermediaries, limit: 65535
      t.text     :key, limit: 65535
      t.datetime :expires_at
      t.datetime :renew_after
      t.string   :verification_path
      t.string   :verification_string

      t.index    :domain
      t.index    :renew_after
      t.timestamps
    end
  end
end
