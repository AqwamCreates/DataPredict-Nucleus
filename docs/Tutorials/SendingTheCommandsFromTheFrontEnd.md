# Sending The Commands From The Front End

This tutorial is the next part for the previous tutorial [here](SettingUpTheCodesForTheRobloxServer.md). If you have not done the previous tutorial, I would recommend you to have a look at it before proceeding.

That being said, let's get right into it.

## Example Initial Setup

In order to see the DataPredict™ Nucleus capabilities, we first need to setup some stuff.

First, let's prepare our data.

```lua

local featureMatrixRegression = {

	{1, 0,  0},
	{1, 10, 2},
	{1, -3, -2},
	{1, -12, -22},
	{1,  2,  2},
	{1, 1,  1},
	{1, -11, -12},
	{1,  3,  3},
	{1, -2, -2},

}

local labelVectorRegression = {

	{ 0},
	{10},
	{-3},
	{-2},
	{ 2},
	{ 1},
	{-1},
	{ 3},
	{-2},

}

```

Then train our model and grab its model parameters.

```lua

LinearRegressionModel:train(featureMatrixRegression, labelVectorRegression)

local ModelParameters = LinearRegressionModel:getModelParameters()

```

Finally, we will visualize the model parameters.

```lua

local TensorL2D = require(TensorL2D) -- Let's get the 2D tensor library.

TensorL2D:printTensor(ModelParameters) -- Then we visualize the model parameters.

```

Once we visualize the model parameters, keep this in mind.

## Sending The Commands

From our previous tutorial, we have not yet added the model name to our [nucleus.datapredict.online](https://nucleus.datapredict.online) website.

For that, we will need to go into the website and add the model name to the middle right edge of it. Make sure the model name is "LinearRegression" since that what we have used in our previous tutorial. This will allow us to control the models that have that model name all at once.

Once you have added the model name, you will now select the getModelParameters inside that website. It will return the average of all model parameters belonging to that model name.

Next, you will press the "Send Command" button at the bottom right corner of the website. This will cause the website to fetch the model parameters from all of the Roblox's servers. Note that it will take a while to load as the back end is rather limited in computational resources.

Once you get the visualization of the model parameters on the website, you will notice that the values of the model parameters from the Roblox server is the same as the ones from the website.

