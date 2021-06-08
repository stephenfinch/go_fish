require "socket"
require_relative "../lib/fish_server"

class MockClient
  attr_reader :socket
  attr_reader :output, :name

  def initialize(port)
    @socket = TCPSocket.new("localhost", port)
  end

  def provide_input(text)
    @socket.puts(text)
  end

  def capture_output(delay = 0.1)
    sleep(delay)
    @output = @socket.read_nonblock(1000).chomp # not gets which blocks
  rescue IO::WaitReadable
    @output = ""
  end

  def close
    @socket.close if @socket
  end
end

describe FishServer do
  let(:clients) { [] }
  let(:server) { FishServer.new }

  before(:each) do
    server.start
  end

  after(:each) do
    server.stop
    clients.each do |client|
      client.close
    end
  end

  it "is not listening on a port before it is started" do
    server.stop
    expect { MockClient.new(server.port_number) }.to raise_error(Errno::ECONNREFUSED)
  end
end

def make_clients_join(number_of_clients, server)
  if number_of_clients > 0
    client1 = MockClient.new(server.port_number)
    clients.push(client1)
    client1.provide_input("Player 1")
    server.accept_new_client
  end
  if number_of_clients > 1
    client2 = MockClient.new(server.port_number)
    clients.push(client2)
    client2.provide_input("Player 2")
    server.accept_new_client
  end
  if number_of_clients > 2
    client3 = MockClient.new(server.port_number)
    clients.push(client3)
    client3.provide_input("Player 3")
    server.accept_new_client
  end
end

describe FishServer do
  let(:clients) { [] }
  let(:server) { FishServer.new }

  before(:each) do
    server.start
  end

  after(:each) do
    server.stop
    clients.each do |client|
      client.close
    end
  end

  it "accepts new clients" do
    make_clients_join(2, server)
    expect(server.lobby.length).to eq 2
  end

  it "starts a game if possible" do
    make_clients_join(3, server)
    server.create_game_if_possible
    expect(server.games.count).to eq 1
  end

  it "starts multiple games if possible" do
    make_clients_join(3, server)
    server.create_game_if_possible
    expect(server.games.count).to eq 1
    make_clients_join(3, server)
    server.create_game_if_possible
    expect(server.games.count).to eq 2
  end
end
