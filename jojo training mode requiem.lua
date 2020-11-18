print("JoJo's Bizarre Adventure: Heritage for the Future Training Mode")
print("Credits to peon2 for programming, potatoboih for finding RAM values and Klofkac for the initial version.")
print("Special Thanks to Zarythe for graphical design and all the beta testers")
print("Developed specifically for JoJo's Bizarre Adventure (Japan 990913, NO CD) (jojoban) though other versions should work. Use this script with FBA-RR")
print("Because of how knockdown is handled in JoJo, meaties may not behave as expected. Occasionally when the game is reset the script messes up, simply hit 'restart' in the lua script window to fix that")
--This script is not compressed or written efficiently as it is layed out to promote legibility.

print()
print("Commands List")
print()
print("Coin+Down -> Toggles Infinite Meter")
print("Coin+Up -> Toggles Music")
print("Coin+Left -> Toggles P1 Combo GUI")
print("Coin+Right -> Toggles P2 Combo GUI")
print("Coin+B -> Toggle Health Refill (when the refill is off it fixes most meaty issues)")
print("Coin+C -> Toggle Instant Stand Guage refill (when the stand guage reaches 0 it fills to full)")
print("Coin+S -> Instant Stand Guage Refill for the opponent")
print("Start+Any Direction -> The opponent moves in that direction until told otherwise")
print("Start+A -> Forcibly stops the opponent")
print("Medium Kick -> Starts recording playback")
print("Heavy Kick -> Starts/Stops playback")
print("Coin+Heavy Kick -> Loops playback")

memory.writebyte(0x20713A8, 0x09) -- Infinite Credits
memory.writebyte(0x20312C1, 0x01) -- Unlock all characters

--Defining variables


--Configurable Variables. Feel free to change these to fit preference.

local P1meterFill = false -- Defaults P1 auto-refill to false
local P2meterFill = false -- Defaults P2 auto-refill to false
local musicToggle = false -- Defaults Music to off
local standRefillToggle = true -- Defaults stands to automatically refill to full when they reach 0.
local healthToggle = true -- Defaults automatic Health refill to true
local inputHistory = 11 -- Number of frames of input history shown
local scrollFromBottom = true -- Toggles scrolling the input history upwards or downwards
local xP1 = 13 -- X Position of the first frame of P1's input history.
local yP1 = 207-- Y Position of the first frame of P1's input history. 207 and 70 are recommended for scrolling from the bottom and top respectively.
local xP2 = 337-- X Position of the first frame of P2's input history.
local yP2 = 207-- Y Position of the first frame of P2's input history. 207 and 70 are recommended for scrolling from the bottom and top respectively.


--Configurable Colours. The colours "clear", "red", "green", "blue", "white", "black", "gray", "grey", "orange", "yellow", "green", "teal", "cyan", "purple" and "magenta" are available by default. Additionally you can create your own colours with rgb in the format {red,green,blue,alpha} (don't put it in quotation marks). e.g. "red" or {255,0,0}

local comboCounterActiveColour = "blue"-- Colour of the combo counter if the combo hasn't dropped
local inputHistoryA="green"-- Colour of the letter A in the input history
local inputHistoryB="blue"-- Colour of the letter B in the input history
local inputHistoryC="red"-- Colour of the letter C in the input history
local inputHistoryS="yellow"-- Colour of the letter S in the input history



--Non-Configurable Variable. It's best if you don't change these
local playerOnePreviousHealth = playerOneHealth 
local playerTwoPreviousHealth = playerTwoHealth 
local playerOneHealth = memory.readbyte(0x205BB28) -- Reads Player One's current health
local playerTwoHealth = memory.readbyte(0x205BB29) -- Reads Player Two's current health
local playerOneDamage = 0 -- Current Damage on P1
local playerTwoDamage = 0 -- Current Damage on P2
local playerOnePreviousDamage = 0 -- Value of Damage used for display
local playerTwoPreviousDamage = 0 -- Value of Damage used for display
local playerOneComboDamage = 0 -- Value of Combo Damage used for display
local playerTwoComboDamage = 0 -- Value of Combo Damage used for display
local playerOneStandHealth = memory.readbyte(0x205BB48)
local playerTwoStandHealth = memory.readbyte(0x205BB49)
local playerOneStandGuage = playerOneStandHealth -- Reads Player One's current stand guage
local playerTwoStandGuage = playerTwoStandHealth -- Reads Player Two's current stand guage
local playerOneCombo=0
local playerTwoCombo=0
local P1control=0
local P2control=0
local controlTemp=0
local P1inputs = 0 
local P2inputs = 0
local P1previousinputs = 0
local P2previousinputs = 0
local inputHistoryTableP1 = {}
local inputHistoryTableP2 = {}
for i = 1, inputHistory, 1 do --Sets the table for use
	inputHistoryTableP1[i] = 0
	inputHistoryTableP2[i] = 0
end
local offset = 3
local toggleP1Gui = true
local toggleP2Gui = false
local frameLockP1=0
local frameLockP2=0
local P1recording=false
local P1playback=false
local P1recorded = {0}
local P1frameCount = 0
local P2recording=false
local P2playback=false
local P2recorded = {0}
local P2frameCount = 0
local P1Loop = false
local P2Loop = false
local frameLockP1 = 1
local frameLockP2 = 1
local P1previousDirection = 0
local P1direction=0
local P2previousDirection = 0
local P2direction=0
local displayComboCounterP1=0
local displayComboCounterP2=0
local comboCounterColourP1="white"
local comboCounterColourP2="white"
local scroll = 1
if scrollFromBottom~=true then
	scroll=-1
end
function memoryReader() -- Reads from memory and assigns variables based on the memory
	playerOnePreviousHealth = playerOneHealth -- Health Value of P1 1f ago
	playerTwoPreviousHealth = playerTwoHealth -- Health Value of P2 1f ago
	playerOneHealth = memory.readbyte(0x205BB28) -- P1 Health this frame
	playerTwoHealth = memory.readbyte(0x205BB29) -- P2 Health this frame
	playerOnePreviousCombo = playerOneCombo -- P1s combo meter count 1f ago
	playerTwoPreviousCombo = playerTwoCombo -- P2s combo meter count 1f ago
	playerOneCombo = memory.readbyte(0x205BB38) -- P1s Combo count this frame
	playerTwoCombo = memory.readbyte(0x205BB39) -- P2s Combo count this frame
	playerOneStandHealth = memory.readbyte(0x205BB48) -- P1s Stand Health
	playerTwoStandHealth = memory.readbyte(0x205BB49) -- P2s Stand Health
	gameinputs=joypad.read() -- reads all inputs
	if playerOneStandGuage<playerOneStandHealth then
		playerOneStandGuage=playerOneStandHealth
	elseif playerTwoStandGuage<playerTwoStandHealth then
		playerTwoStandGuage=playerTwoStandHealth
	end
end

function inputSorter() --sorts inputs
	P1previousinputs = P1inputs
	P2previousinputs = P2inputs
	P1inputs = 0 --resets P1 inputs
	P2inputs = 0 --resets P2 inputs
	
	
	if gameinputs["P1 Left"] then
		P1inputs=P1inputs+1
	end
	if gameinputs["P1 Down"] then
		P1inputs=P1inputs+3
	end
	if gameinputs["P1 Right"] then
		P1inputs=P1inputs+5
	end
	if gameinputs["P1 Up"] then
		P1inputs=P1inputs+10
	end
		P1previousDirection=P1direction
		P1direction=P1inputs
		
	if gameinputs["P1 Weak Kick"] then
		P1inputs=P1inputs+20
	end
	if gameinputs["P1 Strong Punch"] then
		P1inputs=P1inputs+40
	end
	if gameinputs["P1 Medium Punch"] then
		P1inputs=P1inputs+80
	end
	if gameinputs["P1 Weak Punch"] then
		P1inputs=P1inputs+160
	end


	if gameinputs["P2 Left"] then
		P2inputs=P2inputs+1
	end
	if gameinputs["P2 Down"] then
		P2inputs=P2inputs+3
	end
	if gameinputs["P2 Right"] then
		P2inputs=P2inputs+5
	end
	if gameinputs["P2 Up"] then
		P2inputs=P2inputs+10
	end
	
	P2previousDirection=P2direction
	P2direction=P2inputs
	
	if gameinputs["P2 Weak Kick"] then
		P2inputs=P2inputs+20
	end
	if gameinputs["P2 Strong Punch"] then
		P2inputs=P2inputs+40
	end
	if gameinputs["P2 Medium Punch"] then
		P2inputs=P2inputs+80
	end
	if gameinputs["P2 Weak Punch"] then
		P2inputs=P2inputs+160
	end
end

function inputHistoryRefresher()
	tempTable={}
	if (P1inputs ~= P1previousinputs) and (P1inputs ~= 0) and (P1previousinputs-P1previousDirection+P1inputs)~=P1previousinputs and (P1previousinputs-P1previousDirection~=P1inputs-P1direction or P1direction~=0) and (not(P1inputs-(P1previousinputs-P1previousDirection)<0)) then
		for i = 1, inputHistory-1, 1 do
			tempTable[i+1] = inputHistoryTableP1[i]
		end
		inputHistoryTableP1 = tempTable
		if (P1previousinputs-P1previousDirection~=P1inputs-P1direction)  then
			inputHistoryTableP1[1] = P1inputs-(P1previousinputs-P1previousDirection)
		else
			inputHistoryTableP1[1] = P1direction
		end
	end
	tempTable={}
	if (P2inputs ~= P2previousinputs) and (P2inputs ~= 0) and (P2previousinputs-P2previousDirection+P2inputs)~=P2previousinputs and (P2previousinputs-P2previousDirection~=P2inputs-P2direction or P2direction~=0) and (not(P2inputs-(P2previousinputs-P2previousDirection)<0)) then
		for i = 1, inputHistory-1, 1 do
			tempTable[i+1] = inputHistoryTableP2[i]
		end
		inputHistoryTableP2 = tempTable
		if (P2previousinputs-P2previousDirection~=P2inputs-P1direction)  then
			inputHistoryTableP2[1] = P2inputs-(P2previousinputs-P2previousDirection)
		else
			inputHistoryTableP2[1] = P2direction
		end
	end
end

function drawDpad(DpadX,DpadY,sideLength)
	gui.box(DpadX,DpadY,DpadX+(sideLength*3),DpadY+sideLength,"black","white")
	gui.box(DpadX+sideLength, DpadY-sideLength, DpadX+(sideLength*2), DpadY+(sideLength*2), "black", "white")
	gui.box(DpadX+1, DpadY+1, DpadX+(sideLength*3)-1, DpadY+sideLength-1,"black")
end

function gameplayLoop() --main loop for gameplay calculations

--combo counters

	
	if (playerOnePreviousHealth > playerOneHealth) or (playerTwoCombo>playerTwoPreviousCombo) then
		playerOneDamage = math.abs(playerOnePreviousHealth-playerOneHealth) -- Calculates damage to P1
		if (playerTwoCombo>1 and playerTwoPreviousCombo~=0) then -- Checks to see if the combo damage counter for P2 should increase. playerTwoCombo and playerTwoPreviousCombo checks that it's not the first hit. playerTwoCombo needs to be >1 or a multihitting move will continue the combo counter like kaks emerald splash.  
			playerTwoComboDamage=math.abs(playerTwoComboDamage)+playerOneDamage  -- Increments Counter by the amount of damage done
		else
			playerTwoComboDamage=playerOneDamage -- Otherwise the combo damage is whatever is done
		end
		playerOnePreviousDamage = playerOneDamage -- Sets a display value for damage dealt
	end
	
	if (playerTwoPreviousHealth > playerTwoHealth) or (playerOneCombo>playerOnePreviousCombo) then
		playerTwoDamage = math.abs(playerTwoPreviousHealth-playerTwoHealth) -- Calculates damage to P2
		if (playerOneCombo>1 and playerOnePreviousCombo~=0) then -- Checks to see if the combo damage counter for P1 should increase. playerOneCombo and playerOnePreviousCombo checks that it's not the first hit. playerOneCombo needs to be >1 or a multihitting move will continue the combo counter like kaks emerald splash.  
			playerOneComboDamage=math.abs(playerOneComboDamage)+playerTwoDamage -- Increments Counter by the amount of damage done
		else
			playerOneComboDamage=playerTwoDamage -- Otherwise the combo damage is whatever is done
		end
		playerTwoPreviousDamage = playerTwoDamage -- Sets a display value for damage dealt
	end
	
	if playerOneCombo>=2 then
		displayComboCounterP1 = playerOneCombo
		comboCounterColourP1=comboCounterActiveColour
	else
		comboCounterColourP1="white"
	end
	
	if playerTwoCombo>=2 then
		displayComboCounterP2 = playerTwoCombo
		comboCounterColourP2=comboCounterActiveColour
	else
		comboCounterColourP2="white"
	end
	

--Health Regen

	--print(playerOnePreviousCombo..":"..playerTwoDamage..":"..playerOneCombo)
	if ((playerOnePreviousCombo>0 or playerTwoDamage~=0) and (playerOneCombo==0)) and healthToggle==true then
        	memory.writebyte(0x2034DED, 0x90)	--p2 health
		playerTwoDamage = 0
	end

	if ((playerTwoPreviousCombo>0 or playerOneDamage~=0) and (playerTwoCombo==0)) and healthToggle==true  then
        	memory.writebyte(0x20349CD, 0x90)	--p1 health
		playerOneDamage = 0
	end


--Meter Refill

	if (P1meterFill == true) then
		memory.writebyte(0x2034863, 0x680A) --refills P1's meter
	end
	
	if P2meterFill == true then
		memory.writebyte(0x2034887, 0x680A) --refills P2's meter
	end

--Music Toggle
	if musicToggle == true then
		memory.writebyte(0x205CC1A, 0x80) --turns in music	
	else
		memory.writebyte(0x205CC1A, 0x00) --turns off music
	end	

--Stand Refill
		if standRefillToggle == true and playerOneStandHealth == 0 then --Automatically Refills P1 stand guage at 0
			memory.writebyte(0x203520D, playerOneStandGuage)
		end
		
		if standRefillToggle == true and playerTwoStandHealth == 0 then --Automatically Refills P2 stand guage at 0
			memory.writebyte(0x203562D, playerTwoStandGuage)
		end

end

function inputChecker()	
--refill meter
	if (gameinputs["P1 Coin"] == true) and (frameLockP1<frame) then -- checks the address "P1 Coin". If P1 Coin is pressed
		if gameinputs["P1 Down"] == true then
			P1meterFill = not(P1meterFill) --inverts the boolean
			frameLockP1 = frame+10
		elseif gameinputs["P1 Up"] == true then
			musicToggle = not(musicToggle)
			frameLockP1 = frame+10
		elseif gameinputs["P1 Left"] == true then
			toggleP1Gui = not(toggleP1Gui)
			frameLockP1 = frame+10
		elseif gameinputs["P1 Right"] == true then
			toggleP2Gui = not(toggleP2Gui)
			frameLockP1 = frame+10
		elseif gameinputs["P1 Medium Punch"] == true then
			healthToggle=not(healthToggle)
			frameLockP1 = frame+10
		elseif gameinputs["P1 Strong Punch"] == true then
			standRefillToggle=not(standRefillToggle)
			frameLockP1 = frame+10
		elseif gameinputs["P1 Weak Kick"] == true then
			memory.writebyte(0x203562D, playerTwoStandGuage)
			frameLockP1 = frame+10
		elseif gameinputs["P1 Strong Kick"] == true then
			P1Loop = not(P1Loop)
			if P1Loop == true then
				P1playback=true
			end
			frameLockP1 = frame+10
			P1frameCount=1
			
		end
	end
	if (gameinputs["P2 Coin"] == true) and (frameLockP2<frame) then -- checks the address "P2 Coin". If P2 Coin is pressed
		if gameinputs["P2 Down"] == true then
			P2meterFill = not(P2meterFill) --inverts the boolean
			frameLockP2 = frame+10
		elseif gameinputs["P2 Up"] == true then
			musicToggle = not(musicToggle)
			frameLockP2 = frame+10
		elseif gameinputs["P2 Left"] == true then
			toggleP1Gui = not(toggleP1Gui)
			frameLockP2 = frame+10
		elseif gameinputs["P2 Right"] == true then
			toggleP2Gui = not(toggleP2Gui)
			frameLockP2 = frame+10
		elseif gameinputs["P2 Medium Punch"] == true then
			healthToggle = not(healthToggle)
			frameLockP2 = frame+10
		elseif gameinputs["P2 Strong Punch"] == true then
			standRefillToggle=not(standRefillToggle)
			frameLockP2 = frame+10
		elseif gameinputs["P2 Weak Kick"] == true then
			memory.writebyte(0x203520D, playerOneStandGuage)
			frameLockP2 = frame+10
		elseif gameinputs["P2 Strong Kick"] == true then
			P2Loop = not(P2Loop)
			if P2Loop == true then
				P2playback=true
			end
			frameLockP2 = frame+10
			P2frameCount=1
		end
	end
	
	if gameinputs["P1 Start"] == true then --checks to see if P1 is holding start
		
		P2control=0
		
		if (gameinputs["P1 Left"]== true) then 
			P2control = P2control+1
			frameLockP1 = frame+10
		end
		if (gameinputs["P1 Down"]== true) then
			P2control = P2control+3
			frameLockP1 = frame+10
		end
		if (gameinputs["P1 Right"]== true) then
			P2control = P2control+5
			frameLockP1 = frame+10
		end
		if (gameinputs["P1 Up"]== true) then
			P2control = P2control+10
			frameLockP1 = frame+10
		end
		if (gameinputs["P1 Weak Punch"]==true) then
			P2control=0
			P2playback=false
			P2Loop=false
			frameLockP1=frame+10
		end
	end


	if gameinputs["P2 Start"] == true then --checks to see if P2 is holding start
		
		P1control=0
		
		if (gameinputs["P2 Left"]== true)  then 
			P1control = P1control+1
			frameLockP2 = frame+10
		end
		if (gameinputs["P2 Down"]== true) then
			P1control = P1control+3
			frameLockP2 = frame+10
		end
		if (gameinputs["P2 Right"]== true) then
			P1control = P1control+5
			frameLockP2 = frame+10
		end
		if (gameinputs["P2 Up"]== true) then
			P1control = P1control+10
			frameLockP2 = frame+10
		end	
		if (gameinputs["P2 Weak Punch"]==true) then
			P1control=0
			frameLockP2=frame+10
			P1playback=false
			P1Loop=false
		end
	end
--Playback Control
--P1
	if (gameinputs["P1 Medium Kick"]==true and frame>frameLockP1) then
		P1playback = false
		P1Loop = false
		P1recording = not(P1recording)
		if P1recording == true then
			P1frameCount=1
		elseif P1recording == false then
			P1frameStop = P1frameCount
		end
		frameLockP1 = frame+10	
	end
	if (gameinputs["P1 Strong Kick"] == true and frame>frameLockP1) then
		P1Loop = false
		P1recording = false
		P1playback = not(P1playback)	
		P1frameCount=1
		frameLockP1 = frame+10
	end

--P2
	if (gameinputs["P2 Medium Kick"]==true and frame>frameLockP2) then
		P2playback = false
		P2Loop = false
		P2recording = not(P2recording)
		if P2recording == true then
			P2frameCount=1
		elseif P2recording == false then
			P2frameStop = P2frameCount
		end
		frameLockP2 = frame+10	
	end
	if (gameinputs["P2 Strong Kick"] == true and frame>frameLockP2) then
		P2Loop = false
		P2recording = false
		P2playback = not(P2playback)	
		P2frameCount=1
		frameLockP2 = frame+10
	end
	
	

end

function characterControl(frameNo)

--P2 control
if not(P2playback == true or P1playback == true) then
	scriptInputs={} --refreshes the table each time so different inputs can be used
end

	controlTemp=0


	if (frameNo ~= nil and P2playback == true) then
		if P2recorded[frameNo] == nil then
			controlTemp = 0
		else
			controlTemp=P2recorded[frameNo]
		end
	else
		controlTemp=P2control
	end

	if (controlTemp-160)>=0 then
		scriptInputs["P2 Weak Punch"] = true
		controlTemp = controlTemp-160
	end
	if (controlTemp-80)>=0 then
		scriptInputs["P2 Medium Punch"] = true
		controlTemp = controlTemp-80
	end
	if (controlTemp-40)>=0 then
		scriptInputs["P2 Strong Punch"] = true
		controlTemp = controlTemp-40
	end
	if (controlTemp-20)>=0 then
		scriptInputs["P2 Weak Kick"] = true
		controlTemp = controlTemp-20
	end
	if (controlTemp-10)>=0 then
		scriptInputs["P2 Up"] = true
		controlTemp = controlTemp-10
	end	
	if (controlTemp-5)>=0 then
		scriptInputs["P2 Right"] = true
		controlTemp = controlTemp-5
	end
	if (controlTemp-3)>=0 then
		scriptInputs["P2 Down"] = true
		controlTemp = controlTemp-3
	end
	if (controlTemp-1)>=0 then
		scriptInputs["P2 Left"] = true
		controlTemp = controlTemp-1
	end

--P1 control
	controlTemp=0

	if (frameNo ~= nil and P1playback==true) then
		if P1recorded[frameNo] == nil then
			controlTemp = 0
		else
			controlTemp=P1recorded[frameNo]
		end
	else
		controlTemp=P1control
	end
	
	if (controlTemp-160)>=0 then
		scriptInputs["P1 Weak Punch"] = true
		controlTemp = controlTemp-160
	end	
	if (controlTemp-80)>=0 then
		scriptInputs["P1 Medium Punch"] = true
		controlTemp = controlTemp-80
	end
	if (controlTemp-40)>=0 then
		scriptInputs["P1 Strong Punch"] = true
		controlTemp = controlTemp-40
	end
	if (controlTemp-20)>=0 then
		scriptInputs["P1 Weak Kick"] = true
		controlTemp = controlTemp-20
	end
	if (controlTemp-10)>=0 then
		scriptInputs["P1 Up"] = true
		controlTemp = controlTemp-10
	end	
	if (controlTemp-5)>=0 then
		scriptInputs["P1 Right"] = true
		controlTemp = controlTemp-5
	end
	if (controlTemp-3)>=0 then
		scriptInputs["P1 Down"] = true
		controlTemp = controlTemp-3
	end
	if (controlTemp-1)>=0 then
		scriptInputs["P1 Left"] = true
	end

	if (P1control ~= 0 or P2control ~= 0 or frameNo ~= nil) then 
		joypad.write(scriptInputs)
	end
end

function guiWriter() -- Writes the GUI
	gui.text(18,15, playerOneHealth) -- P1 Health at x:18 and y:15
	gui.text(355,15, playerTwoHealth) -- P2 Health
	gui.text(50, 24, playerOneStandHealth) -- P1's Stand Health
	gui.text(326,24, playerTwoStandHealth) -- P2's Stand Health
	gui.text(135,216,tostring(memory.readbyte(0x205BB64))) -- P1's meter fill
	gui.text(242,216,tostring(memory.readbyte(0x205BB65))) -- P2's meter fill
	
	if (toggleP1Gui) then

		gui.text(8,50,"P1 Damage: ".. tostring(playerTwoPreviousDamage)) -- Damage of P1's last hit
		gui.text(8,66,"P1 Combo: ")
		gui.text(48,66, displayComboCounterP1, comboCounterColourP1) -- P1's combo count
		gui.text(8,58,"P1 Combo Damage: ".. tostring(playerOneComboDamage)) -- Damage of P1's combo in total
		
		for i = 1, inputHistory, 1 do
			tempTable=inputHistoryTableP1[i]
			buttonOffset=0
			if (tempTable-160)>=0 then --A
				gui.text(xP1+offset*4,yP1-1-((11)*i*scroll),"A",inputHistoryA)
				tempTable = tempTable-160
				buttonOffset=buttonOffset+6
			end	
			if (tempTable-80)>=0 then --B
				gui.text(xP1+offset*4+buttonOffset,yP1-1-((11)*i*scroll),"B",inputHistoryB)
				tempTable = tempTable-80
				buttonOffset=buttonOffset+6
			end
			if (tempTable-40)>=0 then --C
				gui.text(xP1+offset*4+buttonOffset,yP1-1-((11)*i*scroll),"C",inputHistoryC)
				tempTable = tempTable-40
				buttonOffset=buttonOffset+6
			end
			if (tempTable-20)>=0 then --S
				gui.text(xP1+offset*4+buttonOffset,yP1-1-((11)*i*scroll),"S",inputHistoryS)
				tempTable = tempTable-20
			end
			if (tempTable<20 and not(tempTable<=0)) then
				drawDpad(xP1,yP1-((11)*i*scroll),offset)
			end
			if (tempTable-10)>=0 then --Up
				gui.box(xP1+offset+1, yP1-(11*i*scroll), xP1+offset*2-1, yP1-offset+1-(11*i*scroll),"red")
				tempTable = tempTable-10
			end	
			if (tempTable-5)>=0 then --Right
				gui.box(xP1+offset*2, yP1+1-(11*i*scroll), xP1+offset*3-1, yP1+offset-1-(11*i*scroll),"red")
				tempTable = tempTable-5
			end
			if (tempTable-3)>=0 then --Down
				gui.box(xP1+offset+1, yP1+offset-(11*i*scroll), xP1+offset*2-1, yP1+offset*2-(11*i*scroll)-1,"red")
				tempTable = tempTable-3
			end
			if (tempTable-1)>=0 then --Left
				gui.box(xP1+1, yP1+1-(11*i*scroll), xP1+offset, yP1+offset-1-(11*i*scroll),"red")
			end
		end
	end
	
	if (P1recording) then
			gui.text(152,32,"Recording", "red")
		elseif (P1playback) then
			gui.text(152,32,"Replaying", "red")
		end

	if (toggleP2Gui) then
	
		gui.text(300,50,"P2 Damage: " .. tostring(playerOnePreviousDamage)) -- Damage of P2's last hit
		gui.text(300,66,"P2 Combo: ")
		gui.text(348,66, displayComboCounterP2, comboCounterColourP2) -- P2's combo count
		gui.text(300,58,"P2 Combo Damage: " .. tostring(playerTwoComboDamage)) -- Damage of P2's combo in total

		for i = 1, inputHistory, 1 do
			tempTable=inputHistoryTableP2[i]
			buttonOffset=0
			if (tempTable-160)>=0 then --A
				gui.text(xP2+offset*4,yP2-1-((11)*i*scroll),"A",inputHistoryA)
				tempTable = tempTable-160
				buttonOffset=buttonOffset+6
			end	
			if (tempTable-80)>=0 then --B
				gui.text(xP2+offset*4+buttonOffset,yP2-1-((11)*i*scroll),"B",inputHistoryB)
				tempTable = tempTable-80
				buttonOffset=buttonOffset+6
			end
			if (tempTable-40)>=0 then --C
				gui.text(xP2+offset*4+buttonOffset,yP2-1-((11)*i*scroll),"C",inputHistoryC)
				tempTable = tempTable-40
				buttonOffset=buttonOffset+6
			end
			if (tempTable-20)>=0 then --S
				gui.text(xP2+offset*4+buttonOffset,yP2-1-((11)*i*scroll),"S",inputHistoryS)
				tempTable = tempTable-20
			end
			if (tempTable<20 and not(tempTable<=0)) then
				drawDpad(xP2,yP2-((11)*i*scroll),offset)
			end
			if (tempTable-10)>=0 then --Up
				gui.box(xP2+offset+1, yP2-(11*i*scroll), xP2+offset*2-1, yP2-offset+1-(11*i*scroll),"red")
				tempTable = tempTable-10
			end	
			if (tempTable-5)>=0 then --Right
				gui.box(xP2+offset*2, yP2+1-(11*i*scroll), xP2+offset*3-1, yP2+offset-1-(11*i*scroll),"red")
				tempTable = tempTable-5
			end
			if (tempTable-3)>=0 then --Down
				gui.box(xP2+offset+1, yP2+offset-(11*i*scroll), xP2+offset*2-1, yP2+offset*2-(11*i*scroll)-1,"red")
				tempTable = tempTable-3
			end
			if (tempTable-1)>=0 then --Left
				gui.box(xP2+1, yP2+1-(11*i*scroll), xP2+offset, yP2+offset-1-(11*i*scroll),"red")
			end
		end
	end
	if (P2recording) then
		gui.text(200,32,"Recording", "red")
	elseif (P2playback) then
		gui.text(200,32,"Replaying", "red")
	end
end

function playbackChecks()
	if P1recording == true then
		P1recorded[P1frameCount]=P1inputs
	end
	
	if (P1playback==true and P1frameCount ~= P1frameStop) then
		scriptInputs={}
		characterControl(P1frameCount)
	elseif (P1frameCount == P1frameStop and P1playback == true) then
		if P1Loop == true then
			P1frameCount = 0
		else
			P1playback=false
		end
	end

	if P2recording == true then
		P2recorded[P2frameCount]=P2inputs
	end
	
	if (P2playback==true and P2frameCount ~= P2frameStop) then
		if P1playback == false then
			scriptInputs={}
		end
		characterControl(P2frameCount)
	elseif (P2frameCount == P2frameStop and P2playback == true) then
		if P2Loop == true then
			P2frameCount=0
		else
			P2playback=false
		end
	end	
end

while true do
	frame = emu.framecount()
	P1frameCount = P1frameCount+1
	P2frameCount = P2frameCount+1
	memoryReader()
	gameplayLoop()
	inputSorter()
	inputChecker()
	playbackChecks()
	inputHistoryRefresher()
	characterControl()
	guiWriter()
	memory.writebyte(0x20314B4, 0x63) -- Infinite Clock Time
	emu.frameadvance()
end
