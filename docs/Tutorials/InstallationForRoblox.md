# Getting Started

In this library, we can remotely control our DataPredict ML models using the front end at [nucleus.datapredict.online](https://nucleus.datapredict.online).

To start, we must first download all three libraries from the links below.

| Version | Remote ML Models Controller For DataPredict (DataPredict Nucleus)                                                                                                                  |
|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Release | [DataPredict Nucleus (Release Version 1.0)](https://github.com/AqwamCreates/DataPredict-Nucleus/blob/main/module_scripts/DataPredict%20Nucleus%20-%20Release%20Version%201.0.rbxm) |
| Beta    | [DataPredict Nucleus (Beta 0.0.0)](https://github.com/AqwamCreates/DataPredict-Nucleus/blob/main/module_scripts/DataPredict%20Nucleus.rbxm)                                        |

| Version | Machine And Deep Learning Library (DataPredict)                                                                                                           |
|---------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| Release | [DataPredict (Release Version 2.3)](https://github.com/AqwamCreates/DataPredict/blob/main/module_scripts/DataPredict%20-%20Release%20Version%202.3.rbxm)  |
| Beta    | [DataPredict (Beta 2.3.0)](https://github.com/AqwamCreates/DataPredict/blob/main/module_scripts/AqwamMachineAndDeepLearningLibrary.rbxm)                  |

| Version | 2D Tensor Library (TensorL-2D)                                                               |
|---------|----------------------------------------------------------------------------------------------|
| Beta    | [TensorL-2D Library](https://github.com/AqwamCreates/TensorL-2D/blob/main/src/TensorL2D.lua) |

You can read the Terms And Conditions for the DataPredict library [here](https://github.com/AqwamCreates/DataPredict/blob/main/docs/TermsAndConditions.md) and the TensorL2D Library [here](https://github.com/AqwamCreates/TensorL-2D/blob/main/docs/TermsAndConditions.md).

To download the files from GitHub, you must click on the download button highlighted in the red box.

![Github File Download Screenshot](https://github.com/AqwamCreates/DataPredict/assets/67371914/b921d568-81b9-4f47-8a96-e0ab0316a4fe)

Then drag the files into Roblox Studio from a file explorer of your choice.

Once you put those three libraries into your game, make sure you link them all using the linkers.

![image](https://github.com/user-attachments/assets/f487abe2-2919-404b-b4bb-b3b56369c8e1)

![image](https://github.com/user-attachments/assets/800beed0-6eb7-4304-8fb4-5cf853448efe)

Next, we will use require() function to our DataPredict Nucleus library:

```lua

local DataPredictNucleus = require(DataPredictNucleus)

```
