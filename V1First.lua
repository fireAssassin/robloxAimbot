local players = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera

local aimbotEnabled = false -- Toggle state for team-based aimbot
local neutralAimbotEnabled = false -- Toggle state for neutral aimbot
local button -- GUI button for toggling team-based aimbot
local neutralButton -- GUI button for toggling neutral aimbot
local highlight -- The highlight effect for the player being aimed at
local tracer -- The tracer line for the player being aimed at

-- Function to create a draggable toggle button for team-based aimbot
local function createToggleButton()
    if button then
        button:Destroy() -- Avoid duplicate buttons
    end

    local screenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
    button = Instance.new("TextButton", screenGui)
    
    button.Size = UDim2.new(0, 100, 0, 50)
    button.Position = UDim2.new(0.5, -150, 0.1, 0) -- Positioned slightly left of center
    button.Text = "Team Aimbot: OFF"
    button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    button.Active = true
    button.Draggable = true

    button.MouseButton1Click:Connect(function()
        aimbotEnabled = not aimbotEnabled
        button.Text = aimbotEnabled and "Team Aimbot: ON" or "Team Aimbot: OFF"
        button.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end)
end

-- Function to create a draggable toggle button for neutral aimbot (ignoring teams)
local function createNeutralToggleButton()
    if neutralButton then
        neutralButton:Destroy() -- Avoid duplicate buttons
    end

    local screenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
    neutralButton = Instance.new("TextButton", screenGui)
    
    neutralButton.Size = UDim2.new(0, 100, 0, 50)
    neutralButton.Position = UDim2.new(0.5, 50, 0.1, 0) -- Positioned slightly right of center
    neutralButton.Text = "Neutral Aimbot: OFF"
    neutralButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    neutralButton.Active = true
    neutralButton.Draggable = true

    neutralButton.MouseButton1Click:Connect(function()
        neutralAimbotEnabled = not neutralAimbotEnabled
        neutralButton.Text = neutralAimbotEnabled and "Neutral Aimbot: ON" or "Neutral Aimbot: OFF"
        neutralButton.BackgroundColor3 = neutralAimbotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end)
end

-- Function to create a highlight for the player being aimed at
local function createHighlight(player)
    if highlight then
        highlight:Destroy() -- Remove previous highlight
    end

    highlight = Instance.new("Highlight")
    highlight.Adornee = player.Character
    highlight.FillColor = Color3.fromRGB(255, 255, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.2
    highlight.Parent = player.Character
end

-- Function to create a tracer line between the local player and the target
local function createTracer(player)
    if tracer then
        tracer:Destroy() -- Remove previous tracer
    end

    tracer = Instance.new("Beam")
    tracer.FaceCamera = true
    tracer.Width0 = 0.95
    tracer.Width1 = 0.95
    tracer.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
    tracer.Attachment0 = Instance.new("Attachment", localPlayer.Character:FindFirstChild("HumanoidRootPart"))
    tracer.Attachment1 = Instance.new("Attachment", player.Character:FindFirstChild("HumanoidRootPart"))
    tracer.Parent = workspace
end

-- Function to get the closest player from a different team that is alive
local function getClosestTeamPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer 
            and player.Team ~= localPlayer.Team -- Ensure player is from a different team
            and player.Character 
            and player.Character:FindFirstChild("HumanoidRootPart") 
            and player.Character:FindFirstChild("Humanoid")
            and player.Character.Humanoid.Health > 0 then -- Ensure the player is alive

            local playerRootPart = player.Character.HumanoidRootPart
            local localRootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")

            if localRootPart then
                local distance = (playerRootPart.Position - localRootPart.Position).Magnitude
                
                local rayOrigin = localRootPart.Position
                local rayDirection = (playerRootPart.Position - localRootPart.Position).unit * distance
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {localPlayer.Character, player.Character}
                rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                
                local raycastResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

                if not raycastResult and distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- Function to get the closest player, ignoring teams, who is alive
local function getClosestNeutralPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer 
            and player.Character 
            and player.Character:FindFirstChild("HumanoidRootPart") 
            and player.Character:FindFirstChild("Humanoid")
            and player.Character.Humanoid.Health > 0 then -- Ensure the player is alive

            local playerRootPart = player.Character.HumanoidRootPart
            local localRootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")

            if localRootPart then
                local distance = (playerRootPart.Position - localRootPart.Position).Magnitude
                
                local rayOrigin = localRootPart.Position
                local rayDirection = (playerRootPart.Position - localRootPart.Position).unit * distance
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {localPlayer.Character, player.Character}
                rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                
                local raycastResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

                if not raycastResult and distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- Function to aim at the closest player and apply highlight/tracers
local function aimAtClosestPlayer()
    local closestPlayer

    if aimbotEnabled then
        closestPlayer = getClosestTeamPlayer()
    elseif neutralAimbotEnabled then
        closestPlayer = getClosestNeutralPlayer()
    end

    if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetPosition = closestPlayer.Character.HumanoidRootPart.Position
        local localRootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")

        if localRootPart then
            local direction = (targetPosition - localRootPart.Position).unit
            local newCFrame = CFrame.new(localRootPart.Position, targetPosition)
            camera.CFrame = newCFrame -- Update camera to look at the target

            -- Create highlight and tracer for the closest player
            createHighlight(closestPlayer)
            createTracer(closestPlayer)
        end
    else
        -- If no valid target, remove previous highlight/tracer
        if highlight then
            highlight:Destroy()
            highlight = nil
        end
        if tracer then
            tracer:Destroy()
            tracer = nil
        end
    end
end

-- Update the aim every frame if either aimbot is enabled
runService.RenderStepped:Connect(function()
    if aimbotEnabled or neutralAimbotEnabled then
        aimAtClosestPlayer()
    end
end)

-- Listen for respawn and recreate the buttons when the player respawns
local function onCharacterAdded()
    createToggleButton() -- Recreate the team-based aimbot button on respawn
    createNeutralToggleButton() -- Recreate the neutral aimbot button on respawn
end

-- Set up initial buttons and event listener
localPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Call once at the start to ensure the buttons exist when the game first runs
if localPlayer.Character then
    onCharacterAdded()
else
    localPlayer.CharacterAdded:Wait()
    onCharacterAdded()
end
