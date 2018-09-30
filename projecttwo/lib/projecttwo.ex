defmodule Projecttwo do
  def main(num_nodes, _topology, algorithm) do
    if algorithm == "gossip" do
      IO.puts "gossip"
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
    if algorithm == "pushsum" do
      IO.puts "pushsum"
      PushSum.createProcesses(String.to_integer(num_nodes), String.to_integer(num_nodes))
      {:ok, server_pid} = GenServer.start_link(ServerNode, 0, name: :serverNode)
      :global.register_name(:servernode, server_pid)
      :global.sync()

      random_start_node = :rand.uniform(String.to_integer(num_nodes))
      IO.puts "Sending random process #{random_start_node} message"

      PushSum.send_message(:global.whereis_name(:"node#{random_start_node}"), 0, 0)
    end
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

  def push_sum_start_cast(pid, s, w) do
    GenServer.cast(pid, {:push_sum_message, s, w})
  end

  def parent_stop_cast(pid) do
    GenServer.cast(pid, {:stop_spam})
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

  def handle_cast({:push_sum_message, s, w}, state) do
    neighbour = get_random(state)
    #IO.puts "My neighbour is #{neighbour}"
    GenServer.cast(:global.whereis_name(String.to_atom(neighbour)), {:push_sum_send_message, s, w})
    #send_message(:global.whereis_name(String.to_atom(neighbour)))
    #GenServer.cast(self(), {:push_sum_message, s, w})

    {:noreply, state}
  end

  def handle_cast({:stop_spam}, state) do
    #IO.puts "Stopping spam"
    #Process.exit(self(),:kill)
    {:shutdown, state}
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
    if Map.get(state, :curr_state) == Map.get(state, :message_limit) do
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
      curr_state = Map.get(state, :curr_state)
      if curr_state == Map.get(state, :message_limit) do
        IO.puts "Process #{Map.get(state, :nodeId)} is done."
        SpamMessage.parent_stop_cast(Map.get(state, :sender_pid))
        GenServer.cast(:global.whereis_name(:servernode), :done)
      end
      #{_, state} = Map.get_and_update(state, :curr_state, fn(x) -> {x, (x || 0) + 1} end)
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

defmodule PushSum do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(args) do
    {:ok, args}
  end

  def handle_cast({:push_sum_send_message, input_s, input_w}, state) do
    #IO.puts "NodeId: #{Map.get(state, :nodeId)}"
    old_s = Enum.at(state, 1)
    old_w = Enum.at(state, 2)

    old_ratio = old_s / old_w

    new_ratio = (Enum.at(state, 1) + input_s) / ( Enum.at(state, 2) + input_w)

    new_s = (Enum.at(state, 1) + input_s) / 2
    new_w = (Enum.at(state, 2) + input_w) / 2

    if Enum.at(state, 3) == 1 do
      IO.puts "NodeId: #{Enum.at(state, 3)} new ratio is #{new_ratio} s: #{input_s} w: #{input_w}"
    end
    #{_, state} =
    #IO.puts "NodeId: #{Map.get(state, :nodeId)} new ratio is #{new_ratio}"
    #is_active = Map.get(state, :active)
    #IO.puts is_active
    #{_, state} =
    new_sc =
    if (new_ratio - old_ratio < 0.0000000001) do
      #IO.puts "#{Enum.at(state, 3)}: saturation is #{Enum.at(state, 4)}"
      Enum.at(state, 4)
    end
    #IO.puts temp

    if Enum.at(state, 4) == 3 do
      IO.puts "Stopping spammer"
      SpamMessage.parent_stop_cast(Enum.at(state, 0))
    end
    #{_, state} =
    #if Map.get(state, :active) == 0 do
      #IO.puts "#{Enum.at(state, 3)}: Sending s: #{Enum.at(state, 1)} and w: #{Enum.at(state, 2)}"
      SpamMessage.push_sum_start_cast(Enum.at(state, 0), new_s, new_w)
      new_active =
      if Enum.at(state, 5) == 0 do
        1
      end
    #end
    new_state = [Enum.at(state, 0), new_s, new_w, Enum.at(state, 3), new_sc, new_active]
    {:noreply, new_state}
  end

  def send_message(pid, s, w) do
    GenServer.cast(pid, {:push_sum_send_message, s, w})
  end

  def createProcesses(num_processes, total_nodes) do
    if num_processes > 0 do
      neighbours = Topology.get_neighbours(num_processes, total_nodes)

      {:ok, send_pid} = GenServer.start_link(SpamMessage, neighbours, name: String.to_atom("sender#{num_processes}"))

      {:ok, pid} = GenServer.start_link(PushSum,
        [send_pid, num_processes, 1, num_processes, 0, 0],
        name: String.to_atom("node#{num_processes}"))
      :global.register_name(String.to_atom("node#{num_processes}"), pid)
      createProcesses(num_processes - 1, total_nodes)
    end
  end
end
