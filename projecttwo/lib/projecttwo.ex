defmodule Projecttwo do
  def main do
    numNodes = [1, 2, 3, 4, 5, 6, 7, 8 , 9, 10]

    Enum.each(numNodes, fn(numNode) ->
      {:ok, pid} = GossipFunction.start_link
      IO.puts "Process #{numNode} started"
      IO.inspect pid
    end)
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

  def createProcesses(numProcesses) do
    if numProcesses > 0 do
      #{:ok, pid} = Genserver.start_link(GossipFunction, 1, name: "Varun")
      #createProcesses(numProcesses - 1)
    end
  end
end
