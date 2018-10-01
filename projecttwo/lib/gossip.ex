defmodule GossipFunction do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(arg) do
    {:ok, arg}
  end

  def send_message(pid) do
    GenServer.cast(pid, {:send_message})
  end

  def handle_cast({:send_message}, state) do

    if Enum.at(state, 1) == Enum.at(state, 3) do
      {:noreply, state}
    else
      if Enum.at(state, 1) == 0 do
        SpamMessage.parent_start_cast(Enum.at(state, 0), "node#{Enum.at(state, 2)}")
      end

      #{_, state} = Map.get_and_update(state, :curr_state, fn(x) -> {x, (x || 0) + 1} end)
      new_state = Enum.at(state, 1) + 1

      #IO.puts "#{Map.get(state, :nodeId)}: New state #{Map.get(state, :curr_state)}"
      #curr_state = Enum.at(state, 1)
      if new_state == Enum.at(state, 3) do
        #IO.puts "Process #{Enum.at(state, 2)} is done."
        ServerNode.add_blacklist(:global.whereis_name(:servernode), "node#{Enum.at(state, 2)}")
        SpamMessage.parent_stop_cast(Enum.at(state, 0))

        #GenServer.cast(:global.whereis_name(:servernode), :done)
      end
      #{_, state} = Map.get_and_update(state, :curr_state, fn(x) -> {x, (x || 0) + 1} end)
      {:noreply, [Enum.at(state, 0), new_state, Enum.at(state, 2), Enum.at(state, 3)]}
    end
  end

  def createProcesses(num_processes, message_limit, total_nodes) do
    if num_processes > 0 do
      temps = Topology.select_topology("full", total_nodes, num_processes)

      neighbours = Enum.map(temps, fn(x) -> "node#{x}" end)
      {:ok, send_pid} = GenServer.start_link(SpamMessage, neighbours, name: String.to_atom("sender#{num_processes}"))

      {:ok, pid} = GenServer.start_link(GossipFunction,
        #%{curr_state: 0, nodeId: num_processes, neighbourList: neighbours, message_limit: message_limit, sender_pid: send_pid}
        [send_pid, 0, num_processes, message_limit],
        name: String.to_atom("node#{num_processes}"))
      :global.register_name(String.to_atom("node#{num_processes}"), pid)

      createProcesses(num_processes - 1, message_limit, total_nodes)
    end

  end
end
