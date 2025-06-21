local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local seeds = {
    "Carrot","Strawberry","Blueberry","Orange Tulip","Tomato","Corn",
    "Daffodil","Watermelon","Pumpkin","Apple","Bamboo","Coconut",
    "Cactus","Dragon Fruit","Mango","Grape","Mushroom","Pepper",
    "Cacao","Beanstalk","Ember Lily"
}

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
    Draggable = true,
})

local AutobuyTab = Window:Tab({ Title = "Autobuy", Icon = "shopping-cart" })

local autobuy_selected = {}
for _, seed in ipairs(seeds) do
    autobuy_selected[seed] = false
end

local autobuy_running = false
local autobuy_thread

-- Main switch at the very top
AutobuyTab:Toggle({
    Title = "⚡ AUTOBUY (Main Switch)",
    Icon = "zap", 
    Default = false,
    Callback = function(state)
        autobuy_running = state
        if autobuy_running then
            autobuy_thread = task.spawn(function()
                while autobuy_running do
                    for seed, selected in pairs(autobuy_selected) do
                        if selected then
                            ReplicatedStorage.GameEvents.BuySeedStock:FireServer(seed)
                            task.wait(0.1)
                        end
                    end
                    task.wait(0.2)
                end
            end)
        else
            if autobuy_thread then
                task.cancel(autobuy_thread)
                autobuy_thread = nil
            end
        end
    end
})

-- Divider/section to visually group the seed toggles
AutobuyTab:Section({ Title = "Select seeds to autobuy:" })

-- Individual toggles for each seed
for _, seed in ipairs(seeds) do
    AutobuyTab:Toggle({
        Title = seed,
        Default = false,
        Callback = function(state)
            autobuy_selected[seed] = state
        end
    })
end

-- Money section remains at the bottom
local leaderstats = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:WaitForChild("leaderstats")
local shecklesStat = leaderstats:FindFirstChild("Sheckles") or leaderstats:WaitForChild("Sheckles")
local moneySection = AutobuyTab:Section({
    Title = "💸 Sheckles: " .. tostring(shecklesStat.Value)
})

spawn(function()
    while true do
        if moneySection and moneySection.SetTitle then
            moneySection:SetTitle("💸 Sheckles: " .. tostring(shecklesStat.Value))
        end
        wait(1)
    end
end)


local PlantTab = Window:Tab({ Title = "Autoplant", Icon = "leaf" })

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = game.Players.LocalPlayer
local plantRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Plant_RE")

local seeds = {
    "Carrot","Strawberry","Blueberry","Orange Tulip","Tomato","Corn",
    "Daffodil","Watermelon","Pumpkin","Apple","Bamboo","Coconut",
    "Cactus","Dragon Fruit","Mango","Grape","Mushroom","Pepper",
    "Cacao","Beanstalk","Ember Lily"
}

local autoplant_selected = {}
for _, seed in ipairs(seeds) do
    autoplant_selected[seed] = false
end

local autoplant_running = false
local autoplant_thread

PlantTab:Toggle({
    Title = "⚡ AUTOPLANT (Main Switch)",
    Icon = "zap",
    Default = false,
    Callback = function(state)
        autoplant_running = state
        if autoplant_running then
            startAutoPlanting()
        else
            if autoplant_thread then
                task.cancel(autoplant_thread)
                autoplant_thread = nil
            end
        end
    end
})

PlantTab:Section({ Title = "Select seeds to autoplant:" })

for _, seed in ipairs(seeds) do
    PlantTab:Toggle({
        Title = seed,
        Default = false,
        Callback = function(state)
            autoplant_selected[seed] = state
        end
    })
end

-- FARM SPOT HELPERS
local function getMyFarm()
    for _, farm in pairs(workspace.Farm:GetChildren()) do
        local data = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
        if data and data:FindFirstChild("Owner") and data.Owner.Value == lp.Name then
            return farm
        end
    end
    return nil
end

local function getCanPlantParts()
    local myFarm = getMyFarm()
    local canPlant = {}
    if myFarm then
        local plantLocations = myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plant_Locations")
        if plantLocations then
            for _, part in ipairs(plantLocations:GetDescendants()) do
                if part:IsA("BasePart") and part.Name:find("Can_Plant") then
                    table.insert(canPlant, part)
                end
            end
        end
    end
    return canPlant
end

local function getRandomPosition(part)
    local offset = Vector3.new(
        math.random() * part.Size.X - part.Size.X/2,
        0,
        math.random() * part.Size.Z - part.Size.Z/2
    )
    return (part.Position + offset + Vector3.new(0, 2, 0))
end

local function getCurrentSeedsInBackpack()
    local result = {}
    for _, tool in ipairs(lp.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local base = tool.Name:match("^(.-) Seed")
            if base and autoplant_selected[base] then
                result[#result + 1] = {BaseName = base, Tool = tool}
            end
        end
    end
    return result
end

local function plantEquippedSeed(seedName)
    local plantParts = getCanPlantParts()
    if #plantParts == 0 then return end
    local plot = plantParts[math.random(1, #plantParts)]
    local pos = getRandomPosition(plot)
    plantRemote:FireServer(pos, seedName)
end

local function equipTool(tool)
    if not tool or not tool:IsDescendantOf(lp.Backpack) then return end
    pcall(function()
        local char = lp.Character or lp.CharacterAdded:Wait()
        char.Humanoid:UnequipTools()
        task.wait(0.1)
        tool.Parent = char
        while not char:FindFirstChild(tool.Name) do
            task.wait(0.1)
        end
    end)
end

function startAutoPlanting()
    if autoplant_thread then return end
    autoplant_thread = task.spawn(function()
        while autoplant_running do
            local seeds = getCurrentSeedsInBackpack()
            for _, data in ipairs(seeds) do
                local tool = data.Tool
                local seedName = data.BaseName
                if not autoplant_selected[seedName] then continue end
                if tool and tool:IsA("Tool") and tool:IsDescendantOf(lp.Backpack) then
                    equipTool(tool)
                    task.wait(0.2)
                    while autoplant_running and lp.Character and lp.Character:FindFirstChild(tool.Name) do
                        if not autoplant_selected[seedName] then break end
                        plantEquippedSeed(seedName)
                        task.wait(0.15)
                    end
                end
            end
            task.wait(0.1)
        end
        autoplant_thread = nil
    end)
end


-- AUTOFARM TAB (WindUI version, plug into your script after seeds/Window/ReplicatedStorage/LocalPlayer are defined)
local UserInputService = game:GetService("UserInputService")

local AutofarmTab = Window:Tab({ Title = "Autofarm", Icon = "tractor" })

-- === AUTOFARM LABEL ===
AutofarmTab:Section({ Title = "Autofarm Features" })

-- === AUTOCOLLECT ===
local collecting = false
local collect_thread

local function getMyFarm()
    for _, farm in pairs(workspace.Farm:GetChildren()) do
        local data = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
        if data and data:FindFirstChild("Owner") and data.Owner.Value == LocalPlayer.Name then
            return farm
        end
    end
end

local function getMyHarvestableCrops()
    local myFarm, crops = getMyFarm(), {}
    if myFarm then
        local plants = myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plants_Physical")
        if plants then
            for _, plant in pairs(plants:GetChildren()) do
                for _, part in pairs(plant:GetDescendants()) do
                    local pr = part:IsA("BasePart") and part:FindFirstChildOfClass("ProximityPrompt")
                    if pr then pr.MaxActivationDistance = 1000 table.insert(crops, part) break end
                end
            end
        end
    end
    return crops
end

local function autoCollectLoop()
    local tp_interval, pr_delay = 7, 0.1
    while collecting do
        local crops = getMyHarvestableCrops()
        if #crops > 0 then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local crop = crops[math.random(1, #crops)]
            if hrp and crop then hrp.CFrame = CFrame.new(crop.Position + Vector3.new(0, 3, 0)) end
            for _, c in ipairs(crops) do
                local pr = c:FindFirstChildOfClass("ProximityPrompt")
                if pr then pcall(function() fireproximityprompt(pr) end) task.wait(pr_delay) end
            end
        end
        task.wait(tp_interval)
    end
end

AutofarmTab:Toggle({
    Title = "Autocollect (auto-harvest crops)",
    Icon = "recycle",
    Default = false,
    Callback = function(state)
        collecting = state
        if collecting then
            collect_thread = task.spawn(autoCollectLoop)
        else
            if collect_thread then
                task.cancel(collect_thread)
                collect_thread = nil
            end
        end
    end
})

-- === AUTOSELL INTERVAL SLIDER & TOGGLE ===
local autosell_interval = 5 -- default seconds
AutofarmTab:Section({ Title = "Autosell every "..tostring(autosell_interval).." seconds" })
local sectionObj = nil

-- WindUI does not always have a true slider, so a dropdown can be used for intervals:
local interval_choices = {}
for i=1,60 do table.insert(interval_choices, tostring(i)) end

AutofarmTab:Dropdown({
    Title = "Set Autosell Interval (seconds)",
    Values = interval_choices,
    Default = tostring(autosell_interval),
    Callback = function(v)
        autosell_interval = tonumber(v)
        if sectionObj and sectionObj.SetTitle then
            sectionObj:SetTitle("Autosell every "..tostring(autosell_interval).." seconds")
        end
    end
})

local autosell_running = false
local autosell_thread

AutofarmTab:Toggle({
    Title = "Autosell",
    Icon = "dollar-sign",
    Default = false,
    Callback = function(state)
        autosell_running = state
        if autosell_running then
            autosell_thread = task.spawn(function()
                local GE = ReplicatedStorage.GameEvents
                while autosell_running do
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local pos = hrp.CFrame
                        if workspace:FindFirstChild("Tutorial_Points") and workspace.Tutorial_Points:FindFirstChild("Tutorial_Point_2") then
                            hrp.CFrame = workspace.Tutorial_Points.Tutorial_Point_2.CFrame
                            task.wait(0.2)
                            GE.Sell_Inventory:FireServer()
                            task.wait(0.2)
                            hrp.CFrame = pos
                        end
                    end
                    for i = 1, autosell_interval do
                        if not autosell_running then break end
                        task.wait(1)
                    end
                end
            end)
        else
            if autosell_thread then
                task.cancel(autosell_thread)
                autosell_thread = nil
            end
        end
    end
})



local gears = {
    "Watering Can",
    "Trowel",
    "Recall Wrench",
    "Basic Sprinkler",
    "Advanced Sprinkler",
    "Godly Sprinkler",
    "Lightning Rod",
    "Master Sprinkler",
}

local GearsTab = Window:Tab({ Title = "Gears", Icon = "wrench" })

local autobuy_gear_selected = {}
for _, gear in ipairs(gears) do
    autobuy_gear_selected[gear] = false
end

local autobuy_gear_running = false
local autobuy_gear_thread

GearsTab:Toggle({
    Title = "⚡ AUTOBUY GEARS (Main Switch)",
    Icon = "zap",
    Default = false,
    Callback = function(state)
        autobuy_gear_running = state
        if autobuy_gear_running then
            autobuy_gear_thread = task.spawn(function()
                while autobuy_gear_running do
                    for gear, selected in pairs(autobuy_gear_selected) do
                        if selected then
                            ReplicatedStorage.GameEvents.BuyGearStock:FireServer(gear)
                            task.wait(0.15)
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

GearsTab:Section({ Title = "Select gears to autobuy:" })

for _, gear in ipairs(gears) do
    GearsTab:Toggle({
        Title = gear,
        Default = false,
        Callback = function(state)
            autobuy_gear_selected[gear] = state
        end
    })
end


local honeyShopItems = {
    "Flower Seed Pack",
    "Nectarine",
    "Hive Fruit",
    "Honey Sprinkler",
    "Bee Egg",
    "Bee Crate",
    "Honey Comb",
    "Bee Chair",
    "Honey Torch",
    "Honey Walkway"
}

local EventsTab = Window:Tab({ Title = "Events", Icon = "gift" })

-- Main Autobuy Honey Shop Items Toggle (like Autobuy Seeds)
local autobuy_honey_selected = {}
for _, item in ipairs(honeyShopItems) do
    autobuy_honey_selected[item] = false
end
local autobuy_honey_running = false
local autobuy_honey_thread

EventsTab:Toggle({
    Title = "⚡ AUTOBUY HONEY SHOP ITEMS (Main Switch)",
    Icon = "zap",
    Default = false,
    Callback = function(state)
        autobuy_honey_running = state
        if autobuy_honey_running then
            autobuy_honey_thread = task.spawn(function()
                while autobuy_honey_running do
                    for item, selected in pairs(autobuy_honey_selected) do
                        if selected then
                            ReplicatedStorage.GameEvents.BuyEventShopStock:FireServer(item)
                            task.wait(0.15)
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            if autobuy_honey_thread then
                task.cancel(autobuy_honey_thread)
                autobuy_honey_thread = nil
            end
        end
    end
})

EventsTab:Section({ Title = "Select Honey Shop Items:" })
for _, item in ipairs(honeyShopItems) do
    EventsTab:Toggle({
        Title = item,
        Default = false,
        Callback = function(state)
            autobuy_honey_selected[item] = state
        end
    })
end

EventsTab:Section({ Title = "Shop & Collect Actions:" })

-- Open Shop UI Button (one-time action)
EventsTab:Button({
    Title = "Open Shop UI",
    Icon = "shopping-bag",
    Callback = function()
        local Players = game:GetService("Players")
        local localPlayer = Players.LocalPlayer
        local shop = localPlayer.PlayerGui:FindFirstChild("HoneyEventShop_UI")
        if shop then
            shop.Enabled = not shop.Enabled
        else
            warn("HoneyEventShop_UI not found in PlayerGui!")
        end
    end
})


EventsTab:Section({ Title = "Event ESP / Automation:" })

-- Mutation ESP Toggle
local mutEspRunning = false
local mutEspThread
EventsTab:Toggle({
    Title = "Mutation ESP",
    Icon = "eye",
    Default = false,
    Callback = function(state)
        mutEspRunning = state
        local function clr()
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BillboardGui") and v.Name == "MutationESP" then v:Destroy() end
            end
        end
        local c = {
            Wet=Color3.fromRGB(100,200,255),Gold=Color3.fromRGB(255,215,0),Frozen=Color3.fromRGB(135,206,235),
            Rainbow=Color3.fromRGB(255,0,255),Choc=Color3.fromRGB(120,72,0),Chilled=Color3.fromRGB(170,230,255),
            Shocked=Color3.fromRGB(255,255,100),Moonlit=Color3.fromRGB(150,100,255),Bloodlit=Color3.fromRGB(200,10,60),
            Celestial=Color3.fromRGB(200,255,255),Disco=Color3.fromRGB(255,120,255),Zombified=Color3.fromRGB(80,255,100),
            Plasma=Color3.fromRGB(60,255,255),["Honey Glazed"]=Color3.fromRGB(255,200,75),Pollinated=Color3.fromRGB(225,255,130)
        }
        if mutEspRunning then
            mutEspThread = task.spawn(function()
                local mutations = {
                    "Wet","Gold","Frozen","Rainbow","Choc","Chilled","Shocked","Moonlit","Bloodlit","Celestial",
                    "Disco","Zombified","Plasma","Honey Glazed","Pollinated"
                }
                while mutEspRunning do
                    clr()
                    local function getMyFarm()
                        for _,farm in ipairs(workspace.Farm:GetChildren()) do
                            local d = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
                            if d and d:FindFirstChild("Owner") and d.Owner.Value == game.Players.LocalPlayer.Name then
                                return farm
                            end
                        end
                    end
                    local g = getMyFarm()
                    if g then
                        local pl = g.Important:FindFirstChild("Plants_Physical")
                        if pl then
                            for _, pt in ipairs(pl:GetChildren()) do
                                local fnd = {}
                                for _, mm in ipairs(mutations) do
                                    if pt:GetAttribute(mm) then table.insert(fnd, mm) end
                                end
                                if #fnd > 0 then
                                    local bp = pt:FindFirstChildWhichIsA("BasePart") or pt.PrimaryPart
                                    if bp then
                                        local gui = Instance.new("BillboardGui")
                                        gui.Name = "MutationESP"
                                        gui.Adornee = bp
                                        gui.Size = UDim2.new(0, 100, 0, 20)
                                        gui.AlwaysOnTop = true
                                        gui.StudsOffset = Vector3.new(0, 6, 0)
                                        local lbl = Instance.new("TextLabel", gui)
                                        lbl.Size = UDim2.new(1, 0, 1, 0)
                                        lbl.BackgroundTransparency = 1
                                        lbl.Text = table.concat(fnd, " + ")
                                        lbl.TextColor3 = c[fnd[1]] or Color3.new(1,1,1)
                                        lbl.TextScaled = false
                                        lbl.TextSize = 12
                                        lbl.Font = Enum.Font.GothamBold
                                        gui.Parent = bp
                                    end
                                end
                            end
                        end
                    end
                    task.wait(5)
                end
                clr()
            end)
        else
            if mutEspThread then
                task.cancel(mutEspThread)
                mutEspThread = nil
            end
            clr()
        end
    end
})

-- Honey ESP Toggle
local honeyEspRunning = false
local honeyEspThread
EventsTab:Toggle({
    Title = "Honey ESP",
    Icon = "sun",
    Default = false,
    Callback = function(state)
        honeyEspRunning = state
        local mutationName = "Pollinated"
        local mutationColor = Color3.fromRGB(255, 225, 80)
        local function clearESP()
            for _,v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BillboardGui") and v.Name=="MutationESP" then v:Destroy() end
            end
        end
        local function getMyFarm()
            for _,farm in ipairs(workspace.Farm:GetChildren()) do
                local d = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
                if d and d:FindFirstChild("Owner") and d.Owner.Value == game.Players.LocalPlayer.Name then
                    return farm
                end
            end
        end
        local function showPollinatedESP()
            clearESP()
            local myFarm = getMyFarm()
            if not myFarm then return end
            local plants = myFarm.Important and myFarm.Important:FindFirstChild("Plants_Physical")
            if not plants then return end
            for _,plant in ipairs(plants:GetChildren()) do
                if plant:GetAttribute(mutationName) then
                    for _,bp in ipairs(plant:GetDescendants()) do
                        if bp:IsA("BasePart") then
                            local gui = Instance.new("BillboardGui")
                            gui.Name = "MutationESP"
                            gui.Adornee = bp
                            gui.Size = UDim2.new(0, 100, 0, 20)
                            gui.AlwaysOnTop = true
                            gui.StudsOffset = Vector3.new(0, 6, 0)
                            local lbl = Instance.new("TextLabel", gui)
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.Text = mutationName
                            lbl.TextColor3 = mutationColor
                            lbl.TextSize = 13
                            lbl.Font = Enum.Font.GothamBold
                            gui.Parent = bp
                        end
                    end
                end
            end
        end
        if honeyEspRunning then
            honeyEspThread = task.spawn(function()
                while honeyEspRunning do
                    showPollinatedESP()
                    task.wait(5)
                end
            end)
        else
            if honeyEspThread then
                task.cancel(honeyEspThread)
                honeyEspThread = nil
            end
            clearESP()
        end
    end
})


EventsTab:Section({ Title = "Auto Honey Farm" })

local AutoCollectHoneyEnabled = false
local AutoGivePlantsEnabled = false

-- Honey Collect Only Toggle
local honeyCollecting = false
local honeyCollectThread
EventsTab:Toggle({
    Title = "Honey Collect Only",
    Icon = "droplet",
    Default = false,
    Callback = function(state)
        honeyCollecting = state
        if honeyCollecting then
            honeyCollectThread = task.spawn(function()
                local Players = game:GetService("Players")
                local localPlayer = Players.LocalPlayer
                local function isInventoryFull()
                    return #localPlayer.Backpack:GetChildren() >= 200
                end
                local function getMyFarm()
                    for _,farm in ipairs(workspace.Farm:GetChildren()) do
                        local d = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
                        if d and d:FindFirstChild("Owner") and d.Owner.Value == localPlayer.Name then
                            return farm
                        end
                    end
                end
                local function getMyHoneyCrops()
                    local myFarm = getMyFarm()
                    local crops = {}
                    if myFarm then
                        local plants = myFarm:FindFirstChild("Important") and myFarm.Important:FindFirstChild("Plants_Physical")
                        if plants then
                            for _, plant in ipairs(plants:GetChildren()) do
                                for _, part in ipairs(plant:GetDescendants()) do
                                    if part:IsA("BasePart") and part:FindFirstChildOfClass("ProximityPrompt") then
                                        local parPlant = part.Parent
                                        if parPlant and (parPlant:GetAttribute("Honey Glazed") or parPlant:GetAttribute("Pollinated")) then
                                            table.insert(crops, part)
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end
                    return crops
                end
                while honeyCollecting do
                    if isInventoryFull() then
                        repeat
                            task.wait(0.5)
                        until not isInventoryFull() or not honeyCollecting
                    end
                    if not honeyCollecting then break end
                    local crops = getMyHoneyCrops()
                    for _, crop in ipairs(crops) do
                        if not honeyCollecting or isInventoryFull() then return end
                        local char = localPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp and crop and crop.Parent then
                            hrp.CFrame = CFrame.new(crop.Position + Vector3.new(0, 3, 0))
                            task.wait(0.15)
                            local prompt = crop:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then
                                pcall(function() fireproximityprompt(prompt) end)
                                task.wait(0.1)
                            end
                        end
                    end
                    task.wait(0.2)
                end
            end)
        else
            if honeyCollectThread then
                task.cancel(honeyCollectThread)
                honeyCollectThread = nil
            end
        end
    end
})

local function getHoneyMachineData()
    local success, result = pcall(function()
        local DataService = require(ReplicatedStorage.Modules.DataService)
        local data = DataService:GetData()
        if data and data.HoneyMachine then
            return data.HoneyMachine
        end
        return nil
    end)
    if success then return result else return nil end
end

local function findHoneyMachine()
    local honeyMachine = workspace.Interaction.UpdateItems:FindFirstChild("HoneyCombpressor", true)
    if not honeyMachine then
        honeyMachine = ReplicatedStorage.Modules.UpdateService:FindFirstChild("HoneyCombpressor", true)
    end
    return honeyMachine
end

local autoCollectHoneyThread
local autoGivePlantsThread

local function collectHoney()
    local honeyMachine = findHoneyMachine()
    if not honeyMachine then return false end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = honeyMachine.Spout.Jar.CFrame + Vector3.new(0, 5, 0)
        task.wait(0.7)
        local HoneyMachineService_RE = ReplicatedStorage.GameEvents:FindFirstChild("HoneyMachineService_RE")
        if HoneyMachineService_RE then
            for i = 1, 3 do
                HoneyMachineService_RE:FireServer("MachineInteract")
                task.wait(0.25)
            end
            return true
        end
    end
    return false
end

local function compressPlants()
    local honeyMachine = findHoneyMachine()
    if not honeyMachine then return false end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = honeyMachine.HoneyFill.Outer.CFrame + Vector3.new(0, 5, 0)
        task.wait(0.7)
        local HoneyMachineService_RE = ReplicatedStorage.GameEvents:FindFirstChild("HoneyMachineService_RE")
        if HoneyMachineService_RE then
            for i = 1, 2 do
                HoneyMachineService_RE:FireServer("MachineInteract")
                task.wait(0.25)
            end
            return true
        end
    end
    return false
end

local function autoCollectHoney()
    if autoCollectHoneyThread then return end
    autoCollectHoneyThread = task.spawn(function()
        while AutoCollectHoneyEnabled do
            task.wait(2)
            local honeyData = getHoneyMachineData()
            if honeyData then
                if honeyData.HoneyStored > 0 then
                    if collectHoney() then
                        WindUI:Notify({ Title = "Autohoney", Content = "Collected " .. honeyData.HoneyStored .. " honey!" })
                        task.wait(0.5)
                    end
                elseif honeyData.PlantWeight >= 10 and honeyData.TimeLeft <= 0 then
                    if compressPlants() then
                        WindUI:Notify({ Title = "Autohoney", Content = "Started honey compression process!" })
                        task.wait(1)
                    end
                end
            end
        end
        autoCollectHoneyThread = nil
    end)
end

local function getAllPollinatedTools()
    local found = {}
    -- Backpack
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("Pollinated") then
            table.insert(found, tool)
        end
    end
    -- Equipped
    if LocalPlayer.Character then
        for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("Pollinated") then
                table.insert(found, tool)
            end
        end
    end
    return found
end

local function equipTool(tool)
    if tool and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and tool.Parent ~= LocalPlayer.Character then
            humanoid:EquipTool(tool)
            task.wait(0.2)
        end
    end
end

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(1, i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

local function autoGivePlants()
    if autoGivePlantsThread then return end
    autoGivePlantsThread = task.spawn(function()
        while AutoGivePlantsEnabled do
            local honeyData = getHoneyMachineData()
            if honeyData and honeyData.TimeLeft <= 0 and honeyData.PlantWeight < 10 and honeyData.HoneyStored <= 0 then
                local pollinatedTools = getAllPollinatedTools()
                if #pollinatedTools == 0 then
                    WindUI:Notify({ Title = "Autohoney", Content = "No pollinated fruit found in inventory!" })
                    task.wait(2)
                else
                    shuffle(pollinatedTools)
                    for _, tool in ipairs(pollinatedTools) do
                        if not AutoGivePlantsEnabled then break end
                        equipTool(tool)
                        local tryStart = tick()
                        local sent = false
                        while AutoGivePlantsEnabled and (tick() - tryStart) < 5 do
                            local HoneyMachineService_RE = ReplicatedStorage.GameEvents:FindFirstChild("HoneyMachineService_RE")
                            if HoneyMachineService_RE then
                                HoneyMachineService_RE:FireServer("MachineInteract")
                            end
                            local stillThere = false
                            if LocalPlayer.Character then
                                for _, t in ipairs(LocalPlayer.Character:GetChildren()) do
                                    if t == tool then
                                        stillThere = true
                                        break
                                    end
                                end
                            end
                            if not stillThere then
                                sent = true
                                break
                            end
                            task.wait(1)
                        end
                        if sent then
                            WindUI:Notify({ Title = "Autohoney", Content = "Pollinated fruit sent to honey machine!" })
                            task.wait(1)
                            break
                        else
                            WindUI:Notify({ Title = "Autohoney", Content = "Current fruit could not be sent. Swapping fruit!" })
                            task.wait(0.5)
                        end
                    end
                end
            else
                task.wait(1)
            end
        end
        autoGivePlantsThread = nil
    end)
end

EventsTab:Toggle({
    Title = "Auto Collect Honey",
    Icon = "droplet",
    Default = false,
    Callback = function(state)
        AutoCollectHoneyEnabled = state
        if state then
            autoCollectHoney()
        else
            if autoCollectHoneyThread then
                task.cancel(autoCollectHoneyThread)
                autoCollectHoneyThread = nil
            end
        end
    end
})

EventsTab:Toggle({
    Title = "Auto Give Plants",
    Icon = "leaf",
    Default = false,
    Callback = function(state)
        AutoGivePlantsEnabled = state
        if state then
            autoGivePlants()
        else
            if autoGivePlantsThread then
                task.cancel(autoGivePlantsThread)
                autoGivePlantsThread = nil
            end
        end
    end
})



local CraftingTab = Window:Tab({ Title = "Crafting", Icon = "hammer" })

local recipesList = {
    "Tropical Mist Sprinkler",
    "Berry Blusher Sprinkler",
    "Spice Spritzer Sprinkler",
    "Sweet Soaker Sprinkler",
    "Flower Froster Sprinkler",
    "Stalk Sprout Sprinkler",
    "Mutation Spray Choc",
    "Mutation Spray Pollinated",
    "Mutation Spray Shocked",
    "Honey Crafters Crate",
    "Anti Bee Egg",
    "Pack Bee"
}

-- you can expand this table as you discover exact requirements
local itemRecipes = {
    ["Tropical Mist Sprinkler"] = {
        { slot = 1, name = "Coconut",         itemType = "Holdable" },
        { slot = 2, name = "Dragon Fruit",    itemType = "Holdable" },
        { slot = 3, name = "Mango",           itemType = "Holdable" },
        { slot = 4, name = "Godly Sprinkler", itemType = "Sprinkler" },
    },
    ["Berry Blusher Sprinkler"] = {
        { slot = 1, name = "Grape",        itemType = "Holdable" },
        { slot = 2, name = "Blueberry",    itemType = "Holdable" },
        { slot = 3, name = "Strawberry",   itemType = "Holdable" },
        { slot = 4, name = "Godly Sprinkler", itemType = "Sprinkler" },
    },
    ["Spice Spritzer Sprinkler"] = {
        { slot = 1, name = "Pepper",           itemType = "Holdable" },
        { slot = 2, name = "Ember Lily",       itemType = "Holdable" },
        { slot = 3, name = "Cacao",            itemType = "Holdable" },
        { slot = 4, name = "Master Sprinkler", itemType = "Sprinkler" },
    },
    ["Sweet Soaker Sprinkler"] = {
        { slot = 1, name = "Watermelon",       itemType = "Holdable" },
        { slot = 2, name = "Watermelon",       itemType = "Holdable" },
        { slot = 3, name = "Watermelon",       itemType = "Holdable" },
        { slot = 4, name = "Master Sprinkler", itemType = "Sprinkler" },
    },
    ["Flower Froster Sprinkler"] = {
        { slot = 1, name = "Orange Tulip",       itemType = "Holdable" },
        { slot = 2, name = "Daffodil",           itemType = "Holdable" },
        { slot = 3, name = "Advanced Sprinkler", itemType = "Sprinkler" },
        { slot = 4, name = "Basic Sprinkler",    itemType = "Sprinkler" },
    },
    ["Stalk Sprout Sprinkler"] = {
        { slot = 1, name = "Bamboo",             itemType = "Holdable" },
        { slot = 2, name = "BeanStalk",          itemType = "Holdable" },
        { slot = 3, name = "Mushroom",           itemType = "Holdable" },
        { slot = 4, name = "Advanced Sprinkler", itemType = "Sprinkler" },
    },
    -- Add more recipes below as you discover them!
}

local selectedRecipe = recipesList[1]

CraftingTab:Section({ Title = "Select Recipe to Craft:" })
CraftingTab:Dropdown({
    Title = "Select Recipe",
    Values = recipesList,
    Default = selectedRecipe,
    Callback = function(val)
        selectedRecipe = val
    end
})

CraftingTab:Section({ Title = "Actions:" })

local autocraftThread = nil
CraftingTab:Toggle({
    Title = "Autocraft",
    Icon = "zap",
    Default = false,
    Callback = function(enabled)
        if enabled then
            autocraftThread = task.spawn(function()
                while enabled do
                    local bench = workspace.Interaction.UpdateItems:FindFirstChild("NewCrafting"):FindFirstChild("EventCraftingWorkBench")
                    local CraftingRemote = game:GetService("ReplicatedStorage").GameEvents.CraftingGlobalObjectService
                    CraftingRemote:FireServer("SetRecipe", bench, "GearEventWorkbench", selectedRecipe)
                    task.wait(60)
                end
            end)
        else
            if autocraftThread then
                task.cancel(autocraftThread)
                autocraftThread = nil
            end
        end
    end
})

CraftingTab:Divider({ Text = "Auto Place Items" })

local autoplaceThread = nil
CraftingTab:Toggle({
    Title = "Auto Place Items",
    Icon = "package",
    Default = false,
    Callback = function(enabled)
        if enabled then
            autoplaceThread = task.spawn(function()
                while enabled do
                    local recipe = itemRecipes[selectedRecipe]
                    if recipe then
                        -- TP to bench
                        local bench = workspace.Interaction.UpdateItems:FindFirstChild("NewCrafting"):FindFirstChild("EventCraftingWorkBench")
                        local char = game.Players.LocalPlayer.Character
                        if bench and bench.PrimaryPart and char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = bench.PrimaryPart.CFrame * CFrame.new(0, 0, -3) + Vector3.new(0, 3, 0)
                        end

                        local function findAndEquip(itemName)
                            local lp = game.Players.LocalPlayer
                            local wanted = itemName:lower()
                            
                            -- first check if already holding the item
                            for _, tool in ipairs(char:GetChildren()) do
                                if tool:IsA("Tool") then
                                    local n = tool.Name:lower()
                                    if n:find(wanted) and not n:find("seed") then
                                        return tool
                                    end
                                end
                            end
                            
                            -- otherwise, search backpack
                            for _, tool in ipairs(lp.Backpack:GetChildren()) do
                                if tool:IsA("Tool") then
                                    local n = tool.Name:lower()
                                    if n:find(wanted) and not n:find("seed") then
                                        tool.Parent = char
                                        task.wait(0.3) -- Give time for equip animation
                                        return tool
                                    end
                                end
                            end
                            return nil
                        end

                        -- for each slot, try to equip and input the needed item
                        for _, req in ipairs(recipe) do
                            local tool = findAndEquip(req.name)
                            if tool then
                                task.wait(0.5) -- wait for item to be properly equipped
                                
                                -- Get the UUID of the equipped item
                                local uuid = tool:GetAttribute("c")
                                if uuid then
                                    local workbench = workspace.Interaction.UpdateItems:FindFirstChild("NewCrafting"):FindFirstChild("EventCraftingWorkBench")
                                    if workbench then
                                        local CraftingRemote = game:GetService("ReplicatedStorage").GameEvents.CraftingGlobalObjectService
                                        CraftingRemote:FireServer(
                                            "InputItem",
                                            workbench,
                                            "GearEventWorkbench",
                                            req.slot,
                                            { ItemType = req.itemType, ItemData = { UUID = uuid } }
                                        )
                                        print("Placed", req.name, "in slot", req.slot)
                                    end
                                end
                            end
                            task.wait(0.5) -- small delay between slots
                        end
                    end
                    task.wait(5) -- wait before trying again
                end
            end)
        else
            if autoplaceThread then
                task.cancel(autoplaceThread)
                autoplaceThread = nil
            end
        end
    end
})

CraftingTab:Toggle({
    Title = "AutoClaim",
    Icon = "gift", -- or any icon you prefer
    Default = false,
    Callback = function(enabled)
        if enabled then
            autoClaimThread = task.spawn(function()
                while enabled do
                    local bench = workspace:WaitForChild("Interaction"):WaitForChild("UpdateItems"):WaitForChild("NewCrafting"):WaitForChild("EventCraftingWorkBench")
                    local CraftingRemote = game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("CraftingGlobalObjectService")
                    CraftingRemote:FireServer("Claim", bench, "GearEventWorkbench", 1)
                    task.wait(10) -- Claim every 2 seconds (adjust if needed)
                end
            end)
        else
            if autoClaimThread then
                task.cancel(autoClaimThread)
                autoClaimThread = nil
            end
        end
    end
})




local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })


-- Notification Section
local notifSection = SettingsTab:Section({ Title = "" })

-- Webhook Input
local webhookBox
SettingsTab:Section({ Title = "Webhook (optional, for Discord notifications, etc.):" })
webhookBox = SettingsTab:Input({
    Title = "Webhook URL",
    Default = "",
    Placeholder = "Paste your Discord webhook URL here...",
    Callback = function(text)
        -- You can access .Text on webhookBox if needed elsewhere
    end
})

local HttpService = game:GetService("HttpService")

-- Join Low Server Button
SettingsTab:Button({
    Title = "Join Low Server",
    Icon = "cloud",
    Callback = function()
        notifSection:SetTitle("Searching for low server...")
        local minPlayers, bestId = math.huge, nil
        local placeId = game.PlaceId
        local cursor = ""
        local function fetchServers()
            local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)
            if cursor ~= "" then url = url.."&cursor="..cursor end
            local response = game:HttpGet(url)
            local data = HttpService:JSONDecode(response)
            for _, server in ipairs(data.data or {}) do
                if server.playing < minPlayers and server.playing > 0 and not server.full then
                    minPlayers = server.playing
                    bestId = server.id
                end
            end
            cursor = data.nextPageCursor or ""
            return cursor ~= ""
        end
        for i=1,3 do if not fetchServers() then break end end
        if bestId then
            notifSection:SetTitle("Teleporting to low server...")
            game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, bestId)
        else
            notifSection:SetTitle("No suitable server found!")
        end
    end
})

-- Delete Other Farms Button
SettingsTab:Button({
    Title = "Delete Other Farms",
    Icon = "trash",
    Callback = function()
        local myName = game.Players.LocalPlayer.Name
        for _, farm in ipairs(workspace.Farm:GetChildren()) do
            local data = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
            if data and data:FindFirstChild("Owner") and data.Owner.Value ~= myName then
                farm:Destroy()
            end
        end
        notifSection:SetTitle("Other farms deleted.")
    end
})

-- Reduce Lag Button
SettingsTab:Button({
    Title = "Reduce Lag",
    Icon = "activity",
    Callback = function()
        pcall(function()
            local l=game:GetService("Lighting")
            l.GlobalShadows=false l.FogEnd=1e10 l.Brightness=0 l.EnvironmentDiffuseScale=0 l.EnvironmentSpecularScale=0 l.OutdoorAmbient=Color3.new(0,0,0)
            local t=workspace:FindFirstChildOfClass("Terrain")
            if t then t.WaterWaveSize=0 t.WaterWaveSpeed=0 t.WaterReflectance=0 t.WaterTransparency=1 end
            for _,v in pairs(game:GetDescendants()) do
                if v:IsA("Decal")or v:IsA("Texture")or v:IsA("ShirtGraphic")or v:IsA("Accessory")or v:IsA("Clothing")then v:Destroy()
                elseif v:IsA("ParticleEmitter")or v:IsA("Trail")then v.Enabled=false
                elseif v:IsA("Explosion")then v.Visible=false
                elseif v:IsA("MeshPart")or v:IsA("Part")or v:IsA("UnionOperation")then v.Material=Enum.Material.SmoothPlastic v.Reflectance=0 v.CastShadow=false end
            end
            workspace.StreamingEnabled=true workspace.StreamingMinRadius=32 workspace.StreamingTargetRadius=64
            settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 settings().Rendering.EditQualityLevel=Enum.QualityLevel.Level01
            for _,o in pairs(workspace:GetDescendants())do
                if o:IsA("BasePart")then pcall(function()o.TextureID=""end) o.CastShadow=false end
                if o:IsA("ParticleEmitter")or o:IsA("Beam")or o:IsA("Trail")then o.Enabled=false end
                if o:IsA("BasePart")and(o.Name=="Wall"or o.Name=="ColorWall")then o:Destroy()end
            end
        end)
        notifSection:SetTitle("Lag reduced!")
    end
})



local HttpService = game:GetService("HttpService")
local webhookReq = (syn and syn.request) or (http and http.request) or http_request or request or httprequest
local localPlayer = game:GetService("Players").LocalPlayer

local WebhookTab = Window:Tab({ Title = "Webhook", Icon = "send" })

-- Notification section for feedback
local notifSection = WebhookTab:Section({ Title = "" })

-- Input for webhook URL
local webhookUrl = ""
WebhookTab:Input({
    Title = "Discord Webhook URL",
    Placeholder = "Paste your Discord webhook here...",
    Value = "",
    Callback = function(text)
        webhookUrl = text
    end
})

-- Slider for interval (WindUI correct layout)
local minValue, maxValue = 1, 60
local sliderValue = 3
WebhookTab:Slider({
    Title = "Send notification interval (minutes)",
    Desc = "How many minutes between Discord webhook sends.",
    Value = {
        Min = minValue,
        Max = maxValue,
        Default = sliderValue
    },
    Callback = function(val)
        sliderValue = val
        notifSection:SetTitle(("Send notification every %d minute%s"):format(
            sliderValue, sliderValue == 1 and "" or "s"))
    end
})
notifSection:SetTitle(("Send notification every %d minute%s"):format(
    sliderValue, sliderValue == 1 and "" or "s"))

-- === WEBHOOK LOGIC (CUMULATIVE GAINS ONLY, EXCLUDING STARTING ITEMS/SEEDS) ===
local leaderstats = localPlayer:WaitForChild("leaderstats")
local shecklesStat = leaderstats:WaitForChild("Sheckles")

local webhookActive = false
local trackerThread = nil
local sessionStart = tick()
local startingInventory = {}
local cumulativeGained = {}

local function getBaseName(name)
    local base = name:match("^(.-) %b[]")
    if base then return base end
    base = name:match("^(.-)%[")
    if base then return base:sub(1, -2) end
    return name
end

local function getCurrentInventory()
    local counts = {}
    for _, item in ipairs(localPlayer.Backpack:GetChildren()) do
        local rawName = item:GetAttribute("Seed") or item.Name
        local baseName = getBaseName(rawName)
        counts[baseName] = (counts[baseName] or 0) + 1
    end
    return counts
end

local function updateCumulativeGained()
    local current = getCurrentInventory()
    for item, count in pairs(current) do
        local startCount = startingInventory[item] or 0
        local gainedNow = count - startCount
        if gainedNow > 0 then
            cumulativeGained[item] = math.max(cumulativeGained[item] or 0, gainedNow)
        end
    end
end

local function formatTotalsGained()
    local lines = {}
    for item, gained in pairs(cumulativeGained) do
        if gained > 0 then
            table.insert(lines, ("%s: %d"):format(item, gained))
        end
    end
    table.sort(lines)
    return #lines > 0 and table.concat(lines, "\n") or "No new items/seeds gained."
end

local function fmt(n)
    if n >= 1e9 then return ("%.2fB"):format(n/1e9)
    elseif n >= 1e6 then return ("%.2fM"):format(n/1e6)
    elseif n >= 1e3 then return ("%.2fK"):format(n/1e3)
    else return tostring(n)
    end
end

local function sendWebhook(username, currentMoney, uptime)
    if webhookUrl == "" then return end
    local embed = {
        title = ("%s's Garden Gained Items/Seeds"):format(username),
        color = 0x48db6a,
        fields = {
            { name = "Total Money", value = fmt(currentMoney), inline = false },
            { name = "Items/Seeds Gained", value = ("```%s```"):format(formatTotalsGained()), inline = false },
            { name = "Session Uptime", value = uptime, inline = false }
        }
    }
    local payload = { embeds = {embed} }
    local success, err = pcall(function()
        webhookReq{
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        }
    end)
    if success then
        notifSection:SetTitle("✅ Webhook sent!")
    else
        notifSection:SetTitle("❌ Failed to send webhook.")
    end
end

local function startWebhook()
    webhookActive = true
    notifSection:SetTitle("Webhook tracking started.")
    sessionStart = tick()
    if trackerThread then
        task.cancel(trackerThread)
    end
    startingInventory = getCurrentInventory()
    cumulativeGained = {}
    trackerThread = task.spawn(function()
        while webhookActive do
            for i = 1, sliderValue * 60 do
                if not webhookActive then return end
                task.wait(1)
                updateCumulativeGained()
            end
            local nowMoney = shecklesStat.Value
            local uptime = os.date("!%X", math.floor(tick() - sessionStart))
            sendWebhook(localPlayer.Name, nowMoney, uptime)
        end
    end)
end

local function stopWebhook()
    webhookActive = false
    notifSection:SetTitle("Webhook tracking stopped.")
    if trackerThread then
        task.cancel(trackerThread)
        trackerThread = nil
    end
end

WebhookTab:Toggle({
    Title = "Webhook Tracking",
    Desc = "Toggle to enable/disable sending Discord webhooks.",
    Value = false,
    Callback = function(state)
        if state then
            if webhookUrl == "" or not webhookUrl:find("discord.com/api/webhooks/") then
                notifSection:SetTitle("❌ Please enter a valid Discord webhook URL!")
                return
            end
            startWebhook()
        else
            stopWebhook()
        end
    end
})


-- SERVICES & MODULES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local ActivePetsService = require(ReplicatedStorage.Modules.PetServices.ActivePetsService)
local DataService = require(ReplicatedStorage.Modules.DataService)
local CalculatePetValue = require(ReplicatedStorage.Modules:WaitForChild("CalculatePetValue"))
local GetFarm = require(ReplicatedStorage.Modules.GetFarm)

local PetsTab = Window:Tab({ Title = "Pets", Icon = "paw" })

-- ========== Utility ==========
local function formatNumber(n)
    local sign = (n < 0) and "-" or ""
    local absn = math.abs(n)
    local suffix = ""
    if absn >= 1e12 then
        n = n/1e12; suffix = "T"
    elseif absn >= 1e9 then
        n = n/1e9; suffix = "B"
    elseif absn >= 1e6 then
        n = n/1e6; suffix = "M"
    end
    local i = math.floor(math.abs(n))
    local f = math.abs(n) - i
    local frac = (f > 0) and ("%.2f"):format(f):sub(2) or ""
    local s = tostring(i)
    while true do
        local count
        s, count = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if count == 0 then break end
    end
    return sign .. s .. frac .. suffix
end

-- ========== PET EGG SELECTION ==========
local petEggNames = {
    "Common Egg",
    "Uncommon Egg",
    "Rare Egg",
    "Legendary Egg",
    "Mythical Egg",
    "Bug Egg",
    "Night Egg",
    "Bee Egg"
}
local Buy_PetEggs = {}
for _, egg in ipairs(petEggNames) do
    Buy_PetEggs[egg] = false
end

-- ========== PET LOGIC STATE ==========
local threads = {}

local function stopThread(name)
    if threads[name] then
        pcall(function() task.cancel(threads[name]) end)
    end
    threads[name] = nil
end

-- ========== DYNAMIC EQUIPPED PET SELECTION ==========
local selectedEquippedPets = {}
local equippedPetSection -- reference to WindUI section
local equippedPetToggles = {} -- Store toggle objects to update/reset if needed

local function getEquippedPets()
    local petData = ActivePetsService:GetPlayerDatastorePetData(player.Name)
    local equipped = {}
    if petData and petData.EquippedPets and petData.PetInventory and petData.PetInventory.Data then
        for _, uuid in ipairs(petData.EquippedPets) do
            local pet = petData.PetInventory.Data[uuid]
            if pet and pet.PetType then
                equipped[pet.PetType] = true
            end
        end
    end
    return equipped
end

local function refreshEquippedPetsSection()
    -- Clear toggles if section exists
    if equippedPetSection and equippedPetSection.Clear then
        equippedPetSection:Clear()
    end
    -- Get currently equipped pets
    local equipped = getEquippedPets()
    equippedPetSection = PetsTab:Section({ Title = "Select Equipped Pets to Auto Feed", Color = Color3.fromRGB(180,255,180) })
    equippedPetToggles = {}
    for petType, _ in pairs(equipped) do
        selectedEquippedPets[petType] = selectedEquippedPets[petType] or false
        table.insert(equippedPetToggles, PetsTab:Toggle({
            Title = petType,
            Default = selectedEquippedPets[petType],
            Callback = function(state)
                selectedEquippedPets[petType] = state
            end
        }))
    end
    if next(equipped) == nil then
        PetsTab:Label({ Text = "No pets currently out. Equip pets in-game to see them here." })
    end
end

-- Optional: Refresh button in case user equips/unequips pets without reloading GUI
PetsTab:Button({
    Title = "🔄 Refresh Equipped Pets List",
    Callback = refreshEquippedPetsSection
})

-- First populate when loading tab
refreshEquippedPetsSection()

-- ========== AUTO FEED PET ==========
local function Auto_Feed_Pet(state)
    stopThread("feedpet")
    if not state then return end
    threads["feedpet"] = task.spawn(function()
        local petRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("ActivePetService")
        while true do
            local allPetsFullyFed = true
            pcall(function()
                local petData = ActivePetsService:GetPlayerDatastorePetData(player.Name)
                if not petData or not petData.EquippedPets or #petData.EquippedPets == 0 then return end
                if not petData.PetInventory or not petData.PetInventory.Data then return end
                local hungryPets = {}
                for _, uuid in ipairs(petData.EquippedPets) do
                    local pet = petData.PetInventory.Data[uuid]
                    if pet and pet.PetData then
                        local hunger = pet.PetData.Hunger or 0
                        local petType = pet.PetType
                        local PetList = require(ReplicatedStorage.Data.PetRegistry.PetList)
                        local maxHunger = (PetList[petType] and PetList[petType].DefaultHunger) or 30000
                        -- Feed only if selected in the equipped toggle list!
                        if selectedEquippedPets[petType] and hunger < maxHunger * 0.4 then
                            allPetsFullyFed = false
                            table.insert(hungryPets, { uuid = uuid, hunger = hunger, type = petType, name = pet.PetData.Name or "Unknown Pet", maxHunger = maxHunger })
                        end
                    end
                end
                table.sort(hungryPets, function(a, b) return (a.hunger / a.maxHunger) < (b.hunger / b.maxHunger) end)
                local backpack = player:FindFirstChild("Backpack")
                local character = player.Character
                if not backpack or not character then return end
                local foodTools = {}
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        local toolName = tool.Name
                        if tool:GetAttribute("IsFavorite") == true then continue end
                        if toolName:find("kg") then
                            local weightStr = toolName:match("(%d+%.?%d*)kg")
                            local weight = tonumber(weightStr)
                            if weight and weight < 20 then
                                table.insert(foodTools, tool)
                            end
                        end
                    end
                end
                for _, pet in ipairs(hungryPets) do
                    for i = 1, math.min(3, #foodTools) do
                        local food = foodTools[i]
                        local equipped = character:FindFirstChildOfClass("Tool")
                        if equipped then equipped.Parent = backpack task.wait(0.2) end
                        food.Parent = character
                        task.wait(0.3)
                        petRemote:FireServer("Feed", pet.uuid)
                        task.wait(0.5)
                        local updatedPetData = ActivePetsService:GetPetData(player.Name, pet.uuid)
                        if updatedPetData and updatedPetData.PetData then
                            local newHunger = updatedPetData.PetData.Hunger or 0
                            if newHunger >= pet.maxHunger * 0.9 then break end
                        end
                    end
                    local equipped = character:FindFirstChildOfClass("Tool")
                    if equipped then equipped.Parent = backpack end
                    task.wait(0.5)
                end
            end)
            if allPetsFullyFed then task.wait(30) else task.wait(5) end
        end
    end)
end

-- ========== AUTO PLACE EGG ==========
local eggIndex = {}
for _, egg in ipairs(petEggNames) do
    eggIndex[egg] = true
end
local function Auto_PlaceEgg(state)
    stopThread("placeegg")
    if not state then return end
    threads["placeegg"] = task.spawn(function()
        while true do
            pcall(function()
                local character = player.Character
                if not character then return end
                local playerData = DataService:GetData()
                if not playerData then return end
                local playerPlot = GetFarm(player)
                if not playerPlot then return end
                local canPlant
                for _, obj in pairs(playerPlot:GetDescendants()) do
                    if obj.Name == "Can_Plant" and obj:IsA("BasePart") then
                        canPlant = obj
                        break
                    end
                end
                if not canPlant then return end
                local currentEggCount = 0
                local existingEggs = {}
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:FindFirstChild("PetEggServer") and obj:GetAttribute("OWNER") == player.Name then
                        currentEggCount = currentEggCount + 1
                        existingEggs[obj:GetAttribute("OBJECT_UUID")] = obj
                    end
                end
                local maxEggSlots = playerData.PetsData.MutableStats.MaxEggsInFarm
                -- Hatch eggs if ready
                for _, eggObj in pairs(existingEggs) do
                    if eggObj:GetAttribute("TimeToHatch") and eggObj:GetAttribute("TimeToHatch") <= 0 then
                        game.ReplicatedStorage.GameEvents.PetEggService:FireServer("HatchPet", eggObj)
                        task.wait(1)
                        return
                    end
                end
                -- Place new eggs if space
                if currentEggCount < maxEggSlots then
                    for _, tool in ipairs(player.Backpack:GetChildren()) do
                        local isEggTool = false
                        if tool:GetAttribute("ItemType") == "PetEgg" and Buy_PetEggs[tool.Name] then isEggTool = true end
                        if not isEggTool and eggIndex[tool.Name] and Buy_PetEggs[tool.Name] then isEggTool = true end
                        if isEggTool then
                            tool.Parent = character
                            task.wait(1)
                            if character:FindFirstChild(tool.Name) then
                                local basePosition = canPlant.Position
                                local randX = math.random(-10, 10)
                                local randZ = math.random(-10, 10)
                                local eggPosition = Vector3.new(basePosition.X + randX, basePosition.Y, basePosition.Z + randZ)
                                local success = pcall(function()
                                    game.ReplicatedStorage.GameEvents.PetEggService:FireServer("CreateEgg", eggPosition)
                                end)
                                if not success then
                                    pcall(function()
                                        game.ReplicatedStorage.GameEvents.PetEggService:FireServer("PlaceEgg", eggPosition)
                                    end)
                                end
                                task.wait(1)
                                if character:FindFirstChild(tool.Name) then
                                    tool.Parent = player.Backpack
                                end
                                return
                            end
                        end
                    end
                end
            end)
            task.wait(1)
        end
    end)
end

-- ========== AUTO BUY PET EGG ==========
local function Auto_BuyEgg(state)
    stopThread("buyegg")
    if not state then return end
    threads["buyegg"] = task.spawn(function()
        while true do
            pcall(function()
                local playerData = DataService:GetData()
                if playerData and playerData.PetEggStock and playerData.PetEggStock.Stocks then
                    for eggIndex, eggData in pairs(playerData.PetEggStock.Stocks) do
                        if Buy_PetEggs[eggData.EggName] and eggData.Stock > 0 then
                            local stockAmount = eggData.Stock
                            for i = 1, stockAmount do
                                ReplicatedStorage.GameEvents.BuyPetEgg:FireServer(eggIndex)
                                task.wait(0.5)
                                local updatedData = DataService:GetData()
                                if updatedData and updatedData.PetEggStock and 
                                   updatedData.PetEggStock.Stocks[eggIndex] then
                                    local newStock = updatedData.PetEggStock.Stocks[eggIndex].Stock
                                    if newStock < stockAmount then
                                        stockAmount = newStock
                                        if stockAmount == 0 then break end
                                    else
                                        task.wait(1)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(5)
        end
    end)
end

-- ========== PETS TAB UI ==========

PetsTab:Divider()
PetsTab:Section({ Title = "Pet Automation", Color = Color3.fromRGB(80, 180, 255) })
PetsTab:Divider()

PetsTab:Toggle({
    Title = "Auto Feed Pets (Only Selected Equipped)",
    Default = false,
    Callback = function(state) Auto_Feed_Pet(state) end,
})

-- Dynamic equipped pets selection section (generated above)
-- "Refresh" button is already at top

PetsTab:Divider()
PetsTab:Toggle({
    Title = "Auto Place Eggs",
    Default = false,
    Callback = function(state) Auto_PlaceEgg(state) end,
})

PetsTab:Divider()
PetsTab:Section({ Title = "Auto Buy Pet Eggs", Color = Color3.fromRGB(255, 220, 90) })
for _, egg in ipairs(petEggNames) do
    PetsTab:Toggle({
        Title = egg,
        Default = false,
        Callback = function(state)
            Buy_PetEggs[egg] = state
        end
    })
end
PetsTab:Toggle({
    Title = "Auto Buy Selected Pet Eggs",
    Default = false,
    Callback = function(state) Auto_BuyEgg(state) end,
})
PetsTab:Button({
    Title = "Buy All Available Eggs (ONCE)",
    Callback = function()
        task.spawn(function()
            local playerData = DataService:GetData()
            if playerData and playerData.PetEggStock and playerData.PetEggStock.Stocks then
                for eggIndex, eggData in pairs(playerData.PetEggStock.Stocks) do
                    if Buy_PetEggs[eggData.EggName] and eggData.Stock > 0 then
                        local stockAmount = eggData.Stock
                        for i = 1, stockAmount do
                            ReplicatedStorage.GameEvents.BuyPetEgg:FireServer(eggIndex)
                            task.wait(0.5)
                            local updatedData = DataService:GetData()
                            if updatedData and updatedData.PetEggStock and updatedData.PetEggStock.Stocks[eggIndex] then
                                local newStock = updatedData.PetEggStock.Stocks[eggIndex].Stock
                                if newStock < stockAmount then
                                    stockAmount = newStock
                                    if stockAmount == 0 then break end
                                else
                                    task.wait(1)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end)
    end,
})

PetsTab:Divider()
PetsTab:Section({ Title = "Manual Actions", Color = Color3.fromRGB(200, 130, 255) })
PetsTab:Divider()
PetsTab:Button({
    Title = "Feed All Selected Equipped Pets NOW",
    Callback = function()
        task.spawn(function()
            Auto_Feed_Pet(false)
            Auto_Feed_Pet(true)
            task.wait(3)
            Auto_Feed_Pet(false)
        end)
    end,
})
PetsTab:Button({
    Title = "Place All Eggs NOW",
    Callback = function()
        Auto_PlaceEgg(false)
        Auto_PlaceEgg(true)
        task.wait(3)
        Auto_PlaceEgg(false)
    end,
})

local equippedPetValueSection = PetsTab:Section({ Title = "Your Pet is Worth: (Equip a pet)" })

local function updatePetValueSection(tool)
    if tool and tool:IsA("Tool") and tool:GetAttribute("ItemType") == "Pet" then
        local val = CalculatePetValue(tool)
        equippedPetValueSection:SetTitle("Your Pet is Worth: " .. formatNumber(val))
    else
        equippedPetValueSection:SetTitle("Your Pet is Worth: (Equip a pet)")
    end
end

for _, tool in ipairs(player.Backpack:GetChildren()) do
    if tool:IsA("Tool") then
        tool.Equipped:Connect(function() updatePetValueSection(tool) end)
        tool.Unequipped:Connect(function() updatePetValueSection(nil) end)
    end
end
player.Backpack.ChildAdded:Connect(function(tool)
    if tool:IsA("Tool") then
        tool.Equipped:Connect(function() updatePetValueSection(tool) end)
        tool.Unequipped:Connect(function() updatePetValueSection(nil) end)
    end
end)
if player.Character then
    for _, tool in ipairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Equipped:Connect(function() updatePetValueSection(tool) end)
            tool.Unequipped:Connect(function() updatePetValueSection(nil) end)
        end
    end
end
player.CharacterAdded:Connect(function(char)
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Equipped:Connect(function() updatePetValueSection(tool) end)
            tool.Unequipped:Connect(function() updatePetValueSection(nil) end)
        end
    end
end)

PetsTab:Divider()
