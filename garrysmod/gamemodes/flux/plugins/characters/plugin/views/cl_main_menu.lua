local PANEL = {}
PANEL.prev_button = nil
PANEL.schema_logo_offset = 450

function PANEL:Init()
  self:SetPos(0, 0)
  self:SetSize(ScrW(), ScrH())

  self:RecreateSidebar(true)

  self:MakePopup()

  local menu_music = theme.get_sound('menu_music')

  if !fl.menu_music and menu_music and menu_music != '' then
    sound.PlayFile(menu_music, '', function(station)
      if IsValid(station) then
        station:Play()

        fl.menu_music = station
      end
    end)
  end

  theme.hook('CreateMainMenu', self)
end

function PANEL:Paint(w, h)
  if self:IsVisible() then
    theme.hook('PaintMainMenu', self, w, h)
  end
end

function PANEL:Think()
  local menu_valid = IsValid(self.menu)

  if self.schema_logo_offset > 0 and menu_valid then
    self.schema_logo_offset = Lerp(FrameTime() * 8, self.schema_logo_offset, 0)
  elseif self.schema_logo_offset < 450 and !menu_valid then
    self.schema_logo_offset = Lerp(FrameTime() * 8, self.schema_logo_offset, 450)
  end
end

function PANEL:RecreateSidebar(create_buttons)
  if IsValid(self.sidebar) then
    self.sidebar:safe_remove()
  end

  self.sidebar = vgui.Create('fl_sidebar', self)
  self.sidebar:SetPos(theme.get_option('menu_sidebar_x'), theme.get_option('menu_sidebar_y'))
  self.sidebar:SetSize(theme.get_option('menu_sidebar_width'), theme.get_option('menu_sidebar_height'))
  self.sidebar:set_margin(theme.get_option('menu_sidebar_margin'))
  self.sidebar:add_space(16)

  self.sidebar.Paint = function() end

  self.sidebar:add_space(theme.get_option('menu_sidebar_logo_space'))

  if create_buttons then
    hook.run('AddMainMenuItems', self, self.sidebar)
  end
end

function PANEL:OpenMenu(panel, data)
  if !IsValid(self.menu) then
    self.menu = theme.create_panel(panel, self)

    if self.menu.set_data then
      self.menu:set_data(data)
    end
  else
    if self.menu.Close then
      self.menu:Close(function()
        self:OpenMenu(panel, data)
      end)
    else
      self.menu:safe_remove()
      self:OpenMenu(panel, data)
    end
  end
end

function PANEL:to_main_menu(from_right)
  local scrw = ScrW()

  self:RecreateSidebar(true)

  self.sidebar:SetPos(from_right and scrw or -self.sidebar:GetWide(), theme.get_option('menu_sidebar_y'))
  self.sidebar:SetDisabled(true)
  self.sidebar:MoveTo(theme.get_option('menu_sidebar_x'), theme.get_option('menu_sidebar_y'), theme.get_option('menu_anim_duration'), 0, 0.5, function()
    self.sidebar:SetDisabled(false)
  end)

  self.menu:MoveTo(from_right and -self.menu:GetWide() or scrw, 0, theme.get_option('menu_anim_duration'), 0, 0.5, function()
    if self.menu.Close then
      self.menu:Close()
    else
      self.menu:safe_remove()
    end
  end)
end

function PANEL:notify(text)
  local panel = vgui.Create('fl_notification', self)
  panel:set_text(text)
  panel:set_lifetime(6)
  panel:set_text_color(Color('pink'))
  panel:set_background_color(Color(50, 50, 50, 220))

  local w, h = panel:GetSize()
  panel:SetPos(ScrW() * 0.5 - w * 0.5, ScrH() - 128)

  function panel:PostThink() self:MoveToFront() end
end

function PANEL:add_button(text, callback)
  local button = vgui.Create('fl_button', self)
  button:SetSize(theme.get_option('menu_sidebar_width'), theme.get_option('menu_sidebar_button_height'))
  button:set_text(string.utf8upper(text))
  button:SetDrawBackground(false)
  button:SetFont(theme.get_font('main_menu_large'))
  button:SetPos(theme.get_option('menu_sidebar_button_offset_x'), 0)
  button:set_text_autoposition(false)
  button:set_centered(theme.get_option('menu_sidebar_button_centered'))
  button:set_text_offset(8)

  button.DoClick = function(btn)
    surface.PlaySound(theme.get_sound('button_click_success_sound'))

    btn:set_active(true)

    if IsValid(self.prev_button) and self.prev_button != btn then
      self.prev_button:set_active(false)
    end

    self.prev_button = btn

    if isfunction(callback) then
      callback(btn)
    elseif isstring(callback) then
      self:OpenMenu(callback)
    end
  end

  self.sidebar:add_panel(button)
  self.sidebar:add_space(6)

  return button
end

vgui.Register('fl_main_menu', PANEL, 'EditablePanel')
