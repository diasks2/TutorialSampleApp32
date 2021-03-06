require 'spec_helper'

describe Micropost do

  before(:each) do
    #FactoryGirl.create(:name) is deprecated; use FactoryGirl.create(:name)
    @user = FactoryGirl.create(:user)
    @attr = { :content => "value for content" }
  end

  it "should create a new instance given valid attributes" do
    @user.microposts.create!(@attr)
  end

  describe "user associations" do

    before(:each) do
      @micropost = @user.microposts.create(@attr)
    end

    it "should have a user attribute" do
      @micropost.should respond_to(:user)
    end

    it "should have the right associated user" do
      @micropost.user_id.should == @user.id
      @micropost.user.should == @user
    end
  end
  
  describe "validations" do

    it "should require a user id" do
      Micropost.new(@attr).should_not be_valid
    end

    it "should require nonblank content" do
      @user.microposts.build(:content => "  ").should_not be_valid
    end

    it "should reject long content" do
      @user.microposts.build(:content => "a" * 141).should_not be_valid
    end
  end

  describe "from_users_followed_by" do

    before(:each) do
      @other_user = FactoryGirl.create(:user, :email => FactoryGirl.generate(:email))
      @third_user = FactoryGirl.create(:user, :email => FactoryGirl.generate(:email))

      @user_post  = @user.microposts.create!(:content => "foo")
      @other_post = @other_user.microposts.create!(:content => "bar")
      @third_post = @third_user.microposts.create!(:content => "baz")

      @user.follow!(@other_user)
    end

    it "should have a from_users_followed_by class method" do
      Micropost.should respond_to(:from_users_followed_by)
    end

    it "should include the followed user's microposts" do
      Micropost.from_users_followed_by(@user).should include(@other_post)
    end

    it "should include the user's own microposts" do
      Micropost.from_users_followed_by(@user).should include(@user_post)
    end

    it "should not include an unfollowed user's microposts" do
      Micropost.from_users_followed_by(@user).should_not include(@third_post)
    end
  end
  describe "from_users_followed_by_including_replies" do

     before(:each) do
       @other_user = FactoryGirl.create(:user, :email => FactoryGirl.generate(:email))
       @third_user = FactoryGirl.create(:user, :email => FactoryGirl.generate(:email))

       @user_post  = @user.microposts.create!(:content => "foo")
       @other_post = @other_user.microposts.create!(:content => "bar")
       @third_post = @third_user.microposts.create!(:content => "baz")
       
       @userToReplyTo = FactoryGirl.create(:userToReplyTo)
       @forth_post = @third_user.microposts.create!(:content => "@#{@userToReplyTo.shorthand} baz")
       
       @user.follow!(@other_user)
     end

     it "should have a from_users_followed_by class method" do
       Micropost.should respond_to(:from_users_followed_by_including_replies)
     end

     it "should include the followed user's microposts" do
       Micropost.from_users_followed_by_including_replies(@user).should include(@other_post)
     end

     it "should include the user's own microposts" do
       Micropost.from_users_followed_by_including_replies(@user).should include(@user_post)
     end

     it "should not include an unfollowed user's microposts" do
       Micropost.from_users_followed_by_including_replies(@user).should_not include(@third_post)
     end
     
     it "should include posts to user" do
       Micropost.from_users_followed_by_including_replies(@userToReplyTo).should include(@forth_post)
     end
   end
  
  describe "replies" do
    before(:each) do
      @reply_to_user = FactoryGirl.create(:userToReplyTo)
      @micropost = @user.microposts.create(content: "@Donald_Duck look a reply to Donald")
    end
    it "should identify a @user and set the in_reply_to field accordingly" do
      @micropost.to.should == @reply_to_user
    end
    
  end

end
