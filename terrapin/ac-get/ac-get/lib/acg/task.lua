-- lint-mode: ac-get

Task = {}

function Task:init(state, id, steps)
  self.id = id

  self.steps = steps or 0

  self.state = state

  self.state:call_hook("task_begin", id, steps)

  logger:debug("Task::init", "Beginning Task (" .. self.steps .. " steps)")
end

function Task:update(detail, prog)
  self.state:call_hook("task_update", self.id, detail, prog, self.steps)
end

function Task:error(detail)
  self.state:call_hook("task_error", self.id, detail)
  logger:error("Task::error", "Task Errored")
end

function Task:done(detail)
  self.state:call_hook("task_complete", self.id, detail or "")
  logger:debug("Task::complete", "Task Complete")
end
