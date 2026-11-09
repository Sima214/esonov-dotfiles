local api = {}

-- theme color(hex) to cairo rgb(a) tuple
function api.color2rgb(color)
  local r, g, b
  local rgb = tonumber(color:sub(2), 16)
  b = (rgb & 0xff) / 0xff
  rgb = rgb >> 8
  g = (rgb & 0xff) / 0xff
  rgb = rgb >> 8
  r = (rgb & 0xff) / 0xff
  return r, g, b
end

function api.color2rgba(color)
  local r, g, b, a
  local rgba = tonumber(color:sub(2), 16)
  a = (rgba & 0xff) / 0xff
  rgba = rgba >> 8
  b = (rgba & 0xff) / 0xff
  rgba = rgba >> 8
  g = (rgba & 0xff) / 0xff
  rgba = rgba >> 8
  r = (rgba & 0xff) / 0xff
  return r, g, b, a
end

-- Box-Muller transform for realistic human click hold duration (Gaussian / normal distribution)
function api.random_gaussian(mean, std_dev, min, max)
  local u1 = math.random()
  local u2 = math.random()
  while u1 <= 1e-7 do u1 = math.random() end
  local z0 = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)
  local val = mean + z0 * std_dev
  if min and val < min then return min end
  if max and val > max then return max end
  return val
end

-- Uniform interval: [min, max] seconds (default 1.8 to 2.3)
function api.random_interval(min, max)
  min = min or 1.8
  max = max or 2.3
  return min + math.random() * (max - min)
end

return api
