--!strict
-- Единый формат ответов сервера / RPC.

export type Ok<T> = { success: true, value: T }
export type Err<E> = { success: false, error: E }
export type Result<T, E> = Ok<T> | Err<E>

local Result = {}

function Result.ok<T>(value: T): Ok<T>
    return { success = true, value = value }
end

function Result.err<E>(error: E): Err<E>
    return { success = false, error = error }
end

return Result
