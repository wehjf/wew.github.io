local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = WindUI:CreateWindow({
    Folder = "Ringta Scripts",   
    Title = "RINGTA SCRIPTS",
    Icon = "star",
    Author = "ringta",
    Theme = "Dark",
    Size = UDim2.fromOffset(500, 350),
    HasOutline = true,
})

Window:EditOpenButton({
    Title = "Open RINGTA SCRIPTS",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 6),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromRGB(30, 30, 30), Color3.fromRGB(255, 255, 255)),
    Draggable = false,
})

local Tabs = {
    Main = Window:Tab({ Title = "Main", Icon = "star" }),
    Other = Window:Tab({ Title = "Other", Icon = "tool" }),
    Towns = Window:Tab({ Title = "Towns", Icon = "map" }),
    Bypass = Window:Tab({ Title = "OTHER TP", Icon = "rocket" }),
    Features = Window:Tab({ Title = "Features", Icon = "bolt" }),
    Transformation = Window:Tab({ Title = "Transformation", Icon = "zap" }),
    Credits = Window:Tab({ Title = "CREDITS", Icon = "award" }),
}

-- MAIN TAB BUTTONS
Tabs.Main:Button({
    Title = "AUTO HIT OP",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/AUTOHITNEW.github.io/refs/heads/main/NEWHIT.lua"))()
    end,
})
Tabs.Main:Button({
    Title = "TP to Train",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/NEWTPTRAIN.github.io/refs/heads/main/TRAIN.LUA"))()
    end,
})
Tabs.Main:Button({
    Title = "TP to Sterling",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/ringtaa/sterlingnotifcation.github.io/refs/heads/main/Sterling.lua'))()
    end,
})
Tabs.Main:Button({
    Title = "TP to TeslaLab",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/ringtaa/tptotesla.github.io/refs/heads/main/Tptotesla.lua'))()
    end,
})
Tabs.Main:Button({
    Title = "TP to Castle",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/castletpfast.github.io/refs/heads/main/FASTCASTLE.lua"))()
    end,
})
Tabs.Main:Button({
    Title = "TP StillWater Prision",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/StillwaterPrisontp.github.io/refs/heads/main/ringta.lua"))()
    end,
})
Tabs.Main:Button({
    Title = "Tp To Fort",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/Tpfort.github.io/refs/heads/main/Tpfort.lua"))()
    end,
})
Tabs.Main:Button({
    Title = "TP to Unicorn",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hbjrev/erhjf.github.io/refs/heads/main/hew.lua"))()
    end,
})

-- OTHER TAB BUTTONS & TOGGLES
Tabs.Other:Button({
    Title = "TP to End",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hbjrev/NEWNEWtpend.github.io/refs/heads/main/en.lua"))()
    end,
})
Tabs.Other:Button({
    Title = "TP to Bank",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/Tptobank.github.io/refs/heads/main/Banktp.lua"))()
    end,
})

local gunKillAuraActive = false
Tabs.Other:Toggle({
    Title = "Gun Aura (Kill Mobs)",
    Default = false,
    Callback = function(state)
        gunKillAuraActive = state
        if state then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/NEWKILLAURA.github.io/refs/heads/main/NEWkill.lua"))()
        end
    end,
})

local Noclip = false
Tabs.Other:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(state)
        Noclip = state
    end
})

local antiVoidActive = false
Tabs.Other:Toggle({
    Title = "Anti-Void",
    Default = false,
    Callback = function(state)
        antiVoidActive = state
    end,
})

Tabs.Other:Button({
    Title = "Train Kill Aura",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hbjrev/trainkillaura.github.io/refs/heads/main/trainkill.lua"))()
    end,
})

-- TOWNS TAB BUTTONS
for i = 1, 6 do
    Tabs.Towns:Button({
        Title = "Town " .. i,
        Callback = function()
            loadstring(game:HttpGet(("https://raw.githubusercontent.com/ringta9321/tptown%d.github.io/refs/heads/main/town%d.lua"):format(i, i)))()
        end,
    })
end

-- BYPASS TAB BUTTONS
Tabs.Bypass:Button({
    Title = "Jade Sword",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/fjruie/tpjadesword.github.io/refs/heads/main/ringta.lua"))()
    end,
})
Tabs.Bypass:Button({
    Title = "Jade Mask",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/jademask.github.io/refs/heads/main/ringta.lua"))()
    end,
})
Tabs.Bypass:Button({
    Title = "Tp To End",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hbjrev/newtpend.github.io/refs/heads/main/ringta.lua"))()
    end,
})
Tabs.Bypass:Button({
    Title = "Tp Trading Post",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hbjrev/trading.github.io/refs/heads/main/ringta.lua"))()
    end,
})

-- FEATURES TAB BUTTONS & FLY
Tabs.Features:Button({
    Title = "Collect All",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/collectall.github.io/refs/heads/main/ringta.lua"))()
    end,
})
Tabs.Features:Button({
    Title = "Auto Electrocutioner",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/Electrocutioner.github.io/refs/heads/main/tesla.lua"))()
    end,
})

local flyEnabled = false
local flySpeed = 50
local flyConnection = nil

Tabs.Features:Slider({
    Title = "Fly Speed",
    Step = 1,
    Value = {Min = 10, Max = 1000, Default = 50},
    Callback = function(val)
        flySpeed = val
    end
})

Tabs.Features:Toggle({
    Title = "Fly",
    Default = false,
    Callback = function(state)
        flyEnabled = state
        if state then
            local Players = game:GetService("Players")
            local RunService = game:GetService("RunService")
            local UserInputService = game:GetService("UserInputService")
            local Workspace = game:GetService("Workspace")
            local LocalPlayer = Players.LocalPlayer
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
            local velocityHandlerName = "VelocityHandler"
            local gyroHandlerName = "GyroHandler"
            local controlModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
            local root = HumanoidRootPart
            local camera = Workspace.CurrentCamera
            local v3inf = Vector3.new(9e9, 9e9, 9e9)
            local bv = Instance.new("BodyVelocity")
            bv.Name = velocityHandlerName
            bv.Parent = root
            bv.MaxForce = v3inf
            bv.Velocity = Vector3.new()
            local bg = Instance.new("BodyGyro")
            bg.Name = gyroHandlerName
            bg.Parent = root
            bg.MaxTorque = v3inf
            bg.P = 1000
            bg.D = 50
            flyConnection = RunService.RenderStepped:Connect(function()
                if not flyEnabled then return end
                local VelocityHandler = root:FindFirstChild(velocityHandlerName)
                local GyroHandler = root:FindFirstChild(gyroHandlerName)
                if VelocityHandler and GyroHandler then
                    GyroHandler.CFrame = camera.CFrame
                    local direction = controlModule:GetMoveVector()
                    VelocityHandler.Velocity =
                        (camera.CFrame.RightVector * direction.X * flySpeed) +
                        (-camera.CFrame.LookVector * direction.Z * flySpeed)
                end
            end)
        else
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
            -- Optionally remove BodyVelocity and BodyGyro
            local LocalPlayer = game:GetService("Players").LocalPlayer
            local Character = LocalPlayer.Character
            if Character then
                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                if HumanoidRootPart then
                    local bv = HumanoidRootPart:FindFirstChild("VelocityHandler")
                    if bv then bv:Destroy() end
                    local bg = HumanoidRootPart:FindFirstChild("GyroHandler")
                    if bg then bg:Destroy() end
                end
            end
        end
    end
})

Tabs.Features:Button({
    Title = "Fly Off",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/un.github.io/refs/heads/main/ufly.lua"))()
    end,
})

-- Runtime toggles (Noclip, AntiVoid)
game:GetService('RunService').Stepped:Connect(function()
    if Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    if antiVoidActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if LocalPlayer.Character.HumanoidRootPart.Position.Y < -1 then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/NEWTPTRAIN.github.io/refs/heads/main/TRAIN.LUA"))()
        end
    end
end)


local autoBanjoActive = false
local autoBanjoConnection

Tabs.Features:Toggle({
    Title = "Auto Banjo",
    Default = false,
    Callback = function(state)
        autoBanjoActive = state
        if state then
            -- Start auto banjo loop
            local v2 = require(game:GetService("ReplicatedStorage").Shared.Remotes)
            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer
            local RunService = game:GetService("RunService")

            autoBanjoConnection = RunService.RenderStepped:Connect(function()
                local character = LocalPlayer.Character
                if character then
                    for _, v in pairs(character:GetChildren()) do
                        if v.Name == "Banjo" then
                            v2.Events.PlayBanjo:FireServer(v, 1)
                        end
                    end
                end
            end)
        else
            if autoBanjoConnection then
                autoBanjoConnection:Disconnect()
                autoBanjoConnection = nil
            end
        end
    end
})



Tabs.Transformation:Divider()
Tabs.Transformation:Section({
    Title = "NOTE: YOU NEED TO HOLD OUT\n VAMPIRE KNIFE TO MAKE\n THE MORPHS WORK",
    Color = Color3.fromRGB(255, 80, 80)
})
Tabs.Transformation:Divider()

Tabs.Transformation:Button({
    Title = "Goliath Morph",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/absscidii/Goliath/refs/heads/main/Script",true))()
    end,
})

Tabs.Transformation:Divider()

Tabs.Transformation:Button({
    Title = "Eggstravaganza Morph",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/absscidii/BigBlackBallsBunny/refs/heads/main/Lol",true))()
    end,
})

Tabs.Transformation:Divider()

Tabs.Transformation:Section({
    Title = "credit to cursed_pink_sheep",
    Color = Color3.fromRGB(255, 200, 0)
})


Tabs.Credits:Section({
    Title = "MADE BY RINGTA",
    Color = Color3.fromRGB(0, 200, 255)
})

Tabs.Credits:Divider()

Tabs.Credits:Button({
    Title = "Ringta Discord",
    Description = "Click to copy discord.gg/ringta to clipboard",
    Callback = function()
        setclipboard("discord.gg/ringta")
        -- Optional: Notify the user
        if Window.Notify then
            Window:Notify({
                Title = "Copied!",
                Content = "Discord invite copied to clipboard.",
                Duration = 3,
            })
        end
    end,
})

Tabs.Credits:Section({
    Title = "Credits to Chonky And KingKM (The other 2 devs)",
    Color = Color3.fromRGB(255, 200, 0) -- You can change color if you want
})
