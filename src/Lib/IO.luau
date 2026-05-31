const StudioService = game:GetService("StudioService")
const HttpService = game:GetService("HttpService")
const ScriptEditorService = game:GetService("ScriptEditorService")
const SelectionService = game:GetService("Selection")

const WRITE_SIZE_LIMIT = 10_000 -- writing very large text is extremely slow, so we do it in chunks of max this size.
const WAIT_SLEEP_RANGE = NumberRange.new(1, 2)
const EXPORT_SPLIT_AT = 150 -- split export into another one if chunks succeed this number.
const MB_LIMIT = 100

local ProcessManager = require(script.Parent.ProcessManager)
const Output = require(script.Parent.Output)

local IO = {}

-- rid string of invalid utf8.
local function PreParseString(content: string): string
	while true do
		local _, invalidPos = utf8.len(content)

		if not invalidPos then
			break
		end

		-- remove the single invalid byte
		content = string.sub(content, 1, invalidPos - 1) .. string.sub(content, invalidPos + 1)
	end

	return content
end

local function GetContentChunkN(content: string): number
	return math.ceil(#content / WRITE_SIZE_LIMIT)
end

local function PromptImportFiles(fileTypes: {string}): {any}?
	local files = StudioService:PromptImportFilesAsync(fileTypes) :: {File}?

	if files == nil or files[1] == nil or #files == 0 then
		Output.print(`Import failed. Make sure their sizes are less than {MB_LIMIT} megabytes.`)

		return nil
	end
	
	return files
end

function IO.getDTString(): string
	local now: DateTime = DateTime.now()
	local localeId: string = StudioService.StudioLocaleId

	return now:FormatLocalTime("YYYYMMDD_HHmmss", localeId)
end

function IO.waitRandom(): ()
	task.wait(math.random(100, 750) * 0.001)
end

function IO.waitSleep(): ()
	local dura = math.random(WAIT_SLEEP_RANGE.Min * 100, WAIT_SLEEP_RANGE.Max * 100) * 0.01
	Output.print(`...Sleeping {dura} seconds...`)
	task.wait(dura)
end

function IO.safeCall(fn: () -> ()): boolean
	local ok, err = pcall(fn)

	if not ok then
		Output.warn(err :: string)
	end

	return ok
end

function IO.getFlatTableSize(t: {any}): number
	local num: number = 0

	for _ in pairs(t) do num += 1 end

	return num
end

-- if merge is true then it'll just return 1 table with the keys and values of all files.
-- only use merge if the files you import are splices of one.
function IO.importMultiple(fileTypes: {string}, merge: boolean?): {any}?
	Output.print("Select one or more files for import.")
	
	merge = if merge == nil then false else merge

	local files: {any}? = PromptImportFiles(fileTypes)

	if files == nil then
		return nil
	end
	
	local data: {any} = {}
	
	if merge == true then
		for _, file: File in ipairs(files) do
			local contents: string = file:GetBinaryContents()
			local ok, decoded = pcall(function()
				return HttpService:JSONDecode(contents)
			end)
			
			if not ok then
				Output.warn(decoded)
				return {}
			end
			
			for k, v in pairs(decoded) do
				data[k] = v
			end

			ProcessManager.maybeExitThis()
		end
	else
		for _, file: File in ipairs(files) do
			local contents: string = file:GetBinaryContents()
			local ok, decoded = pcall(function()
				return HttpService:JSONDecode(contents)
			end)

			if not ok then
				Output.warn(decoded)
				return {}
			end
			
			table.insert(data, decoded)
			ProcessManager.maybeExitThis()
		end
	end
	
	return data
end

function IO.importFromChunks(fileTypes: {string}): {any}?
	Output.print(`Select file chunks.`)
	
	local files: {any}? = PromptImportFiles(fileTypes)
	
	if files == nil then
		return nil
	end
	
	local content: string = ""

	-- merge their contents
	for _, file: File in ipairs(files) do
		local contents = file:GetBinaryContents()

		content ..= contents

		ProcessManager.maybeExitThis()
	end

	local ok, data = pcall(function()
		return HttpService:JSONDecode(PreParseString(content))
	end)
	
	if not ok then
		Output.warn(`Failed to decode the imported chunks from JSON.\n{data}`)
		
		return nil
	end
	
	return data
end

function IO.exportRaw(content: string, fileName: string): boolean
	local temp: ModuleScript = Instance.new("ModuleScript")
	temp.Archivable = false
	temp.Name = script.Parent.Parent.Name.." Temp Export File"
	temp.Parent = game:GetService("TweenService")

	local ok, err = pcall(function()
		ScriptEditorService:UpdateSourceAsync(temp, function()
			return content
		end)
	end)
	err = err :: string

	if not ok then
		if err:find("denied") then
			Output.warn("Script injection permissions are required to export (a script must be created for export).")
			return false
		else
			Output.warn(err)
			return false
		end
	end

	Output.print(`({fileName}) Prompting save...`)

	local originalSelection = SelectionService:Get()

	SelectionService:Set({ temp })

	local exported = plugin:PromptSaveSelectionAsync(fileName)

	SelectionService:Set(originalSelection)
	temp:Destroy()

	if exported then
		Output.print(`{fileName} was exported.`)
	else
		Output.print(`Cancelled export for {fileName}`)
		return false
	end

	return true
end

function IO.exportToChunks(t: {}?, fileName: string): boolean
	local content: string = PreParseString(HttpService:JSONEncode(t))
	local numExports: number = math.ceil(GetContentChunkN(content) / EXPORT_SPLIT_AT)
	local step: number = math.floor(#content / numExports)

	for num = 1, numExports do
		local contentChunk: string = content:sub(math.min(1, step * (num - 1)), step * num)
		local temp: ModuleScript = Instance.new("ModuleScript")
		temp.Archivable = false
		temp.Name = script.Parent.Parent.Name.." Temp Export File"
		temp.Parent = game:GetService("TweenService")

		local ok, err = pcall(function()
			local len: number = #contentChunk

			if len > WRITE_SIZE_LIMIT then
				local chunks: number = GetContentChunkN(contentChunk)

				Output.print(`({fileName}) Length of {len} characters can't be written in one go; splitting it up into {chunks} portions...`)

				for i = 1, chunks do
					local slice = contentChunk:sub((i - 1) * WRITE_SIZE_LIMIT + 1, i * WRITE_SIZE_LIMIT)
					local perc = string.format("%.2f", (i/chunks) * 100):gsub("%.?0+$", "")

					Output.print(`({fileName}) Writing data to file... {perc}%`)
					ScriptEditorService:UpdateSourceAsync(temp, function(old: string)
						if i == 1 then
							return slice
						else
							return old .. slice
						end
					end)
					
					ProcessManager.maybeExitThis(function() temp:Destroy() end)
					task.wait()
				end
			else
				Output.print(`Full length of {len} characters can be written in one go...`)
				ScriptEditorService:UpdateSourceAsync(temp, function()
					return content
				end)
			end
		end)
		err = err :: string

		if not ok then
			if err:find("denied") then
				Output.warn("Script injection permissions are required to export (a script must be created for export).")
				return false
			else
				Output.warn(err)
				return false
			end
		end

		Output.print(`({fileName}) Prompting save... ({numExports - num} remaining. Exports are split to prevent crashes.)`)

		local originalSelection = SelectionService:Get()

		SelectionService:Set({ temp })

		local exported = plugin:PromptSaveSelectionAsync(`{fileName} ({num} of {numExports})`)

		SelectionService:Set(originalSelection)
		temp:Destroy()

		if exported then
			Output.print(`({fileName}) {num}/{numExports} Exported.`)
		else
			Output.print(`Cancelled export for {fileName} ({numExports} files)`)
			return false
		end
	end
	
	return true
end

return IO