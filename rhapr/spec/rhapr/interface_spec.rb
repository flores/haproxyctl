require 'spec_helper'

describe Rhapr::Interface do
  let(:basic_info) do
    "Name: HAProxy\nVersion: 1.4.15\nRelease_date: 2011/04/08\nNbproc: 1\nProcess_num: 1\nPid: 97413\nUptime: 0d 18h43m53s\n"   <<
    "Uptime_sec: 67433\nMemmax_MB: 0\nUlimit-n: 2066\nMaxsock: 2066\nMaxconn: 1024\nMaxpipes: 0\nCurrConns: 1\nPipesUsed: 0\n"  <<
    "PipesFree: 0\nTasks: 7\nRun_queue: 1\nnode: skg.local\ndescription: \n"
  end

  let(:basic_stat) do
    '# pxname,svname,qcur,qmax,scur,smax,slim,stot,bin,bout,dreq,dresp,ereq,econ,eresp,wretr,wredis,status,weight,act,bck,chkfail,'           <<
    'chkdown,lastchg,downtime,qlimit,pid,iid,sid,throttle,lbtot,tracked,type,rate,rate_lim,rate_max,check_status,check_code,check_duration,'  <<
    "hrsp_1xx,hrsp_2xx,hrsp_3xx,hrsp_4xx,hrsp_5xx,hrsp_other,hanafail,req_rate,req_rate_max,req_tot,cli_abrt,srv_abrt,\nsrv,FRONTEND,"        <<
    ",,0,0,2000,0,0,0,0,0,0,,,,,OPEN,,,,,,,,,1,1,0,,,,0,0,0,0,,,,,,,,,,,0,0,0,,,\nsrv,srv1,0,0,0,0,20,0,0,0,,0,,0,0,0,0,DOWN,1,1,0,"          <<
    "0,1,72468,72468,,1,1,1,,0,,2,0,,0,L4CON,,0,,,,,,,0,,,,0,0,\nsrv,srv2,0,0,0,0,20,0,0,0,,0,,0,0,0,0,DOWN,1,1,0,0,1,72465,72465,,"          <<
    "1,1,2,,0,,2,0,,0,L4CON,,0,,,,,,,0,,,,0,0,\n"
  end

  subject { Rhapr::Interface.new }

  describe '#clear_counters' do
    it 'should send the "clear counters" message to HAProxy' do
      subject.should_receive(:send).with('clear counters').and_return("\n")

      subject.clear_counters.should be_true
    end
  end

  describe '#show_info' do
    it 'should parse and return a Hash of HAProxy\'s info attributes' do
      subject.should_receive(:send).with('show info').and_return(basic_info)

      subject.show_info.should be_a(Hash)
    end

    it 'should normalize the attribute names into lower-case and underscore-ized form'
  end

  describe '#show_stat' do
    before(:each) do
      subject.should_receive(:send).with('show stat').and_return(basic_stat)
    end

    it 'should return an Array of Hashes, returned from HAProxy\'s "show stats" request' do
      stats = subject.show_stat

      stats.should be_a(Array)
      stats.each { |stat| stat.should be_a(Hash) }
    end

    it 'should strip the "# " from the beginning of the headers, before calling CSV.parse' do
      stats = subject.show_stat

      stats.first.should_not  have_key('# pxname')
      stats.first.should      have_key('pxname')
    end
  end

  describe '#show_errors'
  describe '#show_sess'

  describe '#get_weight' do
    it 'should parse the weight into an Array, with two elements: The weight and the initial weight' do
      subject.should_receive(:send).with('get weight test/test1').and_return('1 (initial 1)')

      subject.get_weight('test', 'test1').should == [1, 1]
    end

    it 'should raise an error if the specific backend+server is not known to HAProxy' do
      subject.should_receive(:send).with('get weight test/test9').and_return('No such server.')

      lambda do
        subject.get_weight('test', 'test9')
      end.should raise_error(ArgumentError, 'HAProxy did not recognize the specified Backend/Server. Response from HAProxy: No such server.')
    end
  end

  describe '#set_weight'
  describe '#disable'
  describe '#enable'
end
