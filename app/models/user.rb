# == Schema Information
# Schema version: 20110323160849
#
# Table name: users
#
#  id                 :integer         not null, primary key
#  name               :string(255)
#  email              :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  encrypted_password :string(255)
#  salt               :string(255)
#  admin              :boolean
#

# == Schema Information
# Schema version: 20110305112815
#
# Table name: users
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime
#  updated_at :datetime
#
require 'digest'

class User < ActiveRecord::Base
  
   attr_accessor :password
   attr_accessible :name, :email, :password, :password_confirmation

   has_many :microposts, :dependent => :destroy
   has_many :relationships, :foreign_key => "follower_id",
                           :dependent => :destroy
   has_many :following, :through => :relationships, :source => :followed
   has_many :reverse_relationships, :foreign_key => "followed_id", 
                                    :class_name => "Relationship",
                                    :dependent => :destroy
   has_many :followers, :through => :reverse_relationships, :source => :follower
   has_many :replies, foreign_key: "to_id",
                      class_name: "Micropost"
   validates :name, :presence => true , :length => { :maximum => 50 } 
  
   email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
   validates :email, :presence => true, :format => { :with => email_regex },
                    :uniqueness => { :case_sensitive => false }
   validates :password, :presence => true,
                       :confirmation => true,
                       :length => {:within => 6..40}
    
  before_save :encrypt_password

  def feed
    Micropost.from_users_followed_by_including_replies(self)
  end

  def has_password?(submitted_password)
   encrypted_password == encrypt(submitted_password) 
  end
 
  def self.authenticate(email, submitted_password) # class method!
   user = find_by_email(email)
   # return nil if user.nil?
   # return user if user.has_password?(submitted_password)
   
   user && user.has_password?(submitted_password) ? user : nil
  end
  def self.authenticate_with_salt(id, cookie_salt)
    user = find_by_id(id)
    (user && user.salt == cookie_salt) ? user : nil
  end

  def following?(followed)
    relationships.find_by_followed_id(followed)
  end

  def follow!(followed)
    relationships.create!(:followed_id => followed.id)
  end
  
  def unfollow!(followed)
    relationships.find_by_followed_id(followed).destroy
  end

  def shorthand
   # name.gsub(/\s*/,"")
   name.gsub(/ /,"_")
  end
  def self.shorthand_to_name(sh)
   # name.gsub(/\s*/,"")
   sh.gsub(/_/," ")
  end
  def self.find_by_shorthand(shorthand_name)
    all = where(name: User.shorthand_to_name(shorthand_name))
    return nil if all.empty?
    all.first
  end

 private 
    def encrypt_password
      self.salt = make_salt if new_record?
      self.encrypted_password = encrypt(password)
    end
    def encrypt(string)
      secure_hash("#{salt}--#{string}")
    end  
    def make_salt
      secure_hash("#{Time.now.utc}--#{password}")
    end
    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end 
  
  
end
