# frozen_string_literal: true
require 'digest'

#   `cantaloupe.properties` settings that have changed:
#     - nil -> `delegate_script.enabled = true`
#     - nil -> `delegate_script.pathname = emory_custom_delegates.rb`
#     - `S3Source.lookup_strategy = BasicLookupStrategy` -> `S3Source.lookup_strategy = ScriptLookupStrategy`
#     - `S3Source.BasicLookupStrategy.bucket.name = dlp-fedora-test-binaries` -> nil # The BasicLookupStrategy
#         only works with Fedora 4. Fedora 7 delegations will always require scripting.
#     - `S3Source.BasicLookupStrategy.path_prefix =` -> `#S3Source.BasicLookupStrategy.path_prefix =`
#     - `S3Source.BasicLookupStrategy.path_suffix =` -> `#S3Source.BasicLookupStrategy.path_suffix =`
#     - All `S3Source.access_key_id = *` -> Reduced to one `S3Source.access_key_id =`
#     - All `S3Source.secret_key = *` -> Reduced to one `S3Source.secret_key =`

# rubocop:disable Rails
class CustomDelegate
  attr_accessor :context

  COMMON_ENDPOINT  = 'https://s3.us-******.amazonaws.com'

  F4_BUCKET        = 'fedora-cor-*-binaries'
  F4_ACCESS_KEY_ID = '**secret1**'
  F4_SECRET_KEY    = '**secret**'

  F7_BUCKET        = 'dlp-fedora-*-binaries'
  F7_ACCESS_KEY_ID = '**secret2**'
  F7_SECRET_KEY    = '**secret3**'

  SHA1_REGEX       = /\A[a-f0-9]{40}\z/i
  UUID_REGEX       = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
  ALLOWED_VARIANTS = %w[original intermediate service].freeze

  def s3source_object_info(_options = {})
    identifier = context['identifier']
    return nil if identifier.nil? || identifier.empty?

    if identifier.start_with?('fedora7--')
      process_fedora7_hash(identifier)
    elsif SHA1_REGEX.match?(identifier)
      process_fedora4_hash(identifier)
    end
  end

  # ---------------------------------------------------------------------------
  # Meta-Identifier Serialization (Optional - return nil to use defaults)
  # ---------------------------------------------------------------------------

  def deserialize_meta_identifier(_meta_identifier)
    nil
  end

  def serialize_meta_identifier(_components)
    nil
  end

  # ---------------------------------------------------------------------------
  # Authorization Hooks (Must return true to allow requests)
  # ---------------------------------------------------------------------------

  def pre_authorize(_options = {})
    true
  end

  def authorize(_options = {})
    true
  end

  # ---------------------------------------------------------------------------
  # IIIF info.json Extension Hooks (Must return a Hash)
  # ---------------------------------------------------------------------------

  def extra_iiif2_information_response_keys(_options = {})
    {}
  end

  def extra_iiif3_information_response_keys(_options = {})
    {}
  end

  # ---------------------------------------------------------------------------
  # Source Selection & Lookup Methods
  # ---------------------------------------------------------------------------

  def source(_options = {})
    nil
  end

  def azurestoragesource_blob_key(_options = {})
    nil
  end

  def filesystemsource_pathname(_options = {})
    nil
  end

  def httpsource_resource_info(_options = {})
    nil
  end

  def jdbcsource_database_identifier(_options = {})
    nil
  end

  def jdbcsource_media_type(_options = {})
    nil
  end

  def jdbcsource_lookup_sql(_options = {})
    nil
  end

  # ---------------------------------------------------------------------------
  # Image Transformation & Metadata Hooks
  # ---------------------------------------------------------------------------

  def overlay(_options = {})
    nil
  end

  def redactions(_options = {})
    []
  end

  def metadata(_options = {})
    nil
  end

  private

    # --- Route 1: Fedora 7 OCFL (fedora7--<variant>--<uuid>) ---
    def process_fedora7_hash(identifier)
      parts = identifier.split('--')
      return nil unless parts.length == 3

      _, variant, uuid = parts
      return nil unless ALLOWED_VARIANTS.include?(variant) && uuid.match?(UUID_REGEX)

      fedora_id = "info:fedora/production/#{uuid}/#{variant}"
      digest    = Digest::SHA256.hexdigest(fedora_id)

      {
        'bucket' => F7_BUCKET,
        'key' => "#{digest[0..2]}/#{digest[3..5]}/#{digest[6..8]}/#{digest}/v1/content/#{variant}",
        'endpoint' => COMMON_ENDPOINT,
        'access_key_id' => F7_ACCESS_KEY_ID,
        'secret_access_key' => F7_SECRET_KEY
      }
    end

    # --- Route 2: Legacy Fedora 4 CAS (40-character SHA-1) ---
    def process_fedora4_hash(identifier)
      {
        'bucket' => F4_BUCKET,
        'key' => identifier,
        'endpoint' => COMMON_ENDPOINT,
        'access_key_id' => F4_ACCESS_KEY_ID,
        'secret_access_key' => F4_SECRET_KEY
      }
    end
end
# rubocop:enable Rails
