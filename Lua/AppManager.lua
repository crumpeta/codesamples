--[[ -------------------------------------------------------------------------------------------

AppManager

AppManager coordinates activity for the UI and game Session objects.
Its purpose is to decouple the UI from the gameSession objects.

AppManager hides the Storyboard API from systems underneath it.  See notes in the Storyboard API 
section below.

@usage 

-- Create an App Manager
appMgr = AppManager:new(gameSession, uiManager, Runtime)

-- Wait until Storyboard scenes receive Storyboard Events.  The scenes will call AppManager with the Storyboard
-- event received and the Scene view.
view = appMgr:handleStoryboardEvent(e, view)

-- When gameEvents are dispatched, Corona will call the AppManager game event handler.
appMgr:handleGameEvent(e)

]]--


local AppManager = {}


---------------------------------------------------------------------------------------------


function AppManager:new(gameSession, uiManager, Runtime)
    
    assert(type(gameSession) == 'table', 'Expected a gameSession object, but got: ' .. tostring(gameSession))
    assert(type(uiManager)   == 'table', 'Expected a uiManager object, but got: '   .. tostring(uiManager))
    assert(type(Runtime)     == 'table', 'Expected a Runtime object, but got: '     .. tostring(Runtime))
    
    local o = {}
    
    o.gameSession = gameSession
    o.uiManager   = uiManager
    o.Runtime     = Runtime
    
    o.lastGameSessionRequest  = nil
    o.lastGameSessionResponse = nil
    
    setmetatable(o, self)
    self.__index = self
    
    return o
    
end


---------------------------------------------------------------------------------------------

-- AppManager specific API

---------------------------------------------------------------------------------------------


function AppManager:playGameRequestListener(event)
    
    if (event) then
        self:dispatchMessage(event.playGameRequest)
    end
    
end 


-- This method helps decouple AppManager from Runtime
function AppManager:dispatchMessage(playRequest)
    
    local playResponse = self.gameSession:play(playRequest)
    
    local responseAck  = self.uiManager:invokeUpdate(playResponse)
    
    --TODO - do we do anything with the responseACK?
    
end


function AppManager:uiHasChangedOld(uiUpdateResponse)
    print("Received uiHasChanged event.")
    
    local gamePhase         = self.gameSession:getGamePhase()
    local squareID          = self.gameSession:getPlayerPosition()
    local playableSquareIDs = self.gameSession:getPlayableSquareIDs()
    
    local uiUpdateRequest = {
        name                = nil,
        phase               = nil,
        
        gamePhase           = gamePhase,
        currentSquareID     = squareID,
        squareID            = squareID,
        playableSquareIDs   = playableSquareIDs,
        storyboard          = self.uiManager.storyboard,
        nextUpdateEvent     = {},
    }
    
    local oe = uiUpdateRequest --convenience var
    
    if ( uiUpdateResponse.type == 'movePlayer' ) then
        
        oe.gamePhase           = self.gameSession:movePlayer(uiUpdateResponse.movedToSquareId)
        oe.squareID            = self.gameSession:getPlayerPosition()
        oe.playableSquareIDs   = self.gameSession:getPlayableSquareIDs()
        
        local nextUpdateEvent = {}
        
        if (uiUpdateResponse.phase == 'began') then
            
            oe.phase                                    = 'began'
            oe.nextUpdateEvent.uiUpdateResponse.type    = 'movePlayer'
            oe.nextUpdateEvent.phase                    = 'ended'
            
        elseif (uiUpdateResponse.phase == 'ended') then
            
            oe.phase                                    = 'ended'
            oe.nextUpdateEvent.uiUpdateResponse.type    = 'playSquare'
            oe.nextUpdateEvent.phase                    = 'began'
            
        end
        
        
        
    elseif (uiUpdateResponse.type == 'playSquare') then
        
        if (uiUpdateResponse.phase == 'began') then
            
            oe = {
                name                = 'playSquare',
                phase               = 'began',
                
                showCardDelayInMs   = uiUpdateResponse.showCardDelayInMs or 0,
                card                = self.gameSession:getCard(),
                gamePhase           = gamePhase,
                currentSquareID     = squareID,
                playableSquareIDs   = playableSquareIDs,
                storyboard          = self.uiManager.storyboard,
            }
            
        elseif (uiUpdateResponse.phase == 'ended') then
            
            local playerID  = self.gameSession:loadNextPlayer()
            gamePhase       = self.gameSession:getGamePhase()
            squareID        = self.gameSession:getPlayerPosition()
            
            oe = {
                name                = 'spinWheel',
                phase               = 'began',
                
                playerID            = playerID,
                gamePhase           = gamePhase,
                squareID            = squareID,
                currentSquareID     = squareID,
                storyboard          = self.uiManager.storyboard,
            }
            
        elseif (uiUpdateResponse.type == 'switchPlayer') then
            
            if (uiUpdateResponse.phase == 'began') then
                
            elseif (uiUpdateResponse.phase == 'ended') then
                
                local playerID  = self.gameSession:loadNextPlayer()
                gamePhase       = self.gameSession:getGamePhase()
                squareID        = self.gameSession:getPlayerPosition()
                
                oe = {
                    name                = uiUpdateResponse.type,
                    phase               = uiUpdateResponse.phase,
                    
                    playerID            = playerID,
                    gamePhase           = gamePhase,
                    squareID            = squareID,
                    currentSquareID     = squareID,
                    storyboard          = self.uiManager.storyboard,
                }
                
            end
            
        else
            
            error('Should not be seeing this event:'..oe.uiUpdateResponse)
            
        end
        
    end -- if
    
    if (oe.showCardDelayInMs == nil) then
        oe.showCardDelayInMs = 1000
    end
    
    if (oe) then
        assert(oe.currentSquareID > 0)
        
        self.uiManager:invokeUpdate(oe)
    end
    
end

---------------------------------------------------------------------------------------------

-- UIManager Facade

---------------------------------------------------------------------------------------------


function AppManager:getDisplayObject(name)
    
    assert(name ~= nil, 'Expected a string value for a display object name.')
    
    return self.uiManager:getDisplayObject(aDisplayObjectName)
    
end



function AppManager:getDisplayGroup(groupName)
    
    assert(groupName ~= nil, 'Expected a display group name.')
    
    return self.uiManager:getDisplayGroup(groupName)
    
end


---------------------------------------------------------------------------------------------

--  Corona Storyboard API Facade

---------------------------------------------------------------------------------------------

-- AppManager understands and captures events from Corona's Storyboard API.  
-- WHenever possible, AppManager will translate these storyboard events into calls that get or set
-- Corona SDK Display Groups or Display Objects.  The goal is to encapsulate the Storyboard API
-- interface and logic at the AppManager level; modules underneath this layer, such as UIManager and
-- gameSession should be unaware that the Storyboard API exists.

---------------------------------------------------------------------------------------------

--[[
Receive a Corona Storyboard event and return the Display Group containing the Display Objects for 
the Storyboard scene.

@param event a Corona Storyboard event
@param storyboardSceneView the DisplayGroup used as the view of the Storyboard Scene
@return displayGroup Display Group to replace the Storyboard Scene view
]]--
function AppManager:handleStoryboardEvent(event, storyboardSceneView)
    
    assert(type(event)           == 'table',  'Expected a storyBoard event object but got '..tostring(event))
    assert(type(event.sceneName) == 'string', 'Expected a storyboard scene name but got '..tostring(event.sceneName))

    event.appManager    = self
    storyboardSceneView = self.uiManager:handleSceneEvent({name = event.sceneName, event=event.name})

    if (event.name == 'enterScene') then
        self.Runtime:addEventListener('playGameRequestListener', self)
    end

    if (event.name == 'exitScene') then
        self.Runtime:removeEventListener('playGameRequestListener', self)

    end

    return storyboardSceneView
    
end


return AppManager
