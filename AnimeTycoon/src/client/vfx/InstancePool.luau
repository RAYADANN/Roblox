--!strict
-- Пул инстансов: берём/возвращаем вместо Instant.destroy thrash.

export type Factory = () -> Instance
export type Reset = (Instance) -> ()

export type InstancePool = {
    take: (self: InstancePool) -> Instance,
    give: (self: InstancePool, instance: Instance) -> (),
    prewarm: (self: InstancePool, count: number) -> (),
    destroy: (self: InstancePool) -> (),
    size: (self: InstancePool) -> number,
}

local InstancePool = {}
InstancePool.__index = InstancePool

export type Config = {
    name: string,
    factory: Factory,
    reset: Reset?,
    maxSize: number?,
    parent: Instance?,
}

function InstancePool.new(config: Config): InstancePool
    local self = setmetatable({
        _name = config.name,
        _factory = config.factory,
        _reset = config.reset,
        _maxSize = config.maxSize or 48,
        _parent = config.parent,
        _free = {} :: { Instance },
        _destroyed = false,
    }, InstancePool)
    return (self :: any) :: InstancePool
end

function InstancePool:take(): Instance
    assert(not self._destroyed, "InstancePool destroyed")
    local free = self._free
    local n = #free
    local inst: Instance
    if n > 0 then
        inst = free[n]
        free[n] = nil
    else
        inst = self._factory()
        inst.Name = self._name
    end
    if self._parent then
        inst.Parent = self._parent
    end
    return inst
end

function InstancePool:give(instance: Instance)
    if self._destroyed then
        instance:Destroy()
        return
    end
    if self._reset then
        self._reset(instance)
    end
    instance.Parent = nil
    local free = self._free
    if #free >= self._maxSize then
        instance:Destroy()
        return
    end
    table.insert(free, instance)
end

function InstancePool:prewarm(count: number)
    for _ = 1, count do
        local inst = self._factory()
        inst.Name = self._name
        inst.Parent = nil
        table.insert(self._free, inst)
    end
end

function InstancePool:size(): number
    return #self._free
end

function InstancePool:destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    for _, inst in self._free do
        inst:Destroy()
    end
    table.clear(self._free)
end

return InstancePool
