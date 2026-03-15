-- [[ CONFIGURATION ]] --
getgenv().DNS = {
    Camlock = {
        Main = { Enabled = true, Key = "C", Smoothness = 0.2, Prediction = 0.111, Parts = {"Head"} },
        FOV = { ShowFOV = false, Radius = 300, Color = Color3.fromRGB(0, 71, 171), Filled = false, Transparency = 0.5 }
    },
    Silent = {
        Main = { Enabled = true, Mode = "Target", Prediction = 0.111, Parts = {"Head", "UpperTorso"} },
        FOV = { ShowFOV = false, Radius = 500, Color = Color3.fromRGB(0, 71, 171), Filled = false, Transparency = 0.5 }
    },
    UI = { Visible = true, ToggleKey = Enum.KeyCode.RightShift }
}

-- [[ SERVICES ]] --
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local plrs = game:GetService("Players")
local ws = game:GetService("Workspace")
local lplr = plrs.LocalPlayer
local camera = ws.CurrentCamera

-- [[ DRAWING LOGIC ]] --
local function CreateFOV(config)
    local circle = Drawing.new("Circle")
    circle.Visible = config.ShowFOV [cite: 2]
    circle.Thickness = 1 [cite: 2]
    circle.NumSides = 30 [cite: 3]
    circle.Radius = config.Radius [cite: 3]
    circle.Color = config.Color [cite: 3]
    circle.Filled = config.Filled [cite: 3]
    circle.Transparency = config.Transparency [cite: 3]
    return circle
end

local cfov = CreateFOV(getgenv().DNS.Camlock.FOV) [cite: 3]
local sfov = CreateFOV(getgenv().DNS.Silent.FOV) [cite: 3]

-- [[ UI CONSTRUCTION ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DNS_V2_PRO"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999

local success, _ = pcall(function() ScreenGui.Parent = game.CoreGui end)
if not success then ScreenGui.Parent = lplr:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 550, 0, 350) [cite: 3]
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175) [cite: 3]
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true [cite: 3]
MainFrame.Draggable = true [cite: 3]

local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(1, 0, 0, 40)
TabBar.BackgroundTransparency = 1

local TabList = Instance.new("UIListLayout", TabBar)
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabList.Padding = UDim.new(0, 15)

local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Size = UDim2.new(1, -20, 1, -60)
ContentArea.Position = UDim2.new(0, 10, 0, 50)
ContentArea.BackgroundTransparency = 1

-- UI Helpers
local function AddToggle(parent, text, default, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
    btn.Text = text .. ": " .. tostring(default)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text .. ": " .. tostring(state)
        callback(state)
    end)
end

local function CreateTab(name)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0, 80, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    
    local page = Instance.new("ScrollingFrame", ContentArea)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Visible = false
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 0
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 5) [cite: 5]
    
    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(ContentArea:GetChildren()) do p.Visible = false end
        page.Visible = true
    end)
    return page
end

-- Tabs
local VisualPage = CreateTab("Visual")
local AimbotPage = CreateTab("Aimbot")
local MiscPage = CreateTab("Misc")
local WhitelistPage = CreateTab("Whitelist")
local TeleportPage = CreateTab("Teleport")

-- Populate Toggles
AddToggle(AimbotPage, "Aimbot Enabled", getgenv().DNS.Camlock.Main.Enabled, function(v) getgenv().DNS.Camlock.Main.Enabled = v end)
AddToggle(VisualPage, "Camlock FOV", getgenv().DNS.Camlock.FOV.ShowFOV, function(v) getgenv().DNS.Camlock.FOV.ShowFOV = v end)
AddToggle(VisualPage, "Silent FOV", getgenv().DNS.Silent.FOV.ShowFOV, function(v) getgenv().DNS.Silent.FOV.ShowFOV = v end)
AddToggle(AimbotPage, "Silent Aim Enabled", getgenv().DNS.Silent.Main.Enabled, function(v) getgenv().DNS.Silent.Main.Enabled = v end)

-- [[ CORE LOGIC ]] --
local camlockTarget = nil
local isLocking = false

local function GetClosestPlayer()
    local target, dist = nil, math.huge
    for _, v in ipairs(plrs:GetPlayers()) do
        if v ~= lplr and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position) [cite: 8]
            if onScreen then
                local mag = (Vector2.new(pos.X, pos.Y) - uis:GetMouseLocation()).Magnitude [cite: 8]
                if mag < dist then target = v; dist = mag end [cite: 8, 9]
            end
        end
    end
    return target
end

uis.InputBegan:Connect(function(input, processed)
    if not processed then
        if input.KeyCode == getgenv().DNS.UI.ToggleKey then
            getgenv().DNS.UI.Visible = not getgenv().DNS.UI.Visible [cite: 9]
            MainFrame.Visible = getgenv().DNS.UI.Visible [cite: 9]
        end
        if input.KeyCode == Enum.KeyCode[getgenv().DNS.Camlock.Main.Key:upper()] then [cite: 10]
            if getgenv().DNS.Camlock.Main.Enabled then [cite: 10]
                isLocking = not isLocking [cite: 10]
                camlockTarget = isLocking and GetClosestPlayer() or nil [cite: 10]
            end
        end
    end
end)

rs.RenderStepped:Connect(function()
    local mouseLoc = uis:GetMouseLocation() [cite: 11]
    cfov.Position = mouseLoc [cite: 11]
    cfov.Visible = getgenv().DNS.Camlock.FOV.ShowFOV [cite: 11]
    cfov.Radius = getgenv().DNS.Camlock.FOV.Radius [cite: 11]
    
    sfov.Position = mouseLoc [cite: 11]
    sfov.Visible = getgenv().DNS.Silent.FOV.ShowFOV [cite: 11]
    sfov.Radius = getgenv().DNS.Silent.FOV.Radius [cite: 11]

    if isLocking and camlockTarget and camlockTarget.Character then [cite: 11]
        local part = camlockTarget.Character:FindFirstChild(getgenv().DNS.Camlock.Main.Parts[1]) [cite: 11]
        if part then
            local prediction = part.Position + (part.Velocity * getgenv().DNS.Camlock.Main.Prediction) [cite: 12]
            local lookAt = CFrame.new(camera.CFrame.Position, prediction) [cite: 12]
            camera.CFrame = camera.CFrame:Lerp(lookAt, getgenv().DNS.Camlock.Main.Smoothness) [cite: 12]
        end
    else
        isLocking = false [cite: 12]
    end
end)

lplr.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then [cite: 12]
            child.Activated:Connect(function() [cite: 13]
                if getgenv().DNS.Silent.Main.Enabled then [cite: 13]
                    local target = (getgenv().DNS.Silent.Main.Mode == "Target") and camlockTarget or GetClosestPlayer() [cite: 7, 13]
                    if target and target.Character then
                        print("Silent Aim targeting: " .. target.Name) [cite: 13, 14]
                    end
                end
            end)
        end
    end)
end)

AimbotPage.Visible = true
