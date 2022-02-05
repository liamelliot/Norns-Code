--norns grid trig seq w/ crow
--code heavily borrowed from @tehn's awake

options = {}
options.OUT = {"crow", "midi", "crow ii JF"}

g = grid.connect()

running = true

step_brightness = 10

seq = {
  pos = 0,
  length = 16,
  one = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  two = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  thr = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  fou = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
}

function clear_all()
--clear all if both keys held
  for i=1, 16 do
  seq.one[i] = 0
  seq.two[i] = 0
  seq.thr[i] = 0
  seq.fou[i] = 0
  end
end

function step()
  while true do
    clock.sync(1) --add divide by step div here
    if running then
      seq.pos = seq.pos + 1
      if seq.pos > seq.length then seq.pos = 1
      end
      if seq.one[seq.pos] > 0 then
        --do I need to add probability to params somewhere?
        if math.random(100) <= params:get("probability") then
          if params:get("out") == 1 then
            crow.output[1].execute()
          end
        end
      end
        --crow output
        --add jf and midi out
        --add 2 3 4
    gridredraw()
    redraw()
    else
    end
  end
end


function stop()
  running = false
end

function start()
  running = true
end

function reset()
  seq.pos = 1
end

function clock.transport.start()
  start()
  --running = true
end

function clock.transport.stop()
  stop()
  --running = false
end

function clock.transport.reset()
  reset()
end


function init()

    params:add_separator("GridTrigSeqCrow")
    params:add_group("outs",3)
    params:add{type = "option", id = "out", name = "out",
      options = options.OUT,
      action = function(value)
        --add functions for other outputs
        if value == 3 then
          crow.ii.pullup(true)
          crow.ii.jf.mode(1) --might not be the right mode
        end
      end}

      for i=1, 4 do
      crow.output[i].action = "{to(5,0),to(0,0.25)}"
      end

      --add any other parameter stuff here
      params:add{type = "number", id = "probability", name = "probability",
      min = 0, max = 100, default = 100}
      params:add{type = "trigger", id = "stop", name = "stop",
      action = function() stop() reset() end}
      params:add{type = "trigger", id = "start", name = "start",
      action = function() start() end}
      params:add{type = "trigger", id = "reset", name = "reset",
      action = function() reset() end}

      add_pattern_params()
      params:default()

      --starts the clock. do I need to set/declare it anywhere?
      params:set("clock_tempo",101)

      clock.run(step)
      norns.enc.sens(1,8)
end


function g.key(x,y,z)
  local grid_h = g.rows
  --see from awake 338 and docs/norns/reference/grid
  if z == 1 then
    if y == 1 then
      seq.one[x] = seq.one[x] == 0 and 1 or 0 --should flip state
    end
    --duplicate for 2 3 4
  end

end


function gridredraw()
  local grid_h = g.rows
  g:all(0)
  for i=1, 16 do
      g:led(i, 1, (seq.one[i] * step_brightness))
      g:led(i, 2, (seq.two[i] * step_brightness))
      g:led(i, 3, (seq.thr[i] * step_brightness))
      g:led(i, 4, (seq.fou[i] * step_brightness))
  end
    g.led(seq.pos, 1, (seq.one[seq.pos] + 2) * 5)
    --duplicate for 2 3 4
    g:refresh()
end


function enc(n, delta)
  --define encoder bahavior
  if n==1 then

  elseif n==2 then
    params:delta("clock_tempo", delta)
  elseif n==3 then
    --params:delta("step_div",delta)
  end

  redraw()
end

function key(n,z)
  --define button bahavior
  if z==1 then
    if n==1 then

    elseif n==2 and n==3 then
      clear_all()
    elseif n==2 then
      if running == true then
        clock.transport.stop()
      elseif running == false then
        clock.transport.reset()
        clock.transport.start()
      end
    elseif n==3 then
      reset()
    end
  end

  redraw()
end


function redraw()
  screen.clear()
  screen.line_width(1)
  screen.aa(0)
  --put screen stuff here - most of it is in the studies
  screen.text(params:get("clock_tempo"))
  --screen.move(0,50)
  screen.update()
end

function cleanup()
end
