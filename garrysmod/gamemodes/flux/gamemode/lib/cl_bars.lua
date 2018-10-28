if !font then util.include 'cl_font.lua' end
if !fl.lang then util.include 'sh_lang.lua' end

library.new('bars', fl)

local stored = fl.bars.stored or {}
local sorted = fl.bars.sorted or {}
fl.bars.stored = stored
fl.bars.sorted = sorted

-- Some fail-safety variables.
fl.bars.defaultX = 8
fl.bars.defaultY = 8
fl.bars.defaultW = font.scale(312)
fl.bars.defaultH = 18
fl.bars.defaultSpacing = 6

function fl.bars:register(id, data, force)
  if !data then return end

  force = force or fl.development

  if stored[id] and !force then
    return stored[id]
  end

  stored[id] = {
    id = id,
    text = data.text or '',
    color = data.color or Color(200, 90, 90),
    max_value = data.max_value or 100,
    hinderColor = data.hinderColor or Color(255, 0, 0),
    hinderText = data.hinderText or '',
    display = data.display or 100,
    minDisplay = data.minDisplay or 0,
    hinderDisplay = data.hinderDisplay or false,
    value = data.value or 0,
    hinderValue = data.hinderValue or 0,
    x = data.x or self.defaultX,
    y = data.y or self.defaultY,
    width = data.width or self.defaultW,
    height = data.height or self.defaultH,
    cornerRadius = data.cornerRadius or 0,
    priority = data.priority or table.Count(stored),
    type = data.type or BAR_TOP,
    font = data.font or 'text_bar',
    spacing = data.spacing or self.defaultSpacing,
    text_offset = data.text_offset or 1,
    callback = data.callback
  }

  hook.run('OnBarRegistered', stored[id], id, force)

  return stored[id]
end

function fl.bars:Get(id)
  if stored[id] then
    return stored[id]
  end

  return false
end

function fl.bars:SetValue(id, newValue)
  local bar = self:Get(id)

  if bar then
    theme.call('PreBarValueSet', bar, bar.value, newValue)

    if bar.value != newValue then
      if bar.hinderDisplay and bar.hinderValue then
        bar.value = math.Clamp(newValue, 0, bar.max_value - bar.hinderValue + 2)
      end

      bar.interpolated = util.cubic_ease_in_out_t(150, bar.value, newValue)
      bar.value = math.Clamp(newValue, 0, bar.max_value)
    end
  end
end

function fl.bars:HinderValue(id, newValue)
  local bar = self:Get(id)

  if bar then
    theme.call('PreBarHinderValueSet', bar, bar.hinderValue, newValue)

    if bar.value != newValue then
      bar.hinderValue = math.Clamp(newValue, 0, bar.max_value)
    end
  end
end

function fl.bars:Prioritize()
  sorted = {}

  for k, v in pairs(stored) do
    if !hook.run('ShouldDrawBar', v) then
      continue
    end

    hook.run('PreBarPrioritized', v)

    sorted[v.priority] = sorted[v.priority] or {}

    if v.type == BAR_TOP then
      table.insert(sorted[v.priority], v.id)
    end
  end

  return sorted
end

function fl.bars:Position()
  self:Prioritize()

  local last_y = self.defaultY
  local lastX = self.defaultX

  for priority, ids in pairs(sorted) do
    for k, v in pairs(ids) do
      local bar = self:Get(v)

      if bar and bar.type == BAR_TOP then
        local offX, offY = hook.run('AdjustBarPos', bar)
        offX = offX or 0
        offY = offY or 0

        bar.y = last_y + offY
        bar.x = bar.x + offX
        last_y = last_y + bar.height + bar.spacing
      end
    end
  end

end

function fl.bars:Draw(id)
  local bar_info = self:Get(id)

  if bar_info then
    hook.run('PreDrawBar', bar_info)
    theme.call('PreDrawBar', bar_info)

    if !hook.run('ShouldDrawBar', bar_info) then
      return
    end

    theme.call('DrawBarBackground', bar_info)

    if hook.run('ShouldFillBar', bar_info) or bar_info.value != 0 then
      theme.call('DrawBarFill', bar_info)
    end

    if bar_info.hinderDisplay and bar_info.hinderDisplay <= bar_info.hinderValue then
      theme.call('DrawBarHindrance', bar_info)
    end

    theme.call('DrawBarTexts', bar_info)

    hook.run('PostDrawBar', bar_info)
    theme.call('PostDrawBar', bar_info)
  end
end

function fl.bars:DrawTopBars()
  for priority, ids in pairs(sorted) do
    for k, v in ipairs(ids) do
      self:Draw(v)
    end
  end
end

function fl.bars:Adjust(id, data)
  local bar = self:Get(id)

  if bar then
    table.merge(bar, data)
  end
end

do
  local Bars = {}

  function Bars:LazyTick()
    if IsValid(fl.client) then
      fl.bars:Position()

      for k, v in pairs(stored) do
        if v.callback then
          fl.bars:SetValue(v.id, v.callback(stored[k]))
        end

        hook.run('AdjustBarInfo', k, stored[k])
      end
    end
  end

  function Bars:PreDrawBar(bar)
    bar.curI = bar.curI or 1

    bar.real_fill_width = bar.width * (bar.value / bar.max_value)

    if bar.interpolated == nil then
      bar.fill_width = bar.real_fill_width
    else
      if bar.curI > 150 then
        bar.interpolated = nil
        bar.curI = 1
      else
        bar.fill_width = bar.width * (bar.interpolated[math.Round(bar.curI)] / bar.max_value)
        bar.curI = bar.curI + math.Clamp(math.Round(1 * (FrameTime() / 0.006)), 1, 10)
      end
    end

    bar.text = string.utf8upper(bar.text)
    bar.hinderText = string.utf8upper(bar.hinderText)
  end

  function Bars:ShouldDrawBar(bar)
    if bar.display < bar.value or bar.minDisplay >= bar.value then
      return false
    end

    return true
  end

  plugin.add_hooks('FLBarHooks', Bars)

  fl.bars:register('respawn', {
    text = t'bar_text.respawn',
    color = Color(50, 200, 50),
    max_value = 100,
    x = ScrW() * 0.5 - fl.bars.defaultW * 0.5,
    y = ScrH() * 0.5 - 8,
    text_offset = 1,
    height = 16,
    type = BAR_MANUAL
  })
end
