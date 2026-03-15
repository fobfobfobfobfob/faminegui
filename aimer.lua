-- [[ STABILITY CLEANER ]] --
if getgenv().DNS then getgenv().DNS = nil end
if game.CoreGui:FindFirstChild("DNS_KeySystem") then game.CoreGui.DNS_KeySystem:Destroy() end

-- [[ KEY SYSTEM UI ]] --
local function LoadMainScript()
    -- [[ CONFIGURATION ]] --
    getgenv().DNS = {
        Camlock = {
            Main = { Enabled = true, Key = "C", Smoothness = 0.2, Prediction = 0.80, Parts = {"Head"} },
            FOV = { ShowFOV = false, Radius = 300, Color = Color3.fromRGB(0, 71, 171), Filled = false, Transparency = 0.5 }
        },
        Silent = {
            Main = { Enabled = true, Mode = "Target", Prediction = 0.200, Parts = {"Head", "UpperTorso"} },
            FOV = { ShowFOV = false, Radius = 500, Color = Color3.fromRGB(0, 71, 171), Filled = false, Transparency = 0.5 }
        },
        Misc = {
            WalkSpeedEnabled = false,
            WalkSpeedValue = 50,
            CFrameSpeedEnabled = false,
            CFrameSpeedValue = 2
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

    -- [[ UI PARENTING ]] --
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DNS_V2_PRO"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999
    
    local function ParentGui(obj)
        local success, _ = pcall(function() obj.Parent = game:GetService("CoreGui") end)
        if not success then obj.Parent = lplr:WaitForChild("PlayerGui") end
    end
    ParentGui(ScreenGui)

    -- [[ DRAWING LOGIC ]] --
    local function CreateFOV(config)
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
                if p:IsA("ScrollingFrame") then p.Visible = false end 
            end
            page.Visible = true
        end)
        return page
    end

    local VisualPage = CreateTab("Visual")
    local AimbotPage = CreateTab("Aimbot")
    local MiscPage = CreateTab("Misc")

    AddToggle(AimbotPage, "Aimbot Enabled", getgenv().DNS.Camlock.Main.Enabled, function(v) getgenv().DNS.Camlock.Main.Enabled = v end)
    AddToggle(VisualPage, "Camlock FOV", getgenv().DNS.Camlock.FOV.ShowFOV, function(v) getgenv().DNS.Camlock.FOV.ShowFOV = v end)
    AddToggle(VisualPage, "Silent FOV", getgenv().DNS.Silent.FOV.ShowFOV, function(v) getgenv().DNS.Silent.FOV.ShowFOV = v end)
    AddToggle(AimbotPage, "Silent Aim Enabled", getgenv().DNS.Silent.Main.Enabled, function(v) getgenv().DNS.Silent.Main.Enabled = v end)
    AddToggle(MiscPage, "WalkSpeed Boost", getgenv().DNS.Misc.WalkSpeedEnabled, function(v) getgenv().DNS.Misc.WalkSpeedEnabled = v end)
    AddToggle(MiscPage, "CFrame Speed (TP)", getgenv().DNS.Misc.CFrameSpeedEnabled, function(v) getgenv().DNS.Misc.CFrameSpeedEnabled = v end)

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

    uis.InputBegan:Connect(function(input, processed)
        if not processed then
            if input.KeyCode == getgenv().DNS.UI.ToggleKey then
                getgenv().DNS.UI.Visible = not getgenv().DNS.UI.Visible
                MainFrame.Visible = getgenv().DNS.UI.Visible
            end
            if input.KeyCode == Enum.KeyCode[getgenv().DNS.Camlock.Main.Key:upper()] then
                if getgenv().DNS.Camlock.Main.Enabled then
                    isLocking = not isLocking
                    camlockTarget = isLocking and GetClosestPlayer() or nil
                end
            end
        end
    end)

    rs.RenderStepped:Connect(function()
        local mouseLoc = uis:GetMouseLocation()
        if cfov and Drawing then
            cfov.Position = mouseLoc
            cfov.Visible = getgenv().DNS.Camlock.FOV.ShowFOV
            cfov.Radius = getgenv().DNS.Camlock.FOV.Radius
        end
        if sfov and Drawing then
            sfov.Position = mouseLoc
            sfov.Visible = getgenv().DNS.Silent.FOV.ShowFOV
            sfov.Radius = getgenv().DNS.Silent.FOV.Radius
        end
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

    rs.Heartbeat:Connect(function()
        if lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
            if getgenv().DNS.Misc.WalkSpeedEnabled then
                lplr.Character.Humanoid.WalkSpeed = getgenv().DNS.Misc.WalkSpeedValue
            else
                lplr.Character.Humanoid.WalkSpeed = 16
            end
            if getgenv().DNS.Misc.CFrameSpeedEnabled and lplr.Character.Humanoid.MoveDirection.Magnitude > 0 then
                lplr.Character:TranslateBy(lplr.Character.Humanoid.MoveDirection * (getgenv().DNS.Misc.CFrameSpeedValue / 10))
            end
        end
    end)

    AimbotPage.Visible = true
    print("DNS V2 Loaded Successfully")
end

-- [[ KEY UI SETUP ]] --
local KeyGui = Instance.new("ScreenGui")
KeyGui.Name = "DNS_KeySystem"
local success, _ = pcall(function() KeyGui.Parent = game:GetService("CoreGui") end)
if not success then KeyGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

local KFrame = Instance.new("Frame", KeyGui)
KFrame.Size = UDim2.new(0, 300, 0, 150)
KFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
KFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
KFrame.BorderSizePixel = 0

local KTitle = Instance.new("TextLabel", KFrame)
KTitle.Size = UDim2.new(1, 0, 0, 30)
KTitle.Text = "FOREIGN AIm V2 - Enter Key"
KTitle.TextColor3 = Color3.new(1, 1, 1)
KTitle.BackgroundTransparency = 1
KTitle.Font = Enum.Font.SourceSansBold

local KInput = Instance.new("TextBox", KFrame)
KInput.Size = UDim2.new(0.8, 0, 0, 30)
KInput.Position = UDim2.new(0.1, 0, 0.35, 0)
KInput.PlaceholderText = "Enter Key Here..."
KInput.Text = ""
KInput.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
KInput.TextColor3 = Color3.new(1,1,1)

local KSubmit = Instance.new("TextButton", KFrame)
KSubmit.Size = UDim2.new(0.5, 0, 0, 30)
KSubmit.Position = UDim2.new(0.25, 0, 0.7, 0)
KSubmit.Text = "Submit"
KSubmit.BackgroundColor3 = Color3.fromRGB(0, 71, 171)
KSubmit.TextColor3 = Color3.new(1, 1, 1)

KSubmit.MouseButton1Click:Connect(function()
    if KInput.Text == "FOREIGN_V2" then
        KeyGui:Destroy()
        LoadMainScript()
    else
        KInput.Text = ""
        KInput.PlaceholderText = "WRONG KEY!"
    end
end)
