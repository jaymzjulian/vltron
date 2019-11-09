
' Allow for up to 1024 co-ords for each of the 4 players
dim player_x[4,1024]
dim player_y[4,1024]
dim player_direction[4]
dim x_move[4]
dim y_move[4]
lc_object = lightcycle()

' we're going to use a bitmap for the arena as well, to simplify collisions
' if you update one of these, you need to update all of them!
arena_size_x = 128
arena_size_y = 128
map_scale = 1
dim arena[arena_size_y,arena_size_y]
x_move = { 0, 1, 0, -1 }
y_move = { 1, 0, -1, 0 }
while true
player_direction = { 0, 2, 1, 3 }

' This is where in the static array the players are
dim player_trail[4]
dim player_trail3d[4]
dim player_pos[4]

dim sprrot[4]

sprrot = {0, 90, 180, 270}
camera_position = { 0.5, 3.5, -80.5 }
camera_rotation = { 0, 0, 0 }
camera_length = 20
camera_angle = -100
clippingRect = {{-255,-255},{255,255}}

move_speed = 1
camera_step = 2


for y = 1 to arena_size_y
  for x = 1 to arena_size_x
    arena[y,x] = 0
  next
next


start_distance = 16
player_count = 2
map_x = 64
map_y = 64
gridlines_x = 8
gridlines_y = 8

computer_only = { true, true, true, true }

' draw the floor here, so that it's globla
' use zig-zag to avoid large pen movements
  dim floor_b[gridlines_y*2+2, 4]
  gridline_scale = arena_size_y / gridlines_y
  for gy = 0 to gridlines_y 
    if gy mod 1 = 0
      floor_b[gy*2+1,1] = MoveTo
      floor_b[gy*2+1,2] = (gy*gridline_scale)-arena_size_x/2 
      floor_b[gy*2+1,3] = 0
      floor_b[gy*2+1,4] = 0-arena_size_y/2
      floor_b[gy*2+2,1] = DrawTo
      floor_b[gy*2+2,2] = (gy*gridline_scale)-arena_size_x/2
      floor_b[gy*2+2,3] = 0
      floor_b[gy*2+2,4] = arena_size_y/2
    else
      floor_b[gy*2+1,1] = MoveTo
      floor_b[gy*2+1,2] = (gy*gridline_scale)-arena_size_x/2
      floor_b[gy*2+1,3] = 0
      floor_b[gy*2+1,4] = arena_size_y/2
      floor_b[gy*2+2,1] = DrawTo
      floor_b[gy*2+2,2] = (gy*gridline_scale)-arena_size_x/2
      floor_b[gy*2+2,3] = 0
      floor_b[gy*2+2,4] = 0-arena_size_y/2
    endif
  next
  
  ' draw vertical gridlines
  ' do these in a zig-zag too so that we don't 
  ' waste pen moves
  dim floor_c[gridlines_y*2+2, 4]
  gridline_scale = arena_size_y / gridlines_y
  for gy = 0 to gridlines_y 
    if gy mod 1 = 0
      floor_c[gy*2+1,1] = MoveTo
      floor_c[gy*2+1,4] = (gy*gridline_scale)-arena_size_x/2
      floor_c[gy*2+1,3] = 0
      floor_c[gy*2+1,2] = arena_size_y/2
      floor_c[gy*2+2,1] = DrawTo
      floor_c[gy*2+2,4] = (gy*gridline_scale)-arena_size_x/2
      floor_c[gy*2+2,3] = 0
      floor_c[gy*2+2,2] = 0-arena_size_y/2
    else
      floor_c[gy*2+1,1] = MoveTo
      floor_c[gy*2+1,4] = (gy*gridline_scale)-arena_size_x/2
      floor_c[gy*2+1,3] = 0
      floor_c[gy*2+1,2] = 0-arena_size_y/2
      floor_c[gy*2+2,1] = DrawTo
      floor_c[gy*2+2,4] = (gy*gridline_scale)-arena_size_x/2
      floor_c[gy*2+2,3] = 0
      floor_c[gy*2+2,2] = arena_size_y/2
    endif
  next

player_pos = {1,1,1,1}
for p = 1 to player_count
  player_x[p, player_pos[p]] = (arena_size_x / 2) - start_distance * x_move[player_direction[p]+1]
  player_y[p, player_pos[p]] = (arena_size_y / 2) - start_distance * y_move[player_direction[p]+1]
  player_x[p, player_pos[p]+1] = (arena_size_x / 2) - start_distance * x_move[player_direction[p]+1]
  player_y[p, player_pos[p]+1] = (arena_size_y / 2) - start_distance * y_move[player_direction[p]+1]
  player_pos[p] = player_pos[p] + 1
next

game_is_playing = true

' set up the screen and the radar box
cycle_sprite = Lines3dSprite(lc_object)


call drawscreen
call ReturnToOriginSprite()
call MoveSprite(-32, -32)
text = TextSprite("PRESS BUTTONS 1+2 FOR PLAY")
text = TextSprite("PRESS BUTTONS 3+4 FOR AI")

last_controls = WaitForFrame(JoystickNone, Controller1, JoystickNone)
game_started = false
active_player = 0
while game_is_playing do
  active_player = active_player + 1
  active_player = active_player mod player_count
  ' grab the controls
  on error call sprite_overflow
  controls = WaitForFrame(JoystickDigital, Controller1, JoystickX + JoystickY)
  on error call 0
  ' handle player input

  if controls[1, 1] < 0 then
    camera_angle = camera_angle - 4
  elseif controls[1, 1] > 0 
    camera_angle = camera_angle + 4
  endif
  if controls[1, 2] < 0 then
    camera_length = camera_length - 1
  elseif controls[1, 2] > 0 
    camera_length = camera_length + 1
  endif
  camera_angle = camera_angle mod 360
  if camera_length < 4
    camera_length = 4
  endif

  for p = 1 to player_count
    if game_started

    require_update = 0
    if computer_only[p]
      ' of our three angles, find which one will kill us the least quickly
      directions_to_test = { player_direction[p], (player_direction[p]+1) mod 4, (player_direction[p]+3) mod 4} 

      if (rand() mod 8 = 1)
        best_dir = player_direction[p]
        best_len = 0

        for c = 1 to 3
          'print "c=",c," dtt=",directions_to_test[c]+1,x_move[1]
          current_x = player_x[p, player_pos[p]] + x_move[directions_to_test[c]+1]
          current_y = player_y[p, player_pos[p]] + y_move[directions_to_test[c]+1]
          cdist = 0
          mdist = 0
          while collision(current_x, current_y) = false 'and cdist < 32
            current_x = current_x + x_move[directions_to_test[c]+1]
            current_y = current_y + y_move[directions_to_test[c]+1]
            cdist = cdist + 1
          endwhile

          if best_len < cdist
            best_dir = directions_to_test[c]
            best_len = cdist
          endif
        next
        'print "---------------------------------------"
        if best_dir != player_direction[p] 
          player_direction[p] = best_dir
          require_update = 1
        endif
      endif
    else
      ' handle input - we use require_update as a flag to know if we
      ' need to redraw the screen...
      if controls[1, 4] = 1 and last_controls[1, 4] != 1
        player_direction[p] = ((player_direction[p] + 1) mod 4) 
        require_update = 1
      endif
      if controls[1, 3] = 1 and last_controls[1, 3] != 1
        ' mod is signed, so doens't really work here.... sad!
        player_direction[p] = (player_direction[p] - 1)
        if player_direction[p] < 0
          player_direction[p] = player_direction[p] + 4
        endif
        require_update = 1
      endif
    endif

    if require_update = 1
      player_pos[p] = player_pos[p] + 1
      player_x[p, player_pos[p]] = player_x[p, player_pos[p] - move_speed] 
      player_y[p, player_pos[p]] = player_y[p, player_pos[p] - move_speed] 
      call drawscreen
    endif

    ' move the cycles
    player_x[p, player_pos[p]] = player_x[p, player_pos[p]] + x_move[player_direction[p]+1]
    player_y[p, player_pos[p]] = player_y[p, player_pos[p]] + y_move[player_direction[p]+1]

    ' update the 2d trail
    player_trail[p][player_pos[p], 2] = player_x[p, player_pos[p]] / map_scale + map_x
    player_trail[p][player_pos[p], 3] = player_y[p, player_pos[p]] / map_scale + map_y

    ' update the 3d trail
    player_trail3d[p][player_pos[p]*4-6, 2] = player_x[p, player_pos[p]] - arena_size_x/2
    player_trail3d[p][player_pos[p]*4-6, 4] = player_y[p, player_pos[p]] - arena_size_y/2

    player_trail3d[p][player_pos[p]*4-4, 2] = player_x[p, player_pos[p]] - arena_size_x/2
    player_trail3d[p][player_pos[p]*4-4, 4] = player_y[p, player_pos[p]] - arena_size_y/2

    player_trail3d[p][player_pos[p]*4-3, 2] = player_x[p, player_pos[p]] - arena_size_x/2
    player_trail3d[p][player_pos[p]*4-3, 4] = player_y[p, player_pos[p]] - arena_size_y/2
  
    ' process collisions
    if collision(player_x[p, player_pos[p]], player_y[p, player_pos[p]]) = true
      game_is_playing = false
    else
      arena[player_y[p, player_pos[p]], player_x[p, player_pos[p]]] = p
    endif
    endif
    
  next
  ' update the cycle position
  ' FIXME: add scaling, obv
  call SpriteTranslate(cycle_sprite, {player_x[active_player+1, player_pos[active_player+1]] - arena_size_x/2, 1, player_y[active_player+1, player_pos[active_player+1]] - arena_size_y/2})
  call SpriteSetRotation(cycle_sprite, 0, 0, sprrot[player_direction[active_player+1]+1])
  
  last_controls = controls

  if game_started = false
    if controls[1, 4] = 1 and controls[1,3] = 1
      computer_only[1] = false
      game_started = true
      call drawscreen
    endif
    if controls[1, 5] = 1 and controls[1,6] = 1
      game_started = true
      computer_only[1] = true
      call drawscreen
    endif
  endif

  ' look at the player
  target_x = player_x[1, player_pos[1]] - arena_size_x/2
  target_y = 1
  target_z = player_y[1, player_pos[1]] - arena_size_y/2
  ' degrees to radians
  angle = ((sprrot[player_direction[1]+1]+camera_angle)mod 360)  / 57.2958
  sa = sin(angle)
  ca = cos(angle)

  wanted_x = (target_x - (ca*camera_length - sa*camera_length )) + 0.5
  wanted_z = (target_z + (sa*camera_length + ca*camera_length )) + 0.5
  if abs(camera_position[1] - wanted_x) < camera_step
    camera_position[1] = wanted_x
  else
    if camera_position[1] > wanted_x
      camera_position[1] = camera_position[1] - camera_step
    else
      camera_position[1] = camera_position[1] + camera_step
    endif
  endif
  if abs(camera_position[3] - wanted_z) < camera_step
    camera_position[3] = wanted_z
  else
    if camera_position[3] > wanted_z
      camera_position[3] = camera_position[3] - camera_step
    else
      camera_position[3] = camera_position[3] + camera_step
    endif
  endif
  
  ' do this _after_ having moved the camear
  lvx = camera_position[1] - target_x
  lvy = camera_position[2] - target_y
  lvz = camera_position[3] - target_z

  ' this returns in radians - convert to degrees first
  z_angle = atan2(-lvx, -lvz) * 57.2958
  'y_angle = atan2(-lvy, -lvz) * 57.2958
  y_angle = 0

  ' clip the camera
  if y_angle > 80
    y_angle = 80
  endif
  if y_angle < -80
    y_angle = -80
  endif

  'print y_angle
  'print z_angle
  'print camera_position
  'print -zangle
  'call SpritePrintVectors(player_trail3d[1])

  call cameraSetRotation(y_angle, 0, -z_angle)


endwhile

print "hit game over"
call ReturnToOriginSprite()
call TextSprite("GAME OVER PRESS 2+3")
done_waiting = false
while done_waiting = false
  controls = WaitForFrame(JoystickDigital, Controller1, JoystickX + JoystickY)
  if controls[1, 4] = 1 and controls[1,5] = 1
    done_waiting = true
  endif
endwhile
print "restart!"

endwhile

function collision(x, y)
    if x = 0 or y = 0 or x = arena_size_x or y = arena_size_y
      'print "colliusion at ",x," ",y," due to arena"
      return true
    endif
    ' got line too long when tryhing to do both of these!
    if arena[y, x] != 0 
      'print "colliusion at ",x," ",y," due to trail ",arena[y,x]
      return true
    endif
    return false
endfunction

sub sprite_overflow
  print "Sprite Overflow - drew ",GetCompiledSpriteCount()," objects - time to reduce!"
endsub

sub drawscreen
  dim p
  ' draw!
  call ClearScreen
  call cameraTranslate(camera_position)
  call IntensitySprite(127)
  'call ScaleSprite(64, 324 / 0.097)
  call ScaleSprite(64, 162 / 0.097)
  ' start from origin
  call ReturnToOriginSprite()
  ' draw an outline for the map
  map_box = LinesSprite({ _
      {MoveTo, map_x, map_y}, _
      {DrawTo, map_x + arena_size_x / map_scale, map_y }, _
      {DrawTo, map_x + arena_size_x / map_scale, map_y + arena_size_y / map_scale }, _
      {DrawTo, map_x , map_y + arena_size_y / map_scale }, _
      {DrawTo, map_x, map_y } })

  call IntensitySprite(96)
  call ReturnToOriginSprite()

  ' draw horizontal gridlines
  ' zig-zag these so we don't do long pen moves
  call IntensitySprite(64)
  call ReturnToOriginSprite()
  sprb = Lines3dSprite(floor_b)
  call SpriteClip(sprb, clippingRect)

  ' and the vertical ones
  call ReturnToOriginSprite()
  sprc = Lines3dSprite(floor_c)
  call SpriteClip(sprc, clippingRect)

  for p = 1 to player_count
    ' draw the 2D representation
    call ReturnToOriginSprite()
    call IntensitySprite(127)
    dim foome[player_pos[p], 3]
    foome[1, 1] = MoveTo
    foome[1, 2] = (player_x[p, 1] / map_scale) + map_x
    foome[1, 3] = (player_y[p, 1] / map_scale) + map_y
    for seg = 2 to player_pos[p] 
      foome[seg, 1] = DrawTo
      foome[seg, 2] = (player_x[p, seg] / map_scale) + map_x
      foome[seg, 3] = (player_y[p, seg] / map_scale) + map_y
    next
    player_trail[p] = foome
    call LinesSprite(player_trail[p])

    ' and the 3D representation
    call ReturnToOriginSprite()
    'dim foome3d[player_pos[p]*4-2, 4]
    dim foome3d[player_pos[p]*4-3, 4]
    foome3d[1, 1] = MoveTo
    foome3d[1, 2] = player_x[p, 1]  - arena_size_x/2
    foome3d[1, 3] = 0
    foome3d[1, 4] = player_y[p, 1] - arena_size_y/2
    for seg = 2 to player_pos[p] 
      ' down-right -> 2*4-6 = 2
      foome3d[seg*4-6, 1] = DrawTo
      foome3d[seg*4-6, 2] = player_x[p, seg] - arena_size_x/2
      foome3d[seg*4-6, 3] = 0
      foome3d[seg*4-6, 4] = player_y[p, seg] - arena_size_y/2
      
      ' up-left -> 2*4-5 = 3
      foome3d[seg*4-5, 1] = DrawTo
      foome3d[seg*4-5, 2] = player_x[p, seg - 1] - arena_size_x/2
      foome3d[seg*4-5, 3] = 2
      foome3d[seg*4-5, 4] = player_y[p, seg - 1] - arena_size_y/2

      ' up-right -> 2*3-4 = 4
      foome3d[seg*4-4, 1] = DrawTo
      foome3d[seg*4-4, 2] = player_x[p, seg] - arena_size_x/2
      foome3d[seg*4-4, 3] = 2
      foome3d[seg*4-4, 4] = player_y[p, seg] - arena_size_y/2
      
      ' down-right
      foome3d[seg*4-3, 1] = DrawTo
      foome3d[seg*4-3, 2] = player_x[p, seg] - arena_size_x/2
      foome3d[seg*4-3, 3] = 0
      foome3d[seg*4-3, 4] = player_y[p, seg] - arena_size_y/2
    next
    'foome3d[player_pos[p]*4-2, 1] = MoveTo
    'foome3d[player_pos[p]*4-2, 2] = 0
    'foome3d[player_pos[p]*4-2, 3] = 0
    'foome3d[player_pos[p]*4-2, 4] = 0
    print player_pos[p]," segments"
    player_trail3d[p] = foome3d
    ptr = Lines3dSprite(player_trail3d[p])
    call SpriteClip(ptr, clippingRect)

  next
  ' return to origin before doing 3d things
  ' we only ever display one cycle, for now!  maybe later we'll simplify it enough to display more...   
  call ReturnToOriginSprite()
  cycle_sprite = Lines3dSprite(lc_object)
  call SpriteClip(cycle_sprite, clippingRect)
endsub


function lightcycle()
mysprite={ _
  {DrawTo, 0.219073,-0.203540,1.200940} , _
  {DrawTo, 0.219073,0.437060,0.762240} , _
  {DrawTo, 0.219073,0.139332,0.509412} , _
  {DrawTo, 0.219073,0.519756,-1.089104} , _
  {DrawTo, 0.219667,-0.621360,-1.089532} , _
  {DrawTo, 0.219073,-0.621424,0.658632} , _
  {DrawTo, 0.219073,0.139332,0.509412} , _
  {DrawTo, 0.219073,-0.621424,0.658632} , _
  {DrawTo, 0.219073,-0.203540,1.200940} , _
  {DrawTo, 0.219073,-0.621424,0.658632} , _
  {DrawTo, 0.219073,-0.623836,1.413196} , _
  {DrawTo, 0.219360,-0.460176,1.412268} , _
  {DrawTo, 0.219073,-0.203540,1.200940} , _
  {DrawTo, 0.219073,0.064276,1.411732} , _
  {DrawTo, 0.219073,0.437060,1.411732} , _
  {DrawTo, 0.219073,0.064276,1.411732} , _
  {DrawTo, -0.218156,0.064276,1.411732} , _
  {DrawTo, -0.218156,0.437060,1.411732} , _
  {DrawTo, 0.219073,0.437060,1.411732} , _
  {DrawTo, -0.155868,0.449016,1.253128} , _
  {DrawTo, -0.155868,0.821492,-0.075852} , _
  {DrawTo, 0.157152,0.822792,-0.075088} , _
  {DrawTo, 0.157380,0.677820,-0.075155} , _
  {DrawTo, 0.157380,0.322298,1.177344} , _
  {DrawTo, -0.155639,0.320990,1.176592} , _
  {DrawTo, -0.155638,0.676444,-0.075908} , _
  {DrawTo, -0.155868,0.821492,-0.075852} , _
  {DrawTo, -0.155868,0.449016,1.253128} , _
  {DrawTo, -0.155639,0.320990,1.176592} , _
  {DrawTo, -0.155868,0.449016,1.253128} , _
  {DrawTo, 0.157152,0.450316,1.253892} , _
  {DrawTo, 0.157152,0.822792,-0.075088} , _
  {DrawTo, 0.157152,0.450316,1.253892} , _
  {DrawTo, 0.157380,0.322298,1.177344} , _
  {DrawTo, 0.157152,0.450316,1.253892} , _
  {MoveTo,0.001113,0.395961,1.414464},   {DrawTo, 0.120608,0.226074,1.414464} , _
  {DrawTo, 0.120608,-0.197485,1.815264} , _
  {DrawTo, 0.001113,-0.196490,2.000000} , _
  {DrawTo, -0.119690,-0.197485,1.815264} , _
  {DrawTo, -0.119690,0.226074,1.414464} , _
  {DrawTo, 0.001113,0.395961,1.414464} , _
  {DrawTo, 0.001113,-0.196490,2.000000} , _
  {DrawTo, 0.001113,0.395961,1.414464} , _
  {DrawTo, -0.218156,0.064276,1.411732} , _
  {DrawTo, 0.219073,0.064276,1.411732} , _
  {DrawTo, 0.219073,-0.203540,1.200940} , _
  {DrawTo, 0.219360,-0.460176,1.412268} , _
  {DrawTo, 0.219073,-0.623836,1.413196} , _
  {DrawTo, -0.218156,-0.623836,1.412228} , _
  {DrawTo, -0.217868,-0.460068,1.412376} , _
  {DrawTo, 0.219360,-0.460176,1.412268} , _
  {DrawTo, -0.217868,-0.460068,1.412376} , _
  {DrawTo, -0.218156,-0.623836,1.412228} , _
  {DrawTo, -0.218156,-0.621424,0.658632} , _
  {DrawTo, -0.218156,0.139332,0.509412} , _
  {DrawTo, -0.218156,0.437060,0.762240} , _
  {DrawTo, -0.218156,-0.203755,1.200940} , _
  {DrawTo, -0.218156,0.437060,0.762240} , _
  {MoveTo,-0.270298,0.466176,1.024284},   {DrawTo, -0.270298,0.741892,-0.104224} , _
  {DrawTo, -0.270298,0.466176,1.024284} , _
  {DrawTo, -0.270202,-0.040552,0.420544} , _
  {DrawTo, -0.270298,0.331591,-1.672704} , _
  {DrawTo, 0.267955,0.331591,-1.672704} , _
  {DrawTo, 0.267955,0.741892,-0.104224} , _
  {DrawTo, 0.271119,-0.040444,0.420440} , _
  {DrawTo, 0.267955,0.466176,1.024608} , _
  {DrawTo, -0.270298,0.466176,1.024284} , _
  {MoveTo,0.267955,0.466176,1.024608},   {DrawTo, 0.267955,0.741892,-0.104224} , _
  {DrawTo, 0.267955,0.466176,1.024608} , _
  {MoveTo,0.081204,-0.060096,1.414464},   {DrawTo, 0.081204,-0.210162,1.282972} , _
  {DrawTo, 0.081204,-0.338960,1.414464} , _
  {DrawTo, 0.081204,-0.204791,1.540588} , _
  {DrawTo, 0.081204,-0.060096,1.414464} , _
  {DrawTo, -0.080287,-0.204791,1.540588} , _
  {DrawTo, -0.080287,-0.338960,1.414464} , _
  {DrawTo, -0.080287,-0.215533,1.282972} , _
  {DrawTo, -0.080287,-0.060096,1.414464} , _
  {DrawTo, -0.218156,-0.203755,1.200940} , _
  {DrawTo, -0.218156,0.064276,1.411732} , _
  {MoveTo,-0.218156,-0.203755,1.200940},   {DrawTo, -0.218156,-0.621424,0.658632} , _
  {DrawTo, -0.218156,-0.203755,1.200940} , _
  {DrawTo, 0.219073,-0.203540,1.200940} , _
  {DrawTo, -0.218156,-0.203755,1.200940} , _
  {DrawTo, -0.217868,-0.460068,1.412376} , _
  {DrawTo, -0.218156,-0.203755,1.200940} , _
  {MoveTo,-0.119690,-0.213598,0.992176},   {DrawTo, -0.119690,-0.625128,1.414464} , _
  {DrawTo, -0.119690,-0.197485,1.815264} , _
  {DrawTo, 0.001113,-0.196490,2.000000} , _
  {DrawTo, 0.001113,-0.795016,1.414464} , _
  {DrawTo, 0.001113,-0.219112,0.791336} , _
  {DrawTo, -0.119690,-0.213598,0.992176} , _
  {MoveTo,0.001113,-0.219112,0.791336},   {DrawTo, 0.001113,-0.795016,1.414464} , _
  {DrawTo, -0.119690,-0.625128,1.414464} , _
  {DrawTo, 0.001113,-0.795016,1.414464} , _
  {DrawTo, 0.001113,-0.196490,2.000000} , _
  {DrawTo, 0.120608,-0.197485,1.815264} , _
  {DrawTo, 0.120608,-0.625128,1.414464} , _
  {DrawTo, 0.001113,-0.795016,1.414464} , _
  {DrawTo, 0.120608,-0.625128,1.414464} , _
  {DrawTo, 0.120608,-0.218970,0.992176} , _
  {DrawTo, 0.001113,-0.219112,0.791336} , _
  {MoveTo,0.271119,-0.040444,0.420440},   {DrawTo, 0.267955,0.741892,-0.104224} , _
  {DrawTo, 0.267955,0.331591,-1.672704} , _
  {DrawTo, 0.271119,-0.040090,-0.828344} , _
  {DrawTo, 0.271119,-0.040444,0.420440} , _
  {MoveTo,-0.218156,0.139332,0.509412},   {DrawTo, -0.218156,-0.621424,0.658632} , _
  {MoveTo,0.004621,-0.346884,-0.723072},   {DrawTo, 0.004621,0.395993,-1.348492} , _
  {DrawTo, 0.004621,-0.346884,-0.723072} , _
  {DrawTo, 0.004621,-0.822792,-1.536196} , _
  {DrawTo, -0.429884,-0.665716,-1.536196} , _
  {DrawTo, 0.004621,-0.822792,-1.536196} , _
  {DrawTo, 0.430804,-0.665716,-1.536196} , _
  {DrawTo, 0.004621,-0.822792,-1.536196} , _
  {DrawTo, 0.004621,-0.346884,-0.723072} , _
  {DrawTo, -0.429884,-0.341574,-0.919252} , _
  {DrawTo, 0.004621,-0.346884,-0.723072} , _
  {DrawTo, 0.430804,-0.341574,-0.919252} , _
  {DrawTo, 0.430804,-0.665716,-1.536196} , _
  {DrawTo, 0.430804,-0.057417,-1.811660} , _
  {DrawTo, 0.430804,0.238918,-1.348492} , _
  {DrawTo, 0.430804,-0.341574,-0.919252} , _
  {DrawTo, 0.004621,-0.346884,-0.723072} , _
  {MoveTo,-0.429884,-0.341574,-0.919252},   {DrawTo, -0.429884,0.238918,-1.348492} , _
  {DrawTo, 0.004621,0.395993,-1.348492} , _
  {DrawTo, 0.430804,0.238918,-1.348492} , _
  {DrawTo, 0.004621,0.395993,-1.348492} , _
  {DrawTo, 0.004621,-0.057336,-2.000000} , _
  {DrawTo, 0.004621,-0.822792,-1.536196} , _
  {DrawTo, 0.004621,-0.057336,-2.000000} , _
  {DrawTo, 0.430804,-0.057417,-1.811660} , _
  {DrawTo, 0.004621,-0.057336,-2.000000} , _
  {DrawTo, 0.004621,0.395993,-1.348492} , _
  {DrawTo, -0.429884,0.238918,-1.348492} , _
  {DrawTo, -0.429884,-0.057417,-1.811660} , _
  {DrawTo, -0.429884,-0.665716,-1.536196} , _
  {DrawTo, -0.429884,-0.341574,-0.919252} , _
  {MoveTo,-0.227876,-0.205074,-1.221820},   {DrawTo, -0.227876,-0.338926,-1.348492} , _
  {DrawTo, -0.227876,-0.203006,-1.477088} , _
  {DrawTo, -0.227876,-0.060064,-1.348492} , _
  {DrawTo, -0.227876,-0.205074,-1.221820} , _
  {MoveTo,-0.218156,-0.621424,-1.089104},   {DrawTo, -0.217187,0.519756,-1.089104} , _
  {DrawTo, -0.218156,0.139332,0.509412} , _
  {MoveTo,-0.270298,0.741892,-0.104224},   {DrawTo, -0.270298,0.331591,-1.672704} , _
  {DrawTo, -0.270298,0.741892,-0.104224} , _
  {DrawTo, 0.267955,0.741892,-0.104224} , _
  {DrawTo, -0.270298,0.741892,-0.104224} , _
  {MoveTo,-0.155638,0.499192,-1.181368},   {DrawTo, -0.155638,0.326386,-1.643784} , _
  {DrawTo, -0.155868,0.351552,-1.785140} , _
  {DrawTo, -0.155638,0.326386,-1.643784} , _
  {DrawTo, 0.157380,0.326374,-1.643804} , _
  {DrawTo, 0.157152,0.352851,-1.784376} , _
  {DrawTo, -0.155868,0.351552,-1.785140} , _
  {DrawTo, 0.157152,0.352851,-1.784376} , _
  {DrawTo, 0.157380,0.326374,-1.643804} , _
  {DrawTo, 0.157380,0.500500,-1.180616} , _
  {DrawTo, 0.157152,0.639460,-1.248664} , _
  {DrawTo, 0.157152,0.352851,-1.784376} , _
  {DrawTo, 0.157152,0.639460,-1.248664} , _
  {DrawTo, -0.155868,0.638164,-1.249428} , _
  {DrawTo, -0.155868,0.351552,-1.785140} , _
  {DrawTo, -0.155868,0.638164,-1.249428} , _
  {DrawTo, -0.155638,0.499192,-1.181368} , _
  {MoveTo,0.228794,-0.060064,-1.348492},   {DrawTo, 0.228794,-0.203006,-1.477088} , _
  {DrawTo, 0.228794,-0.338926,-1.348492} , _
  {DrawTo, 0.228794,-0.205074,-1.221820} , _
  {DrawTo, 0.228794,-0.060064,-1.348492} , _
  {MoveTo,0.004621,-0.057336,-2.000000},   {DrawTo, -0.429884,-0.057417,-1.811660} , _
  {DrawTo, 0.004621,-0.057336,-2.000000} }
  return mysprite
endfunction
