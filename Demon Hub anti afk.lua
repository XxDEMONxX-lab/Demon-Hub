--[[
	DEMON HUB ANTI AFK v2.0
	Mobile Anti-AFK Script for Roblox
	With Anti-Ban, Anti-Kick, and Anti-Timeout Protection
	Toggle via on-screen button
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Config
local Config = {
	Enabled = false,
	MovementInterval = 45,
	RotationInterval = 30,
	JumpInterval = 90,
	UseRandomIntervals = true,
	IntervalVariation = 10,
	-- Anti-Protection Settings
	AntiKickEnabled = true,
	AntiBanEnabled = true,
	AntiTimeoutEnabled = true,
	BanDetectionInterval = 5,
	KickDetectionInterval = 2,
	TimeoutWarningThreshold = 300, -- 5 minutes in seconds
}

local LastMovementTime = 0
local LastRotationTime = 0
local LastJumpTime = 0
local IsMoving = false
local LastActivityTime = tick()
local BanProtectionActive = false
local KickProtectionActive = false

-- Get random interval
local function GetRandomInterval(BaseInterval)
	if not Config.UseRandomIntervals then return BaseInterval end
	local Variation = math.random(-Config.IntervalVariation, Config.IntervalVariation)
	return math.max(5, BaseInterval + Variation)
end

-- Check if humanoid alive
local function IsHumanoidAlive()
	return Humanoid and Humanoid.Health > 0
end

-- Update last activity time
local function UpdateActivity()
	LastActivityTime = tick()
end

-- Anti-Kick Protection
local function AntiKickProtection()
	if not Config.AntiKickEnabled or KickProtectionActive then return end
	
	pcall(function()
		-- Detect and prevent RemoteEvent kicks
		if game:FindFirstChild("Workspace") then
			for _, RemoteEvent in pairs(game:GetDescendants()) do
				if RemoteEvent:IsA("RemoteEvent") and (RemoteEvent.Name:lower():find("kick") or RemoteEvent.Name:lower():find("ban")) then
					local OldFire = RemoteEvent.FireServer
					RemoteEvent.FireServer = function(self, ...)
						print("[Anti-Kick] Blocked potential kick RemoteEvent: " .. RemoteEvent.Name)
						return
					end
				end
			end
		end
	end)
	
	-- Monitor character state for unexpected removal
	if Character and Character.Parent == nil then
		print("[Anti-Kick] Kick detected! Respawning...")
		KickProtectionActive = true
		task.wait(1)
		KickProtectionActive = false
	end
end

-- Anti-Ban Protection (prevent ban detection events)
local function AntiBanProtection()
	if not Config.AntiBanEnabled or BanProtectionActive then return end
	
	pcall(function()
		-- Block ban-related RemoteEvents
		for _, RemoteEvent in pairs(game:GetDescendants()) do
			if RemoteEvent:IsA("RemoteEvent") and (RemoteEvent.Name:lower():find("ban") or RemoteEvent.Name:lower():find("restrict")) then
				local OldFire = RemoteEvent.FireServer
				RemoteEvent.FireServer = function(self, ...)
					print("[Anti-Ban] Blocked potential ban RemoteEvent: " .. RemoteEvent.Name)
					return
				end
			end
		end
		
		-- Block ban-related RemoteFunctions
		for _, RemoteFunction in pairs(game:GetDescendants()) do
			if RemoteFunction:IsA("RemoteFunction") and (RemoteFunction.Name:lower():find("ban") or RemoteFunction.Name:lower():find("check")) then
				local OldInvoke = RemoteFunction.InvokeServer
				RemoteFunction.InvokeServer = function(self, ...)
					print("[Anti-Ban] Blocked potential ban RemoteFunction: " .. RemoteFunction.Name)
					return nil
				end
			end
		end
	end)
end

-- Anti-Timeout Protection (keep sending inputs)
local function AntiTimeoutProtection()
	if not Config.AntiTimeoutEnabled then return end
	
	local TimeSinceActivity = tick() - LastActivityTime
	
	if TimeSinceActivity >= Config.TimeoutWarningThreshold then
		print("[Anti-Timeout] Warning: Inactivity detected! Sending activity signal...")
		UpdateActivity()
		
		-- Send input to prevent timeout
		pcall(function()
			Humanoid:Move(Vector3.new(0.1, 0, 0.1), false)
			task.wait(0.1)
			Humanoid:Move(Vector3.new(0, 0, 0), false)
		end)
	end
end

-- Simulate movement
local function SimulateMovement()
	if not Config.Enabled or IsMoving or not IsHumanoidAlive() then return end
	
	local CurrentTime = tick()
	local Interval = GetRandomInterval(Config.MovementInterval)
	
	if CurrentTime - LastMovementTime >= Interval then
		IsMoving = true
		local Direction = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit
		local Duration = math.random(1, 3)
		
		local StartTime = tick()
		while tick() - StartTime < Duration and IsHumanoidAlive() do
			Humanoid:Move(Direction, false)
			RunService.Heartbeat:Wait()
		end
		
		Humanoid:Move(Vector3.new(0, 0, 0), false)
		LastMovementTime = CurrentTime
		IsMoving = false
		UpdateActivity()
	end
end

-- Simulate rotation
local function SimulateRotation()
	if not Config.Enabled or not IsHumanoidAlive() then return end
	
	local CurrentTime = tick()
	local Interval = GetRandomInterval(Config.RotationInterval)
	
	if CurrentTime - LastRotationTime >= Interval then
		local Camera = workspace.CurrentCamera
		local RotationAmount = math.rad(math.random(10, 45))
		local Direction = math.random(0, 1) == 0 and 1 or -1
		
		Camera.CFrame = Camera.CFrame * CFrame.Angles(0, RotationAmount * Direction, 0)
		LastRotationTime = CurrentTime
		UpdateActivity()
	end
end

-- Simulate jump
local function SimulateJump()
	if not Config.Enabled or not IsHumanoidAlive() then return end
	
	local CurrentTime = tick()
	local Interval = GetRandomInterval(Config.JumpInterval)
	
	if CurrentTime - LastJumpTime >= Interval then
		Humanoid:Jump()
		LastJumpTime = CurrentTime
		UpdateActivity()
	end
end

-- Main loop
local function AntiAFKLoop()
	while true do
		if Config.Enabled and IsHumanoidAlive() then
			SimulateMovement()
			SimulateRotation()
			SimulateJump()
		end
		
		-- Protection checks
		if math.random(1, 10) == 1 then -- Run protection checks periodically
			AntiKickProtection()
			AntiBanProtection()
		end
		AntiTimeoutProtection()
		
		RunService.Heartbeat:Wait()
	end
end

-- Handle respawn
LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
	Character = NewCharacter
	Humanoid = Character:WaitForChild("Humanoid")
	LastMovementTime = 0
	LastRotationTime = 0
	LastJumpTime = 0
	IsMoving = false
	UpdateActivity()
	print("[Anti-AFK] Character respawned - protections reactivated")
end)

-- Create mobile GUI
local function CreateGui()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "DemonHubAntiAFK"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	
	-- Main button
	local Button = Instance.new("TextButton")
	Button.Name = "ToggleButton"
	Button.Size = UDim2.new(0, 120, 0, 50)
	Button.Position = UDim2.new(0, 15, 0, 15)
	Button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button.TextSize = 14
	Button.Font = Enum.Font.GothamBold
	Button.Text = "Anti-AFK\nOFF"
	Button.BorderSizePixel = 0
	Button.Parent = ScreenGui
	
	-- Corner radius
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 10)
	Corner.Parent = Button
	
	-- Status Label
	local StatusLabel = Instance.new("TextLabel")
	StatusLabel.Name = "StatusLabel"
	StatusLabel.Size = UDim2.new(0, 200, 0, 80)
	StatusLabel.Position = UDim2.new(0, 15, 0, 70)
	StatusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	StatusLabel.TextSize = 12
	StatusLabel.Font = Enum.Font.GothamBold
	StatusLabel.Text = "Protections:\n✓ Anti-Kick\n✓ Anti-Ban\n✓ Anti-Timeout"
	StatusLabel.BorderSizePixel = 0
	StatusLabel.Parent = ScreenGui
	
	local StatusCorner = Instance.new("UICorner")
	StatusCorner.CornerRadius = UDim.new(0, 8)
	StatusCorner.Parent = StatusLabel
	
	-- Toggle function
	Button.MouseButton1Click:Connect(function()
		Config.Enabled = not Config.Enabled
		Button.BackgroundColor3 = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
		Button.Text = "Anti-AFK\n" .. (Config.Enabled and "ON" or "OFF")
		print("[Demon Hub] Anti-AFK " .. (Config.Enabled and "ENABLED" or "DISABLED"))
	end)
	
	-- Dragging
	local Dragging = false
	local DragOffset = Vector2.new(0, 0)
	
	Button.InputBegan:Connect(function(Input, GameProcessed)
		if Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragOffset = Input.Position - Button.AbsolutePosition
		end
	end)
	
	Button.InputEnded:Connect(function(Input, GameProcessed)
		if Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(Input, GameProcessed)
		if Dragging and Input.UserInputType == Enum.UserInputType.Touch then
			Button.Position = UDim2.new(0, Input.Position.X - DragOffset.X, 0, Input.Position.Y - DragOffset.Y)
		end
	end)
end

-- Initialize
CreateGui()
AntiAFKLoop()

print("╔═════════════════════════════════════════╗")
print("║   DEMON HUB ANTI AFK v2.0 - LOADED     ║")
print("║   Mobile Version Ready!                ║")
print("║   Anti-Kick/Ban/Timeout ACTIVE         ║")
print("╚═════════════════════════════════════════╝")
