defmodule Projecttwo do
  def main(num_nodes, topology, algorithm) do
    nodes =
      if topology == "torus" do
        :math.sqrt(String.to_integer(num_nodes)) |> :math.ceil |> Kernel.trunc
      else
        String.to_integer(num_nodes)
      end
    b =
    if algorithm == "gossip" do
      message_limit = 5
      GossipFunction.createProcesses(nodes, message_limit, nodes)
      {:ok, server_pid} = GenServer.start_link(ServerNode, [], name: :serverNode)
      :global.register_name(:servernode, server_pid)
      :global.sync()

      random_start_node = :rand.uniform(nodes)

      GossipFunction.send_message(:global.whereis_name(:"node#{random_start_node}"))
      System.system_time(:millisecond)
    else
      PushSum.createProcesses(nodes, nodes, topology)
      {:ok, server_pid} = GenServer.start_link(ServerNode, [], name: :serverNode)
      :global.register_name(:servernode, server_pid)
      :global.sync()

      random_start_node = :rand.uniform(nodes)

      PushSum.send_message(:global.whereis_name(:"node#{random_start_node}"), 0, 0)
      System.system_time(:millisecond)
    end
    checkConvergence(b, nodes)
  end

  def checkConvergence(b, num_nodes) do
    len = Kernel.length(GenServer.call(:global.whereis_name(:servernode), :get_blacklist, :infinity))
    #IO.puts "Len: #{len}"
    if(len == num_nodes) do
      IO.puts "Time = #{System.system_time(:millisecond) - b}"
      System.halt(1)
    end
    checkConvergence(b, num_nodes)
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

  def add_blacklist(pid, message) do
    GenServer.cast(pid, {:add_blacklist, message})
  end

  #def get_blacklist(pid) do
   # GenServer.call(pid, :get_blacklist, :infinity)
  #end

  def handle_call({:get_neighbours, neighbours}, _from, state) do

    neighbours = Enum.filter(neighbours, fn el -> !Enum.member?(state, el) end)

    rnd_neigh = []
    rnd_neigh =
    if Kernel.length(neighbours) >= 1 do
      rnd_num = :rand.uniform(Kernel.length(neighbours))
      rnd_neigh ++ [Enum.at(neighbours, rnd_num - 1)]
    else
      []
    end
    {:reply, rnd_neigh, state}
  end

  def handle_call(:get_blacklist, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:add_blacklist, new_message}, messages) do
    IO.puts Kernel.length messages
    {:noreply, [new_message | messages]}
  end

  def get_neighbours(pid, nodeId) do
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

  def parent_start_cast(pid, parentId) do
    GenServer.cast(pid, {:spam_message, parentId})
  end

  def push_sum_start_cast(pid, s, w, parentId) do
    GenServer.cast(pid, {:push_sum_message, s, w, parentId})
  end

  def parent_stop_cast(pid) do
    GenServer.cast(pid, {:stop_spam})
  end

  def send_message(pid) do
    GenServer.cast(pid, {:spam_message})
  end

  def handle_cast({:spam_message, parentId}, state) do
    #neighbour = get_random(state)
    neighbour = GenServer.call(:global.whereis_name(:servernode), {:get_neighbours, state})
    #IO.puts "My neighbour is #{neighbour}"
    if Kernel.length(neighbour) == 0 do
      #IO.puts "hi"
      ServerNode.add_blacklist(:global.whereis_name(:servernode), "node#{parentId}")
      #kill parent and helper here?
    else
      GenServer.cast(:global.whereis_name(String.to_atom(List.first(neighbour))), {:send_message})
      GenServer.cast(self(), {:spam_message, parentId})
    end

    #send_message(:global.whereis_name(String.to_atom(neighbour)))


    {:noreply, state}
  end

  def handle_cast({:push_sum_message, s, w, parentId}, state) do

    neighbour = GenServer.call(:global.whereis_name(:servernode), {:get_neighbours, state})
    #IO.puts "My neighbour is #{neighbour}"
    if Kernel.length(neighbour) == 0 do
      #IO.puts "hi"
      ServerNode.add_blacklist(:global.whereis_name(:servernode), "node#{parentId}")
    else
    #IO.puts "My neighbour is #{neighbour}"
      GenServer.cast(:global.whereis_name(String.to_atom(List.first(neighbour))), {:push_sum_send_message, s, w})
    #send_message(:global.whereis_name(String.to_atom(neighbour)))
      GenServer.cast(self(), {:push_sum_message, s, w, parentId})
    end
    {:noreply, state}
  end

  def handle_cast({:stop_spam}, state) do
    Process.exit(self(),:normal)
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
