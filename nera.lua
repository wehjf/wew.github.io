local plrs = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local plr = plrs.LocalPlayer
local character = plr.Character or plr.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")

local CHAIR_POS = Vector3.new(57, -5, -9000)
local positions = {
    CHAIR_POS,
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

local function isUnanchored(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part.Anchored then
            return false
        end
    end
    return true
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

local function sitAndJumpOutChair(seat)
    local jumped = false
    while true do
        if humanoid.SeatPart ~= seat then
            hrp.CFrame = seat.CFrame
            task.wait(0.1)
        else
            local weld = seat:FindFirstChild("SeatWeld")
            if weld and weld.Part1 and weld.Part1:IsDescendantOf(character) then
                if not jumped then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.15)
                    hrp.CFrame = seat.CFrame
                    jumped = true
                else
                    break
                end
            end
        end
    end
end

-- 1. Go to chair position, find & sit on chair, jump out
local function sitOnChairAtStart()
    hrp.CFrame = CFrame.new(CHAIR_POS)
    task.wait(1)
    local chair = findNearestValidChair(CHAIR_POS)
    if chair then
        sitAndJumpOutChair(chair)
        task.wait(0.4)
    end
end

-- --- GOLD LOGIC (your original logic, unchanged) ---

local function UseSack()
    local sack = plr.Backpack:FindFirstChild("Sack")
    if sack then
        plr.character:WaitForChild("Humanoid"):EquipTool(sack)
        return true
    end
    return false
end

UseSack()

local function TPTo(pos)
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, -5, 0))
    task.wait(2)
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

local function CheckBanks(towns, pos)
    local isEmpty = true
    for _, town in ipairs(towns:GetChildren()) do
        local townPos = getPos(town)
        if townPos then
            local dist = (townPos - pos).Magnitude
            local banks = FindBank(town)
            if banks then
                for _, bank in ipairs(banks) do
                    local bankPos = getPos(bank)
                    if bankPos then
                        TPTo(bankPos)
                        task.wait(0.4)
                        StoreGold()
                        local Bars = FindGold()
                        if #Bars > 0 then
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

-- *** MAIN EXECUTION ***
sitOnChairAtStart()

for i, pos in ipairs(positions) do
    TPTo(pos)
    local towns = Workspace:FindFirstChild("Towns")
    if not towns then continue end
    CheckBanks(towns, pos)
end

isFullConfig()
NoGold()
