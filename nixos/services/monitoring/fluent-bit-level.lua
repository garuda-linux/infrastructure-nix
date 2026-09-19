local ANSI = "\27%[[%d;]*[%a]"

-- Explicit level tokens, mapped to Loki's normalised names
local TOKENS = {
  emerg = "fatal",
  alert = "fatal",
  crit = "fatal",
  critical = "fatal",
  fatal = "fatal",
  panic = "fatal",
  error = "error",
  err = "error",
  warn = "warn",
  warning = "warn",
  wrn = "warn",
  notice = "info",
  info = "info",
  debug = "debug",
  trace = "debug",
}

-- Journald syslog priority, used only when the line carries no level token
local PRIORITY = {
  ["0"] = "fatal",
  ["1"] = "fatal",
  ["2"] = "fatal",
  ["3"] = "error",
  ["4"] = "warn",
  ["5"] = "info",
  ["6"] = "info",
  ["7"] = "debug",
}

local function earliest_token(lower)
  local pos, level
  for tok, lvl in pairs(TOKENS) do
    local s = lower:find("%f[%w]" .. tok .. "%f[%W]")
    if s and (pos == nil or s < pos) then
      pos, level = s, lvl
    end
  end
  return level
end

function process(tag, timestamp, record)
  local msg = record["message"]
  local level

  if type(msg) == "string" then
    msg = msg:gsub(ANSI, "")
    record["message"] = msg
    level = earliest_token(msg:lower())
  end

  -- No explicit token: fall back to the journald priority
  if not level and record["container_id"] == nil then
    level = PRIORITY[tostring(record["priority"] or "")]
  end

  level = level or "unknown"

  -- Never ship anything below info to Loki
  if level == "debug" then
    return -1, timestamp, record
  end

  record["detected_level"] = level
  return 2, timestamp, record
end
