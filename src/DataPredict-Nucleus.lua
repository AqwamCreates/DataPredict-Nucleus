local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local LogStore = DataStoreService:GetDataStore("DataPredictLogStore")
local CommandPayloadArrayStore = MemoryStoreService:GetSortedMap("CommandPayloadArrayStore")

local DataPredictLibraryLinker = script.DataPredictLibraryLinker.Value
local TensorL2DLibraryLinker = script.TensorL2DLibraryLinker.Value

local defaultAddress = "localhost"

local defaultPort = 4444

local defaultCommandPayloadArrayKey = "default"

local defaultSyncTime = 3

local defaultNumberOfSyncRetry = 3

local defaultSyncRetryDelay = 2

local defaultCommandPayloadArrayCacheDuration = 30

local logTypeArray = {"Normal", "Warning", "Error"}

local isStudio = RunService:IsStudio()

local gameJobId = (isStudio and "Studio") or game.JobId

local ignoreValueDictionaryKeyNameArray = {"modelName", "keyArray"}

local DataPredictNucleusInstancesArray = {}

local DataPredictNucleus = {}

function DataPredictNucleus.new(propertyTable: {})

	local instanceId: any = propertyTable.instanceId

	local existingInstance = DataPredictNucleusInstancesArray[instanceId]

	if existingInstance then return existingInstance end

	local address: string = propertyTable.address or defaultAddress

	local port: string = propertyTable.port or defaultPort

	local uuid: string = propertyTable.uuid

	local apiKey: string = propertyTable.apiKey

	local encryptionKey: string = propertyTable.encryptionKey

	local commandPayloadArrayKey: string = propertyTable.commandPayloadArrayKey or defaultCommandPayloadArrayKey

	local syncTime: number = propertyTable.syncTime or defaultSyncTime

	local numberOfSyncRetry: number = propertyTable.numberOfSyncRetry or defaultNumberOfSyncRetry

	local syncRetryDelay: number = propertyTable.syncRetryDelay or defaultSyncRetryDelay

	local commandPayloadArrayCacheDuration: number = propertyTable.commandPayloadArrayCacheDuration or defaultCommandPayloadArrayCacheDuration

	if (not encryptionKey) then warn("Without an encryption key, the data will not be encrypted. This means that the hackers can intercept the unencrypted data.") end

	local commandFunctionDictionary = {}

	local modelDataDictionary = {}

	local logArray = {}

	local isSyncThreadRunning = false
	
	local lastCacheIdentifier = nil

	local NewDataPredictNucleusInstance

	local function destroy()

		isSyncThreadRunning = false

		table.clear(NewDataPredictNucleusInstance)

		------------------------------------------------

		instanceId = nil

		existingInstance = nil

		address = nil

		port = nil

		apiKey = nil

		encryptionKey = nil

		commandPayloadArrayKey = nil

		syncTime = nil

		numberOfSyncRetry = nil

		syncRetryDelay = nil

		commandPayloadArrayCacheDuration = nil

		commandFunctionDictionary = nil

		modelDataDictionary = nil

		logArray = nil
		
		lastCacheIdentifier = nil

		------------------------------------------------

		NewDataPredictNucleusInstance = nil
		
		DataPredictNucleusInstancesArray[instanceId] = nil

	end

	local function addLog(logType, logMessage)

		if (not table.find(logTypeArray, logType)) then error("Invalid log type.") end

		local currentTime = os.time()

		local logInfoArray = {currentTime, logType, logMessage}

		table.insert(logArray, logInfoArray)

		local success, errorMessage = pcall(function() 

			local jobIdString = tostring(gameJobId)

			LogStore:SetAsync(jobIdString, logArray) 

		end)

		if (not success) then warn("Failed to save log to DataStore: " .. errorMessage) end

	end

	local function removeLog(position)

		table.remove(logArray, position)

	end

	local function getLogArray()

		return logArray

	end

	local function clearAllLogs()

		table.clear(logArray)

	end

	local function processCommandPayload(commandPayload)

		local command = commandPayload["command"]

		local valueDictionary = commandPayload["valueDictionary"]

		local commandFunction = commandFunctionDictionary[command]

		if (not commandFunction) then addLog("Error", "Command function for " .. command .. " does not exist.") return end

		local commandSuccess = pcall(commandFunction, valueDictionary)

		if (not commandSuccess) then addLog("Error", "Unable to run " .. command .. " command.") end

	end

	local function processCommandPayloadArray(commandPayloadArray)

		for _, commandPayload in ipairs(commandPayloadArray) do
			
			task.spawn(processCommandPayload, commandPayload)

		end

	end

	local function fetchCommandPayloadArray()
		
		local cachedCommandPayloadArray = CommandPayloadArrayStore:GetAsync(commandPayloadArrayKey)

		if (cachedCommandPayloadArray) then
			
			local currentCacheIdentifier = cachedCommandPayloadArray.cacheIdentifier

			if currentCacheIdentifier ~= lastCacheIdentifier then
				
				lastCacheIdentifier = currentCacheIdentifier
				
				return cachedCommandPayloadArray
				
			end
			
		end

		local url = "http://" .. address .. ":" .. port .. "/request-commands"
		local requestDictionary = { uuid = uuid, apiKey = apiKey }
		local requestBody = HttpService:JSONEncode(requestDictionary)

		for attempt = 1, numberOfSyncRetry, 1 do
			
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

						lastCacheIdentifier = cacheIdentifier

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
							
							addLog("Error", "Failed to update cache: " .. err)
							
						else

							CommandPayloadArrayStore:SetAsync(commandPayloadArrayKey, commandPayloadArray, commandPayloadArrayCacheDuration)
							
						end

						return commandPayloadArray
						
					else
						
						return nil
						
					end
					
				else
					
					addLog("Error", "Failed to decode API response.")
					
				end
				
			end

			addLog("Warning", "Sync attempt " .. attempt .. " failed. Retrying in " .. syncRetryDelay .. " seconds.")
			
			local currentSyncRetryDelay = syncRetryDelay ^ attempt -- Exponential backoff
			
			task.wait(currentSyncRetryDelay)
			
		end

		addLog("Warning", "Unable to fetch response from " .. url .. ".")
		
		return nil
	end

	local function startSync()

		if (isSyncThreadRunning) then error("Already syncing.") end

		isSyncThreadRunning = true

		task.spawn(function()

			while isSyncThreadRunning do

				local commandPayloadArray = fetchCommandPayloadArray()

				if commandPayloadArray then processCommandPayloadArray(commandPayloadArray) end

				task.wait(syncTime)

			end

		end)

	end

	local function stopSync()

		if (not isSyncThreadRunning) then error("Currently not syncing.") end

		isSyncThreadRunning = false

	end

	local function addCommand(commandName, functionToRun)

		if (type(commandName) ~= "string") then error("Command name is not a string.") return end

		commandFunctionDictionary[commandName] = functionToRun

	end

	local function removeCommand(commandName)

		if (type(commandName) ~= "string") then error("Command name is not a string.") return end

		commandFunctionDictionary[commandName] = nil

	end

	local function addModelData(modelName, ModelDictionary, modelParameterNameArray)

		if (type(modelName) ~= "string") then error("Model name is not a string.") return end

		modelDataDictionary[modelName] = {

			ModelDictionary = ModelDictionary or {}, 

			modelParameterNameArray = modelParameterNameArray or {}

		}

	end

	local function removeModelData(modelName)

		modelDataDictionary[modelName] = nil

	end

	local function getModelData(modelName)

		return modelDataDictionary[modelName]

	end

	local function addModelToModelData(modelName, key, Model)

		local modelData = modelDataDictionary[modelName]

		if (not modelData) then addLog("Error", modelName .. " data does not exist.") return end

		if (type(key) ~= "string") then addLog("Error", "Key is not a string.") return end

		local ModelDictionary = modelData.ModelDictionary

		if (ModelDictionary[key]) then addLog("Error", "Model already exist for key " .. key .. ".") return end

		ModelDictionary[key] = Model

	end

	local function removeModelFromModelData(modelName, key)

		local modelData = modelDataDictionary[modelName]

		if (not modelData) then addLog("Error", modelName .. " data does not exist.") return end

		if (type(key) ~= "string") then addLog("Error", "Key is not a string.") return end

		modelData.ModelDictionary[key] = nil

	end

	local function applyFunctionToAllModelsInModelData(modelName, functionToApply)

		local modelData = modelDataDictionary[modelName]

		if (not modelData) then addLog("Error", modelName .. " data does not exist.") return end

		local modelParameterNameArray = modelData.modelParameterNameArray

		for key, Model in pairs(modelData.ModelDictionary) do

			functionToApply(key, Model, modelParameterNameArray)

		end

	end

	local function getModelParameters(valueDictionary)

		local modelName = valueDictionary.modelName

		local keyArray = valueDictionary.keyArray

		local url = "http://" .. address .. ":" .. port

		applyFunctionToAllModelsInModelData(modelName, function(key, Model, modelParameterNameArray)

			if keyArray then

				if (not table.find(keyArray, key)) then return end

			end

			local ModelParameters = Model:getModelParameters()

			local requestDictionary = {

				apiKey = apiKey,

				modelName = modelName,

				ModelParameters = ModelParameters,

				modelParameterNameArray = modelParameterNameArray

			}

			local requestBody = HttpService:JSONEncode(requestDictionary)

			local responseSuccess, responseBody = pcall(function()

				return HttpService:PostAsync(url, requestBody, Enum.HttpContentType.ApplicationJson)

			end)

			if (responseSuccess) then

				local decodeSuccess, response = pcall(function()

					return HttpService:JSONDecode(responseBody)

				end)

				if (decodeSuccess) then 

					addLog("Normal", modelName .. " model parameters " .. key .. " has been sent using the \"getModelParameters\" command.")

				else

					addLog("Error", "Failed to decode API response using the \"getModelParameters\" command: " .. responseBody)

				end

			else

				addLog("Error", "Failed to send model parameters " .. key .. "  to API using the \"getModelParameters\" command: " .. responseBody)

			end

		end)

	end

	local function setModelParameters(valueDictionary)

		local modelName = valueDictionary.modelName

		local keyArray = valueDictionary.keyArray

		local ModelParameters = valueDictionary.ModelParameters

		if (not ModelParameters) then addLog("Error", modelName .. " model parameters does not exist when calling the \"setModelParameters\" command.")  return end

		applyFunctionToAllModelsInModelData(modelName, function(key, Model, modelParameterNameArray)

			if (keyArray) then

				if (not table.find(keyArray, key)) then return end

			end

			local success = pcall(function()

				Model:setModelParameters(ModelParameters)

			end)

			if (success) then

				addLog("Normal", modelName .. " model parameters ".. key .. " has been replaced using the \"setModelParameters\" command.")

			else

				addLog("Error", modelName .. " model parameters ".. key .. " has not been replaced using the \"setModelParameters\" command.")

			end

		end)

	end

	local function setParameters(valueDictionary)

		local modelName = valueDictionary.modelName

		local keyArray = valueDictionary.keyArray

		applyFunctionToAllModelsInModelData(modelName, function(key, Model, modelParameterNameArray)

			if (keyArray) then

				if (not table.find(keyArray, key)) then return end

			end

			local success = pcall(function()

				for key, value in pairs(valueDictionary) do 
					
					if (table.find(ignoreValueDictionaryKeyNameArray, key)) then continue end
					
					Model[key] = value 
					
				end

			end)

			if (success) then

				addLog("Normal", modelName .. " parameters ".. key .. " has been replaced using the \"setParameters\" command.")

			else

				addLog("Error", modelName .. " parameters ".. key .. " has not been replaced using the \"setParameters\" command.")

			end

		end)

	end

	local function train(valueDictionary)

		local modelName = valueDictionary.modelName

		local keyArray = valueDictionary.keyArray

		local featureMatrix = valueDictionary.featureMatrix

		local labelMatrix = valueDictionary.labelMatrix

		if (not featureMatrix) then addLog("Error", modelName .. " feature matrix does not exist when calling the \"train\" command.") return end

		if (not labelMatrix) then addLog("Error", modelName .. " label matrix does not exist when calling the \"train\" command.")  return end

		applyFunctionToAllModelsInModelData(modelName, function(key, Model, modelParameterNameArray)

			if (keyArray) then

				if (not table.find(keyArray, key)) then return end

			end

			local success = pcall(function()

				Model:train(featureMatrix, labelMatrix)

			end)

			if success then

				addLog("Normal", modelName .. " model parameters ".. key .. " has been updated using the \"train\" command.")

			else

				addLog("Error", modelName .. " model parameters ".. key .. " has not been updated using the \"train\" command.")

			end

		end)

	end

	local function predict(valueDictionary)

		local modelName = valueDictionary.modelName

		local keyArray = valueDictionary.keyArray

		local featureMatrix = valueDictionary.featureMatrix

		local returnOriginalOutput = valueDictionary.returnOriginalOutput

		if (not featureMatrix) then addLog("Error", modelName .. " feature matrix does not exist when calling the \"predict\" command.") return end

		local url = "http://" .. address .. ":" .. port

		applyFunctionToAllModelsInModelData(modelName, function(key, Model, modelParameterNameArray)

			if (keyArray) then

				if (not table.find(keyArray, key)) then return end

			end

			local labelMatrix = Model:predict(featureMatrix, returnOriginalOutput)

			local requestDictionary = {

				apiKey = apiKey,

				modelName = modelName,

				labelMatrix = labelMatrix,

			}

			local requestBody = HttpService:JSONEncode(requestDictionary)

			local responseSuccess, responseBody = pcall(function()

				return HttpService:PostAsync(url, requestBody, Enum.HttpContentType.ApplicationJson)

			end)

			if (responseSuccess) then

				local decodeSuccess, response = pcall(function()

					return HttpService:JSONDecode(responseBody)

				end)

				if (decodeSuccess) then 

					addLog("Normal", modelName .. " prediction for " .. key .. " has been sent using the \"predict\" command.")

				else

					addLog("Error", "Failed to decode API response using the \"predict\" command: " .. responseBody)

				end

			else

				addLog("Error", "Failed to send model parameters " .. key .. "  to API using the \"predict\" command: " .. responseBody)

			end

		end)

	end

	local function gradientDescent(valueDictionary)

		local modelName = valueDictionary.modelName

		local keyArray = valueDictionary.keyArray

		local ModelParametersGradient = valueDictionary.ModelParametersGradient

		if (not ModelParametersGradient) then addLog("Error", modelName .. " model parameters gradient does not exist when calling the \"gradientDescent\" command.")  return end

		applyFunctionToAllModelsInModelData(modelName, function(key, Model, modelParameterNameArray)

			if (keyArray) then

				if (not table.find(keyArray, key)) then return end

			end

			local success = pcall(function()

				Model:gradientDescent(ModelParametersGradient)

			end)

			if (success) then

				addLog("Normal", modelName .. " model parameters ".. key .. " has been updated using the \"gradientDescent\" command.")

			else

				addLog("Error", modelName .. " model parameters ".. key .. " has not been updated using the \"gradientDescent\" command.")

			end

		end)

	end

	local function runCommand(valueDictionary)

		local commandName = valueDictionary.commandName

		if (type(commandName) ~= "string") then error("Command name is not a string.") return end

		local commandFunction = commandFunctionDictionary[commandName]

		if (not commandFunction) then addLog("Error", commandName .. " command does not exist.") return end

		commandFunction(valueDictionary)

	end

	game:BindToClose(function()

		isSyncThreadRunning = false

	end)

	commandFunctionDictionary["getModelParameters"] = getModelParameters

	commandFunctionDictionary["setModelParameters"] = setModelParameters

	commandFunctionDictionary["setParameters"] = setParameters

	commandFunctionDictionary["train"] = train

	commandFunctionDictionary["predict"] = predict

	commandFunctionDictionary["gradientDescent"] = gradientDescent

	commandFunctionDictionary["runCommand"] = runCommand
	
	local function tableUnwrap(table, functionToRun, ...)
		
		functionToRun(...)
		
	end

	NewDataPredictNucleusInstance = {

		destroy = destroy,

		addLog = addLog,
		removeLog = removeLog,
		getLogArray = getLogArray,
		clearAllLogs = clearAllLogs,

		addModelToModelData = addModelToModelData,
		removeModelFromModelData = removeModelFromModelData,
		applyFunctionToAllModelsInModelData = applyFunctionToAllModelsInModelData,

		startSync = startSync,
		stopSync = stopSync,

		addCommand = addCommand,
		removeCommand = removeCommand,
		runCommand = runCommand,

		addModelData = addModelData,
		removeModelData = removeModelData,
		getModelData = getModelData,

	}

	return NewDataPredictNucleusInstance

end

return DataPredictNucleus
