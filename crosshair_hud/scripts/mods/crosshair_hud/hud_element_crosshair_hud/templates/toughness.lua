local mod = get_mod("crosshair_hud")
local mod_utils = mod.utils
local _shadows_enabled = mod_utils.shadows_enabled

local UIWorkspaceSettings = mod:original_require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = mod:original_require("scripts/managers/ui/ui_widget")
local UIHudSettings = mod:original_require("scripts/settings/ui/ui_hud_settings")

local global_scale = mod:get("global_scale")
local toughness_scale = mod:get("toughness_scale") * global_scale

local global_offset = {
  mod:get("global_x_offset"),
  mod:get("global_y_offset")
}
local toughness_offset = {
  mod:get("toughness_x_offset"),
  mod:get("toughness_y_offset")
}

local template = {
  name = "toughness_indicator"
}

template.scenegraph_definition = {
  screen = UIWorkspaceSettings.screen,
  [template.name] = {
    parent = "screen",
    vertical_alignment = "center",
    horizontal_alignment = "center",
    size = { 48 * toughness_scale, 24 * toughness_scale },
    position = {
      global_offset[1] + toughness_offset[1],
      global_offset[2] + toughness_offset[2],
      55
    }
  }
}

function template.create_widget_definitions()
  return {
    [template.name] = UIWidget.create_definition({
      {
        pass_type = "text",
        style_id = "text_1",
        value_id = "text_1",
        value = "0",
        style = {
          font_size = 24 * toughness_scale,
          text_vertical_alignment = "top",
          text_horizontal_alignment = "center",

          font_type = "machine_medium",
          text_color = UIHudSettings.color_tint_main_2,
          offset = {
            -14 * toughness_scale,
            2 * toughness_scale,
            2
          }
        }
      },
      {
        pass_type = "text",
        style_id = "text_1_shadow",
        value_id = "text_1",
        value = "0",
        style = {
          font_size = 24 * toughness_scale,
          text_vertical_alignment = "top",
          text_horizontal_alignment = "center",
          font_type = "machine_medium",
          text_color = UIHudSettings.color_tint_0,
          offset = {
            -12 * toughness_scale,
            4 * toughness_scale,
            1
          }
        },
        visibility_function = function(content, style)
          return _shadows_enabled("toughness")
        end
      },
      {
        pass_type = "text",
        style_id = "text_2",
        value_id = "text_2",
        value = "0",
        style = {
          font_size = 24 * toughness_scale,
          text_vertical_alignment = "top",
          text_horizontal_alignment = "center",

          font_type = "machine_medium",
          text_color = UIHudSettings.color_tint_main_2,
          offset = {
            0,
            2 * toughness_scale,
            2
          }
        }
      },
      {
        pass_type = "text",
        style_id = "text_2_shadow",
        value_id = "text_2",
        value = "0",
        style = {
          font_size = 24 * toughness_scale,
          text_vertical_alignment = "top",
          text_horizontal_alignment = "center",

          font_type = "machine_medium",
          text_color = UIHudSettings.color_tint_0,
          offset = {
            2 * toughness_scale,
            4 * toughness_scale,
            1
          }
        },
        visibility_function = function(content, style)
          return _shadows_enabled("toughness")
        end
      },
      {
        pass_type = "text",
        style_id = "text_3",
        value_id = "text_3",
        value = "0",
        style = {
          font_size = 24 * toughness_scale,
          text_vertical_alignment = "top",
          text_horizontal_alignment = "center",

          font_type = "machine_medium",
          text_color = UIHudSettings.color_tint_main_2,
          offset = {
            14 * toughness_scale,
            2 * toughness_scale,
            2
          }
        }
      },
      {
        pass_type = "text",
        style_id = "text_3_shadow",
        value_id = "text_3",
        value = "0",
        style = {
          font_size = 24 * toughness_scale,
          text_vertical_alignment = "top",
          text_horizontal_alignment = "center",

          font_type = "machine_medium",
          text_color = UIHudSettings.color_tint_0,
          offset = {
            16 * toughness_scale,
            4 * toughness_scale,
            1
          }
        },
        visibility_function = function(content, style)
          return _shadows_enabled("toughness")
        end
      },
      {
        pass_type = "text",
        style_id = "text_symbol",
        value_id = "text_symbol",
        value = "%",
        style = {
          font_size = 16 * toughness_scale,
          text_vertical_alignment = "top",
          text_horizontal_alignment = "center",

          font_type = "machine_medium",
          text_color = UIHudSettings.color_tint_main_2,
          offset = { 30 * toughness_scale, 2 * toughness_scale, 2 }
        }
      },
      {
        pass_type = "text",
        style_id = "text_symbol_shadow",
        value_id = "text_symbol",
        value = "%",
        style = {
          text_style_id = "text_symbol",
          font_size = 16 * toughness_scale,
          text_vertical_alignment = "top",
          text_horizontal_alignment = "center",

          font_type = "machine_medium",
          text_color = UIHudSettings.color_tint_0,
          offset = { 32 * toughness_scale, 4 * toughness_scale, 1 }
        },
        visibility_function = function(content, style)
          return style.parent[style.text_style_id].visible and _shadows_enabled("toughness")
        end
      }
    }, template.name)
  }
end

function template.update(parent, dt, t)
  local player_extensions = parent._parent:player_extensions()
  local toughness_extension = player_extensions.toughness
  local toughness_percent = toughness_extension:current_toughness_percent()
  local current_toughness = toughness_extension:remaining_toughness()
  local toughness_widget = parent._widgets_by_name.toughness_indicator

  if toughness_percent == 1 and mod:get("toughness_hide_at_full") then
    toughness_widget.content.visible = false
    return
  end

  local toughness_always_show = mod:get("toughness_always_show")
  if toughness_always_show or current_toughness ~= parent.current_toughness then
    parent.current_toughness = current_toughness
    parent.toughness_visible_timer = mod:get("health_stay_time") or 1.5

    toughness_widget.content.visible = true

    local toughness_display_type = mod:get("toughness_display_type")
    local number_to_display = (toughness_display_type == mod.options_display_type.percent and (toughness_percent * 100)) or current_toughness
    local text_color = mod_utils.get_text_color_for_percent_threshold(toughness_percent, "toughness") or UIHudSettings.color_tint_6

    local amount = math.ceil(number_to_display)
    local texts = mod_utils.convert_number_to_display_texts(amount, 3, nil, false, true)
    for i = 1, 3 do
      local key = string.format("text_%s", i)
      toughness_widget.content[key] = texts[i] or ""
      toughness_widget.style[key].text_color = text_color
    end
    toughness_widget.style.text_symbol.visible = toughness_display_type == mod.options_display_type.percent
    toughness_widget.style.text_symbol.text_color = text_color
    toughness_widget.dirty = true
  end

  if not toughness_always_show and parent.toughness_visible_timer then
    parent.toughness_visible_timer = parent.toughness_visible_timer - dt
    if parent.toughness_visible_timer <= 0 then
      parent.toughness_visible_timer = nil
      toughness_widget.content.visible = false
    end
  end
end

return template
