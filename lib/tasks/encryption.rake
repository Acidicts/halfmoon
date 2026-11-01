# frozen_string_literal: true

# Usage:
#   bin/rails "encryption:reencrypt_legacy"        # re-encrypt every legacy plaintext value
#   bin/rails "encryption:reencrypt_legacy[dry]"   # report only, do not write
#
# This task scans every model that declares `encrypts` attributes and, for each
# encrypted column, detects rows that still hold raw plaintext (legacy data
# written before encryption was enabled). It then re-saves those records so
# Rails encrypts the value with the current keys.
#
# It relies on `encrypts ..., support_unencrypted_data: true` being set on the
# model (see User) so legacy rows can be instantiated without raising while they
# are being re-encrypted.

namespace :encryption do
  desc "Re-encrypt legacy plaintext values in encrypted columns"
  task :reencrypt_legacy, %i[mode] => :environment do |_task, args|
    mode = args[:mode]&.to_s
    dry_run = mode == "dry" || mode == "dry-run"

    puts dry_run ? "=== DRY RUN: no changes will be written ===" : "=== Re-encrypting legacy plaintext values ==="
    puts

    encryptor = ActiveRecord::Encryption.encryptor
    scanned = 0
    fixed = 0
    failures = []

    models = [User].compact

    ActiveRecord::Base.descendants.each do |model|
      next if model == User
      next unless model.respond_to?(:encrypted_attributes) && model.encrypted_attributes.present?
      models << model
    end

    models.uniq.each do |model|
      table = model.table_name
      model.encrypted_attributes.each do |attr|
        rows = model.connection.select_all("SELECT id, #{attr} FROM #{table} WHERE #{attr} IS NOT NULL")

        rows.each do |row|
          scanned += 1
          id = row["id"]
          raw = row[attr.to_s]

          next if raw.nil?

          encrypted = begin
                        encryptor.encrypted?(raw)
                      rescue StandardError
                        false
                      end

          next if encrypted

          if dry_run
            puts "  [dry] would re-encrypt #{model} id=#{id} #{attr}=#{raw.inspect[0, 80]}"
            next
          end

          begin
            ciphertext = model.type_for_attribute(attr).serialize(raw)
            quoted = model.connection.quote(ciphertext)
            model.connection.update(
              "UPDATE #{model.table_name} SET #{attr} = #{quoted} WHERE id = #{id}"
            )
            fixed += 1
            puts "  re-encrypted #{model} id=#{id} #{attr}"
          rescue StandardError => e
            failures << "#{model} id=#{id} #{attr}: #{e.class}: #{e.message}"
            puts "  ERROR  #{model} id=#{id} #{attr}: #{e.class}: #{e.message}"
          end
        end
      end
    end

    puts
    puts "=== Done: scanned #{scanned} encrypted values, re-encrypted #{fixed} ==="
    puts "No legacy plaintext values remain." if fixed.zero? && !failures.any?
    if failures.any?
      puts "WARNING: #{failures.count} record(s) could not be re-encrypted (see above)."
      exit 1
    end
  end
end
