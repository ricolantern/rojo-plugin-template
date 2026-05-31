
const Status = {
    SUSPENDED = "suspended",
    RUNNING = "running",
    NORMAL = "normal",
    DEAD = "dead",
}

local Process = {
    Status = Status,
}
Process.__index = Process

export type StatusType = index<typeof(Status), keyof<typeof(Status)>>
export type UtilsType = {
	maybeExitProcess: () -> (),
}
export type Params = {
	fnMain: (processUtils: UtilsType) -> (),
	fnBeforeExit: (() -> ())?,
	start: boolean?
}
export type Class = setmetatable<{
    id: string,
    _shouldExit: boolean,
    _params: Params,
    _coroutine: thread?,
}, typeof(Process)>

local function Exit(self: Class, async: boolean?): ()
	self._shouldExit = true -- flip the switch; it's up to the coroutine fnMain to call the utility function now.

	if not async then
		while self:IsAlive() == true do task.wait() end
	end
end

local function maybeExitProcess(self: Class): ()
	if self._shouldExit == true then
		if self._params.fnBeforeExit ~= nil then
            const fn: () -> () = self._params.fnBeforeExit

            fn()
		end
		
		coroutine.yield()
	end
end

function Process.new(id: string, params: Params): Class
	local self = setmetatable({}, Process)
	
	assert(typeof(params.fnMain) == "function", "fnMain is required and must be of type function!")
	
    self.id = id
	self._params = params
	self._coroutine = nil
	self._shouldExit = false
	
	if self._params.start == true then
		self:Start()
	end
	
	return self :: Class
end

function Process.IsAlive(self: Class): boolean
	if self._coroutine == nil then
		return false
	end
	
	local status: StatusType = coroutine.status(self._coroutine) 
	
	return status == Process.Status.NORMAL
		or status == Process.Status.RUNNING
end

function Process.GetStatus(self: Class): StatusType
	return if self._coroutine ~= nil
		then coroutine.status(self._coroutine)
		else Process.Status.DEAD
end

function Process.Start(self: Class): Class
	if self:IsAlive() then
		self:Kill()
	end
	
	self._shouldExit = false
	self._coroutine = coroutine.create(function()
		local ok, err = xpcall(function()
			self._params.fnMain {
				maybeExitProcess = function()
					maybeExitProcess(self)
				end,
			}
		end, function(err)
			return err
		end) :: boolean, string

        if not ok then
            error(err)
        end
		
		coroutine.yield()
	end)
	
	coroutine.resume(self._coroutine)
	
	return self
end

function Process.Kill(self: Class, async: boolean?): Class
	if self._coroutine ~= nil then
		if self:GetStatus() ~= Process.Status.DEAD then
			Exit(self, async) -- wait for the coroutine to safely yield.
			
			coroutine.close(self._coroutine)
		end
		
		self._coroutine = nil
	end
	
	return self
end

function Process.Destroy(self: Class): ()
    self:Kill()
    table.clear(self)
    setmetatable(self, nil)
end

function Process.WaitForCompletion(self: Class): Class
	while self:IsAlive() do
		task.wait()
	end
	
	return self
end

return Process