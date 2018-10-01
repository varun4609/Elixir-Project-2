defmodule PushSum do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(args) do
    {:ok, args}
  end

  def handle_cast({:push_sum_send_message, input_s, input_w}, state) do
    if(Enum.at(state, 6) == 1) do
      {:noreply, state}
    else
      old_s = Enum.at(state, 1)
      old_w = Enum.at(state, 2)

      old_ratio = old_s / old_w

      new_ratio = (Enum.at(state, 1) + input_s) / ( Enum.at(state, 2) + input_w)

      new_s = (Enum.at(state, 1) + input_s) / 2
      new_w = (Enum.at(state, 2) + input_w) / 2

      new_sc =
      if Kernel.abs(old_ratio - new_ratio) < 0.0000000001 do
        Enum.at(state, 4) + 1
      else
        0
      end

      new_state =
      if new_sc >= 3 do
        #IO.puts "#{new_ratio}: Done"
        ServerNode.add_blacklist(:global.whereis_name(:servernode), "node#{Enum.at(state, 3)}")
        #Process.exit(self(), :normal)
        1
      else
        0
      end

      neigh = GenServer.call(:global.whereis_name(:servernode), {:get_neighbours, Enum.at(state, 6)})

      if Kernel.length(neigh) == 0 do
        #IO.puts "No neighbours"
        ServerNode.add_blacklist(:global.whereis_name(:servernode), "node#{Enum.at(state, 3)}")
        #Process.exit(self(), :normal)
      else
        GenServer.cast(:global.whereis_name(String.to_atom(List.first(neigh))), {:push_sum_send_message, new_s, new_w})
        #{:ok, pid} = Task.start_link(my_task_module())
        :timer.sleep 1

          #if (Enum.at(state, 5) == 0) do

            #{:ok, pid} = Task.start_link(Dummy, :my_task_module, [])
            #send pid, {:hi, List.first(neigh)}
          #end


        GenServer.cast(self(), {:push_sum_send_message, new_s, new_w})
        #SpamMessage.push_sum_start_cast(Enum.at(state, 0), new_s, new_w, Enum.at(state, 3))
      end

      new_active =
      if Enum.at(state, 5) == 0 do
        1
      end

      new_state = [Enum.at(state, 0), new_s, new_w, Enum.at(state, 3), new_sc, new_active, Enum.at(state, 6), new_state]
      {:noreply, new_state}
    end
  end


  def send_message(pid, s, w) do
    GenServer.cast(pid, {:push_sum_send_message, s, w})
  end

  def createProcesses(num_processes, total_nodes, topology) do
    if num_processes > 0 do
      #neighbours = Topology.get_neighbours(num_processes, total_nodes)
      temps = Topology.select_topology(topology, total_nodes, num_processes)

      neighbours = Enum.map(temps, fn(x) -> "node#{x}" end)
      #IO.puts "#{num_processes}: #{neighbours}"

      {:ok, send_pid} = GenServer.start_link(SpamMessage, neighbours, name: String.to_atom("sender#{num_processes}"))

      {:ok, pid} = GenServer.start_link(PushSum,
        [send_pid, num_processes, 1, num_processes, 0, 0, neighbours, 0],
        name: String.to_atom("node#{num_processes}"))
      :global.register_name(String.to_atom("node#{num_processes}"), pid)
      createProcesses(num_processes - 1, total_nodes, topology)
    end
  end
end

defmodule Dummy do
  def my_task_module do
    receive do
      {:hi, value} ->
        IO.puts value
      after 1 ->
        IO.puts 10
    end

  end
end
