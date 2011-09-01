require 'spec_helper'
require 'backend/shared_backend_spec'
require 'delayed/backend/active_record'

describe Delayed::Backend::ActiveRecord::Job do
  before(:all) do
    @backend = Delayed::Backend::ActiveRecord::Job
  end
  
  before(:each) do
    Delayed::Backend::ActiveRecord::Job.delete_all
    SimpleJob.runs = 0
  end
  
  after do
    Time.zone = nil
  end
  
  [Delayed::DEFAULT_QUEUE, Delayed::ALL_QUEUES, "foo"].each do |queue|
    context "when given a queue of #{queue}" do
      before do
        Delayed::Worker.queue = queue
      end
      it_should_behave_like 'a backend'
    end
  end

  context "named queues" do
    def create_job(opts = {})
      @backend.create({:payload_object => SimpleJob.new, :queue => Delayed::Worker.queue}.merge(opts))
    end

    context "when worker has one queue set" do
      before(:each) do
        @worker = Delayed::Worker.new(:queue => "large")
      end

      it "should only work off jobs which are from its queue" do
        SimpleJob.runs.should == 0

        create_job(:queue => "large")
        create_job(:queue => "small")
        @worker.work_off

        SimpleJob.runs.should == 1
      end
    end

    context "when worker has all queues set" do
      before(:each) do
        @worker = Delayed::Worker.new(:queue => Delayed::ALL_QUEUES)
      end

      it "should work off all jobs for ALL queue designator" do
        SimpleJob.runs.should == 0

        create_job(:queue => "large")
        create_job(:queue => "small")
        create_job(:queue => "medium")
        create_job(:queue => Delayed::DEFAULT_QUEUE)
        @worker.work_off

        SimpleJob.runs.should == 4
      end
    end
  end

  context "db_time_now" do
    it "should return time in current time zone if set" do
      Time.zone = 'Eastern Time (US & Canada)'
      %w(EST EDT).should include(Delayed::Job.db_time_now.zone)
    end
    
    it "should return UTC time if that is the AR default" do
      Time.zone = nil
      ActiveRecord::Base.default_timezone = :utc
      Delayed::Backend::ActiveRecord::Job.db_time_now.zone.should == 'UTC'
    end

    it "should return local time if that is the AR default" do
      Time.zone = 'Central Time (US & Canada)'
      ActiveRecord::Base.default_timezone = :local
      %w(CST CDT).should include(Delayed::Backend::ActiveRecord::Job.db_time_now.zone)
    end
  end
  
  describe "after_fork" do
    it "should call reconnect on the connection" do
      ActiveRecord::Base.connection.should_receive(:reconnect!)
      Delayed::Backend::ActiveRecord::Job.after_fork
    end
  end
end
