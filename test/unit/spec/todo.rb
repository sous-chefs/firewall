RSpec.configure do |config|
  config.platform = 'ubuntu'
  config.version = '12.04'
end

describe 'firewall::default' do
  before do
    mock_mixlib_shellout = double('new')
    mock_output_stream = double('output_stream')

    allow(Mixlib::ShellOut).to receive(:new).and_return(mock_mixlib_shellout)

    allow(mock_mixlib_shellout).to receive(:live_stream).and_return(mock_output_stream)
    allow(mock_mixlib_shellout).to receive(:run_command).and_return(mock_mixlib_shellout)
    allow(mock_mixlib_shellout).to receive(:error?).and_return(false)
    allow(mock_mixlib_shellout).to receive(:error!).and_return(nil)
    allow(mock_mixlib_shellout).to receive(:stdout).and_return('false')
  end

  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(firewall firewall_rule)).converge(described_recipe) }

  it 'enables the firewall' do
    expect(chef_run).to enable_firewall('default')
  end
end
