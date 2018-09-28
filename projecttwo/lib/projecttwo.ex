defmodule Projecttwo do
  def main(numNodes, _topology, _algorithm) do
    GossipFunction.createProcesses(String.to_integer(numNodes))
    random_start_node = :rand.uniform(String.to_integer(numNodes))
    IO.puts random_start_node
    #IO.puts :global.whereis_name(:"node#{random_start_node}")
    GossipFunction.send_message(:global.whereis_name(:"node#{random_start_node}"))
  end
end

defmodule GossipFunction do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(arg) do
    {:ok, arg}
  end

  def send_message(pid) do
    #IO.puts "Sending message to #{IO.inspect pid}"
    GenServer.cast(pid, {:send_message})
  end

  def handle_cast({:send_message}, state) do
    IO.puts "My current state : #{state}"
    :timer.sleep 1
    #get neighbours
    #send messages to them
    IO.puts "My new state : #{state + 1}"
    {:noreply, state + 1}
  end

  def display_done do

  end
  def createProcesses(numProcesses) do
    if numProcesses > 0 do
      {:ok, pid} = GenServer.start_link(GossipFunction, 1, name: String.to_atom("node#{numProcesses}"))
      :global.register_name(String.to_atom("node#{numProcesses}"), pid)
      #IO.puts "Process #{numProcesses} started"
      #IO.inspect pid
      createProcesses(numProcesses - 1)
    end

  end
end
