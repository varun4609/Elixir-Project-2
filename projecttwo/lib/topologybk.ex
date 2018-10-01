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

            topology == "random2D" ->
                
                limit = :math.sqrt(n)
                dig = :math.log(limit)/ :math.log(10)
                granularity = :math.pow(10,dig)
                
                IO.puts "here"

            topology == "3D" ->
                limit = :math.pow(n, 1/3) |> round
                twoDlim = limit * limit
                temp = []
                temp = 
                   
                cond do
                    #leftmost but not top or bottom 
                    
                    rem(rem((l - 1) , limit), limit) == 0 && (rem(l,twoDlim) - limit > 0) && (rem(l,twoDlim) - (twoDlim - limit) <= 0)  ->
                        IO.puts "leftmost but not top or bottom"
                        temp =temp ++ [(l+limit), (l-limit), (l+1)]
                       # [(l+limit), (l-limit), (l+1)]

                    #rightmost but not top or bottom
                    
                    rem(l ,limit) == 0 && (rem(l, twoDlim) - limit > 0) && (rem(l, twoDlim) - (twoDlim - limit) <= 0)  ->
                        IO.puts "rightmost but not top or bottom"
                        temp = temp ++ [(l - 1), (l + limit), (l - limit)]
                                           
                    #topmost but not right/leftmost
                    
                    rem(l, twoDlim) - limit <= 0 && (rem(l,limit) != 0) && (rem(rem((l-1), limit), limit) != 0) && (rem(l,twoDlim) - (twoDlim - limit) <= 0) ->
                        IO.puts "topmost but not right/leftmost"
                        temp = temp ++ [(l + 1), (l - 1), (l + limit)]
                   
                    #bottomost but not right / leftmost
                    
                    (rem(l, twoDlim) - (twoDlim - limit) > 0) && (rem(l,limit) != 0) && (rem(rem((l-1), limit), limit) != 0) ->
                        IO.puts "bottomost but not right / leftmost"
                        temp = temp ++ [(l - limit), (l + 1), (l - 1)]
                                        
                    #leftmost and topmost
                    
                    rem(rem((l - 1), limit), limit) == 0 && rem(l, twoDlim) - limit <= 0 && (rem(l,twoDlim) - (twoDlim - limit) <= 0) ->
                        IO.puts "leftmost and topmost #{limit}"
                        temp = temp ++ [(l + 1), (l + limit) ]
                      IO.inspect temp                    
                    #righttmost  and topmost 
                    
                    rem(l ,limit) == 0 && (rem(l, (twoDlim+1) )- limit <= 0) && (rem(l,twoDlim) - (twoDlim - limit) <= 0)->
                        IO.puts "righttmost  and topmost"
                    temp ++ [(l - 1), (l + limit)]

                    #leftmost and bottommost 
                    
                    rem(rem((l - 1), limit), limit) == 0 && (rem(l, twoDlim) - (twoDlim - limit) > 0) ->
                        IO.puts "leftmost and bottommost "
                        temp ++ [(l - limit), (l + 1) ]
                    #[(l - limit), (l + 1) ]
                    #rightmost and bottom
                    rem(l ,limit) == 0 && (rem(l, twoDlim+1) - (twoDlim - limit) > 0) ->
                        IO.puts "rightmost and bottom"
                    temp ++ [(l - 1), (l - limit)]
                                        
                    true ->
                     [(l - 1), (l + 1), (l - limit), (l + limit)]
                end
                neighbor =
                cond do
                    #front
                    l <= twoDlim  ->
                    temp ++ [(l + twoDlim)]

                    #back
                    l > (twoDlim * (limit - 1) ) ->
                    temp ++ [(l - twoDlim)]
                    
                    true ->
                    temp ++ [(l + twoDlim), (l - twoDlim)]      
                end
                neighbor
            topology == "torus" ->
                j = :math.sqrt(n) |> round
                IO.puts "in torus j = #{j}"
                neighbor = []
                # horizontal right to left
                neighbor =
                cond do
                    #leftmost but not top or bottom
                    rem(l-1,j) == 0 && (l-j > 0) && (l - (n-j) <= 0)   ->
                    neighbor ++ [(l + j - 1), (l+1), (l-j), (l+j)]
                    
                    #rightmost but not top or bottom
                    rem(l,j) == 0 && (l-j > 0) && (l - (n-j) <= 0)   ->
                    neighbor ++ [(l - j + 1), (l-1), (l-j), (l+j)]
                    
                    #topmost but not right/leftmost
                    l-j <= 0 && (rem(l,j) != 0) && (rem(l-1,j) != 0) ->
                    neighbor ++ [(l + j*(j-1)), (l+j), (l+1), (l-1)]
                    
                    #bottomost but not right / leftmost
                    l - (n-j) >= 0 && (rem(l,j) != 0) && (rem(l-1,j) != 0) ->
                    neighbor ++ [(l - j*(j-1)), (l-j), (l+1), (l-1)]
                    
                    #rightmost and topmost
                    rem(l,j) == 0 && (l-j <= 0)->
                    IO.puts "rightmost and topmost"
                    neighbor ++ [(l - j + 1), (l-1), (l+j)] #right end to left end
                    IO.inspect neighbor
                 
                    #rightmost and bottom
                    rem(l,j) == 0 && (l-(n-j) > 0) ->
                    IO.puts "rightmost and bottom"
                    neighbor ++ [(l - j + 1), (l-1), (l-j)] #right end to left end
                    
                    #leftmost and topmost
                    #horizontal connection left to right
                    rem(l-1,j) == 0 && (l-j <= 0)->
                    IO.puts "leftmost topmost"
                    neighbor ++ [(l + j - 1) , (l+1), (l+j)]
                  
                    #leftmost and bottommost
                    rem(l-1,j) == 0 && (l-(n-j) > 0)->
                    IO.puts "leftmost topmost"
                    neighbor ++ [(l + j - 1) , (l+1), (l-j)]
                    #topmost
                    #vertical connection top to bottom
                    l-j <= 0 ->
                    IO.puts "in torus3"
                    neighbor ++ [(l + j*(j-1)), (l+j)]
                    #neighbor = neighbor ++ (l+j)
                
                    #bottom
                    #vertical connection bottom to top
                    l - (n-j) >= 0 ->
                    IO.puts "in torus4"
                    neighbor ++ [(l - j*(j-1)), (l-j)]
                    #neighbor = neighbor ++ (l-j)
                 
                    true -> 
                    neighbor ++ [(l+1), (l-1), (l+j), (l-j)]
                    
                
                 end
                 neighbor  
                           

            
                end
              
         #cond select topology

         
        
        
    end
    
    def main(topology, numNodes, nodeId) do
       # cond do 
       #     topology == "3D" ->
       #     limit = :math.pow(numNodes, (1/3)) |> round
       #     x = :rand.uniform(limit)
       #     y = :rand.uniform(limit)
       #     z = :rand.uniform(limit)
       #     nodeList = threeD(topology, numNodes, x,y,z)  
       #     IO.inspect nodeList
       #     true ->
            nodeList = select_topology(topology, numNodes, nodeId)
            IO.inspect nodeList
      #end
        
    end
end