local Players, Workspace, ReplicatedStorage = game:GetService("Players"), game:GetService("Workspace"), game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer
local character = plr.Character or plr.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")

local maximGunTP = Vector3.new(57, -5, -9000)
local afterHorseTP = Vector3.new(147, 10, 29928)
local tpInterval, horseScanInterval, retryDelay = 2, 0.15, 20

-- --- HORSE SEARCH ---
local function outlawNearby(pos)
    local outlawNames = { "Model_RifleOutlaw", "Model_RevolverOutlaw" }
    -- Animals
    local animals = Workspace:FindFirstChild("Baseplates")
    animals = animals and animals:FindFirstChild("Baseplate")
    animals = animals and animals:FindFirstChild("CenterBaseplate")
    animals = animals and animals:FindFirstChild("Animals")
    if animals then
        for _, obj in ipairs(animals:GetChildren()) do
            for _, outlawName in ipairs(outlawNames) do
                if obj:IsA("Model") and obj.Name == outlawName then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if part and (part.Position - pos).Magnitude <= 100 then
                        return true
                    end
                end
            end
        end
    end
    -- RuntimeItems
    local runtime = Workspace:FindFirstChild("RuntimeItems")
    if runtime then
        for _, obj in ipairs(runtime:GetChildren()) do
            for _, outlawName in ipairs(outlawNames) do
                if obj:IsA("Model") and obj.Name == outlawName then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if part and (part.Position - pos).Magnitude <= 100 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function findSafeHorse()
    -- Only return a horse if it has no parent AND no outlaw nearby
    -- Workspace horses
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name == "Model_Horse" and not obj.Parent then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part and not outlawNearby(part.Position) then
                return obj, part.Position
            end
        end
    end
    -- Animals horses
    local animals = Workspace:FindFirstChild("Baseplates")
    animals = animals and animals:FindFirstChild("Baseplate")
    animals = animals and animals:FindFirstChild("CenterBaseplate")
    animals = animals and animals:FindFirstChild("Animals")
    if animals then
        for _, obj in ipairs(animals:GetChildren()) do
            if obj:IsA("Model") and obj.Name == "Model_Horse" and not obj.Parent then
                local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if part and not outlawNearby(part.Position) then
                    return obj, part.Position
                end
            end
        end
    end
    return nil, nil
end

-- --- SACK COUNT ---
local function getSackCount()
    local c = plr.Character
    local s = c and c:FindFirstChild("Sack") or plr.Backpack:FindFirstChild("Sack")
    local l = s and s:FindFirstChild("BillboardGui") and s.BillboardGui:FindFirstChild("TextLabel")
    return l and tonumber(l.Text:match("^(%d+)/")) or nil
end

-- --- MAXIM GUN LOGIC ---
local function destroyBookcases()
    local castle = Workspace:FindFirstChild("VampireCastle")
    if castle then
        for _, d in ipairs(castle:GetDescendants()) do
            if d:IsA("Model") and d.Name == "Bookcase" then d:Destroy() end
        end
    end
end

local function getMaximGunSeat()
    destroyBookcases()
    local ri = Workspace:FindFirstChild("RuntimeItems")
    for _, g in ipairs(ri and ri:GetChildren() or {}) do
        if g.Name == "MaximGun" then
            return g:FindFirstChildWhichIsA("VehicleSeat")
        end
    end
end

local function ensureSeatedInMaximGun()
    local seat = getMaximGunSeat()
    if seat and humanoid.SeatPart ~= seat then
        repeat
            hrp.CFrame = seat.CFrame
            seat.Disabled = false
            task.wait(0.1)
        until humanoid.SeatPart == seat or not seat.Parent
    end
end

local function sitAndJumpOutSeat(seat)
    local jumped = false
    while true do
        if humanoid.SeatPart ~= seat then
            hrp.CFrame = seat.CFrame; task.wait(0.1)
        else
            local weld = seat:FindFirstChild("SeatWeld")
            if weld and weld.Part1 and weld.Part1:IsDescendantOf(plr.Character) then
                if not jumped then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.15)
                    hrp.CFrame = seat.CFrame
                    jumped = true
                else break end
            end
        end
    end
end

-- --- CLAIM LOGIC ---
local function claimHorseLoop(model, doMaximGunLoop)
    local lastPos, storeTries = nil, 0
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not model or model.Parent or not part or outlawNearby(part.Position) then
        return nil, false
    end
    while model and not model.Parent and part and not outlawNearby(part.Position) do
        if doMaximGunLoop then ensureSeatedInMaximGun() end
        local pos = part.Position
        -- Only allow max 4 blocks above the horse to attempt storing
        local targetY = math.max(pos.Y + 2, pos.Y + 4)
        if math.abs(hrp.Position.Y - pos.Y) > 4 then
            hrp.CFrame = CFrame.new(pos.X, pos.Y + 4, pos.Z)
        else
            hrp.CFrame = CFrame.new(pos.X, hrp.Position.Y, pos.Z)
        end
        lastPos = pos
        humanoid.Jump = true
        ReplicatedStorage.Remotes.StoreItem:FireServer(model)
        storeTries = storeTries + 1
        task.wait(0.15)
        if getSackCount() == 1 then return pos, true end
        if storeTries >= 5 then return pos, false end
    end
    return lastPos, false
end

-- --- SACK USAGE ---
local function UseSack()
    local sack = plr.Backpack:FindFirstChild("Sack")
    if sack then
        character:WaitForChild("Humanoid"):EquipTool(sack)
        return true
    end
    return false
end
task.spawn(function()
    task.wait(4)
    UseSack()
end)

-- --- ROBUST TP AFTER HORSE ---
local function robustAfterHorseTP()
    local stayStart = nil
    while true do
        hrp.CFrame = CFrame.new(afterHorseTP)
        if (hrp.Position - afterHorseTP).Magnitude < 10 then
            if not stayStart then
                stayStart = tick()
            elseif tick() - stayStart >= 1 then
                break
            end
        else
            stayStart = nil
        end
        task.wait(0.1)
    end
end

-- --- MAIN ROUTINE ---
local function startRoutine()
    -- Step 1: Maxim Gun sit/jump logic
    while true do
        hrp.CFrame = CFrame.new(maximGunTP)
        task.wait(0.5)
        local seat = getMaximGunSeat()
        if seat then
            seat.Disabled = false
            sitAndJumpOutSeat(seat)
            break
        end
        task.wait(1)
    end

    -- Step 2: Find first valid horse and mark its position
    local horseModel, horsePos = findSafeHorse()
    if not horseModel or not horsePos then
        warn("No valid horse found!")
        return
    end

    -- Step 3: Load fly
    task.spawn(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/fly.github.io/refs/heads/main/fly.lua"))()
    end)

    -- Step 4: Back-and-forth TP farming
    local horseCFrame = CFrame.new(horsePos.X, 50, horsePos.Z)
    local tpForward = 10000
    local delayTime = 1.5
    for i = 1, 8 do
        if i % 2 == 1 then
            -- Go 10k forward on Z
            hrp.CFrame = CFrame.new(horsePos.X, 50, horsePos.Z + tpForward)
        else
            -- Return to horse location
            hrp.CFrame = horseCFrame
        end
        task.wait(delayTime)
    end
    -- Final return to horse location for safety
    hrp.CFrame = horseCFrame
    task.wait(0.5)

    -- Step 5: Claim horse with maxim gun seat maintenance
    local horseLastPos, horseClaimed = claimHorseLoop(horseModel, true)
    -- Maximgun resit logic, then afterHorseTP, then fly end, then finish
    if horseClaimed and horseLastPos then
        -- If we're off the maxim gun, get back on
        ensureSeatedInMaximGun()
        task.wait(2)
        hrp.CFrame = CFrame.new(horseLastPos.X, horseLastPos.Y + 80, horseLastPos.Z)
        task.wait(2)
        robustAfterHorseTP()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/unfly.github.io/refs/heads/main/unfly.lua"))()
        -- END
    else
        task.wait(retryDelay)
        startRoutine()
    end
end

startRoutine()
