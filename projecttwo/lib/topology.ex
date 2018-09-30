defmodule Topology do
  def get_neighbours(nodeId, total_nodes) do
    neighbours = cond do
      nodeId == 1 -> ["node2"]
      nodeId == total_nodes -> ["node#{total_nodes - 1}"]
      true -> ["node#{nodeId-1}", "node#{nodeId+1}"]
    end
      neighbours
  end
end
