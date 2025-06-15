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
local sackCapacity = 10 -- Set to 15 if needed
local maxStoreCount = 80
local totalStoreCount = 0
local hiding = false
local pauseHiding = false

local function isInRuntimeItems(instance)
    local runtimeItems = Workspace:FindFirstChild("RuntimeItems")
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

task.spawn(function()
    task.wait(10)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/fly.github.io/refs/heads/main/fly.lua"))()
end)

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

local function unhideAllVisuals()
    local player = Players.LocalPlayer
    local radius = 2000

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

local function TPTo(position)
    pcall(function()
        hrp.CFrame = CFrame.new(position)
    end)
    task.wait(0.6)
end

local function DestroyCase()
    local castle = Workspace:FindFirstChild("VampireCastle")
    if castle then
        for _, descendant in ipairs(castle:GetDescendants()) do
            if descendant:IsA("Model") and descendant.Name == "Bookcase" then
                descendant:Destroy()
            end
        end
    end
end

local function getSeat()
    DestroyCase()
    local runtime = Workspace:FindFirstChild("RuntimeItems")
    if not runtime then return nil end
    for _, gun in ipairs(runtime:GetChildren()) do
        if gun.Name == "MaximGun" then
            local seat = gun:FindFirstChildWhichIsA("VehicleSeat")
            if seat then return seat end
        end
    end
    return nil
end

local function SitSeat(seat)
    local jumped = false
    while true do
        if humanoid.SeatPart ~= seat then
            hrp.CFrame = seat.CFrame
            task.wait(0.1)
        else
            local weld = seat:FindFirstChild("SeatWeld")
            if weld and weld.Part1 and weld.Part1:IsDescendantOf(plr.Character) then
                if not jumped then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.15)
                    hrp.CFrame = seat.CFrame
                    jumped = true
                else
                    break
                end
            else
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.2)
                jumped = false
            end
        end
        task.wait(0.05)
    end
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

-- Seating logic before valuables
while true do
    local seat = getSeat()
    if not seat then
        TPTo(Vector3.new(57, -5, -9000))
        task.wait(0.5)
        continue
    end
    seat.Disabled = false
    SitSeat(seat)
    break
end

task.wait(1)
UseSack()

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

-- MAIN LOOP
local duration = 0.7

while true do
    -- 1. Scan all goldbar locations for valuables
    local foundItems = {}
    for _, location in ipairs(goldbarLocations) do
        TPTo(location)
        task.wait(0.2)
        local runtime = Workspace:FindFirstChild("RuntimeItems")
        if runtime then
            for _, item in ipairs(runtime:GetChildren()) do
                if item:IsA("Model") and table.find(targetNames, item.Name) and item.PrimaryPart then
                    table.insert(foundItems, item)
                end
            end
        end
    end

    -- 2. If no items found or hit maxStoreCount, break and end script
    if #foundItems == 0 or totalStoreCount >= maxStoreCount then
        break
    end

    -- 3. Collect up to sackCapacity or until maxStoreCount is hit
    local collected = 0
    for i = #foundItems, 1, -1 do
        if collected >= sackCapacity or totalStoreCount >= maxStoreCount then break end
        local itemToCollect = foundItems[i]
        if itemToCollect and itemToCollect.Parent and itemToCollect.PrimaryPart then
            local pos = itemToCollect.PrimaryPart.Position
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
            collected = collected + 1
            totalStoreCount = totalStoreCount + 1
            dropIfFull()
            task.wait(0.5)
        end
    end

    -- 4. Drop any leftovers in case not full
    dropIfFull()
end

-- Final drop and cleanup
TPTo(storageLocation)
local itemCount = getSackCount()
if itemCount and itemCount > 0 then
    FireDrop(itemCount)
end
hiding = false
unhideAllVisuals()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/unfly.github.io/refs/heads/main/unfly.lua"))()
