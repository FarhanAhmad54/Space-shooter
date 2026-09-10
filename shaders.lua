-- Shader system for visual effects

local Shaders = {}
Shaders.__index = Shaders

function Shaders.new()
    local self = setmetatable({}, Shaders)
    
    -- Canvases for multi-pass rendering
    self.canvas = nil
    self.bloomCanvas = nil
    self.finalCanvas = nil
    
    -- Shader code
    self.bloomShader = nil
    self.chromaticAberrationShader = nil
    self.vignetteShader = nil
    self.distortionShader = nil
    self.compositeShader = nil
    
    -- Effect parameters (Minimal to prevent gray screen)
    self.bloomIntensity = 0.2  -- Further reduced
    self.chromaticAmount = 0.0005  -- Nearly disabled
    self.vignetteStrength = 0.0  -- Completely disabled to prevent gray screen
    self.distortionAmount = 0
    self.distortionDecay = 5.0
    self.supported = true
    self.quality = "high"
    
    local ok = pcall(function() self:initShaders(); self:createCanvases() end)
    self.supported = ok
    if not ok then
        self.bloomShader, self.chromaticAberrationShader, self.vignetteShader, self.distortionShader, self.compositeShader = nil,nil,nil,nil,nil
        self.canvas, self.bloomCanvas, self.finalCanvas = nil,nil,nil
    end
    
    return self
end

function Shaders:setQuality(quality)
    if quality=="low" or quality=="medium" or quality=="high" then self.quality=quality end
end

function Shaders:isSupported() return self.supported end

function Shaders:initShaders()
    -- Bloom extraction shader (bright pass)
    self.bloomShader = love.graphics.newShader([[
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 texcolor = Texel(texture, texture_coords);
            float brightness = dot(texcolor.rgb, vec3(0.2126, 0.7152, 0.0722));
            
            // Extract bright areas
            if (brightness > 0.7) {
                return texcolor * color * 1.5;
            }
            return vec4(0.0, 0.0, 0.0, texcolor.a);
        }
    ]])
    
    -- Chromatic aberration shader
    self.chromaticAberrationShader = love.graphics.newShader([[
        extern number aberration;
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 direction = texture_coords - vec2(0.5);
            float dist = length(direction);
            
            vec2 offset = direction * aberration * dist;
            
            float r = Texel(texture, texture_coords - offset).r;
            float g = Texel(texture, texture_coords).g;
            float b = Texel(texture, texture_coords + offset).b;
            float a = Texel(texture, texture_coords).a;
            
            return vec4(r, g, b, a) * color;
        }
    ]])
    
    -- Vignette shader
    self.vignetteShader = love.graphics.newShader([[
        extern number strength;
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 texcolor = Texel(texture, texture_coords);
            
            vec2 position = texture_coords - vec2(0.5);
            float dist = length(position);
            float vignette = 1.0 - dist * strength;
            
            return texcolor * vec4(vignette, vignette, vignette, 1.0) * color;
        }
    ]])
    
    -- Screen distortion shader
    self.distortionShader = love.graphics.newShader([[
        extern number distortion;
        extern number time;
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 center = vec2(0.5);
            vec2 direction = texture_coords - center;
            float dist = length(direction);
            
            // Radial distortion
            vec2 offset = direction * sin(dist * 10.0 - time * 5.0) * distortion;
            vec2 distorted_coords = texture_coords + offset;
            
            // Clamp to valid texture coordinates
            distorted_coords = clamp(distorted_coords, vec2(0.0), vec2(1.0));
            
            return Texel(texture, distorted_coords) * color;
        }
    ]])
    
    -- Composite shader for final output
    self.compositeShader = love.graphics.newShader([[
        extern Image bloomTexture;
        extern number bloomIntensity;
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 base = Texel(texture, texture_coords);
            vec4 bloom = Texel(bloomTexture, texture_coords);
            
            // Additive blending for bloom
            return base + bloom * bloomIntensity * color;
        }
    ]])
end

function Shaders:createCanvases()
    local w, h = love.graphics.getDimensions()
    self.canvas = love.graphics.newCanvas(w, h)
    self.bloomCanvas = love.graphics.newCanvas(w, h)
    self.finalCanvas = love.graphics.newCanvas(w, h)
end

function Shaders:beginScene()
    if not self.supported or not self.canvas then return false end
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 0)  -- Clear to transparent, not opaque black!
end

function Shaders:endScene()
    if not self.supported then return end
    love.graphics.setCanvas()
end

function Shaders:applyEffects(dt)
    if not self.supported or not self.canvas or not self.finalCanvas then return false end
    -- Update distortion decay
    if self.distortionAmount > 0 then
        self.distortionAmount = math.max(0, self.distortionAmount - self.distortionDecay * dt)
    end
    
    local w, h = love.graphics.getDimensions()
    
    -- 1. Extract bloom (bright pass)
    love.graphics.setCanvas(self.bloomCanvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setShader(self.bloomShader)
    love.graphics.draw(self.canvas)
    love.graphics.setShader()
    
    -- Blur the bloom canvas (simple box blur)
    self:simpleBlur(self.bloomCanvas, 2)
    
    -- 2. Composite bloom with original
    love.graphics.setCanvas(self.finalCanvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setShader(self.compositeShader)
    self.compositeShader:send("bloomTexture", self.bloomCanvas)
    self.compositeShader:send("bloomIntensity", self.bloomIntensity)
    love.graphics.draw(self.canvas)
    love.graphics.setShader()
    
    -- 3. Apply chromatic aberration
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setShader(self.chromaticAberrationShader)
    self.chromaticAberrationShader:send("aberration", self.chromaticAmount)
    love.graphics.draw(self.finalCanvas)
    love.graphics.setShader()
    
    -- 4. Apply screen distortion if active
    if self.distortionAmount > 0 then
        love.graphics.setCanvas(self.finalCanvas)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setShader(self.distortionShader)
        self.distortionShader:send("distortion", self.distortionAmount)
        self.distortionShader:send("time", love.timer.getTime())
        love.graphics.draw(self.canvas)
        love.graphics.setShader()
        
        love.graphics.setCanvas(self.canvas)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.draw(self.finalCanvas)
    end
    
    -- 5. Apply vignette (final pass)
    love.graphics.setCanvas(self.finalCanvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setShader(self.vignetteShader)
    self.vignetteShader:send("strength", self.vignetteStrength)
    love.graphics.draw(self.canvas)
    love.graphics.setShader()
    
    love.graphics.setCanvas()
    return true
end

function Shaders:simpleBlur(canvas, passes)
    local temp = love.graphics.newCanvas(canvas:getDimensions())
    
    for i = 1, passes do
        -- Horizontal blur
        love.graphics.setCanvas(temp)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setBlendMode("alpha", "premultiplied")
        
        for offset = -2, 2 do
            love.graphics.draw(canvas, offset, 0, 0, 1, 1)
        end
        
        love.graphics.setBlendMode("alpha")
        
        -- Vertical blur
        love.graphics.setCanvas(canvas)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setBlendMode("alpha", "premultiplied")
        
        for offset = -2, 2 do
            love.graphics.draw(temp, 0, offset, 0, 1, 1)
        end
        
        love.graphics.setBlendMode("alpha")
    end
    
    love.graphics.setCanvas()
end

function Shaders:draw()
    if not self.supported or not self.finalCanvas then return false end
    -- Draw the final composited result to screen
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.finalCanvas)
end

function Shaders:addDistortion(amount)
    self.distortionAmount = math.min(0.05, self.distortionAmount + amount)
end

return Shaders
