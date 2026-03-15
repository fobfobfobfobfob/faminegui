-- [[ STABILITY CLEANER ]] --
if getgenv().DNS then getgenv().DNS = nil end

-- [[ KEY SYSTEM ]] --
local CorrectKey = "FOREIGN_V2" -- Change this to your desired key
local EnteredKey = _G.Key or "KEY_HERE" -- Uses _G.Key if set, otherwise "KEY_HERE"

if EnteredKey ~= CorrectKey then
    warn("DNS V2: Invalid Key. Please check the Discord.")
    return 
end

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

-- [[ UI PARENTING FIX ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DNS_V2_PRO"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999

-- Safer parenting to avoid crashes on some executors
local function ParentGui()
    local success, _ = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if not success then 
        ScreenGui.Parent = lplr:WaitForChild("PlayerGui") 
    end
end
ParentGui()

-- [[ DRAWING LOGIC ]] --
local function CreateFOV(config)
    -- Check if Drawing API exists to prevent crashes
    if not Drawing then return {Visible = false} end
    
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
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 550, 0, 350)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

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
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 5)
    
    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(ContentArea:GetChildren()) do 
            if p
