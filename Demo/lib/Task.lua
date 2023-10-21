local task = {
    stack = {}
}

function task.new(self, name, fn)
    if not self.stack[name] then self.stack[name] = {} end
    self.stack[name][#self.stack[name]+1] = fn
end

function task:call(name)
    if not self.stack[name] then return end

    for _,v in ipairs(self.stack[name]) do
        v()
    end

    self.stack[name] = nil
end

local mt = {
    __index = task,
    __call = task.new
}
return setmetatable(task, mt)