
--
--

---------------------------------------------------------------------------------------------

UnitTest = {}

-- Local functions ------------

---------------------------------------------------------------------------------------------

local _errorCurrentLevel = 2
local _errorPreTestLevel = 2

local function __setErrorLevel(levelNumber)
    
    if (levelNumber == nil or levelNumber <= 0) then
        
        _errorCurrentLevel = 2 -- Reset to Blame errors to the calling function
        
    end
    
    _errorPreTestLevel = _errorCurrentLevel
    _errorCurrentLevel = levelNumber  -- Blame errors to callers levelNumber's up
    
end


local function __setToPreviousErrorLevel()
    
    _errorCurrentLevel = _errorPreTestLevel
    
end

local function __normalizeEmptyOrNilMessage(message, separator)
    
    local messageAsString = tostring(message)
    
    if (messageAsString == 'nil') then
        messageAsString = ""
    elseif (separator ~= nil) then
        messageAsString = tostring(separator) .. messageAsString
    end
    
    return messageAsString
    
end


---------------------------------------------------------------------------------------------

--  Static methods

---------------------------------------------------------------------------------------------


function UnitTest.assertEquals(expected, actual, message)
    
    if not (actual == expected) then
        message = __normalizeEmptyOrNilMessage(message, ': ')
        error('\nExpected value <'..tostring(expected)..'> but got <'..tostring(actual)..'>'..message, _errorCurrentLevel)
    end
    
    return true
    
end


function UnitTest.assertNotEquals(expected, actual, message)
    
    if (actual == expected) then
        message = __normalizeEmptyOrNilMessage(message, ': ')
        error('\nExpected Not same values but got <'..tostring(expected)..'> and <'..tostring(actual)..'>'..message, _errorCurrentLevel)
    end
    
    return true
    
end


function UnitTest.assertEqualsIn(expected, actual, message)
    
    local isFound = false
    
    if (type(expected) == 'table' and #expected > 0) then
        
        for k, v in ipairs(expected) do
            
            if (v == actual) then
                isFound = true
            end
            
        end
        
    else
        
        error('The array provided is either empty or not a valid array', _errorCurrentLevel)
        
    end
    
    
    message = tostring(message) .. ' : Did not find value '.. tostring(actual) ..' in values of expected array.'
    
    assert(isFound, message)
    
    return isFound
    
end



function UnitTest.assertIsNumber(actual, message)
    
    return  UnitTest.assertType('number', actual, message)
    
end


function UnitTest.assertNumber(actual, expected, message)
    
    return __assertNumberEquals(actual, expected, message)
    
end

function UnitTest.assertNumberEquals(actual, expected, message)
    
    return __assertNumberEquals(actual, expected, message)
    
end


function __assertNumberEquals(actual, expected, message)
    
    __setErrorLevel(4)
    
    local isNumber = UnitTest.assertIsNumber(actual, message)
    local isEquals = UnitTest.assertEquals(actual, expected, message)
    
    __setToPreviousErrorLevel()
    
    return isNumber and isEquals
    
end

--[[
@param actual argument checked for equality to the table data type
@param message (optional) text message to display if the test fails
]]--
function UnitTest.assertIsTable(actual, message)
    
    __setErrorLevel(3)
    
    local aResult = UnitTest.assertType('table', actual, message)
    
    __setToPreviousErrorLevel()
    
    return aResult
    
end

-- UnitTest.assertIsNumber(1):greaterThan(9)


function UnitTest.assertType(expected, actual, message)
    
    local _typeA = type(actual)
    local _typeE = expected     -- table, number, string, boolean, etc
    
    message = __normalizeEmptyOrNilMessage(message, ': ')
    if not (_typeA == _typeE) then
        error('\nExpected value of type <'..tostring(_typeE)..'> but got <'..tostring(_typeA)..'>'..message, _errorCurrentLevel)
    end
    
    return true
    
end

--[[  ---------------------------------------------------------------------------------------

@param isErrorExpected boolean value indicating if the function to test is expected to throw an error.


@usage

-- The first parameter value, true, sets the expectation that when 'someFunction' is tested, it will throw an error.
t._assertFunctionErrorThrowing(true, someFunction, someErrorMsg, someParameter)

--]]
function UnitTest._assertFunctionErrorThrowing(isErrorExpected, functionName, errMsg, ...)
    
    local Args = {...}
    
    local errCode, pCallVal = pcall(functionName, unpack(Args))  -- pcall returns true if the function call returns without errors
    
    __setErrorLevel(4) -- A function 4 levels up in the stack is to really blame.
    
    local expectedErrorCode = not isErrorExpected
    
    --TODO - Shouldn't we try to catch the error and then throw it from this function?  Otherwise there is no point to
    -- having an isAsserted variable since it will only ever be set to true and never false.
    
    local isAsserted = UnitTest.assertEquals(expectedErrorCode, errCode, 'Function call test failed.  '..tostring(errMsg) .. ' >> '..tostring(pCallVal))
    
    __setToPreviousErrorLevel()
    
    local assertionResponse = errMsg
    
    if (type(pCallVal) ~= 'table') then -- pCallVal represents an error...
        
        assertionResponse = tostring(errMsg) .. ' ' .. __normalizeEmptyOrNilMessage(pCallVal)
        
    else --  ... pCallVal is the return value of the sucessfully called "pcall-ed" function
        
        assertionResponse = pCallVal -- Return the function call return value(s)
        
    end
    
    if (isErrorExpected) then
        
        assertionResponse = tostring(errMsg) .. ' >> '  ..tostring(errCode) .. ' : ' .. tostring(pCallVal)
        
    end
    
    
    return isAsserted, assertionResponse, errCode
    
end


function UnitTest.assertFunctionDoesNotThrowError(functionName, errMsg, ...)
    
    assert(type(functionName) == 'function', 'Expected first argument to be a function but got: '..type(functionName))
    assert(type(errMsg) == 'string', 'Expected the errMsg parameter to be a string but got: '..type(errMsg))
    
    local Args            = {...}
    local isErrorExpected = false
    
    local isAsserted, assertionResponse, errCode = 
    UnitTest._assertFunctionErrorThrowing(isErrorExpected, functionName, errMsg, unpack(Args))
    
    return isAsserted, assertionResponse, errCode
    
end


--[[  ---------------------------------------------------------------------------------------

@param functionToTest the function that will be tested
@param errMgs string value appended to the error message returned
@param ... If the function is an instance method, first include the instance Class object followed by any arguments to the instance method

--]]
function UnitTest.assertFunctionThrowsError(functionToTest, errMsg, ...)
    
    assert(type(functionToTest) == 'function', 'Expected first argument to be a function but got: '..type(functionToTest))
    assert(type(errMsg) == 'string', 'Expected the errMsg parameter to be a string but got: '..type(errMsg))
    
    local Args            = {...}
    local isErrorExpected = true
    
    -- Assign results to local variables and then return them to avoid Lua treating the return call
    -- as a tail call and therefore interfering with the debug results.  See lua docs for details.
    local isAsserted, assertionResponse, errCode = 
    UnitTest._assertFunctionErrorThrowing(isErrorExpected, functionToTest, errMsg, unpack(Args))
    
    return isAsserted, assertionResponse, errCode
    
end


return UnitTest

