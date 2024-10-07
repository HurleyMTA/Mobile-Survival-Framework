local objects = {}

local function createWindow(x, y, width, height, title, center)
    -- parent window
    local group = display.newGroup()
    group.x = x
    group.y = y
    group.type = "window"

    -- background
    local background = display.newRoundedRect(group, 0, 0, width, height, 0)
    background.anchorX = 0
    background.anchorY = 0
    background:setFillColor(0, 0, 0, 0.6)

    -- titlebar
    local titlebar = display.newRoundedRect(group, 0, 0, width, 16, 0)
    titlebar.anchorX = 0
    titlebar.anchorY = 0
    titlebar:setFillColor(1, 0, 0, 0.6)

    -- title
    local title = display.newText({ parent = group, text = title, y = 2, width = width, height = 15, align = "center", fontSize = 10 })
    title.anchorX = 0
    title.anchorY = 0

    -- center window
    if center then
        group.x = display.safeScreenOriginX + (display.safeActualContentWidth / 2) - (width / 2)
        group.y = display.safeScreenOriginY + (display.safeActualContentHeight / 2) - (height / 2)
    end

    return group
end

local function createButton(x, y, width, height, title, parent)
    -- parent button
    local group = display.newGroup()
    group.x = x
    group.y = y
    group.type = "button"

    -- assign to parent if there is one
    if parent then
        parent:insert(group)
    end

    -- background
    local background = display.newRoundedRect(group, 0, 0, width, height, 0)
    background.anchorX = 0
    background.anchorY = 0
    background:setFillColor(1, 0, 0, 0.6)

    -- title
    local title = display.newText({ parent = group, text = title, y = 5.5, width = width, height = height, align = "center", fontSize = 10 })
    title.anchorX = 0
    title.anchorY = 0

    return group
end

local function createLabel(x, y, width, height, title, align, parent)
    -- parent label
    local group = display.newGroup()
    group.x = x
    group.y = y
    group.type = "label"
 
    -- assign to parent if there is one
    if parent then
        parent:insert(group)
    end

    -- text
    group.text = display.newText({ parent = group, text = title, width = width, height = height, align = align, fontSize = 10 })
    group.text.anchorX = 0
    group.text.anchorY = 0

    return group
end

local function createImage(x, y, width, height, path, caption, parent)
    -- parent label
    local group = display.newGroup()
    group.x = x
    group.y = y
    group.type = "image"
  
    -- assign to parent if there is one
    if parent then
        parent:insert(group)
    end

    -- image
    local image = display.newImageRect(group, path, width, height)
    image.anchorX = 0
    image.anchorY = 0

    -- caption
    if caption then
        local title = display.newText({ parent = group, text = caption, y = height, width = width, height = 11, align = "center", fontSize = 9 })
        title.anchorX = 0
        title.anchorY = 0
    end

    return group
end

local function createRectangle(x, y, width, height, parent)
    -- parent label
    local group = display.newGroup()
    group.x = x
    group.y = y
    group.type = "rectangle"
   
    -- assign to parent if there is one
    if parent then
        parent:insert(group)
    end

    -- shape
    local shape = display.newRoundedRect(group, 0, 0, width, height, 0)
    shape.anchorX = 0
    shape.anchorY = 0
    shape:setFillColor(1, 1, 1, 0.2)

    return group
end

return {
    window = createWindow,
    button = createButton,
    label = createLabel,
    image = createImage,
    rect = createRectangle,
}