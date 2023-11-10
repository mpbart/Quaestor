require 'config_reader'

RSpec.describe ConfigReader do
  let(:config_file) { {key: 'value'} }
  let(:client_name) { 'client' }

  describe '.for' do
    before { allow(described_class).to receive(:config_file).and_return(config_file) }
    subject { described_class.for(client_name) }

    it 'retrieves the jsonified config file' do
      expect(described_class).to receive(:config_file)
      subject
    end

    it "retrieves the key corresponding to the client's name" do
      expect(config_file).to receive(:dig).with(client_name)
      subject
    end
  end
end
