-module (counter).
-export ([start/0, increment/0]).

start() -> register(counter,spawn(fun() -> loop(0) end)).

increment() -> 
	counter ! {incr_counter,self()},
	receive
		{count,Counter} -> Counter
	end.

loop(Counter) ->
	receive
		{incr_counter,Pid} -> 
			NewCounter = (Counter +1),
			Pid ! {count,NewCounter},
			loop(NewCounter);
		_ -> loop(Counter)
	end.