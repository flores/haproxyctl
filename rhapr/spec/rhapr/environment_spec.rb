require 'spec_helper'

describe Rhapr::Environment do
  class EnvTest
    include Rhapr::Environment
  end

  before(:each) do
    @env_test = EnvTest.new
  end

  describe '#config_path' do
    it 'should set to the ENV variable, if present' do
      ENV['HAPROXY_CONFIG'] = '/some/path.cfg'

      @env_test.config_path.should == '/some/path.cfg'

      # Clean up.
      ENV.delete 'HAPROXY_CONFIG'
    end

    it 'should go down a list of pre-defined file names' do
      File.stub!(:exists?).and_return(false)
      File.should_receive(:exists?).with('/etc/haproxy.cfg').and_return(true)

      @env_test.config_path.should == '/etc/haproxy.cfg'
    end

    it 'should select the first configuration found, from the pre-defined list' do
      File.stub!(:exists?).and_return(false)
      File.should_receive(:exists?).with('/etc/haproxy/haproxy.cfg').and_return(true)
      File.should_receive(:exists?).with('/etc/haproxy.cfg').and_return(true)

      @env_test.config_path.should == '/etc/haproxy/haproxy.cfg'
    end

    it 'should be nil if config files do not exist and $HAPROXY_CONFIG is not set' do
      File.stub!(:exists?).and_return(false)
      @env_test.config_path.should be_nil
    end
  end

  describe '#config' do
    before(:each) do
      File.stub!(:exists?).and_return(false)
      File.should_receive(:exists?).with('/etc/haproxy.cfg').and_return(true)
    end

    it 'should raise an exception if it cannot read from #config_path' do
      File.should_receive(:read).and_raise(Errno::ENOENT)

      lambda do
        @env_test.config
      end.should raise_error(RuntimeError)
    end

    it 'should read and return the contents of a file' do
      File.should_receive(:read).and_return { "I can haz cfg ?\n" }

      @env_test.config.should == "I can haz cfg ?\n"
    end
  end

  describe '#exec' do
    it 'should set to the ENV variable, if present' do
      ENV['HAPROXY_BIN'] = '/usr/local/bin/haproxy'

      @env_test.exec.should == '/usr/local/bin/haproxy'

      # Clean up.
      ENV.delete 'HAPROXY_BIN'
    end

    it 'should call out to the `which` command to find haproxy, if the ENV var is not set' do
      @env_test.should_receive(:`).with('which haproxy').and_return('/opt/bin/haproxy')

      @env_test.exec.should == '/opt/bin/haproxy'
    end

    it 'should call out to haproxy directly, if all else fails' do
      @env_test.should_receive(:`).with('which haproxy').and_return('')
      @env_test.should_receive(:`).with('haproxy -v').and_return("HA-Proxy version 1.4.15 2011/04/08\nCopyright 2000-2010 Willy Tarreau <w@1wt.eu>\n\n")

      @env_test.exec.should == 'haproxy'
    end

    it 'should be nil if none of the above worked' do
      @env_test.should_receive(:`).with('which haproxy').and_return('')
      @env_test.should_receive(:`).with('haproxy -v').and_raise(Errno::ENOENT)

      @env_test.exec.should be_nil
    end
  end

  describe '#socket' do
    it 'should establish a socket connection with HAProxy'
  end

  describe '#socket_path' do
    it 'should parse out the io socket from the config file' do
      @env_test.should_receive(:config).and_return { config_for(:basic_haproxy) }

      @env_test.socket_path.should == '/tmp/haproxy'
    end

    it 'should raise an error if it cannot derive an io socket from the config file' do
      @env_test.should_receive(:config).and_return { config_for(:crappy_haproxy) }

      lambda do
        @env_test.socket_path
      end.should raise_error(RuntimeError)
    end
  end

  describe '#pid' do
    it 'should parse out the pidfile from the config file' do
      @env_test.should_receive(:config).and_return { config_for(:pid_test_haproxy) }

      @env_test.pid.should == '/some/other/run/haproxy.pid'
    end

    it 'should return a default path if it cannot derive an io socket from the config file' do
      @env_test.should_receive(:config).and_return { config_for(:crappy_haproxy) }

      @env_test.pid.should == '/var/run/haproxy.pid'
    end
  end

  describe '#check_running, #pidof' do
    pending 'TBD'
  end
end
