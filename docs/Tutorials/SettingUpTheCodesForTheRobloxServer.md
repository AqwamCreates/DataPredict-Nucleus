# Setting Up The Codes For The Roblox Server

Currently, the models from DataPredict™ cannot be controlled remotely and this limit the flexibility on how we can apply them.

In this tutorial, we will show on how to enable remote model control ability through DataPredict™ Nucleus library.

## Setting Up Our DataPredict™ Nucleus Instance

In order to construct our DataPredict™ Nucleus instance, we need to provide two important information:

* The UUID

* The API Key

For the UUID, it will automatically given to you when you register your account at [nucleus.datapredict.online](https://nucleus.datapredict.online). It can be found at the top right corner of the website.

As for the API key, you are required to log in with your account and must add it manually at the middle right edge of the website.

Once you note down those two information, place them to the Roblox Studio code as shown below.

```lua

local DataPredictNucleusBaseInstance = require(DataPredictNucleus)

local DataPredictNucleus = DataPredictNucleusBaseInstance.new({uuid = "12345678-9123-4567-8912-345678912345", apiKey = "example"})

```

Replace the UUID and API key strings with yours.

## Adding Models To The DataPredict™ Nucleus Instance

Currently, our DataPredict™ Nucleus instance does not do anything because we did not add any DataPredict™ models. Below, we will demonstrate on how we can add them.

First, we need to create model data so we can have a place to store our models.

```lua

local modelName = "LinearRegression"

DataPredictNucleus.addModelData("LinearRegression")

```

Then, we will need to create our models.

```lua

local DataPredict = require(DataPredict) -- Get the machine and deep learning library, DataPredict.

local LinearRegressionModel = DataPredict.Models.LinearRegression.new({learningRate = 0.001}) -- Then create our model.

```

Finally, we will need to move our model to model data and start syncing.

```lua

local key = "tutorial"

DataPredict.addModelToModelData(modelName, key, LinearRegressionModel)

DataPredictNucleus.startSync()

```

That is pretty much it.

Now you know how to set up the codes for the Roblox server. Congratulations!

You can now proceed to the next tutorial [here](SendingTheCommandsFromTheFrontEnd.md)!
