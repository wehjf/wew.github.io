local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")

local chairTP = Vector3.new(57, -5, -9000)

-- Find any valid Chair model with a valid Seat inside
local function findAnyValidChairSeat()
    local runtimeFolder = workspace:FindFirstChild("RuntimeItems")
    if not runtimeFolder then return nil end
    for _, chair in ipairs(runtimeFolder:GetChildren()) do
        if chair:IsA("Model") and chair.Name == "Chair" then
            for _, child in ipairs(chair:GetChildren()) do
                if child:IsA("Seat") and not child.Anchored and not child.Occupant then
                    return child
                end
            end
        end
    end
    return nil
end

local function sitAndJumpOutSeat(seat)
    local jumped = false
    local timeout = tick() + 10 -- 10s timeout to avoid infinite loops
    while tick() < timeout do
        if humanoid.SeatPart ~= seat then
            -- Only teleport if not already sitting!
            hrp.CFrame = seat.CFrame
            task.wait(0.1)
        else
            -- Once you're sitting, stop teleporting!
            local weld = seat:FindFirstChild("SeatWeld")
            if weld == nil or (weld.Part1 and weld.Part1:IsDescendantOf(char)) then
                if not jumped then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.2)
                    -- After jumping, you can optionally teleport again if you want to try to re-seat
                    jumped = true
                else
                    return true
                end
            end
        end
    end
    return false
end

-- Main: Keep trying until it works
while true do
    -- Only teleport if not already sitting!
    local seat = findAnyValidChairSeat()
    if seat then
        if humanoid.SeatPart ~= seat then
            hrp.CFrame = seat.CFrame
            task.wait(0.5)
        end
        local success = sitAndJumpOutSeat(seat)
        if success then
            break
        end
    end
    task.wait(0.5)
end
