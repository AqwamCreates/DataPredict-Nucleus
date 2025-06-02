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

TensorL2D:printTensor(LinearRegressionModel:getModelParameters()) -- Then we visualize the model parameters.

```

Once we visualize the model parameters, keep this in mind.

