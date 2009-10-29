require 'spec/spec_helper'

describe Mingle do
  describe '#merge' do
    before :each do
      @mike = Factory :user, :username => 'mike'
      @bob  = Factory :user, :username => 'bob', :first_name => 'Bob'
    end
    
    it 'requires the target and victim to be of the same type' do
      @band = Factory :artist
      lambda { @mike.merge @band }.should raise_error(Mingle::IncompatibleTypes)
    end
    
    describe 'with basic objects' do
      it 'fills blanks in the target with data from the victim' do
        @mike.first_name.should be_nil
        @mike.merge @bob
        @mike.username.should == 'mike'
        @mike.first_name.should == 'Bob'
      end
      
      describe 'when the target is valid after the merge' do
        it 'saves the target record' do
          @mike.should_receive :save
          @mike.merge @bob
        end
        
        it 'removes the victim from the database' do
          User.count.should == 2
          @mike.merge @bob
          User.count.should == 1
          User.first.should == @mike
        end
        
        it 'removes the victim record using #destroy' do
          @bob.should_receive(:destroy)
          @mike.merge @bob
        end
      end
      
      describe 'when the target is invalid after the merge' do
        before :each do
          @mike.username = 'admin'
          @mike.should_not be_valid
        end
        
        it 'does not save the target record' do
          @mike.should_not_receive :save
          @mike.merge @bob
        end
        
        it 'does not remove the target from the database' do
          @mike.merge @bob
          User.count.should == 2
        end
      end
      
      it 'protects fields passed with :keep' do
        @mike.merge @bob, :keep => :first_name
        @mike.first_name.should be_nil
      end
      
      it 'overwrites fields passed with :overwrite' do
        @mike.merge @bob, :overwrite => :username
        @mike.username.should == 'bob'
      end
    end
    
    describe 'with has_many associations' do
      before :each do
        @mike.posts = (1..3).map { Factory :post, :user => @mike }
        @bob.posts  = (1..4).map { Factory :post, :user => @bob }
      end
      
      describe 'when the merged object is valid' do
        it 'concatenates the associated collections' do
          @mike.merge @bob
          @mike.reload.posts.size.should == 7
        end
        
        it 'updates all foreign keys using one query' do
          ActiveRecord::Base.connection.should_receive(:execute).once
          @mike.merge_association @bob, :posts
        end
      end
      
      describe 'when the merged object is not valid' do
        before :each do
          @mike.username = 'admin'
        end
        
        it 'does not concatenate the associated collections' do
          @mike.merge @bob
          @mike.reload.posts.size.should == 3
          @bob.reload.posts.size.should == 4
        end
      end
    end
    
    describe 'with has_and_belongs_to_many associations' do
      before :each do
        @mike.groups = (1..2).map { Factory :group }
        @bob.groups  = (1..3).map { Factory :group }
      end
      
      it 'concatenates the associated collections' do
        @bob.merge @mike
        @bob.reload.groups.size.should == 5
        Group.all.each { |g| g.users.should == [@bob] }
      end
      
      it 'updates all foreign keys using one query' do
        ActiveRecord::Base.connection.should_receive(:execute).once
        @bob.merge_association @mike, :groups
      end
    end
  end
end

