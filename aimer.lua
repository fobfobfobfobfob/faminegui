-- [[ CONFIGURATION ]] --
getgenv().DNS = {
    Camlock = {
        Main = { Enabled = true, Key = "C", Smoothness = 0.2, Prediction = 0.111, Shake = false, ShakeValue = 15, Parts = {"Head"} },
        FOV = { ShowFOV = false, Radius = 300, Color = Color3.fromRGB(0, 71, 171), Filled = false, Transparency = 0.5 }
    },
    Silent = {
        Main = { Enabled = true, Mode = "Target", Prediction = 0.111, Parts = {"Head", "UpperTorso"} },
        FOV = { ShowFOV = false, Radius = 500, Color = Color3.fromRGB(0, 71, 171), Filled = false, Transparency = 0.5 }
    },
    UI = { Visible = true }
}

-- [[ SERVICES ]] --
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local plrs = game:GetService("Players")
local ws = game:GetService("Workspace")
local lplr = plrs.LocalPlayer
local camera = ws.CurrentCamera

-- [[ ORIGINAL DRAWING LOGIC ]] --
local function CreateFOV(config)
    local circle = Drawing.new("Circle")
    circle.Visible = config.ShowFOV
    circle.Thickness = 1
    circle.NumSides = 30
    circle.Radius = config.Radius
    circle.Color = config.Color
    circle.Filled = config.Filled
    circle.Transparency = config.Transparency
    return circle
end

local cfov = CreateFOV(getgenv().DNS.Camlock.FOV)
local sfov = CreateFOV(getgenv().DNS.Silent.FOV)

-- [[ UI CONSTRUCTION ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DNS_V1_GUI"
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
MainFrame.Active = true
MainFrame.Draggable = true

local Sidebar = Instance.new("Frame")
Sidebar.Parent = MainFrame
Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Sidebar.Size = UDim2.new(0, 120, 1, 0)

local Container = Instance.new("Frame")
Container.Parent = MainFrame
Container.Position = UDim2.new(0, 130, 0, 10)
Container.Size = UDim2.new(1, -140, 1, -20)
Container.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", Sidebar)
Layout.Padding = UDim.new(0, 5)

-- Tab Creator
local function CreateTab(name)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.new(1,1,1)
    
    local page = Instance.new("ScrollingFrame", Container)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.CanvasSize = UDim2.new(0,0,2,0)
    page.ScrollBarThickness = 2
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 5)
    
    btn.MouseButton1Click:Connect(function()
        for _, v in pairs(Container:GetChildren()) do v.Visible = false end
        page.Visible = true
    end)
    return page
end

local CamPage = CreateTab("Camlock")
local SilentPage = CreateTab("Silent Aim")
CamPage.Visible = true

-- Toggle Helper
local function AddToggle(parent, text, default, callback)
    local t = Instance.new("TextButton", parent)
    t.Size = UDim2.new(1, -10, 0, 30)
    t.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    t.Text = text .. ": " .. tostring(default)
    t.TextColor3 = Color3.new(1,1,1)
    
    local state = default
    t.MouseButton1Click:Connect(function()
        state = not state
        t.Text = text .. ": " .. tostring(state)
        callback(state)
    end)
end

-- Populate Settings
AddToggle(CamPage, "Enabled", getgenv().DNS.Camlock.Main.Enabled, function(v) getgenv().DNS.Camlock.Main.Enabled = v end)
AddToggle(CamPage, "Show FOV", getgenv().DNS.Camlock.FOV.ShowFOV, function(v) getgenv().DNS.Camlock.FOV.ShowFOV = v end)
AddToggle(SilentPage, "Enabled", getgenv().DNS.Silent.Main.Enabled, function(v) getgenv().DNS.Silent.Main.Enabled = v end)
AddToggle(SilentPage, "Show FOV", getgenv().DNS.Silent.FOV.ShowFOV, function(v) getgenv().DNS.Silent.FOV.ShowFOV = v end)

-- [[ CORE LOGIC (ORIGINAL SCRIPT) ]] --
local camlockTarget = nil
local isLocking = false

local function GetClosestPlayer()
    local target, dist = nil, math.huge
    for _, v in ipairs(plrs:GetPlayers()) do
        if v ~= lplr and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
            if onScreen then
                local mag = (Vector2.new(pos.X, pos.Y) - uis:GetMouseLocation()).Magnitude
                if mag < dist then target = v; dist = mag end
            end
        end
    end
    return target
end

-- Close/Open GUI Handler
uis.InputBegan:Connect(function(input, processed)
    if not processed then
        if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightShift then
            getgenv().DNS.UI.Visible = not getgenv().DNS.UI.Visible
            MainFrame.Visible = getgenv().DNS.UI.Visible
        end
        -- Camlock Key
        if input.KeyCode == Enum.KeyCode[getgenv().DNS.Camlock.Main.Key:upper()] then
            if getgenv().DNS.Camlock.Main.Enabled then
                isLocking = not isLocking
                camlockTarget = isLocking and GetClosestPlayer() or nil
            end
        end
    end
end)

-- Main Loop
rs.RenderStepped:Connect(function()
    -- Update FOVs
    local mouseLoc = uis:GetMouseLocation()
    cfov.Position = mouseLoc
    cfov.Visible = getgenv().DNS.Camlock.FOV.ShowFOV
    cfov.Radius = getgenv().DNS.Camlock.FOV.Radius
    
    sfov.Position = mouseLoc
    sfov.Visible = getgenv().DNS.Silent.FOV.ShowFOV
    sfov.Radius = getgenv().DNS.Silent.FOV.Radius

    -- Camlock Movement
    if isLocking and camlockTarget and camlockTarget.Character then
        local part = camlockTarget.Character:FindFirstChild(getgenv().DNS.Camlock.Main.Parts[1])
        if part then
            local prediction = part.Position + (part.Velocity * getgenv().DNS.Camlock.Main.Prediction)
            local lookAt = CFrame.new(camera.CFrame.Position, prediction)
            camera.CFrame = camera.CFrame:Lerp(lookAt, getgenv().DNS.Camlock.Main.Smoothness)
        end
    else
        isLocking = false
    end
end)

-- Silent Aim Tool Hook
local function GetSilentTarget()
    return (getgenv().DNS.Silent.Main.Mode == "Target") and camlockTarget or GetClosestPlayer()
end

lplr.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Activated:Connect(function()
                if getgenv().DNS.Silent.Main.Enabled then
                    local target = GetSilentTarget()
                    if target and target.Character then
                        print("Silent Aim targeting: " .. target.Name)
                    end
                end
            end)
        end
    end)
end)
