local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hum = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

local positions = {
    Vector3.new(57, -5, -9000),
    Vector3.new(57, -5, 21959),
    Vector3.new(57, -5, 13973),
    Vector3.new(57, -5, 6025),
    Vector3.new(57, -5, -17737),
    Vector3.new(57, -5, -25870),
    Vector3.new(57, -5, -33844),
    Vector3.new(57, -5, -9020)
}

local oldPos = hrp.Position
local wasStored = {}

-- === Chair Seating Logic ===

local function isUnanchored(model)
    for _, p in pairs(model:GetDescendants()) do
        if p:IsA("BasePart") and not p.Anchored then
            return true
        end
    end
    return false
end

local function findNearestValidChair(origin)
    local runtimeFolder = Workspace:FindFirstChild("RuntimeItems")
    if not runtimeFolder then return nil end

    local closestSeat, shortest = nil, math.huge
    for _, item in pairs(runtimeFolder:GetChildren()) do
        if item:IsA("Model") and item.Name == "Chair" and isUnanchored(item) then
            local seat = item:FindFirstChildWhichIsA("Seat", true)
            if seat and not seat.Occupant then
                local dist = (origin - seat.Position).Magnitude
                if dist <= 300 and dist < shortest then
                    closestSeat = seat
                    shortest = dist
                end
            end
        end
    end
    return closestSeat
end

local function sitAndWeldToSeat(seat)
    hrp.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
    wait(0.2)
    seat:Sit(hum)

    for i = 1, 30 do
        if hum.SeatPart == seat then break end
        wait(0.1)
    end

    local weld = Instance.new("WeldConstraint")
    weld.Name = "PersistentSeatWeld"
    weld.Part0 = hrp
    weld.Part1 = seat
    weld.Parent = hrp

    return seat, weld
end

-- === Gold Farming Logic ===

local function UseSack()
    local sack = player.Backpack:FindFirstChild("Sack")
    if sack then
        hum:EquipTool(sack)
        return true
    end
    return false
end

local function TPTo(pos)
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    task.wait(1)
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

local function FindGold()
    local golds = {}
    for _, item in ipairs(Workspace.RuntimeItems:GetChildren()) do
        if item.Name == "GoldBar" and not wasStored[item] then
            table.insert(golds, item)
        end
    end
    return golds
end

local function FireStore(item)
    ReplicatedStorage.Remotes.StoreItem:FireServer(item)
end

local function FireDrop(count)
    for _ = 1, count do
        local before = Workspace.RuntimeItems:GetChildren()
        ReplicatedStorage.Remotes.DropItem:FireServer()
        task.wait(0.1)
        local after = Workspace.RuntimeItems:GetChildren()
        for _, item in ipairs(after) do
            if item.Name == "GoldBar" and not table.find(before, item) then
                wasStored[item] = true
            end
        end
    end
end

local function isFull()
    local sack = character:FindFirstChild("Sack") or player.Backpack:FindFirstChild("Sack")
    if sack then
        local label = sack:FindFirstChild("BillboardGui") and sack.BillboardGui:FindFirstChild("TextLabel")
        if label and (label.Text == "10/10" or label.Text == "15/15") then
            return tonumber(label.Text:match("^(%d+)/"))
        end
    end
    return nil
end

local function isFullConfig()
    local FullSack = isFull()
    if FullSack then
        TPTo(oldPos)
        FireDrop(FullSack)
        task.wait(0.1)
    end
end

local function StoreGold()
    local Bars = FindGold()
    for _, bar in ipairs(Bars) do
        local barPos = getPos(bar)
        if barPos then
            TPTo(barPos)
            FireStore(bar)
            task.wait(0.4)
            isFullConfig()
        end
    end
end

local function NoGold()
    local Bars = FindGold()
    if #Bars == 0 then
        TPTo(oldPos)
    end
end

local function FindBank(town)
    local buildings = town:FindFirstChild("Buildings")
    if not buildings then return nil end
    local normal = buildings:FindFirstChild("Bank")
    local destroyed = buildings:FindFirstChild("BankDestroyed")
    if normal and destroyed then return {normal, destroyed}
    elseif normal then return {normal}
    elseif destroyed then return {destroyed}
    end
    return nil
end

local function CheckBanks(towns, pos)
    local isEmpty = true
    for _, town in ipairs(towns:GetChildren()) do
        local townPos = getPos(town)
        if townPos then
            local banks = FindBank(town)
            if banks then
                for _, bank in ipairs(banks) do
                    local bankPos = getPos(bank)
                    if bankPos then
                        TPTo(bankPos)
                        task.wait(0.4)
                        StoreGold()
                        if #FindGold() > 0 then
                            isEmpty = false
                        end
                    end
                end
            end
        end
    end
    if isEmpty then
        TPTo(oldPos)
    end
end

-- === MAIN FLOW ===

task.spawn(function()
    repeat task.wait() until Workspace:FindFirstChild("RuntimeItems") and #Workspace.RuntimeItems:GetChildren() > 0

    local origin = Vector3.new(57, -5, -9000) -- Any known good area
    TPTo(origin)

    local chosenSeat, weld = nil, nil
    while not chosenSeat do
        local seat = findNearestValidChair(origin)
        if seat then
            local s, w = sitAndWeldToSeat(seat)
            if s then
                chosenSeat, weld = s, w
            end
        end
        wait(0.25)
    end

    UseSack()

    for _, pos in ipairs(positions) do
        TPTo(pos)
        local towns = Workspace:FindFirstChild("Towns")
        if towns then
            CheckBanks(towns, pos)
        end
    end

    isFullConfig()
    NoGold()
end)
