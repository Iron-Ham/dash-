# GitHub User model
# This represents a GitHub user account with common attributes and functionality

class User < ApplicationRecord
  # Associations
  has_many :repositories, dependent: :destroy
  has_many :owned_repositories, -> { where(owner_type: 'User') }, 
           class_name: 'Repository', foreign_key: 'owner_id'
  has_many :organizations_users, dependent: :destroy
  has_many :organizations, through: :organizations_users
  has_many :issues, dependent: :destroy
  has_many :pull_requests, dependent: :destroy
  has_many :stars, dependent: :destroy
  has_many :starred_repositories, through: :stars, source: :repository
  has_many :followers_relationships, class_name: 'Follow', foreign_key: 'followed_id'
  has_many :followers, through: :followers_relationships, source: :follower
  has_many :following_relationships, class_name: 'Follow', foreign_key: 'follower_id'
  has_many :following, through: :following_relationships, source: :followed
  has_many :gists, dependent: :destroy
  has_many :commit_comments, dependent: :destroy
  has_many :issue_comments, dependent: :destroy
  has_many :pull_request_reviews, dependent: :destroy

  # Validations
  validates :login, presence: true, uniqueness: { case_sensitive: false }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, 
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, length: { maximum: 100 }
  validates :bio, length: { maximum: 160 }
  validates :location, length: { maximum: 100 }
  validates :blog, length: { maximum: 200 }
  validates :twitter_username, length: { maximum: 50 }

  # Scopes
  scope :verified, -> { where(verified: true) }
  scope :hireable, -> { where(hireable: true) }
  scope :with_email, -> { where.not(email: nil) }
  scope :public_profiles, -> { where(private_profile: false) }

  # Callbacks
  before_save :downcase_login
  before_create :generate_node_id
  after_create :create_default_settings

  # Attributes
  # Standard GitHub user fields that would be in the database:
  # - id (primary key)
  # - login (username)
  # - email
  # - name
  # - bio
  # - location
  # - blog (website URL)
  # - twitter_username
  # - avatar_url
  # - gravatar_id
  # - node_id (GraphQL ID)
  # - html_url (profile URL)
  # - type (User vs Organization)
  # - site_admin (boolean)
  # - hireable (boolean)
  # - verified (boolean)
  # - private_profile (boolean)
  # - public_repos (counter cache)
  # - public_gists (counter cache)
  # - followers_count (counter cache)
  # - following_count (counter cache)
  # - created_at
  # - updated_at

  def to_param
    login
  end

  def display_name
    name.presence || login
  end

  def avatar_url(size: 80)
    if self[:avatar_url].present?
      "#{self[:avatar_url]}&s=#{size}"
    else
      "https://github.com/identicons/#{login}.png&s=#{size}"
    end
  end

  def profile_url
    "https://github.com/#{login}"
  end

  def api_url
    "https://api.github.com/users/#{login}"
  end

  def admin?
    site_admin?
  end

  def can_create_repository?
    !suspended? && verified?
  end

  def following?(other_user)
    following_relationships.exists?(followed: other_user)
  end

  def follow!(other_user)
    following_relationships.create!(followed: other_user) unless following?(other_user)
  end

  def unfollow!(other_user)
    following_relationships.where(followed: other_user).destroy_all
  end

  def starred?(repository)
    stars.exists?(repository: repository)
  end

  def star!(repository)
    stars.create!(repository: repository) unless starred?(repository)
  end

  def unstar!(repository)
    stars.where(repository: repository).destroy_all
  end

  def member_of?(organization)
    organizations.exists?(id: organization.id)
  end

  def can_access_repository?(repository)
    return true if repository.public?
    return true if repository.owner == self
    return true if member_of?(repository.owner) && repository.owner.is_a?(Organization)
    
    # Check for collaborator access
    repository.collaborators.exists?(id: self.id)
  end

  def contribution_calendar_data(year = Date.current.year)
    # This would typically query contribution data
    # Simplified version for demonstration
    start_date = Date.new(year, 1, 1)
    end_date = Date.new(year, 12, 31)
    
    repositories.joins(:commits)
              .where(commits: { author_email: email, created_at: start_date..end_date })
              .group('DATE(commits.created_at)')
              .count
  end

  def suspended?
    # This would check if the user account is suspended
    false # Simplified for demonstration
  end

  def organization?
    type == 'Organization'
  end

  def user?
    type == 'User'
  end

  private

  def downcase_login
    self.login = login.downcase if login.present?
  end

  def generate_node_id
    # Generate a base64 encoded node ID for GraphQL API
    self.node_id = Base64.strict_encode64("04:User#{id}")
  end

  def create_default_settings
    # Create default user settings
    # This would typically create associated settings records
  end
end