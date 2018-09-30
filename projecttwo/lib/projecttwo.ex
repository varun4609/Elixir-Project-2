defmodule Projecttwo do
  def main(num_nodes, _topology, _algorithm) do
    message_limit = 10
    GossipFunction.createProcesses(String.to_integer(num_nodes), message_limit, String.to_integer(num_nodes))
    {:ok, server_pid} = GenServer.start_link(ServerNode, 0, name: :serverNode)
    :global.register_name(:servernode, server_pid)
    :global.sync()
    #IO.puts "Creating children"
    random_start_node = :rand.uniform(String.to_integer(num_nodes))
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

  def handle_call({:get_neighbours}, _from, state) do
    #neighbours = Topology.get_neighbours(nodeId)
    #IO.inspect neighbours, label: "Neighbours are :"
    {:reply, state, state}
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

defmodule SpamMessage do
  use GenServer
  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(args) do
    {:ok, args}
  end

  def parent_start_cast(pid) do
    GenServer.cast(pid, {:spam_message})
  end

  def parent_stop_cast(pid) do
    GenServer.cast(pid, :stop_spam)
  end

  def send_message(pid) do
    GenServer.cast(pid, {:spam_message})
  end

  def handle_cast({:spam_message}, state) do
    neighbour = get_random(state)
    #IO.puts "My neighbour is #{neighbour}"
    GenServer.cast(:global.whereis_name(String.to_atom(neighbour)), {:send_message})
    #send_message(:global.whereis_name(String.to_atom(neighbour)))
    GenServer.cast(self(), {:spam_message})

    {:noreply, state}
  end

  def handle_cast({:stop_spam}, state) do
    IO.puts "Stopping spam"
    Process.exit(self(),:kill)
    {:noreply, state}
  end

  def get_random(state) do
    if Kernel.length(state) > 1 do
      rnd_neighbour = :rand.uniform(Kernel.length(state))
      Enum.at(state, rnd_neighbour - 1)
    else
      Enum.at(state, 0)
    end
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

  def get_random(state) do
    if Kernel.length(Map.get(state, :neighbourList)) > 1 do
      rnd_neighbour = :rand.uniform(Kernel.length(Map.get(state, :neighbourList)))
      Enum.at(Map.get(state, :neighbourList), rnd_neighbour - 1)
    else
      Enum.at(Map.get(state, :neighbourList), 0)
    end
  end

  def send_message(pid) do
    GenServer.cast(pid, {:send_message})
  end

  def myProg(state) when is_list(state) do
    IO.puts "I am a list"
  end

  def handle_cast({:send_message}, state) do
    #IO.puts "NodeId: #{nodeId}"
    if Map.get(state, :curr_state) == 10 do
      {:noreply, state}
    else
      #neighbours = get_random(state)
      #IO.puts "#{Map.get(state, :nodeId)}: My neighbour is #{neighbours}"
      #myProg(neighbours)
      #GossipFunction.send_message(:global.whereis_name(String.to_atom(neighbours)))
      if Map.get(state, :curr_state) == 0 do
        SpamMessage.parent_start_cast(Map.get(state, :sender_pid))
      end

      {_, state} = Map.get_and_update(state, :curr_state, fn(x) -> {x, (x || 0) + 1} end)

      #IO.puts "#{Map.get(state, :nodeId)}: New state #{Map.get(state, :curr_state)}"

      if Map.get(state, :curr_state) + 1 == 10 do
        IO.puts "Process #{Map.get(state, :nodeId)} is done."
        SpamMessage.parent_stop_cast(:global.whereis_name(String.to_atom("sender#{Map.get(state, :nodeId)}")))
        GenServer.cast(:global.whereis_name(:servernode), :done)
      end
      {_, state} = Map.get_and_update(state, :curr_state, fn(x) -> {x, (x || 0) + 1} end)
      {:noreply, state}
    end
  end

  def createProcesses(num_processes, message_limit, total_nodes) do
    if num_processes > 0 do
      neighbours = Topology.get_neighbours(num_processes, total_nodes)

      {:ok, send_pid} = GenServer.start_link(SpamMessage, neighbours, name: String.to_atom("sender#{num_processes}"))

      {:ok, pid} = GenServer.start_link(GossipFunction,
        %{curr_state: 0, nodeId: num_processes, neighbourList: neighbours, message_limit: message_limit, sender_pid: send_pid},
        name: String.to_atom("node#{num_processes}"))
      :global.register_name(String.to_atom("node#{num_processes}"), pid)

      createProcesses(num_processes - 1, message_limit, total_nodes)
    end

  end
end
