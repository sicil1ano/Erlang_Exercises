-module (job_centre).

-behaviour (gen_server).
-export ([start_link/0]).

%%gen_server callbacks
-export ([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).
-define (SERVER, ?MODULE).

%%interface routines
start_link() -> 
	gen_server:start_link({local, ?SERVER}, ?MODULE, [], []),
	counter:start().

stop() -> gen_server:call(?MODULE, stop).

add_job(Job) -> gen_server:call(?MODULE, {add, Job}).

work_wanted() -> gen_server:call(?MODULE, {work_wanted, self()}).

job_done(JobNumber) -> gen_server:call(?MODULE, {done, JobNumber, self()}).

%%callback routines
init([]) -> {ok, ets:new(?MODULE, [ordered_set, named_table])}.

handle_call({add, Job}, _From, Tab) ->
	Reply = case ets:lookup(Tab, Job) of
				[] -> 	JobCounter = counter:increment(),
						ets:insert_new(Tab, {JobCounter,Job,no_worker_assigned,to_do}),
						{new_job_number,JobCounter};
				[_] -> {Job, job_already_exists}
			end,
	{reply, Reply, Tab};

handle_call({work_wanted, Worker}, _From, Tab) ->
	Reply = case ets:first(Tab) of
				'$end_of_table' -> {Worker, no_job_to_assign}; %%check if table is empty..
				_ -> 
					case ets:match_object(Tab,{'$1','_','no_worker_assigned','to_do'}) of
						[] -> {Worker, no_job_to_assign};
						[{JobNumber,_,_,_}|_] -> 
							ets:update_element(Tab,JobNumber,{3,Worker}),
							{job_assigned,JobNumber,Worker}
					end					
			end,
	{reply, Reply, Tab};

handle_call({done, JobNumber, Worker}, _From, Tab) ->
	Reply = case ets:lookup(Tab, JobNumber) of
				[] -> {Worker, no_job_found};
				[{JobNumber, _, _, to_do}] -> 
					ets:update_element(Tab, JobNumber, {4, done}),
					{job_done, Worker, job_done}
			end,
	{reply, Reply, Tab};

handle_call(stop, _From, Tab) -> {stop, normal, stopped, Tab}.

handle_cast(_Msg, State) -> {noreply, State}.

handle_info(_Info, State) -> {noreply, State}.

terminate(_Reason, _State) -> ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.