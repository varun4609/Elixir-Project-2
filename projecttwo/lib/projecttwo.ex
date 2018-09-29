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

defmodule Topology do
    def imp2Dloop(n, neighbor,l) do
        ran = :rand.uniform(n)
        if ran == l or Enum.member?(neighbor, ran) == true do
            imp2Dloop(n, neighbor, l)
        else
            ran
        end
    end
    def select_topology(topology, n, l) do
        max = n
        number2d = l
        cond do
            topology == "line" ->
                cond do
                    l == 1 -> neighbor = [l+1]
                    l == max -> neighbor = [l-1]
                    true -> neighbor = [l+1, l-1]       
                end

            topology == "imperfectLine" ->
                cond do
                    l == 1 -> neighbor = [l+1]
                        neighbor = neighbor ++ Enum.to_list(3..max)
                    l == max -> neighbor = [l-1]
                        neighbor = neighbor ++ Enum.to_list(1..l-2)
                    true -> neighbor = [l+1, l-1]  
                        neighbor = neighbor ++ Enum.to_list(1..l-2)
                        neighbor = neighbor ++ Enum.to_list(l+2..max) 
                    end

            topology == "full" -> neighbor=Enum.to_list(1..max)

            topology == "torus" ->
                j = :math.sqrt(n) |> round
                IO.puts "in torus j = #{j}"
                neighbor = []
                # horizontal right to left
                cond do
                    #leftmost but not top or bottom
                    rem(l-1,j) == 0 && (l-j > 0) && (l - (n-j) < 0)   ->
                    neighbor = neighbor ++ [(l + j - 1), (l+1), (l-j), (l+j)]
                    
                    #rightmost but not top or bottom
                    rem(l,j) == 0 && (l-j > 0) && (l - (n-j) < 0)   ->
                    neighbor = neighbor ++ [(l - j + 1), (l-1), (l-j), (l+j)]
                    
                    #topmost but not right/leftmost
                    l-j <= 0 && (rem(l,j) != 0) && (rem(l-1,j) != 0) ->
                    neighbor = neighbor ++ [(l + j*(j-1)), (l+j), (l+1), (l-1)]
                    
                    #bottomost but not right / leftmost
                    l - (n-j) >= 0 && (rem(l,j) != 0) && (rem(l-1,j) != 0) ->
                    neighbor = neighbor ++ [(l - j*(j-1)), (l-j), (l+1), (l-1)]
                    
                    #rightmost and topmost
                    rem(l,j) == 0 && (l-j <= 0)->
                    IO.puts "rightmost and topmost"
                    neighbor = neighbor ++ [(l - j + 1), (l-1), (l+j)] #right end to left end
                    IO.inspect neighbor
                 
                    #rightmost and bottom
                    rem(l,j) == 0 && (l-(n-j) >= 0) ->
                    IO.puts "rightmost and bottom"
                    neighbor = neighbor ++ [(l - j + 1), (l-1), (l-j)] #right end to left end
                    
                    #leftmost and topmost
                    #horizontal connection left to right
                    rem(l-1,j) == 0 && (l-j <= 0)->
                    IO.puts "leftmost topmost"
                    neighbor = neighbor ++ [(l + j - 1) , (l+1), (l+j)]
                  
                    #leftmost and bottommost
                    rem(l-1,j) == 0 && (l-(n-j) >= 0)->
                    IO.puts "leftmost topmost"
                    neighbor = neighbor ++ [(l + j - 1) , (l+1), (l-j)]
                    #topmost
                    #vertical connection top to bottom
                    l-j <= 0 ->
                    IO.puts "in torus3"
                    neighbor = neighbor ++ [(l + j*(j-1)), (l+j)]
                    #neighbor = neighbor ++ (l+j)
                
                    #bottom
                    #vertical connection bottom to top
                    l - (n-j) >= 0 ->
                    IO.puts "in torus4"
                    neighbor = neighbor ++ [(l - j*(j-1)), (l-j)]
                    #neighbor = neighbor ++ (l-j)
                 
                    true -> 
                    neighbor = neighbor ++ [(l+1), (l-1), (l+j), (l-j)]
                    
                
                 end
               
                    

            topology == "2D" or topology == "imp2D" ->
                
                j = :math.sqrt(n) |> round
                IO.puts "j = #{j}"
                neighbor = []
                if rem(l,j) == 0 do
                    IO.puts "here1"
                    neighbor = neighbor ++ (l+1)
                end
                if rem(l+1,j) do
                    IO.puts "here2"
                    neighbor = neighbor ++ (l-1)
                    IO.inspect neighbor
                end
                if l-j<0 do
                    IO.puts "here3"
                    neighbor = neighbor ++ (l+j)
                    IO.inspect neighbor
                end
                if l - (n-j) >= 0 do
                    IO.puts "here4"
                    neighbor = neighbor ++ (l-j)
                end
                if n > 4 do
                    IO.puts "here5"
                    IO.inspect neighbor
                    if rem(l,j) != 0 and rem(l+1,j) != 0 do
                        neighbor = neighbor ++ [(l-1), (l+1)]
                        IO.inspect neighbor
                        #neighbor = neighbor ++ (l+1)
                    end
                    if l-j>0 and l - (n-j) <0 do
                        neighbor = neighbor ++ [(l+j), (l-j)]
                        #neighbor = neighbor ++ (l-j)
                    end
                    if l == j do
                        neighbor = neighbor ++ [(l-j), (l+j)]
                        #neighbor = neighbor ++ (l+j)
                    end
                end
                if topology == "imp2D" do
                    rnd = imp2Dloop(n, neighbor, l)
                    neighbor = neighbor ++ [rnd]
                end
                IO.inspect neighbor
                neighbor
            
            true -> "Select a valid topology"
        end
    end

    def main(topology, numNodes, nodeId) do
        nodeList = select_topology(topology, numNodes, nodeId)
        IO.inspect nodeList
    end
end
