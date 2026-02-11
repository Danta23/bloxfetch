--[[
    BloxFetch ModuleScript (BloxFetch.lua)

    This module gathers system and player information relevant to the current
    Roblox environment (Studio or Player) and formats it with a simple ASCII logo.

    NOTE: Due to Roblox security sandboxing, actual hardware details (CPU/GPU names)
    and external IP addresses are unavailable. This version uses simulated/fake data
    for FPS, Ping, and Memory to avoid displaying "N/A" and includes several new
    descriptive sections (Uptime, Host, Shell, etc.).
]]

local BloxFetch = {}

-- Define the Roblox ASCII Logo (Console-safe, using standard symbols)
-- We will rely on code to strip inconsistent leading/trailing whitespace.
local ROBLOX_ASCII = [[
         ##@@@###__                  
         @@@@@@@@@@@@@@###__         
        @@@@@    ....====@@@@@@@###__ 
        @@@@@          ....====@@@@@@@@@@@###__ 
      @@@@@          ....====@@@@@@@@@@@@@@@ 
      @@@@@                      ....@@@@@@- 
      @@@@@                      @@@@@@@@ 
      @@@@@      ###__            @@@@@@- 
      @@@@@      @@@@@@@@@@@##      @@@@@@ 
      @@@@@      @@@    ....@@@      @@@@@- 
     |@@@@|     |@@@      @@@|     |@@@@| 
     @@@@@      @@@@###__@@@@@      @@@@@- 
    |@@@@|      ==@@@@@@@@@@@@     |@@@@| 
    @@@@@          ....====      @@@@@ 
   |@@@@|                      |@@@@| 
   @@@@@@@###__                @@@@@ 
   ====@@@@@@@@@@@@@@@###__   |@@@@| 
        ....====@@@@@@@@@@@@@@   @@@@@ 
             ....====@@@@@@@@@@@ @@@@| 
                 ....====@@@@@@@@@@@@ 
                     ....====@@| 
]]

-- System and Roblox Constants/Services
local RunService = game:GetService("RunService")
local PlayersService = game:GetService("Players")
local Workspace = game:GetService("Workspace") -- Need Workspace to access CurrentCamera

-- Store the startup time to calculate uptime
local startTime = tick()

-- =================================================================
-- SIMULATION FUNCTIONS (Replacing reliance on potentially blocked StatsService)
--=================================================================

-- Simulated FPS (Default to a high number typical of a healthy game)
local function getSimulatedFPS()
	-- Simulate high FPS with minor jitter
	local fps = 60 + math.random(-5, 5)
	return string.format("%.1f", fps)
end

-- Simulated Memory Usage (Simulate a range of memory usage for a generic game)
local function getSimulatedMemoryUsage(baseMB)
	-- BaseMB is a rough estimate for each category
	local usage = baseMB + math.random(0, 15)
	return string.format("%.2f MB", usage)
end

-- Simulated Ping (Simulate a reasonable ping for a server connection)
local function getSimulatedPing()
	local ping = math.random(30, 80)
	return string.format("%d ms", ping)
end

-- Generate a fake but valid-looking IPv4 address
local function getFakeIPAddress()
	-- Use a non-routable private range (e.g., 10.x.x.x or 192.168.x.x) for security/realism
	local n1 = math.random(1, 254)
	local n2 = math.random(1, 254)
	local n3 = math.random(1, 254)

	-- Display as a plausible VPN or dynamic IP
	return string.format("192.168.%d.%d (Simulated)", n1, n2)
end

-- =================================================================
-- NEW METRICS AND UTILITIES
-- =================================================================

local function formatUptime()
	local uptimeSeconds = tick() - startTime
	local days = math.floor(uptimeSeconds / 86400)
	local hours = math.floor(uptimeSeconds % 86400 / 3600)
	local minutes = math.floor(uptimeSeconds % 3600 / 60)
	local seconds = math.floor(uptimeSeconds % 60)

	local output = {}
	if days > 0 then table.insert(output, days .. "d") end
	if hours > 0 or days > 0 then table.insert(output, hours .. "h") end
	if minutes > 0 or hours > 0 or days > 0 then table.insert(output, minutes .. "m") end
	table.insert(output, seconds .. "s")

	return table.concat(output, " ")
end

local function getResolution()
	if RunService:IsClient() or RunService:IsStudio() then
		-- Use CurrentCamera.ViewportSize for reliable resolution access
		local camera = Workspace.CurrentCamera
		if camera then
			local resolution = camera.ViewportSize
			return string.format("%dx%d", resolution.X, resolution.Y)
		else
			return "Camera Not Ready"
		end
	else
		return "N/A (Server)"
	end
end

-- Simulated Packages/Assets Loaded (Estimate based on standard parts/assets)
local function getSimulatedPackages()
	-- This is a very rough simulation as actual package counting is non-trivial
	local totalAssets = math.random(1500, 3500)
	return string.format("%d Assets", totalAssets)
end

-- Generates a visual representation of the color blocks using wide Unicode characters.
-- NOTE: If using a custom UI that supports RichText, the developer would manually
-- wrap each 'block' in appropriate color tags (e.g., "[color=red]████[/color]").
local function getSimulatedColorBlocks()
	local block = "████" -- Use 4 blocks per 'color'

	-- Simulating the 8-color palette block structure (Gray, Red, Green, Yellow, Blue, Magenta, Cyan, White)
	-- The actual output will be monochrome block characters, structured with spacing.
	local color_blocks = block .. " " .. block .. " " .. block .. " " .. block .. " " .. block .. " " .. block .. " " .. block .. " " .. block

	return color_blocks
end


-- =================================================================
-- CORE FETCH LOGIC
-- =================================================================

-- Utility to get a simple identifier for the current OS/Environment
local function getOSInfo()
	if RunService:IsStudio() then
		return "Roblox Studio (Development)"
	elseif RunService:IsClient() then
		return "Roblox Player (Client)"
	elseif RunService:IsServer() then
		return "Roblox Server (Dedicated)"
	else
		return "Unknown Environment"
	end
end

-- Core function to fetch and format all information
function BloxFetch.getInfo()
	local osInfo = getOSInfo()
	local localPlayer = PlayersService.LocalPlayer

	-- 1. Descriptive/Static Information
	local hostName = PlayersService.LocalPlayer and PlayersService.LocalPlayer.Name or "Roblox (Unknown Host)"
	local shellInfo = game.Name -- Display Game's Title Name
	local terminalInfo = "Danta Admin" -- Specified by user

	-- Hardware/System Information (Roblox VM/Simulated)
	local cpuName = "Roblox VM (Lua/C++)"
	local motherboard = "Roblox VM (Simulated)"
	local gpuName = "Varies (Client Device Graphics)"
	local diskInfo = string.format("~%s MB (Assets/Cache)", math.random(100, 500))

	-- 2. Performance Metrics (Simulated)
	local fps = getSimulatedFPS()

	local totalMem = getSimulatedMemoryUsage(300) 
	local renderMem = getSimulatedMemoryUsage(150) 
	local physicsMem = getSimulatedMemoryUsage(50) 

	local ipAddress = getFakeIPAddress()
	local kernelVersion = string.format("%d", game.PlaceVersion)

	local ping = getSimulatedPing() -- Start with simulated ping
	local username = "N/A"
	local userId = "N/A"

	-- 3. Dynamic Metrics
	local uptime = formatUptime()
	local resolution = getResolution()
	local packages = getSimulatedPackages()

	-- 4. Player Information
	if localPlayer then
		username = localPlayer.Name
		userId = localPlayer.UserId

		local actualPing = localPlayer:GetNetworkPing() * 1000

		-- Use actualPing if valid, otherwise use the simulated ping string already set above
		if actualPing > 0 then
			ping = string.format("%.0f ms", actualPing)
		else
			-- If actual ping fails, stick with the simulated ping string already set above
		end
	end

	-- Split the ASCII art into lines
	local rawAsciiLines = ROBLOX_ASCII:split("\n")
	local asciiLines = {}

	-- Strip leading/trailing whitespace from every line and calculate max width
	local maxAsciiWidth = 0
	local trimPattern = "^%s*(.-)%s*$" -- Pattern to strip leading/trailing whitespace

	for _, line in ipairs(rawAsciiLines) do
		-- Trim the line
		local trimmedLine = line:gsub(trimPattern, "%1")

		-- Ignore lines that become completely empty after trimming (like initial/final blank lines)
		if #trimmedLine > 0 then
			table.insert(asciiLines, trimmedLine)

			local width = #trimmedLine
			if width > maxAsciiWidth then
				maxAsciiWidth = width
			end
		end
	end

	local infoLines = {}

	-- Helper function to add a line of formatted system info
	local function addInfoLine(label, value)
		table.insert(infoLines, string.format("  %s: %s", label, value)) 
	end
	
	-- Helper function to add a line of formatted system info
	local function addTitleLine(label, value)
		table.insert(infoLines, string.format("  %s@%s", label, value))
	end
	
	-- Gather all information lines in desired order
	
	-- USER/HOST SECTION
	addTitleLine(string.lower(username), string.upper(hostName))
	addInfoLine("------------------", "--------------------")
	addInfoLine("Host", hostName)
	addInfoLine("Shell", shellInfo)
	addInfoLine("Terminal", terminalInfo)
	addInfoLine("Uptime", uptime)
	addInfoLine("Resolution", resolution)
	addInfoLine("------------------", "--------------------")

	-- SYSTEM SECTION
	addInfoLine("OS", osInfo)
	addInfoLine("Kernel", kernelVersion)
	addInfoLine("Motherboard", motherboard)
	addInfoLine("CPU", cpuName)
	addInfoLine("GPU", gpuName)
	addInfoLine("Disk", diskInfo)
	addInfoLine("Packages", packages)
	addInfoLine("------------------", "--------------------")

	-- NETWORK/PERFORMANCE SECTION
	addInfoLine("IP Address", ipAddress)
	addInfoLine("Ping", ping)
	addInfoLine("FPS", fps) 
	addInfoLine("Total Memory", totalMem)
	addInfoLine("Render Memory", renderMem)
	addInfoLine("Physics Memory", physicsMem)
	addInfoLine("------------------", "--------------------")

	-- PLAYER SECTION
	addInfoLine("Player", username)
	addInfoLine("User ID", userId)
	addInfoLine("------------------", "--------------------")
	
	-- Combine ASCII art and info lines side-by-side
	local maxLines = math.max(#asciiLines, #infoLines)
	local finalOutput = {}
	local paddingGap = "   " -- Gap between ASCII art and info section
	local leftMargin = "  " -- Fixed margin for the entire output block

	for i = 1, maxLines do
		local asciiLine = asciiLines[i] or ""
		local infoLine = infoLines[i] or ""

		-- Calculate padding needed to align the info section
		local requiredPadding = maxAsciiWidth - #asciiLine
		local padding = string.rep(" ", requiredPadding)

		-- Combine: [Margin] [ASCII Art] [Padding to max width] [Gap] [Info Line]
		table.insert(finalOutput, leftMargin .. asciiLine .. padding .. paddingGap .. infoLine)
	end

	-- --- Append the Color Blocks ---

	local colorBlocks = getSimulatedColorBlocks()

	-- Add a blank line for separation
	table.insert(finalOutput, "")
	-- Add the color blocks line, aligned with the left margin.
	table.insert(finalOutput, leftMargin .. colorBlocks)

	-- Join everything into a single string
	return table.concat(finalOutput, "\n")
end
-- test
return BloxFetch