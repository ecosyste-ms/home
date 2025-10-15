class ApiKey < ApplicationRecord
  belongs_to :account

  validates :name, presence: true
  validates :key_hash, presence: true, uniqueness: true
  validates :key_prefix, presence: true

  scope :active, -> { where(revoked_at: nil).where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }

  before_create :generate_key

  attr_accessor :raw_key

  def active?
    revoked_at.nil? && (expires_at.nil? || expires_at > Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def revoke!
    update(revoked_at: Time.current)
  end

  def touch_last_used!
    update(last_used_at: Time.current)
  end

  def self.authenticate(key)
    return nil unless key.present?

    prefix = key[0, 8]
    api_key = active.find_by(key_prefix: prefix)
    return nil unless api_key

    return api_key if BCrypt::Password.new(api_key.key_hash) == key
    nil
  end

  private

  def generate_key
    # Generate a random API key (32 characters)
    self.raw_key = SecureRandom.alphanumeric(32)
    self.key_prefix = raw_key[0, 8]
    self.key_hash = BCrypt::Password.create(raw_key)
  end
end
