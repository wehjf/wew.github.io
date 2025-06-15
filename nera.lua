local plrs = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local plr = plrs.LocalPlayer
local character = plr.Character or plr.CharacterAdded:Wait()
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
    for _, item in ipairs(workspace.RuntimeItems:GetChildren()) do
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
        local before = workspace.RuntimeItems:GetChildren()
        ReplicatedStorage.Remotes.DropItem:FireServer()
        task.wait(0.1)
        local after = workspace.RuntimeItems:GetChildren()
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

for i, pos in ipairs(positions) do
    TPTo(pos)

    local towns = workspace:FindFirstChild("Towns")
    if not towns then continue end

    CheckBanks(towns, pos)
end

isFullConfig()
NoGold()
