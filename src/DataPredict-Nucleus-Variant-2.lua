local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local LogStore = DataStoreService:GetDataStore("DataPredictLogStore")
local CommandPayloadArrayStore = MemoryStoreService:GetSortedMap("CommandPayloadArrayStore")

local DataPredictLibraryLinker = script.DataPredictLibraryLinker.Value
local TensorL2DLibraryLinker = script.TensorL2DLibraryLinker.Value

local defaultUrl = "http://localhost:4444"

local defaultCommandPayloadArrayKey = "default"

local defaultSyncTime = 30

local defaultNumberOfSyncRetry = 3

local defaultSyncRetryDelay = 3

local defaultCommandPayloadArrayCacheDuration = 30

local logTypeArray = {"Normal", "Warning", "Error"}

local isStudio = RunService:IsStudio()

local gameJobId = (isStudio and "Studio") or game.JobId

local ignoreValueDictionaryKeyNameArray = {"modelName", "keyArray", "featureMatrix", "featureVector", "labelMatrix", "labelVector"}

local DataPredictNucleusInstancesArray = {}

local DataPredictNucleus = {}

DataPredictNucleus.__index = DataPredictNucleus

function DataPredictNucleus.new(propertyTable: {})

	local instanceId: any = propertyTable.instanceId

	local existingInstance = DataPredictNucleusInstancesArray[instanceId]

	if existingInstance then return existingInstance end

	local NewDataPredictNucleusInstance = {}

	setmetatable(NewDataPredictNucleusInstance, DataPredictNucleus)

	NewDataPredictNucleusInstance.url = propertyTable.url or defaultUrl

	NewDataPredictNucleusInstance.uuid = propertyTable.uuid

	NewDataPredictNucleusInstance.apiKey = propertyTable.apiKey

	NewDataPredictNucleusInstance.encryptionKey = propertyTable.encryptionKey

	NewDataPredictNucleusInstance.commandPayloadArrayKey = propertyTable.commandPayloadArrayKey or defaultCommandPayloadArrayKey

	NewDataPredictNucleusInstance.syncTime = propertyTable.syncTime or defaultSyncTime

	NewDataPredictNucleusInstance.numberOfSyncRetry = propertyTable.numberOfSyncRetry or defaultNumberOfSyncRetry

	NewDataPredictNucleusInstance.syncRetryDelay = propertyTable.syncRetryDelay or defaultSyncRetryDelay

	NewDataPredictNucleusInstance.commandPayloadArrayCacheDuration = propertyTable.commandPayloadArrayCacheDuration or defaultCommandPayloadArrayCacheDuration

	if (not NewDataPredictNucleusInstance.encryptionKey) then warn("Without an encryption key, the data will not be encrypted. This means that the hackers can intercept the unencrypted data.") end

	NewDataPredictNucleusInstance.commandFunctionDictionary = {}

	NewDataPredictNucleusInstance.modelDataDictionary = {}

	NewDataPredictNucleusInstance.logArray = {}

	NewDataPredictNucleusInstance.isSyncThreadRunning = false

	NewDataPredictNucleusInstance.lastCacheIdentifier = nil

	return NewDataPredictNucleusInstance

end

function DataPredictNucleus:destroy()

	isSyncThreadRunning = false
	
	local instanceId = self.instanceId

	self.instanceId = nil

	self.existingInstance = nil

	self.url = nil

	self.apiKey = nil

	self.encryptionKey = nil

	self.commandPayloadArrayKey = nil

	self.syncTime = nil

	self.numberOfSyncRetry = nil

	self.syncRetryDelay = nil

	self.commandPayloadArrayCacheDuration = nil

	self.commandFunctionDictionary = nil

	self.modelDataDictionary = nil

	self.logArray = nil

	self.lastCacheIdentifier = nil

	DataPredictNucleusInstancesArray[instanceId] = nil

end


function DataPredictNucleus:addLog(logType, logMessage)

	if (not table.find(logTypeArray, logType)) then error("Invalid log type.") end

	local logArray = self.logArray

	local currentTime = os.time()

	local logInfoArray = {currentTime, logType, logMessage}

	table.insert(logArray, logInfoArray)

	local success, errorMessage = pcall(function() 

		local jobIdString = tostring(gameJobId)

		LogStore:SetAsync(jobIdString, logArray) 

	end)

	if (not success) then warn("Failed to save log to DataStore: " .. errorMessage) end

end

function DataPredictNucleus:removeLog(position)

	table.remove(self.logArray, position)

end

function DataPredictNucleus:getLogArray()

	return self.logArray

end

function DataPredictNucleus:clearAllLogs()

	table.clear(self.logArray)

end

function DataPredictNucleus:processCommandPayload(commandPayload)

	local command = commandPayload["command"]

	local valueDictionary = commandPayload["valueDictionary"]

	local commandFunction = self.commandFunctionDictionary[command]
	
	if (not commandFunction) then self:addLog("Error", "Command function for " .. command .. " does not exist.") return end

	if (not commandFunction) then self:addLog("Error", "Command function for " .. command .. " does not exist.") return end

	local commandSuccess = pcall(commandFunction, valueDictionary)

	if (not commandSuccess) then self:addLog("Error", "Unable to run " .. command .. " command.") end

end

function DataPredictNucleus:processCommandPayloadArray(commandPayloadArray)

	for _, commandPayload in ipairs(commandPayloadArray) do
		
		task.spawn(function()
			
			self:processCommandPayload(commandPayload)
			
		end)

	end

end

function DataPredictNucleus:fetchCommandPayloadArray()

	local commandPayloadArrayKey = self.commandPayloadArrayKey

	local cachedCommandPayloadArray = CommandPayloadArrayStore:GetAsync(commandPayloadArrayKey)

	if (cachedCommandPayloadArray) then

		local currentCacheIdentifier = cachedCommandPayloadArray.cacheIdentifier

		if currentCacheIdentifier ~= self.lastCacheIdentifier then

			self.lastCacheIdentifier = currentCacheIdentifier

			return cachedCommandPayloadArray

		end

	end

	local syncRetryDelay = self.syncRetryDelay

	local url = self.url .. "/request-commands"
	local requestDictionary = { uuid = self.uuid, apiKey = self.apiKey }
	local requestBody = HttpService:JSONEncode(requestDictionary)

	for attempt = 1, self.numberOfSyncRetry, 1 do

		local responseSuccess, responseBody = pcall(function()

			return HttpService:PostAsync(url, requestBody, Enum.HttpContentType.ApplicationJson)

		end)

		if (responseSuccess) then

			local decodeSuccess, data = pcall(function()

				return HttpService:JSONDecode(responseBody)

			end)

			if (decodeSuccess) and (data) then

				local commandPayloadArray = data.commandPayloadArray

				if commandPayloadArray then
					
					local cacheIdentifier = HttpService:GenerateGUID(false) 
					
					commandPayloadArray.cacheIdentifier = cacheIdentifier
					
					self.lastCacheIdentifier = cacheIdentifier

					local success, err = pcall(function()

						CommandPayloadArrayStore:UpdateAsync(commandPayloadArrayKey, function(previousCommandPayLoadArray)

							if (not previousCommandPayLoadArray) or (previousCommandPayLoadArray.cacheIdentifier ~= commandPayloadArray.cacheIdentifier) then

								return commandPayloadArray  -- Apply the new data

							else

								return previousCommandPayLoadArray  -- Don't update if the cache is already fresh

							end

						end)

					end)

					if (not success) then

						self:addLog("Error", "Failed to update cache: " .. err)

					else

						CommandPayloadArrayStore:SetAsync(commandPayloadArrayKey, commandPayloadArray, self.commandPayloadArrayCacheDuration)

					end

					return commandPayloadArray
					
				else
					
					return nil

				end

			else

				self:addLog("Error", "Failed to decode API response.")

			end

		end

		self:addLog("Warning", "Sync attempt " .. attempt .. " failed. Retrying in " .. syncRetryDelay .. " seconds.")

		local currentSyncRetryDelay = syncRetryDelay ^ attempt -- Exponential backoff

		task.wait(currentSyncRetryDelay)

	end

	self:addLog("Warning", "Unable to fetch response from " .. url .. ".")

	return nil
end

function DataPredictNucleus:startSync()

	if (isSyncThreadRunning) then error("Already syncing.") end
	
	isSyncThreadRunning = true
	
	local syncTime = self.syncTime

	task.spawn(function()

		while isSyncThreadRunning do

			local commandPayloadArray = self:fetchCommandPayloadArray()

			if commandPayloadArray then self:processCommandPayloadArray(commandPayloadArray) end

			task.wait(syncTime)

		end

	end)

end

function DataPredictNucleus:stopSync()

	if (not isSyncThreadRunning) then error("Currently not syncing.") end

	isSyncThreadRunning = false

end

function DataPredictNucleus:addCommand(commandName, functionToRun)

	if (type(commandName) ~= "string") then error("Command name is not a string.") return end

	self.commandFunctionDictionary[commandName] = functionToRun

end

function DataPredictNucleus:removeCommand(commandName)

	if (type(commandName) ~= "string") then error("Command name is not a string.") return end

	self.commandFunctionDictionary[commandName] = nil

end

function DataPredictNucleus:addModelData(modelName, ModelDictionary, modelParameterNameArray)

	print(ModelDictionary)

	if (type(modelName) ~= "string") then error("Model name is not a string.") return end

	self.modelDataDictionary[modelName] = {

		ModelDictionary = ModelDictionary or {}, 

		modelParameterNameArray = modelParameterNameArray or {}

	}

end

function DataPredictNucleus:removeModelData(modelName)

	self.modelDataDictionary[modelName] = nil

end

function DataPredictNucleus:getModelData(modelName)

	return self.modelDataDictionary[modelName]

end

function DataPredictNucleus:addModelToModelData(modelName, key, Model)

	local modelData = self.modelDataDictionary[modelName]

	if (not modelData) then self:addLog("Error", modelName .. " data does not exist.") return end

	if (type(key) ~= "string") then self:addLog("Error", "Key is not a string.") return end

	local ModelDictionary = modelData.ModelDictionary

	if (ModelDictionary[key]) then self:addLog("Error", "Model already exist for key " .. key .. ".") return end

	ModelDictionary[key] = Model

end

function DataPredictNucleus:removeModelFromModelData(modelName, key)

	local modelData = self.modelDataDictionary[modelName]

	if (not modelData) then self:addLog("Error", modelName .. " data does not exist.") return end

	if (type(key) ~= "string") then self:addLog("Error", "Key is not a string.") return end

	modelData.ModelDictionary[key] = nil

end

function DataPredictNucleus:applyFunctionToAllModelsInModelData(modelName, functionToApply)

	local modelData = self.modelDataDictionary[modelName]

	if (not modelData) then self:addLog("Error", modelName .. " data does not exist.") return end

	local modelParameterNameArray = modelData.modelParameterNameArray

	for key, Model in pairs(modelData.ModelDictionary) do

		functionToApply(key, Model, modelParameterNameArray)

	end

end

function DataPredictNucleus:getModelParameters(valueDictionary)

	local modelName = valueDictionary.modelName

	local keyArray = valueDictionary.keyArray

	local fullUrl = self.url .. "/send-model-parameters"

	self:applyFunctionToAllModelsInModelData(modelName, function(key, Model, modelParameterNameArray)

		if keyArray then

			if (not table.find(keyArray, key)) then return end

		end

		local ModelParameters = Model:getModelParameters()

		local requestDictionary = {

			apiKey = self.apiKey,

			modelName = modelName,

			ModelParameters = ModelParameters,

			modelParameterNameArray = modelParameterNameArray

		}

		local requestBody = HttpService:JSONEncode(requestDictionary)

		local responseSuccess, responseBody = pcall(function()

			return HttpService:PostAsync(fullUrl, requestBody, Enum.HttpContentType.ApplicationJson)

		end)

		if (responseSuccess) then

			local decodeSuccess, response = pcall(function()

				return HttpService:JSONDecode(responseBody)

			end)

			if (decodeSuccess) then 

				self:addLog("Normal", modelName .. " model parameters " .. key .. " has been sent using the \"getModelParameters\" command.")

			else

				self:addLog("Error", "Failed to decode API response using the \"getModelParameters\" command: " .. responseBody)

			end

		else

			self:addLog("Error", "Failed to send model parameters " .. key .. "  to API using the \"getModelParameters\" command: " .. responseBody)

		end

	end)

end

function DataPredictNucleus:setModelParameters(valueDictionary)

	local modelName = valueDictionary.modelName

	local keyArray = valueDictionary.keyArray

	local ModelParameters = valueDictionary.ModelParameters

	if (not ModelParameters) then self:addLog("Error", modelName .. " model parameters does not exist when calling the \"setModelParameters\" command.")  return end

	self:applyFunctionToAllModelsInModelData(modelName, function(key, Model, modelParameterNameArray)

		if (keyArray) then

			if (not table.find(keyArray, key)) then return end

		end

		local success = pcall(function()

			Model:setModelParameters(ModelParameters)

		end)

		if (success) then

			self:addLog("Normal", modelName .. " model parameters ".. key .. " has been replaced using the \"setModelParameters\" command.")

		else

			self:addLog("Error", modelName .. " model parameters ".. key .. " has not been replaced using the \"setModelParameters\" command.")

		end

	end)

end

function DataPredictNucleus:setParameters(valueDictionary)

	local modelName = valueDictionary.modelName

	local keyArray = valueDictionary.keyArray

	local Parameters = valueDictionary.Parameters

	if (not Parameters) then self:addLog("Error", modelName .. " parameters does not exist when calling the \"setParameters\" command.")  return end

	self:applyFunctionToAllModelsInModelData(modelName, function(key, Model, modelParameterNameArray)

		if (keyArray) then

			if (not table.find(keyArray, key)) then return end

		end

		local success = pcall(function()

			for key, value in pairs(Parameters) do
				
				if (table.find(ignoreValueDictionaryKeyNameArray, key)) then continue end
				
				Model[key] = value 
				
			end

		end)

		if (success) then

			self:addLog("Normal", modelName .. " parameters ".. key .. " has been replaced using the \"setParameters\" command.")

		else

			self:addLog("Error", modelName .. " parameters ".. key .. " has not been replaced using the \"setParameters\" command.")

		end

	end)

end

function DataPredictNucleus:train(valueDictionary)

	local modelName = valueDictionary.modelName

	local keyArray = valueDictionary.keyArray

	local featureMatrix = valueDictionary.featureMatrix

	local labelMatrix = valueDictionary.labelMatrix

	if (not featureMatrix) then self:addLog("Error", modelName .. " feature matrix does not exist when calling the \"train\" command.") return end

	if (not labelMatrix) then self:addLog("Error", modelName .. " label matrix does not exist when calling the \"train\" command.")  return end

	self:applyFunctionToAllModelsInModelData(modelName, function(key, Model, modelParameterNameArray)

		if (keyArray) then

			if (not table.find(keyArray, key)) then return end

		end

		local success = pcall(function()

			Model:train(featureMatrix, labelMatrix)

		end)

		if success then

			self:addLog("Normal", modelName .. " model parameters ".. key .. " has been updated using the \"train\" command.")

		else

			self:addLog("Error", modelName .. " model parameters ".. key .. " has not been updated using the \"train\" command.")

		end

	end)

end

function DataPredictNucleus:predict(valueDictionary)

	local modelName = valueDictionary.modelName

	local keyArray = valueDictionary.keyArray

	local featureMatrix = valueDictionary.featureMatrix

	local returnOriginalOutput = valueDictionary.returnOriginalOutput

	if (not featureMatrix) then self:addLog("Error", modelName .. " feature matrix does not exist when calling the \"predict\" command.") return end

	local fullUrl = self.url .. "/send-model-parameters"

	self:applyFunctionToAllModelsInModelData(modelName, function(key, Model, modelParameterNameArray)

		if (keyArray) then

			if (not table.find(keyArray, key)) then return end

		end

		local labelMatrix = Model:predict(featureMatrix, returnOriginalOutput)

		local requestDictionary = {

			apiKey = self.apiKey,

			modelName = modelName,

			labelMatrix = labelMatrix,

		}

		local requestBody = HttpService:JSONEncode(requestDictionary)

		local responseSuccess, responseBody = pcall(function()

			return HttpService:PostAsync(fullUrl, requestBody, Enum.HttpContentType.ApplicationJson)

		end)

		if (responseSuccess) then

			local decodeSuccess, response = pcall(function()

				return HttpService:JSONDecode(responseBody)

			end)

			if (decodeSuccess) then 

				self:addLog("Normal", modelName .. " prediction for " .. key .. " has been sent using the \"predict\" command.")

			else

				self:addLog("Error", "Failed to decode API response using the \"predict\" command: " .. responseBody)

			end

		else

			self:addLog("Error", "Failed to send model parameters " .. key .. "  to API using the \"predict\" command: " .. responseBody)

		end

	end)

end

function DataPredictNucleus:gradientDescent(valueDictionary)

	local modelName = valueDictionary.modelName

	local keyArray = valueDictionary.keyArray

	local ModelParametersGradient = valueDictionary.ModelParametersGradient

	if (not ModelParametersGradient) then self:addLog("Error", modelName .. " model parameters gradient does not exist when calling the \"gradientDescent\" command.")  return end

	self:applyFunctionToAllModelsInModelData(modelName, function(key, Model, modelParameterNameArray)

		if (keyArray) then

			if (not table.find(keyArray, key)) then return end

		end

		local success = pcall(function()

			Model:gradientDescent(ModelParametersGradient)

		end)

		if (success) then

			self:addLog("Normal", modelName .. " model parameters ".. key .. " has been updated using the \"gradientDescent\" command.")

		else

			self:addLog("Error", modelName .. " model parameters ".. key .. " has not been updated using the \"gradientDescent\" command.")

		end

	end)

end

function DataPredictNucleus:runCommand(valueDictionary)

	local commandName = valueDictionary.commandName

	if (type(commandName) ~= "string") then error("Command name is not a string.") return end

	local commandFunction = self.commandFunctionDictionary[commandName]

	if (not commandFunction) then self:addLog("Error", commandName .. " command does not exist.") return end

	commandFunction(valueDictionary)

end

return DataPredictNucleus
