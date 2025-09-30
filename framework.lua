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
function deploymentFramework:create_deployables(wave, deploy_table)
    if not self.deployables[wave] then
        self.deployables[wave] = {}
    end

    for itemName, positions in pairs(deploy_table) do
        if not self.deployables[wave][itemName] then
            self.deployables[wave][itemName] = {}
        end

        for _, cf in ipairs(positions) do
            table.insert(self.deployables[wave][itemName], cf)
        end
    end
end

-- deploy everything for the *current* wave
function deploymentFramework:deploy_wave(wave) -- need to pass the wave here
    local current_wave = tonumber(wave)
    if not current_wave then
        warn("Wave label text is not a valid number.")
        return
    end

    local waveDeploys = self.deployables[current_wave]
    if not waveDeploys then
        warn("No deployables registered for wave " .. tostring(current_wave))
        return
    end

    for itemName, positions in pairs(waveDeploys) do
        for _, cf in ipairs(positions) do
            game.ReplicatedStorage.RemoteFunctions.CreateDeployable:InvokeServer(itemName, cf, "Close")
        end
    end
end

return deploymentFramework
