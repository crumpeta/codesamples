local t = require "UnitTest"
local test = {}

local DisplayObjectManager = require "DisplayObjectManager"
local MockObjectMaker = require "MockObjectMaker"

local mMaker
local mockDoDS

--[[  ---------------------------------------------------------------------------------------

Setup and Teardown

--]]


local function setup()
    
    mMaker = MockObjectMaker:new()
    
    mockDoDS = {}
    
end


local function tearDown()
    
    mMaker:runAsserts()
    
    mMaker   = nil
    mockDoDS = nil
    
end


--[[  ---------------------------------------------------------------------------------------

Tests

--]]



local function testConstructor()
    
    local mockDODataSource = {}
    local doManager        = DisplayObjectManager:new(mockDODataSource)
    
    assert(type(doManager) == 'table')
    
end




local function testConstructorFails()
    
    t.assertFunctionThrowsError(DisplayObjectManager.new, 'Expected a thrown error.', DisplayObjectManager, nil)
    
end


local function testGetDisplayGroup()
    
    local mockDisplayObjectDataSource = {}
    mockDisplayObjectDataSource.getDisplayGroup =
    mMaker:newMockMethod({expectedCallCount=1, returnValue={}, name='getDispayGroup'})
    
    local doManager = DisplayObjectManager:new(mockDisplayObjectDataSource)
    
    local aDispGroup = doManager:getDisplayGroup('bananaGroup')
    
    assert(type(aDispGroup) == 'table', 'Expected a displayGroup object.')
    
end


local function testGetDisplayGroupAndMakeDefaultGroup()
    
    mockDoDS.getDisplayGroup = mMaker:newMockMethod( {expectedCallCount = 1, returnValue = {}, name = 'getDisplayGroup'})
    
    local displayObjMgr      = DisplayObjectManager:new( mockDoDS )
    
    local topBananaDG = displayObjMgr:getDisplayGroup('topBananaDG', true)
    
    t.assertIsTable(topBananaDG, 'Expected a DisplayGroup but got '.. type(topBananaDG))
    
end


local function testGetDisplayGroupFailsWithNonExistingDisplayGroup()
    
    mockDoDS.getDisplayGroup = mMaker:newMockMethod( {expectedCallCount = 1, returnValue = nil, name = 'getDisplayGroup'})
    
    local displayObjMgr = DisplayObjectManager:new( mockDoDS )
    
    expectedErrorMsg = 'Expected a thrown error when the Display Group does not exist.'
    
    t.assertFunctionThrowsError(displayObjMgr.getDisplayGroup, expectedErrorMsg, displayObjMgr, 'ThisGroupDoesNotExist')
    
end


local function testGetDisplayGroupFailsWithInvalidParameters()
    
    -- Fail if DisplayGroup parameter value is missing
    local displayObjMgr    = DisplayObjectManager:new({})
    local expectedErrorMsg = 'Expected a thrown error for method call without Display Group parameter value.'
    
    t.assertFunctionThrowsError(displayObjMgr.getDisplayGroup, expectedErrorMsg, displayObjMgr, 'BananaDisplayGroup')
    
    -- Fail if DisplayGroup parameter value is not of type string.
    local displayObjMgr2    = DisplayObjectManager:new({})
    local expectedErrorMsg2 = 'Expected a thrown error for method call and non-boolean second parameter.'
    
    t.assertFunctionThrowsError(displayObjMgr2.getDisplayGroup, expectedErrorMsg2, displayObjMgr2, 
    'BananaDisplayGroup', {'This table should be a boolean param.'})
    
end


local function testGetDisplayObject()
    
    mockDoDS.getDisplayObject = mMaker:newMockMethod( 
    {expectedCallCount = 1,
        returnValue        = {},
        name               = 'getDisplayObject',
    expectedArgument   = 'bananaDO'})
    mockDoDS.getDisplayGroup = mMaker
    
    local displayObjMgr = DisplayObjectManager:new( mockDoDS )
    
    local displayObj = displayObjMgr:getDisplayObject('bananaDO', 'bananaDG')
    
    t.assertIsTable(displayObj)
    
end


local function testGetDisplayObjectAfterDefaultGroupIsSet()
    
    mockDoDS.getDisplayGroup  = mMaker:newMockMethod({expectedCallCount=1, returnValue = {}, name='getDisplayGroup'})
    mockDoDS.getDisplayObject = mMaker:newMockMethod({expectedCallCount=1, returnValue = {}, name='getDisplayObject'})
    
    local displayObjMgr = DisplayObjectManager:new( mockDoDS )
    local bananaDG      = displayObjMgr:getDisplayGroup('BananaDisplayGroup', true) -- Set the banana DG as the default DG
    local bananaDO      = displayObjMgr:getDisplayObject('BananaDO')   -- ... and no DG parameter is needed.
    
    t.assertIsTable(bananaDO)
    
end


local function testGetDisplayObjectFailsWhenDGParamOmmittedAndDefaultDGIsNotSet()
    
    mockDoDS.getDisplayObject = mMaker:newMockMethod({  expectedCallCount = 1,
        returnValue       = nil,
        name              = 'getDisplayObject'
    })
    
    local displayObjMgr    = DisplayObjectManager:new( mockDoDS )
    
    local expectedErrorMsg = 'Expected a thrown error when the DisplayGroupName parameter is '..
    'missing and a default DisplayGroup has not been set.'
    
    t.assertFunctionThrowsError(displayObjMgr.getDisplayObject, expectedErrorMsg, displayObjMgr, 
    'bananaDO', nil) -- nil stands for the missing DG param
    
end


local function testGetDisplayObjectFailsWithNonExistentDOArgument()
    
    mockDoDS.getDisplayObject = mMaker:newMockMethod({  expectedCallCount = 1,
        returnValue       = nil,
        name              = 'getDisplayObject'
    })
    
    local displayObjMgr = DisplayObjectManager:new( mockDoDS )
    
    local expectedErrorMsg = 'Expected an error when the DisplayObject does not exist.'
    
    t.assertFunctionThrowsError(    displayObjMgr.getDisplayObject, 
    expectedErrorMsg,
    displayObjMgr,
    'chimpDisplayObject'
    )
    
end


----------------------------------------------------------------------------------------------------


function test.runTests()
    
    setup()
    testConstructor()
    tearDown()
    
    setup()
    testConstructorFails()
    tearDown()
    
    setup()
    testGetDisplayGroup()
    tearDown()
    
    setup()
    testGetDisplayGroupFailsWithInvalidParameters()
    tearDown()
    
    setup()
    testGetDisplayGroupAndMakeDefaultGroup()
    tearDown()
    
    setup()
    testGetDisplayGroupFailsWithNonExistingDisplayGroup()
    tearDown()
    
    setup()
    testGetDisplayObject()
    tearDown()
    
    setup()
    testGetDisplayObjectAfterDefaultGroupIsSet()
    tearDown()
    
    setup()
    testGetDisplayObjectFailsWhenDGParamOmmittedAndDefaultDGIsNotSet()
    tearDown()
    
    setup()
    testGetDisplayObjectFailsWithNonExistentDOArgument()
    tearDown()
    
end

return test
