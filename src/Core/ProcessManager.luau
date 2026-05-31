const Process = require(script.Parent.Process)
const Output = require(script.Parent.Output)

const ProcessManager = {
    current = nil :: Process.Class?,
}

const function AssertCanStart(process: Process.Class): ()
    if ProcessManager.current ~= nil and ProcessManager.current:IsAlive() then
        error(`Process with id "{ProcessManager.current.id}" is still running.`)
    end
end

function ProcessManager.start(process: Process.Class): Process.Class
    AssertCanStart(process)

    ProcessManager.current = process

    process:Start()
    process._params.fnBeforeExit = function(): ()
        if process._params.fnBeforeExit then
            process._params.fnBeforeExit()
        end

        process:Destroy()
        ProcessManager.current = nil
    end

    return process
end

function ProcessManager.kill(): ()
    if ProcessManager.current ~= nil then
        ProcessManager.current:Kill()
    end
end

function ProcessManager.maybeExitThis(onExit: (() -> ())?): ()
    if ProcessManager.current == nil then
        return
    end

    if ProcessManager.current._shouldExit == true then
        Output.print(`Process with id "{ProcessManager.current.id}" was terminated.`)
        if onExit then onExit() end
        coroutine.yield()
    end
end

return ProcessManager