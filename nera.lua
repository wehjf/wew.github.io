local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local character = plr.Character or plr.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local targetNames = {
    "GoldBar", "SilverBar", "Crucifix",
    "GoldStatue", "SilverStatue", "BrainJar"
}

local goldbarLocations = {
    Vector3.new(57, -5, -9000),
    Vector3.new(57, -5, 21959),
    Vector3.new(57, -5, 13973),
    Vector3.new(57, -5, 6025),
    Vector3.new(57, -5, -17737),
    Vector3.new(57, -5, -25870),
    Vector3.new(57, -5, -33844),
}

local storageLocation = Vector3.new(57, 5, 30000)
local wasStored = {}
local sackCapacity = 10

local runtimeItems = Workspace:FindFirstChild("RuntimeItems")
local hiding = false
local pauseHiding = false

local function isInRuntimeItems(instance)
    if not runtimeItems then return false end
    return instance:IsDescendantOf(runtimeItems)
end

local function hideVisuals(instance)
    if isInRuntimeItems(instance) then return end
    if instance:IsA("BasePart") then
        instance.LocalTransparencyModifier = 1
        instance.CanCollide = false
    elseif instance:IsA("Decal") or instance:IsA("Texture") then
        instance.Transparency = 1
    elseif instance:IsA("Beam") or instance:IsA("Trail") then
        instance.Enabled = false
    end
end

local function unhideAllVisuals()
    local player = Players.LocalPlayer
    local radius = 2000 -- Adjust as needed

    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local origin = character.HumanoidRootPart.Position

        for _, instance in ipairs(workspace:GetDescendants()) do
            if instance:IsA("BasePart") and (instance.Position - origin).Magnitude <= radius then
                instance.LocalTransparencyModifier = 0
                instance.CanCollide = true
            elseif (instance:IsA("Decal") or instance:IsA("Texture")) and instance:IsDescendantOf(workspace) then
                local parent = instance.Parent
                if parent and parent:IsA("BasePart") and (parent.Position - origin).Magnitude <= radius then
                    instance.Transparency = 0
                end
            elseif (instance:IsA("Beam") or instance:IsA("Trail")) and instance:IsDescendantOf(workspace) then
                local parent = instance.Parent
                if parent and parent:IsA("BasePart") and (parent.Position - origin).Magnitude <= radius then
                    instance.Enabled = true
                end
            end
        end
    end
end

coroutine.wrap(function()
    task.wait(10)
    hiding = true
    while hiding do
        if not pauseHiding then
            for _, instance in ipairs(Workspace:GetDescendants()) do
                hideVisuals(instance)
            end
        end
        task.wait(1)
    end
end)()

local function TPTo(position)
    pcall(function()
        hrp.CFrame = CFrame.new(position)
    end)
    task.wait(0.4)
end

local function TPToAndVerify(position, maxAttempts, epsilon)
    maxAttempts = maxAttempts or 6
    epsilon = epsilon or 8
    for i = 1, maxAttempts do
        TPTo(position)
        if (hrp.Position - position).Magnitude <= epsilon then
            return true
        end
        task.wait(0.3)
    end
    return (hrp.Position - position).Magnitude <= epsilon
end

local function UseSack()
    local sack = plr.Backpack:FindFirstChild("Sack")
    if sack then
        character:WaitForChild("Humanoid"):EquipTool(sack)
        return true
    end
    return false
end

local function FireStore(item)
    ReplicatedStorage.Remotes.StoreItem:FireServer(item)
end

local function isFull()
    local sack = character:FindFirstChild("Sack") or plr.Backpack:FindFirstChild("Sack")
    if sack then
        local label = sack:FindFirstChild("BillboardGui") and sack.BillboardGui:FindFirstChild("TextLabel")
        if label and (label.Text == "10/10" or label.Text == "15/15") then
            return tonumber(label.Text:match("^(%d+)/"))
        end
    end
    return nil
end

local function FireDrop(count)
    for _ = 1, count do
        ReplicatedStorage.Remotes.DropItem:FireServer()
        task.wait(0.2)
    end
end

local function dropIfFull()
    local sackCount = isFull()
    if sackCount then
        pauseHiding = true
        TPTo(storageLocation)
        FireDrop(sackCount)
        task.wait(0.3)
        TPTo(Vector3.new(57, 5, 29980))
        task.wait(0.3)
        pauseHiding = false
    end
end

local function getPos(model)
    if model:IsA("Model") then
        if model.PrimaryPart then
            return model.PrimaryPart.Position
        else
            local part = model:FindFirstChildWhichIsA("BasePart")
            if part then return part.Position end
        end
    end
    return nil
end

-- Gather valuables near all goldbar locations
local foundItems = {}
for _, location in ipairs(goldbarLocations) do
    TPTo(location)
    task.wait(0.2)
    local runtime = Workspace:FindFirstChild("RuntimeItems")
    if runtime then
        for _, item in ipairs(runtime:GetChildren()) do
            if item:IsA("Model") and table.find(targetNames, item.Name) and item.PrimaryPart then
                local pos = item.PrimaryPart.Position
                if (pos - location).Magnitude < 50 then -- within 50 studs of the location
                    table.insert(foundItems, pos)
                end
            end
        end
    end
end

-- Limit of 40 stores, then drop and end
local storeCount = 0
local reachedLimit = false
local duration = 0.7

while #foundItems > 0 and not reachedLimit do
    for i = #foundItems, 1, -1 do
        local pos = foundItems[i]
        local runtime = Workspace:FindFirstChild("RuntimeItems")
        local itemToCollect = nil
        if runtime then
            for _, item in ipairs(runtime:GetChildren()) do
                if item:IsA("Model") and table.find(targetNames, item.Name) and item.PrimaryPart and (item.PrimaryPart.Position - pos).Magnitude < 1 and not wasStored[item] then
                    itemToCollect = item
                    break
                end
            end
        end
        if itemToCollect then
            local dist = (hrp.Position - pos).Magnitude
            local targetPos = Vector3.new(pos.X, pos.Y - 5, pos.Z)
            if dist <= 15 then
                UseSack()
                FireStore(itemToCollect)
            elseif dist <= 500 then
                local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
                tween:Play()
                tween.Completed:Wait()
                UseSack()
                FireStore(itemToCollect)
            else
                TPTo(targetPos)
                UseSack()
                FireStore(itemToCollect)
            end
            wasStored[itemToCollect] = true
            table.remove(foundItems, i)
            storeCount = storeCount + 1
            dropIfFull()
            task.wait(0.5)
            if storeCount >= 40 then
                reachedLimit = true
                break
            end
        else
            table.remove(foundItems, i)
        end
    end
    -- Optionally, you can re-scan for new valuables at locations here
end

local function getSackCount()
    local sack = character:FindFirstChild("Sack") or plr.Backpack:FindFirstChild("Sack")
    if sack then
        local label = sack:FindFirstChild("BillboardGui") and sack.BillboardGui:FindFirstChild("TextLabel")
        if label then
            local current = label.Text:match("^(%d+)%/")
            return tonumber(current)
        end
    end
    return 0
end

-- After reaching limit, drop everything and unhide visuals, then end script
if storeCount >= 40 then
    local tpSuccess = TPToAndVerify(storageLocation, 6, 8)
    if tpSuccess then
        local itemCount = getSackCount()
        if itemCount and itemCount > 0 then
            FireDrop(itemCount)
        end
        hiding = false
        unhideAllVisuals()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/unfly.github.io/refs/heads/main/unfly.lua"))()
        task.wait(0.3)
        return -- end script
    else
        warn("Failed to TP to storageLocation for ending script. Script not ended, try again.")
    end
end

dropIfFull()
hiding = false
unhideAllVisuals()
