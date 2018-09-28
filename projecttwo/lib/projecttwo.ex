defmodule Projecttwo do
  def main(numNodes, _topology, _algorithm) do
    GossipFunction.createProcesses(String.to_integer(numNodes))
    {:ok, server_pid} = GenServer.start_link(ServerNode, 0, name: :serverNode)
    :global.register_name(:servernode, server_pid)
    :global.sync()
    #IO.puts "Creating children"
    random_start_node = :rand.uniform(String.to_integer(numNodes))
    IO.puts "Sending random process #{random_start_node} message"
    #IO.puts :global.whereis_name(:node1)
    GossipFunction.send_message(:global.whereis_name(:"node#{random_start_node}"))

  end
end

defmodule ServerNode do
  use GenServer
  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(args) do
    {:ok, args}
  end

  def handle_call({:get_neighbours, nodeId}, _from, state) do
    #IO.puts "I am invoked by #{nodeId}"
    #IO.inspect nodeId, label: "Neighbours are :"
    neighbours = cond do
      nodeId == 1 -> ["node2"]
      nodeId == 10 -> ["node4"]
      true -> ["node#{nodeId-1}", "node#{nodeId+1}"]
    end
    #IO.inspect neighbours, label: "Neighbours are :"
    {:reply, neighbours, state}
  end

  #wait for all done messages and then exit
  def handle_cast(:done, state) do
    if state == 10 do
      :ok
      #Process.exit(self(), :kill)
    end
    IO.puts "Server state is #{state+1}"
    {:noreply, state + 1}
  end

  def get_neighbours(pid, nodeId) do
    #IO.puts "Hello #{nodeId}"
    #IO.inspect pid
    GenServer.call(pid , {:get_neighbours, nodeId})
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
    [head | tail] = state
    #if List.first(tail) == 5 do
     # IO.puts "Process #{List.first(tail)}: My current state is #{head}"
    #end
    #IO.puts "Process #{List.first(tail)}: My current state is #{head}"
    #IO.puts "My tail state : #{List.first(tail)}"

    if head == 10 do
      #if List.first(tail) == 5 do
       # IO.puts "Process #{List.first(tail)} is done."
      #end
      #IO.puts "Process #{List.first(tail)} is done."
      #GenServer.cast(:global.whereis_name(:servernode), {:done})
      #Process.exit(self(), :kill)
      {:noreply, state}
    else
      #IO.puts "Got the server ID"
      #:timer.sleep 1

      #get neighbours
      #IO.puts "Getting neighbours"
      neighbours = ServerNode.get_neighbours(:global.whereis_name(:servernode), List.first(tail))
      #IO.inspect neighbours
      #IO.puts "Got neighbours: #{neighbours}"
      #send messages to them
      Enum.each(neighbours, fn(neighbour) ->
        send_message(:global.whereis_name(String.to_atom(neighbour)))
      end)
      #if List.first(tail) == 5 do
      #  IO.puts "Process #{List.first(tail)}: My new state : #{head + 1}"
      #end
      #IO.puts "Process #{List.first(tail)}: My new state : #{head + 1}"
      if head + 1 == 10 do
        IO.puts "Process #{List.first(tail)} is done."
        GenServer.cast(:global.whereis_name(:servernode), :done)
      end
      {:noreply, [head + Kernel.length(neighbours) | tail]}
    end


  end

  def display_done do

  end

  def createProcesses(numProcesses) do
    if numProcesses > 0 do
      {:ok, pid} = GenServer.start_link(GossipFunction, [1, numProcesses], name: String.to_atom("node#{numProcesses}"))
      :global.register_name(String.to_atom("node#{numProcesses}"), pid)
      createProcesses(numProcesses - 1)
    end

  end
end
