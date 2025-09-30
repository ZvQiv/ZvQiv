local deploymentFramework = {}
deploymentFramework.__index = deploymentFramework

-- constructor
function deploymentFramework.new()
    local object_data = setmetatable({
        deployables = {} -- stores deployables grouped by wave
    }, deploymentFramework)

    return object_data
end

-- store deployables in memory
-- deploy_table format:
-- { ["Flame Turret"] = { positions = {CFrame1, CFrame2}, autoReplace = true } }
function deploymentFramework:create_deployables(wave, deploy_table)
    if not self.deployables[wave] then
        self.deployables[wave] = {}
    end

    for itemName, info in pairs(deploy_table) do
        local positions = info.positions or info
        local autoReplace = info.autoReplace or false

        if not self.deployables[wave][itemName] then
            self.deployables[wave][itemName] = {
                positions = {},
                autoReplace = autoReplace
            }
        end

        for _, cf in ipairs(positions) do
            table.insert(self.deployables[wave][itemName].positions, cf)
        end

        self.deployables[wave][itemName].autoReplace = autoReplace
    end
end

-- deploy everything for a given wave
function deploymentFramework:deploy_wave(wave)
    local current_wave = tonumber(wave)
    if not current_wave then
        warn("Wave is not a valid number.")
        return
    end

    local waveDeploys = self.deployables[current_wave]
    if not waveDeploys then
        warn("No deployables registered for wave " .. tostring(current_wave))
        return
    end

    for itemName, info in pairs(waveDeploys) do
        for _, cf in ipairs(info.positions) do
            game.ReplicatedStorage.RemoteFunctions.CreateDeployable:InvokeServer(itemName, cf, "Close")
        end
    end
end

-- enable auto-replacement of deployables that have autoReplace = true
function deploymentFramework:enableAutoReplace()
    local playerDeployables = workspace.Deployables[game.Players.LocalPlayer.Name]
    if not playerDeployables then return end

    playerDeployables.ChildRemoved:Connect(function(v)
        if not v.PrimaryPart then
            warn("Cannot respawn "..v.Name..", no PrimaryPart!")
            return
        end

        for _, waveData in pairs(self.deployables) do
            for itemName, info in pairs(waveData) do
                if info.autoReplace and itemName == v.Name then
                    -- Optional: apply Y-offset so it sits on the ground
                    local cf = v.WorldPivot

                    game.ReplicatedStorage.RemoteFunctions.CreateDeployable:InvokeServer(
                        itemName,
                        cf,
                        "Close"
                    )
                    return
                end
            end
        end
    end)
end


return deploymentFramework
