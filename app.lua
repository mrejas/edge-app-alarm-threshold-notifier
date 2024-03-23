local function matchCriteria(fn, criteria)
    local isArray = false
    local arrayMatch = false
    for k, v in pairs(criteria) do
        if math.type(k) ~= nil then
            isArray = true
            if fn.id == v then
                arrayMatch = true
                break
            end
        else
            if k == 'id' then
                if fn.id ~= v then return false end
            end
            if k == 'type' then
                if fn.type:match('^' .. v .. '$') == nil then return false end
            end
            if fn.meta[k] == nil then return false end
            if fn.meta[k]:match('^' .. v .. '$') == nil and v ~= '*' then return false end
        end
    end
    if isArray then return arrayMatch end
    return true
end

function findDevice(criteria)
    devices = lynx.getDevices()
    if math.type(criteria) ~= nil then
        for _, dev in ipairs(devices) do
            if dev.id == criteria then return dev end
        end
    elseif type(criteria) == 'table' then
        for _, dev in ipairs(devices) do
            if matchCriteria(dev, criteria) then return dev end
        end
    end
    return nil
end


function findFunction(criteria)
    if math.type(criteria) ~= nil then
        for _, fn in ipairs(functions) do
            if fn.id == criteria then return fn end
        end
    elseif type(criteria) == 'table' then
        for _, fn in ipairs(functions) do
            if matchCriteria(fn, criteria) then return fn end
        end
    end
    return nil
end


function findFunctions(criteria)
    local res = {}
    if type(criteria) == 'table' then
        for _, fn in ipairs(functions) do
            if matchCriteria(fn, criteria) then table.insert(res, fn) end
        end
    end
    return res
end

local topicArmed = {}
local topicFunction = {}
local topicMin = {}
local topicMax = {}
local edgeTrigger = {}

function handleTrigger(topic, payload, retained)

	if topicFunction[topic] == nil then return end


	local data = json:decode(payload)
	local triggerRule = 'none'
	
	local isAlarm = false -- Assume ok. 

	-- If the value passes from over max to under min withou passing ok, 
	-- no new alert will be sent since there is only one Armedlist. I think that is ok.
	if topicBetween[topic] ~= nil then
		under = topicBetween[topic].under
		over =  topicBetween[topic].over

		if under < over then -- e.g. 10 - 20 
			if data.value < under or data.value > over then
				isAlarm = true
				triggerRule = 'not between'
			end
		elseif under > over then -- e.d 20 - 10
			if data.value < under and data.value > over then	
				isAlarm = true
				triggerRule = 'between'
			end
		end
	end

	if topicUnder[topic] ~= nil then
		if data.value < topicUnder[topic] then
			isAlarm = true
			triggerRule = 'under'
		end
	end

	if topicOver[topic] ~= nil then
		if data.value > topicOver[topic] then
			isAlarm = true
			triggerRule = 'over'
		end
	end

	if topicOn[topic] ~= nil then
		if data.value == topicOn[topic] then
			isAlarm = true
			triggerRule = 'on'
		end
	end

	if topicNot[topic] ~= nil then
		if data.value ~= topicNot[topic] then
			isAlarm = true
			triggerRule = 'not'
		end
	end

	topicArmed[topic] = isAlarm

	sendNotificationIfArmed(topic, data.value, triggerRule)
end

function findFunctionsToMonitor ()
	for _, fn in ipairs(functions) do
		local isMonitored = false
		if fn.meta['alarm_over'] ~= nil and fn.meta['alarm_under'] ~= nil and fn.meta['topic_read'] ~= nil then
			-- If we have booth let's check between or not between
				topicBetween[fn.meta.topic_read] = { over=tonumber(fn.meta['alarm_over']), under=tonumber(fn.meta['alarm_under']) }
				isMonitored=true		
		else
			if fn.meta['alarm_over'] ~= nil and fn.meta['topic_read'] ~= nil then
				topicOver[fn.meta.topic_read] = tonumber(fn.meta['alarm_over'])
				isMonitored=true
			end
			if fn.meta['alarm_under'] ~= nil and fn.meta['topic_read'] ~= nil then
				topicUnder[fn.meta.topic_read] = tonumber(fn.meta['alarm_under'])
				isMonitored=true
			end
		end
		if fn.meta['alarm_on'] ~= nil and fn.meta['topic_read'] ~= nil then
			topicOn[fn.meta.topic_read] = tonumber(fn.meta['alarm_on'])
			isMonitored=true
		end
		if fn.meta['alarm_not'] ~= nil and fn.meta['topic_read'] ~= nil then
			topicNot[fn.meta.topic_read] = tonumber(fn.meta['alarm_not'])
			isMonitored=true
		end
		if isMonitored then
			topicFunction[fn.meta.topic_read] = fn
		end
	end
end

function setUpFunctions()
	topicArmed = {}
	topicFunction = {}
	topicOver = {}
	topicBetween = {}
	topicUnder = {}
	topicOn = {}
	topicNot = {}
	
	findFunctionsToMonitor()
end

function onFunctionsUpdated()
	setUpFunctions()
end
function onStart()
	setUpFunctions()

	-- Since there might be thousands of functions a wide subsriptions is best.
	mq:sub('obj/#', 0)
	mq:bind('obj/#', handleTrigger)
end

function sendNotificationIfArmed(topic, value, rule)
    if cfg.notification_outputs == nil then return end

    local func = topicFunction[topic]
    local dev = findDevice(tonumber(func.meta.device_id))
    local armed = topicArmed[topic]
    local sent = edgeTrigger[topic]
    local threshold = nil

    if rule == 'over' then threshold = topicOver[topic] end
    if rule == 'under' then threshold = topicUnder[topic] end
    if rule == 'on' then threshold = topicOn[topic] end
    if rule == 'not' then threshold = topicNot[topic] end
    
    if rule == 'not between' then threshold = topicBetween[topic].under .. '-' .. topicBetween[topic].over  end
    if rule == 'between' then threshold = topicBetween[topic].over .. '-' .. topicBetween[topic].under  end

    if armed then
        if sent then return end
	local payloadData = {
	    value = value,
	    trigger = rule,
	    firing = func.meta.name,
	    unit = func.meta.unit,
	    note = func.meta.note,
	    func = func,
	    device = dev,
	    threshold = threshold
	} 

	for i, no in ipairs(cfg.notification_outputs) do
                lynx.notify(no, payloadData)
        end

	edgeTrigger[topic] = true
    else
        edgeTrigger[topic] = false
    end
end
