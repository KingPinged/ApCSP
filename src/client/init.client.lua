local player: Player = game.Players.LocalPlayer
local PlayerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local problemGui = PlayerGui:WaitForChild("problem") :: ScreenGui
local problemContainer: Frame = problemGui:WaitForChild("container") :: Frame
local answer: TextLabel = problemGui:WaitForChild("answer") :: TextLabel

local optionsContainer = problemGui:WaitForChild("options")

local config = {
	availableColor = Color3.fromRGB(28, 179, 26),
	unavailableColor = Color3.fromRGB(255, 0, 0),
	placedColor = Color3.fromRGB(0, 0, 255),
	defaultText = "Enter +*-/ into the boxes below to get to 10! Each operator can only be used once!",
}

for _, v in pairs(optionsContainer:GetChildren()) do
	if v:IsA("Frame") then
		v.BackgroundColor3 = config.availableColor
	end
end

local problems: { { number } } = {
	{ 5, 3, 2, 1 },
	{ 3, 3, 1, 2 },
}
--[[
 5 + (3 * 2) - 1
3 * 3 + 1 - 2
8 - (4 / 2)
]]
--

local currentlyUsing = {}

local currentLevel: number = 1

local problemsUIInstances: { TextBox | TextLabel } = {}

local events = {}

function calculateAnswer(problem): number | boolean
	local answer: number = 0

	local problemString = ""
	local problemArray = {}
	for _, v: TextBox | TextLabel in pairs(problemsUIInstances) do
		if v.Text == "" then
			return false
		end
		problemString = problemString .. v.Text
		table.insert(problemArray, v.Text)
	end

	local whereIsMultiply = tonumber(table.find(problemArray, "*"))

	if whereIsMultiply then
		local multiplValue1: number = tonumber(problemArray[whereIsMultiply - 1]) or 0
		local multiplValue2: number = tonumber(problemArray[whereIsMultiply + 1]) or 0

		local multipliedTogether = multiplValue1 * multiplValue2

		local newArray = {}
		for i, v in pairs(problemArray) do
			if (i ~= (whereIsMultiply - 1)) and (i ~= (whereIsMultiply + 1)) and (i ~= whereIsMultiply) then
				table.insert(newArray, v)
			end
			if i == whereIsMultiply then
				table.insert(newArray, multipliedTogether)
			end
		end
		problemArray = newArray
	end

	local whereIsDivide = tonumber(table.find(problemArray, "/"))

	if whereIsDivide then
		local multiplValue1: number = tonumber(problemArray[whereIsDivide - 1]) or 0
		local multiplValue2: number = tonumber(problemArray[whereIsDivide + 1]) or 0

		local multipliedTogether = multiplValue1 / multiplValue2

		local newArray = {}
		for i, v in pairs(problemArray) do
			if (i ~= (whereIsDivide - 1)) and (i ~= (whereIsDivide + 1)) and (i ~= whereIsDivide) then
				table.insert(newArray, v)
			end
			if i == whereIsDivide then
				table.insert(newArray, multipliedTogether)
			end
		end
		problemArray = newArray
	end

	print(problemArray)

	local lastElement = nil
	local lastSign = nil

	answer = tonumber(problemArray[1]) or 0

	for _, v in pairs(problemArray) do
		if lastElement then
			if v == "+" then
				lastSign = "+"
			elseif v == "-" then
				lastSign = "-"
			else
				if lastSign == "+" then
					answer = lastElement + tonumber(v)
					lastElement = answer
					lastSign = nil
				elseif lastSign == "-" then
					answer = lastElement - tonumber(v)
					lastElement = answer
					lastSign = nil
				end
			end
		else
			lastElement = tonumber(v)
		end
	end

	return answer
end

function checkAllUi()
	for _, v in pairs(optionsContainer:GetChildren()) do
		if v:IsA("TextLabel") then
			if table.find(currentlyUsing, v.Text) then
				v.BackgroundColor3 = config.unavailableColor
			else
				v.BackgroundColor3 = config.availableColor
			end
		end
	end

	currentlyUsing = {}
	for _, v in pairs(problemsUIInstances) do
		if v:IsA("TextBox") then
			if table.find({ "/", "*", "+", "-" }, v.Text) then
				table.insert(currentlyUsing, v.Text)
				print("adding based on checkallui")
			end
		end
	end
end

function passedLevel()
	currentLevel = currentLevel + 1
	currentlyUsing = {}

	for _, v in pairs(events) do
		v:Disconnect()
	end

	for _, v in pairs(problemsUIInstances) do
		v:Destroy()
	end

	createUi(problems[currentLevel])
	checkAllUi()
end

function checkInputValid(problem, textBox: TextBox)
	if table.find({ "/", "*", "+", "-" }, textBox.Text) then
		if table.find(currentlyUsing, textBox.Text) then
			textBox.Text = ""
		else
			print("adding to currentlyused")
			table.insert(currentlyUsing, textBox.Text)

			--valid
			local answerValue = calculateAnswer(problem)
			if answerValue then
				answer.Text = answerValue

				if answerValue == 10 then
					print("passed")
					for _, v in pairs(problemsUIInstances) do
						if v:IsA("TextBox") then
							v.Text = ""
						end
					end
					passedLevel()
				end
			else
				answer.Text = config.defaultText
			end
		end
	else
		textBox.Text = ""
	end

	checkAllUi()
end

function createUi(problem)
	for i, v in pairs(problem) do
		if i ~= 1 then
			local blank: TextBox = Instance.new("TextBox")
			blank.Text = ""
			blank.Name = "blank"
			blank.TextScaled = true
			blank.Size = UDim2.new(0, 100, 0, 100)
			blank.TextColor3 = config.placedColor
			blank.Parent = problemContainer
			table.insert(problemsUIInstances, blank)

			local e
			e = blank:GetPropertyChangedSignal("Text"):Connect(function()
				if problems[currentLevel] ~= problem then
					e:Disconnect()
					print("WHY NO DISCONNECT")
					return
				end
				checkInputValid(problem, blank)
				print("changed", problem)
			end)
			table.insert(events, e)
		end

		local ui: TextLabel = Instance.new("TextLabel")
		ui.Text = v
		ui.TextScaled = true
		ui.Size = UDim2.new(0, 100, 0, 100)
		ui.Parent = problemContainer
		table.insert(problemsUIInstances, ui)
	end

	answer.Text = config.defaultText
	currentlyUsing = {}
end

createUi(problems[currentLevel])
checkAllUi()
