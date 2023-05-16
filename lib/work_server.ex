defmodule WorkServer do
  @moduledoc """
  Manages work on a task, capping the available number of 'workers' operating concurrently.
  Work must be structured in a form where a function operates on some number of fixed 
  A single manager process conducts the management of a given task by spawning new processes when others finish.
  """
  use Task

  @doc """
  Start a task using the distributed capped process count method.

  `fun` is a function with arity 1 to be performed in each task. This function must yield a tuple structured as {result, new_tasks}, where result may be any value, and new_tasks is a list of new values for the queue.
  `queue` is the queue of tasks to perform.
  `count` is the maximum number of tasks to be spawned concurrently.
  
  Returns a list of all accumulated results.
  """
  def run_task(fun, work, count) when is_list(work), do: manager(fun, work, count)
  def run_task(fun, work, count), do: run_task(fun, [work], count)

  @doc """
  Work manager.

  `fun` is a function with arity 1 to be performed in each task. This function must yield a tuple structured as {result, new_tasks}, where result may be any value, and new_tasks is a list of new values for the queue.
  `queue` is the queue of tasks to perform.
  `count` is the maximum number of tasks to be spawned concurrently.
  `tasks` is the list of ongoing tasks being performed.
  `res` is the accumulated list of results.

  Returns a list of all accumulated results.
  """
  defp manager(fun, queue, count), do: manager(fun, queue, count, [], [])
  defp manager(_, [], _, [], res), do: res
  defp manager(fun, queue, count, tasks, res) when count == length(tasks) or queue == [] do # Check progress if task limit is reached or queue is empty
    val = Task.yield_many(tasks)
    done = val
             |> Enum.filter(fn {_, {:ok, _}} -> true
                               _             -> false
                            end)
    
    manager(fun,
            (done |> Enum.reduce([], fn {_, {_, {_, next}}}, acc -> next ++ acc end)) ++ queue,
            count,
            val
              |> Enum.filter(fn {_, {:ok, _}} -> false
                                _             -> true
                             end)
              |> Enum.map(fn {task, _} -> task end),
            (done |> Enum.filter(fn {_, {_, {r, _}}} -> r != :cont and r != :error end) |> Enum.map(fn {_, {_, {r, _}}} -> r end)) ++ res)
  end
  defp manager(fun, queue, cnt, tasks, res) do
    manager(fun,
            queue |> Enum.drop(cnt-length(tasks)),
            cnt,
            queue
              |> Enum.take(cnt-length(tasks))
              |> Enum.map(fn t -> Task.async(fn -> fun.(t) end) end),
            res)
  end
end
