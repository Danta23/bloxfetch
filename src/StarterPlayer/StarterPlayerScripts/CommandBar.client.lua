--[[
    CommandBar.lua (LocalScript)
    
    This script is responsible for:
    1. Creating a simple command bar GUI at the bottom of the screen.
    2. Listening for keyboard shortcuts (Ctrl+Enter to show, Ctrl+Q to hide) 
       and 'Enter' key press (FocusLost) on the TextBox.
    3. Executing commands: 'bloxfetch', 'echo', 'ls', 'dir', 'cls', 'help', 
       'cat', 'cd', and 'exit'.
    4. Includes smooth tweening for showing/hiding the UI.
    
    Rojo Path: src/StarterPlayerScripts/CommandBar.lua
    Roblox Path: StarterPlayerScripts/CommandBar
    
    CHANGELOG:
    - Fixed the 'exit' command causing a 'nil value' error by returning early 
      from handleCommand after calling toggleCommandBar(false).
    - **NEW: Added functionality to hide the Developer Console when 'exit' is typed.**
    - Fixed the 'ReleaseFocus' error by calling it directly on the TextBox.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService") 

-- Ensure the BloxFetch module is available
local BloxFetch = require(ReplicatedStorage:WaitForChild("BloxFetch"))

-- --- History Management ---
local commandHistory = {} -- Stores executed commands
local historyIndex = 0    -- Index for cycling through history (0 = newest/no history selected)

-- NEW: Directory/Path Management
-- CWD is always stored as the GetFullName() path relative to the DataModel ('game.')
local currentDirectoryPath = "Workspace" -- Initial CWD path, starting in Workspace for convenience

-- --- Tween Configuration ---

local TWEEN_INFO = TweenInfo.new(
	0.4, -- Duration of the animation (0.4 seconds)
	Enum.EasingStyle.Quart, 
	Enum.EasingDirection.Out
)

-- Define Target Positions (Frame height is 50px)
local VISIBLE_POS = UDim2.new(0.5, 0, 1, -10) -- Centered at the bottom, 10px up
local HIDDEN_POS = UDim2.new(0.5, 0, 1, 60)   -- Centered at the bottom, 60px down (off-screen)

-- --- GUI Creation ---

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BloxFetchCommandBarGui"
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10 
screenGui.Enabled = false -- Start hidden
-- Parent the GUI to the player's PlayerGui on load
local player = Players.LocalPlayer
if player then
	screenGui.Parent = player:WaitForChild("PlayerGui")
else
	screenGui.Parent = StarterGui
end

local frame = Instance.new("Frame")
frame.Name = "CommandFrame"
frame.Size = UDim2.new(1, 0, 0, 50) 
frame.AnchorPoint = Vector2.new(0.5, 1)
frame.Position = HIDDEN_POS 
frame.BackgroundTransparency = 1 
frame.Parent = screenGui

local textBox = Instance.new("TextBox")
textBox.Name = "CommandInput"
textBox.Size = UDim2.new(1, -40, 1, -20) 
textBox.Position = UDim2.new(0.5, 0, 0.5, 0) 
textBox.AnchorPoint = Vector2.new(0.5, 0.5)

-- UPDATED: Placeholder text now includes new commands
textBox.PlaceholderText = "Type 'help' for commands (cd, cat, ls, dir, exit, bloxfetch)"
textBox.Text = ""
textBox.TextSize = 18
textBox.Font = Enum.Font.SourceSans
textBox.TextColor3 = Color3.new(1, 1, 1)
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.TextYAlignment = Enum.TextYAlignment.Center
textBox.ClearTextOnFocus = false
-- Styling for Transparency and Background
textBox.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1) 
textBox.BackgroundTransparency = 0.4 
textBox.BorderSizePixel = 0
textBox.Parent = frame

-- Add UICorner for rounded edges (child of the TextBox)
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10) 
uiCorner.Parent = textBox

-- --- Command Definitions and Logic (Implemented locally) ---

local COMMAND_BLOXTCH = "bloxfetch"
local COMMAND_ECHO = "echo"
local COMMAND_LS = "ls"
local COMMAND_CLS = "cls" 
local COMMAND_HELP = "help" 
local COMMAND_CAT = "cat"   -- NEW
local COMMAND_CD = "cd"     -- NEW
local COMMAND_EXIT = "exit" -- NEW
local COMMAND_DIR = "dir"   -- NEW
local BLOXFETCH_VERSION = "1.1.0" 

-- Utility to safely find an instance based on a path string (absolute or relative to CWD)
local function resolveInstance(path)
	local fullPath = path

	-- 1. Handle special relative paths ('', '.', '..')
	if path == "" or path == "." then
		fullPath = currentDirectoryPath
	elseif path == ".." then
		local parts = currentDirectoryPath:split(".")
		-- Only allow moving up if not at the root (game)
		if #parts > 1 and parts[1] ~= "game" then
			table.remove(parts)
			fullPath = table.concat(parts, ".")
		else
			fullPath = parts[1] or "game" -- Stay at the top level
		end
	elseif not path:match("^[A-Z]") and not path:match("^game") then
		-- 2. Relative path resolution (prepend CWD)
		fullPath = currentDirectoryPath .. "." .. path
	end

	-- 3. Now, resolve the determined absolute/service path
	local current = game
	local pathParts = fullPath:split(".")

	-- Skip the "game" root part if present and we start from game
	if pathParts[1] == "game" then
		table.remove(pathParts, 1)
	end

	for i, partName in ipairs(pathParts) do
		if partName == "" then continue end

		local child = current:FindFirstChild(partName)

		-- Try GetService only for the first part if starting at the DataModel ('game')
		if not child and current == game and i == 1 and game:GetService(partName) and partName:match("^[A-Z]") then
			child = game:GetService(partName)
		end

		if not child then
			return nil
		end
		current = child
	end

	return current
end

-- Function to handle changing directory (cd)
local function changeDirectory(path)
	-- If no path is given, show current directory
	if path == "" or path == "." then
		return string.format("Current Directory: %s", currentDirectoryPath)
	end

	local targetInstance = resolveInstance(path)

	if targetInstance and targetInstance:IsA("Instance") then
		local newPath = targetInstance:GetFullName()

		-- Clean up path (e.g., "game.Workspace" -> "Workspace")
		if newPath:sub(1, 5) == "game." then
			newPath = newPath:sub(6)
		end

		-- Update the CWD
		currentDirectoryPath = newPath

		return string.format("Changed directory to: %s", currentDirectoryPath)
	else
		return string.format("Error: Directory '%s' not found.", path)
	end
end

-- Function to handle reading properties (cat)
local function readInstanceProperties(path)
	local targetInstance = resolveInstance(path)

	if not targetInstance then
		return string.format("Error: File/Instance '%s' not found relative to '%s'.", path, currentDirectoryPath)
	end

	local output = {string.format("Properties of: %s (%s)", targetInstance.Name, targetInstance.ClassName)}
	table.insert(output, "------------------------------")

	-- Common properties
	table.insert(output, string.format("  CWD: %s", currentDirectoryPath))
	table.insert(output, string.format("  Name: %s", targetInstance.Name))
	table.insert(output, string.format("  ClassName: %s", targetInstance.ClassName))
	table.insert(output, string.format("  Parent: %s", targetInstance.Parent and targetInstance.Parent.Name or "nil"))
	table.insert(output, string.format("  Children Count: %d", #targetInstance:GetChildren()))

	-- Specific properties (examples)
	if targetInstance:IsA("BasePart") then
		table.insert(output, string.format("  Position: %s", tostring(targetInstance.Position)))
		table.insert(output, string.format("  Anchored: %s", tostring(targetInstance.Anchored)))
	elseif targetInstance:IsA("TextBox") or targetInstance:IsA("TextLabel") or targetInstance:IsA("TextButton") then
		local text = targetInstance.Text
		table.insert(output, string.format("  Text: '%s'", text:sub(1, 50) .. ( #text > 50 and "..." or "" ))) -- Truncate long text
	elseif targetInstance:IsA("StringValue") or targetInstance:IsA("NumberValue") or targetInstance:IsA("IntValue") then
		table.insert(output, string.format("  Value: %s", tostring(targetInstance.Value)))
	end

	return table.concat(output, "\n")
end


-- Function to list assets (for 'ls' or 'dir' command) - Adapted to use CWD
local function listAssets(targetPath)
	local path = targetPath or "."

	local targetInstance = resolveInstance(path)
	if not targetInstance then
		return string.format("Error: Directory or Service path '%s' not found relative to '%s'.", path, currentDirectoryPath)
	end

	local output = {
		string.format("CWD: %s", currentDirectoryPath),
		string.format("Listing contents of: %s (%s)", targetInstance:GetFullName(), targetInstance.ClassName)
	}

	local showHidden = false
	local showDetails = false

	if path == "-a" then
		showHidden = true
		path = "."
	elseif path == "-l" then
		showDetails = true
		path = "."
	elseif path == "-la" or path == "-al" then
		showHidden = true
		showDetails = true
		path = "."
	end

	local children = targetInstance:GetChildren()
	if #children == 0 then
		table.insert(output, "  (Empty)")
	else
		for _, child in ipairs(children) do
			-- Skip hidden if not showing
			if not showHidden and child.Name:sub(1,1) == "." then
				-- just skip this iteration
			else
				if showDetails then
					table.insert(output, string.format("  [%s] %s - Size: %d children", child.ClassName, child.Name, #child:GetChildren()))
				else
					table.insert(output, string.format("  [%s] %s", child.ClassName, child.Name))
				end
			end
		end
	end

	return table.concat(output, "\n")
end

-- NEW: Help command implementation
local function getHelpMessage()
	local helpText = {
		"BloxFetch Command Bar Help:",
		"------------------------------",
		"bloxfetch (-v | --version) : Displays system information (like 'neofetch').",
		"echo <message>             : Prints the specified message to the console.",
		"ls [path] / dir [path]     : Lists the children of an instance. Defaults to CWD.",
		"cd [path]                  : Changes the Current Working Directory (CWD). Use '.' for CWD, '..' for parent.",
		"cat <path>                 : Reads and displays common properties of an instance ('file').",
		"cls                        : Clears the Developer Console output log.",
		"exit                       : Closes the command bar AND the Developer Console.", -- Updated description
		"whoami                     : Show current user",
		"uname -a                   : Show system info",
		"df -h                      : Show disk usage",
		"pwd                        : Show current directory path",
		"ps aux                     : Show all running processes",
		"help                       : Displays this list of commands.",
		"",
		"Shortcuts:",
		"Ctrl + Enter: Toggle / Focus Command Bar",
		"Ctrl + Q / Esc: Hide Command Bar",
		"Up / Down Arrow: Cycle through command history"
	}
	return table.concat(helpText, "\n")
end


-- Utility to split command and arguments by space
local function parseCommand(input)
	-- Tokenize by space, trimming initial/final whitespace from the whole string
	local tokens = {}
	local trimmedInput = input:gsub("^%s*(.-)%s*$", "%1")

	-- Use gmatch to find non-space sequences
	for token in trimmedInput:gmatch("%S+") do
		table.insert(tokens, token)
	end
	return tokens
end


local function handleCommand(inputString)
	local tokens = parseCommand(inputString)
	if #tokens == 0 then return end -- Empty command

	local primaryCommand = tokens[1]:lower()
	local argument = tokens[2] or ""

	local outputMessage = nil

	if primaryCommand == COMMAND_BLOXTCH then
		local flag = argument:lower() or nil

		if flag == "--version" or flag == "-v" then
			outputMessage = string.format("BloxFetch Module Version: %s", BLOXFETCH_VERSION)
		elseif argument == "" then
			outputMessage = BloxFetch.getInfo()
		else
			outputMessage = string.format("Error: Unknown flag '%s' for command '%s'. Supported flags: --version (-v)", flag, primaryCommand)
		end

	elseif primaryCommand == COMMAND_ECHO then
		-- Handle echo command locally
		local commandLength = #COMMAND_ECHO
		-- Find the position right after the 'echo' command and skip any subsequent spaces
		local messageStart = inputString:find(COMMAND_ECHO, 1, true) + commandLength
		local message = inputString:sub(messageStart):gsub("^%s*", "") -- Get substring and remove leading space

		outputMessage = message

	elseif primaryCommand == COMMAND_LS or primaryCommand == COMMAND_DIR then -- LS / DIR
		outputMessage = listAssets(argument)

	elseif primaryCommand == COMMAND_CD then -- CD (Change Directory)
		outputMessage = changeDirectory(argument)

	elseif primaryCommand == COMMAND_CAT then -- CAT (Read Properties)
		if argument == "" then
			outputMessage = "Error: 'cat' requires an instance path (e.g., cat Camera)."
		else
			outputMessage = readInstanceProperties(argument)
		end

	elseif primaryCommand == COMMAND_CLS then 
		-- Print 50 newlines to push previous output off the Developer Console screen
		local clearLines = string.rep("\n", 50)
		outputMessage = clearLines .. "\n== Developer Console Log Cleared =="

	elseif primaryCommand == COMMAND_HELP then 
		outputMessage = getHelpMessage()


	elseif primaryCommand == "whoami" then
		outputMessage = "Current User: " .. player.Name

	elseif primaryCommand == "uname" and argument == "-a" then
		outputMessage = [[RobloxOS 1.0.0 (Simulated) - Kernel v1.2.3 - x86_64]]

	elseif primaryCommand == "df" and argument == "-h" then
		outputMessage = [[Filesystem      Size  Used Avail Use% Mounted on
gamefs          512M  128M  384M  25% /
workspacefs     1G    256M  744M  26% /Workspace]]

	elseif primaryCommand == "pwd" then
		outputMessage = "Current Directory: " .. currentDirectoryPath

	elseif primaryCommand == "ps" and argument == "aux" then
		outputMessage = [[USER       PID %CPU %MEM COMMAND
roblox     1001  0.3  1.2  CommandBar
roblox     1002  0.1  0.5  TweenService
roblox     1003  0.0  0.3  UserInputService]]
	elseif primaryCommand == COMMAND_EXIT then -- EXIT (Close Command Bar)
		-- NEW FIX: Turn off the Developer Console
		StarterGui:SetCore("DevConsoleVisible", false)
		return -- CRITICAL FIX: Return immediately after closing the bar to prevent nil value error

	else
		outputMessage = string.format("Error: Unknown command '%s'. Type 'help' for supported commands.", primaryCommand)
	end

	if outputMessage then
		-- Open the console and print the message
		StarterGui:SetCore("DevConsoleVisible", true)
		print("====================== COMMAND OUTPUT ======================")
		print(outputMessage)
		print("============================================================")
	end
end

-- --- Event Connection ---

textBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local input = textBox.Text
		local trimmedInput = input:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace

		if #trimmedInput > 0 then
			-- Store command history only if input is not empty
			table.insert(commandHistory, trimmedInput)
			-- Reset index to allow user to start from the end of history
			historyIndex = #commandHistory 
		end

		handleCommand(input)
		textBox.Text = "" -- Clear the input after execution
		textBox:CaptureFocus() -- Recapture focus
	end
end)


-- --- Tweening Logic for Toggling Visibility ---

local function tweenFrame(targetPosition, onComplete)
	local tween = TweenService:Create(frame, TWEEN_INFO, {Position = targetPosition})
	if onComplete then
		tween.Completed:Once(onComplete)
	end
	tween:Play()
	return tween
end


local function toggleCommandBar(shouldBeVisible)
	if shouldBeVisible == nil then
		-- Only proceed if the state is changing
		if screenGui.Enabled == true then 
			shouldBeVisible = false 
		else
			shouldBeVisible = true
		end
	end

	if shouldBeVisible and not screenGui.Enabled then
		-- SHOW LOGIC: Enable GUI, then slide up and capture focus
		screenGui.Enabled = true
		-- Display CWD as prompt when showing
		textBox.Text = "" 
		textBox.PlaceholderText = string.format("CWD: %s > ", currentDirectoryPath)

		-- Slide frame up to VISIBLE_POS
		tweenFrame(VISIBLE_POS, function()
			-- After animation is complete, capture focus
			textBox:CaptureFocus() 
		end)

	elseif not shouldBeVisible and screenGui.Enabled then
		-- HIDE LOGIC: Release focus (on the TextBox), slide down, then disable GUI

		-- FIX: Use ReleaseFocus on the TextBox instance
		textBox:ReleaseFocus() 
		textBox.Text = "" 
		-- Reset placeholder text
		textBox.PlaceholderText = "Type 'help' for commands (cd, cat, ls, dir, exit, bloxfetch)"

		-- Slide frame down to HIDDEN_POS
		tweenFrame(HIDDEN_POS, function()
			-- After animation is complete, disable the screenGui
			screenGui.Enabled = false
		end)
	end
end

-- Input handler for shortcuts and history
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)

	-- Check for command bar visibility/focus
	if screenGui.Enabled then
		-- Update placeholder prompt on every key press to keep it current
		textBox.PlaceholderText = string.format("CWD: %s > ", currentDirectoryPath)

		if input.KeyCode == Enum.KeyCode.Up then
			-- Handle UP arrow for history (move backward)

			if gameProcessedEvent then return end 

			if #commandHistory > 0 and historyIndex > 1 then
				historyIndex = historyIndex - 1
				textBox.Text = commandHistory[historyIndex]
			end
			return -- Consume the input

		elseif input.KeyCode == Enum.KeyCode.Down then
			-- Handle DOWN arrow for history (move forward)

			if gameProcessedEvent then return end 

			if historyIndex < #commandHistory then
				historyIndex = historyIndex + 1
				textBox.Text = commandHistory[historyIndex]
			elseif historyIndex == #commandHistory then
				-- If at the last command, moving down clears the text (ready for new input)
				historyIndex = #commandHistory + 1
				textBox.Text = ""
			end
			return -- Consume the input

		elseif input.KeyCode == Enum.KeyCode.Escape then
			-- Use Escape to close the bar when it's open, regardless of focus status
			toggleCommandBar(false)
			return -- Consume the input
		end
	end

	-- Check for control shortcuts
	if gameProcessedEvent then return end

	local isControlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)

	if isControlDown then
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
			-- Ctrl + Enter (or Keypad Enter) -> Show/Focus
			if not screenGui.Enabled then
				toggleCommandBar(true)
			end
		elseif input.KeyCode == Enum.KeyCode.Q then
			-- Ctrl + Q -> Hide/Close
			if screenGui.Enabled then
				toggleCommandBar(false)
			end
		end
	end
end)

print("BloxFetch Command Bar initialized with smooth transition. Use Ctrl+Enter to toggle.")