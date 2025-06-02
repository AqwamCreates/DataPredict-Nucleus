# API Reference

## Constructors

### new()

```

DataPredictNucleus.new({instanceId: string, url: string, uuid: string, apiKey: string}): DataPredictNucleusInstance

```

#### Parameters:

* instanceId: The id for the instance. If the instance id already exists, it will return the instance containing that id.

* url: The target url that contains the backend code. [Default: nucleus-api.datapredict.online]

* uuid: The unique identifier that was given to you when you registered your account.

* apiKey: The API key that deter

* commandPayloadArrayKey: The key for retrieving cached command payload. [Default: default]

* syncTime: The duration between syncs in seconds. [Default: 3]

* maximumNumberOfSyncRetry: The maximum number of sync retries if the sync fails. [Default: 3]

* syncRetryDelay: The delay between sync retries in seconds. [Default: 2]

* commandPayloadArrayCacheDuration: How long should the cached command payload should persists in seconds. [Default: 30]

#### Returns:

* DataPredictNucleusInstance: The instance created/retrieved based on the instance id.

## Functions

### destroy()

```

DataPredictNucleus:destroy()

```

### startSync()

```

DataPredictNucleus:startSync()

```

### stopSync()

```

DataPredictNucleus:stopSync()

```

### addModelData()

```

DataPredictNucleus:addModelData(modelName: string, modelDictionary: {}, modelParameterNameArray: {string}, modelParametersType: string, classNameArray: {string})

```
#### Parameters:

* modelName: The model name to be used by the front end.

* modelDictionary: The existing model dictionary (if any) to be added. [Default: {}]

* modelParameterNameArray: The model parameter names to be added. [Default: {}]

* modelParametersType: The type of model parameters for this model. Available options are:

    * nil (Default)

    * Gradient

    * Centroids

 * classNameArray: An array containing all the classes based on the output of the model.

### removeModelData()

```

DataPredictNucleus:removeModelData(modelName: string)

```

#### Parameters:

* modelName: The model name to be removed from the DataPredict Nucleus instance.

### getModelData()

```

DataPredictNucleus:getModelData(modelName: string): {}

```

#### Parameters:

* modelName: The model name to be retrieved from the DataPredict Nucleus instance.

#### Returns:

* modelData: A dictionary containing all the data for that particular model.

### addLog()

```

DataPredictNucleus:addLog(logType: string, logMessage: string)


```

#### Parameters:

* logType: The type of the log. Available options are:

    * Normal

    * Warning

    * Error

* logMessage: The log message to add.

### removeLog()

```

DataPredictNucleus:removeLog(position: number)

```

* position: The position of the log message to be removed.

### getLogArray()

```

DataPredictNucleus:getLogArray(): {{string}}


```

#### Returns:

* logArray: An array containing all the logs.

### clearLogArray()

```

DataPredictNucleus:clearLogArray()

```