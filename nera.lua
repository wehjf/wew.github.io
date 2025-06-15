local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local character = plr.Character or plr.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local runtime = Workspace:WaitForChild("RuntimeItems")
local tesla = Workspace:WaitForChild("TeslaLab"):WaitForChild("Generator")

hrp.CFrame = tesla:GetPivot() + Vector3.new(0,5,0)
hrp.Anchored = true
task.wait(2)
hrp.Anchored = false

local function orderedSeats()
    local seats, pos = {}, hrp.Position
    for _,m in ipairs(runtime:GetChildren()) do
        if m:IsA("Model") and m.Name == "Chair" then
            local s = m:FindFirstChildOfClass("Seat")
            if s and not s.Occupant then
                table.insert(seats, {s=s, d=(s.Position-pos).Magnitude})
            end
        end
    end
    table.sort(seats, function(a,b) return a.d < b.d end)
    return seats
end

local function sitOn(seat)
    hrp.Anchored = true
    hrp.CFrame = seat.CFrame + Vector3.new(0,3,0)
    task.wait(0.2)
    hrp.Anchored = false
    task.wait(0.35)
    seat:Sit(humanoid)
end

local usedChairs = {}

local function stableMoved(startPos)
    local lastPos = nil
    for i=1,7 do
        task.wait(0.1)
        lastPos = hrp.Position
    end
    return (lastPos - startPos).Magnitude > 5
end

while true do
    local seats = orderedSeats()
    local found = false
    for _,v in ipairs(seats) do
        if not usedChairs[v.s] then
            humanoid.Sit = false
            task.wait(0.2)
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.3)
            local startPos = hrp.Position
            sitOn(v.s)
            if stableMoved(startPos) then
                usedChairs = {}
                goto sitting_success
            else
                usedChairs[v.s] = true
            end
            found = true
            break
        end
    end
    if not found then
        usedChairs = {}
    end
    task.wait(2)
end

::sitting_success::
task.wait(5)

local targetNames = {
    "GoldBar", "SilverBar", "Crucifix",
    "GoldStatue", "SilverStatue", "BrainJar"
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
    task.wait(0.6)
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
    if ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("StoreItem") then
        ReplicatedStorage.Remotes.StoreItem:FireServer(item)
    end
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
    if ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("DropItem") then
        for _ = 1, count do
            ReplicatedStorage.Remotes.DropItem:FireServer()
            task.wait(0.2)
        end
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

task.wait(1)
UseSack()

local foundItems = {}

local function alreadyTracked(pos)
    for _, v in ipairs(foundItems) do
        if (v - pos).Magnitude < 1 then
            return true
        end
    end
    return false
end

local x, y = 57, 3
local startZ, endZ, stepZ = 30000, -49032.99, -2000
local duration = 0.7

local function scanForValuables()
    local runtime = Workspace:FindFirstChild("RuntimeItems")
    if not runtime then return end
    for _, item in ipairs(runtime:GetChildren()) do
        if item:IsA("Model") and table.find(targetNames, item.Name) and item.PrimaryPart then
            local pos = item.PrimaryPart.Position
            if typeof(pos) == "Vector3" and not alreadyTracked(pos) then
                table.insert(foundItems, pos)
            end
        end
    end
end

local function tweenMovementAndTrack()
    local currentZ = startZ
    while currentZ >= endZ do
        local startCFrame = CFrame.new(x, y, currentZ)
        local endCFrame = CFrame.new(x, y, currentZ + stepZ)
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = endCFrame})
        tween:Play()

        local tweenRunning = true
        local conn
        conn = game:GetService("RunService").Heartbeat:Connect(function()
            if tweenRunning then scanForValuables() end
        end)

        tween.Completed:Wait()
        tweenRunning = false
        if conn then conn:Disconnect() end

        currentZ = currentZ + stepZ
        task.wait(0.1)
    end
end

local success, errorMessage = pcall(tweenMovementAndTrack)
if not success then
    warn("Error in tweenMovement: " .. errorMessage)
end

local storeCount = 0
local reachedLimit = false

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
            task.wait(0.4)
            if storeCount >= 80 then
                reachedLimit = true
                break
            end
        else
            table.remove(foundItems, i)
        end
        task.wait(0.1)
    end
    scanForValuables()
    task.wait(0.2)
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

if storeCount >= 80 then
    TPTo(storageLocation)
    local itemCount = getSackCount()
    if itemCount and itemCount > 0 then
        FireDrop(itemCount)
    end
    task.wait(0.3)
    return
end

dropIfFull()
