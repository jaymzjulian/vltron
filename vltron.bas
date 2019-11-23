
' Allow for up to 1024 co-ords for each of the 4 players
dim player_x[4,1024]
dim player_y[4,1024]
dim player_direction[4]
dim x_move[4]
dim y_move[4]
lc_object = lightcycle()

vx_scale_factor = 128.0
cycle_vx_scale_factor = 32.0
local_scale = 64/vx_scale_factor
cycle_local_scale = 64/cycle_vx_scale_factor
vx_frame_rate = 60
target_game_rate = 20

' we're going to use a bitmap for the arena as well, to simplify collisions
' if you update one of these, you need to update all of them!
arena_size_x = 128
arena_size_y = 128
map_scale = 1 / local_scale
arena = ByteArray((arena_size_y+1)*(arena_size_x+1))

first_person = false
viewports = 2

x_move = { 0, 1, 0, -1 }
y_move = { 1, 0, -1, 0 }
while true

status_enabled = true
player_direction = { 0, 2, 1, 3 }
player_intensity = {127, 96, 64, 80 }
alive = { true, true, true, true }
floor_intensity = 48
wall_intensity = 48

dim status_display[4, 3]

status_display[1,1] = -255 * local_scale
status_display[1,2] = 255 * local_scale
status_display[1,3] = "FPS: "

status_display[2,1] = -255 * local_scale
status_display[2,2] = 235 * local_scale
status_display[2,3] = "VXTIME: "

status_display[3,1] = -255 * local_scale
status_display[3,2] = 215 * local_scale
status_display[3,3] = "LAST REDRAW: "

status_display[4,1] = -255 * local_scale
status_display[4,2] = 195 * local_scale
status_display[4,3] = "AI: "

' This is where in the static array the players are
dim player_trail[4]
dim player_trail3d[4]
dim player_pos[4]

dim sprrot[4]

sprrot = {0, 270, 180, 90}
camera_position = { 0.5, 4.5, -80.5 }
camera_rotation = { 0, 0, 0 }
camera_length = 20
camera_angle = -100
clippingRect = {{-255*local_scale,-255*local_scale},{255*local_scale,255*local_scale}}
cycle_clippingRect = {{-255*cycle_local_scale,-255*cycle_local_scale},{255*cycle_local_scale,255*cycle_local_scale}}

move_speed = 1
camera_step = 2

' finger in the air as to how many sprites we'll display at most!
dim all_sprites[256]
dim all_origins[256]
total_objects = 0

for y = 1 to arena_size_y
  for x = 1 to arena_size_x
    arena[y*arena_size_x + x] = 0
  next
next


start_distance = 16
player_count = 4
map_x = 64 * local_scale
map_y = 64 * local_scale
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

' do thius to avoid an error condition
call ClearScreen
controls = WaitForFrame(JoystickDigital, Controller1, JoystickX + JoystickY)
las_controls = controls

' set up the screen and the radar box
dim cycle_sprite[4]
for p = 1 to player_count
  cycle_sprite[p] = Lines3dSprite(lc_object)
next


call drawscreen
call aps_rto()
call aps(MoveSprite(-32 * local_scale, -32 * local_scale))
call aps(IntensitySprite(127))
text = aps(TextSprite("PRESS BUTTONS 1+2 FOR PLAY"))
text = aps(TextSprite("PRESS BUTTONS 3+4 FOR AI"))

' some state
game_started = false
overflowed = false
new_overflow = false
last_begin = 0
last_rotation = 0
max_rotation = 15
last_frame_time = 0
wait_for_frame_time = 100
rdt = 0
game_start_time = GetTickCount()
frames_played = 0
ai_time = 0
deal_with_overflow = false
while game_is_playing do
  ' show FPS before we get too far 
  ' this is at 960 hz - so we divide by 960 to get GPS
  if status_enabled
    ctick = GetTickCount()
    fps_val = 960.0 / (ctick - last_frame_time) 
    status_display[1,3] = "FPS: "+Int(fps_val) + " ("+ (ctick - last_frame_time) +"T)"
    vx_pc = (wait_for_frame_time*100.0) / (ctick - last_frame_time)
    status_display[2,3] = "WAITTIME: "+Int(vx_pc)+"%"+" ("+wait_for_frame_time+"T)"
    status_display[3,3] = "LAST REDRAW: "+rdt+"T"
    status_display[4,3] = "AI: "+ai_time+"T"
    last_frame_time = ctick
  endif


  require_redraw = false
  lft = GetTickCount() - last_begin
  ' grab the controls
  new_overflowed = false
  f = GetTickCount()
  on error call sprite_overflow
  controls = WaitForFrame(JoystickDigital, Controller1, JoystickX + JoystickY)
  on error call 0
  wait_for_frame_time = GetTickCount()-f
  if wait_for_frame_time > 100
    print "Drawscreen took ",wait_for_frame_time," lastov: ",overflowed," thisov: ",new_overflowed, " last: ",lft
  endif
  last_begin = GetTickCount()

  ' at this point, overflowed is the _last_ frame overflow value, whereas
  ' new_overflow is our _new_ frame overflow value.  
  overflowed = new_overflowed
  

  ' if we didn't overflow, ensure all sprites are enabled next frame
  if deal_with_overflow
  if overflowed = false
    for sp = 1 to total_objects
      call SpriteEnable(all_sprites[sp], true)
    next
  ' if we _did_ overflow, disable some sprites!
  else
    drawn_sprites = GetCompiledSpriteCount()
    sprites_to_disable = (total_objects - drawn_sprites) 
    start_sprite = drawn_sprites - sprites_to_disable
    end_sprite = drawn_sprites

    print "Disabling ",drawn_sprites," most recently drawn sprites so remaining can draw next remianing frame, hopefully"
    
    if start_sprite < 1
      start_sprite = 1
    endif
    if end_sprite > total_objects
      end_sprite = total_objects
    endif

    ' we have to align to return_to_origins here - otherwise
    ' we'll get pen drift.  To do this, we'll move _BOTH_ start sprite and
    ' end sprite back, on the grounds that if we half drew something, we should give it a 
    ' second chance to draw here!
    while all_origins[start_sprite] = false  and start_sprite > 1
      start_sprite = start_sprite - 1
    endwhile
    ' for end sprite, we want to stop one shy of the return to origin - we want
    ' the RTO to be executed!
    while all_origins[end_sprite+1] = false  and end_sprite > 1
      end_sprite = end_sprite - 1
    endwhile

    ' FIXME: traverse back/forward to a return_to_origin_sprite - but how do we detect one?
    for sp = start_sprite to end_sprite
      call SpriteEnable(all_sprites[sp], false)
    next
  endif
  endif


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

  ' actual game logic is here :)
  ' are we due for another frame?
  target_frames = ((GetTickCount() - game_start_time) * target_game_rate) / 960.0
  'print "Target: ",target_frames, " Played: ", frames_played

  ai_time = 0
  ' FIXME: support partial frames - which is to say, do fractional increments of position, at least for the 3d
  ' part
  while target_frames > frames_played
  ' process!
  frames_played = frames_played + 1
  run_count = 0
  for p = 1 to player_count
    if game_started and alive[p]

    require_update = 0
    if computer_only[p] and run_count = 0
      start_ai = GetTickCount()
      ' of our three angles, find which one will kill us the least quickly
      directions_to_test = { player_direction[p], (player_direction[p]+1) mod 4, (player_direction[p]+3) mod 4} 

      'if (rand() mod 8 = 1)
      if (rand() mod 4 = 1)
        best_dir = player_direction[p]
        best_len = 0

        for c = 1 to 3
          'print "c=",c," dtt=",directions_to_test[c]+1,x_move[1]
          current_x = player_x[p, player_pos[p]] + x_move[directions_to_test[c]+1]
          current_y = player_y[p, player_pos[p]] + y_move[directions_to_test[c]+1]
          cdist = 0
          mdist = 0
          while collision(current_x, current_y) = false and cdist < 16
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
      ai_time = ai_time + (GetTickCount()-start_ai)
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
      require_redraw = true
      s = GetTickCount()
      call drawscreen
      rdt = s - GetTickCount()
    endif

    ' move the cycles
    player_x[p, player_pos[p]] = player_x[p, player_pos[p]] + x_move[player_direction[p]+1]
    player_y[p, player_pos[p]] = player_y[p, player_pos[p]] + y_move[player_direction[p]+1]

    if require_redraw = false
      ' update the 2d trail
      player_trail[p][player_pos[p], 2] = player_x[p, player_pos[p]] / map_scale + map_x
      player_trail[p][player_pos[p], 3] = player_y[p, player_pos[p]] / map_scale + map_y

      if first_person = false or p != 1
        ' update the 3d trail
        player_trail3d[p][(player_pos[p]-2)*4+1, 2] = player_x[p, player_pos[p]] - arena_size_x/2
        player_trail3d[p][(player_pos[p]-2)*4+1, 4] = player_y[p, player_pos[p]] - arena_size_y/2
  
        player_trail3d[p][(player_pos[p]-2)*4+4, 2] = player_x[p, player_pos[p]] - arena_size_x/2
        player_trail3d[p][(player_pos[p]-2)*4+4, 4] = player_y[p, player_pos[p]] - arena_size_y/2
      endif
    endif
  
    ' process collisions
    if collision(player_x[p, player_pos[p]], player_y[p, player_pos[p]]) = true
      alive[p] = false
      require_redraw = true
    else
      arena[player_y[p, player_pos[p]] * arena_size_x  + player_x[p, player_pos[p]]] = p
    endif
    endif
    if first_person = false or p != 1
      call SpriteTranslate(cycle_sprite[p], {player_x[p, player_pos[p]] - arena_size_x/2, 1, player_y[p, player_pos[p]] - arena_size_y/2})
      call SpriteSetRotation(cycle_sprite[p], 0, 0, sprrot[player_direction[p]+1])
    endif
  next

  ' end the frame loop _before_ we redraw the screen, since that is expensive - though we should keep track 
  ' of how many loops we did and modify camera based on that!
  run_count = run_count + 1
  endwhile

  ' if require redraw, do it now
  if require_redraw and game_started 
    call drawscreen
  endif
  
  last_controls = controls

  ' if we're not playing yet, wait until we are!
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

  if first_person
    target_rotation = 360-sprrot[player_direction[1]+1]
    if target_rotation != last_rotation
      ' we need to work out which direction to turn from last_rotation to hit
      ' target_rotation soonest.  We normalize this to -180 to 180
      rot_dif = target_rotation - last_rotation
      while rot_dif > 180
        rot_dif = rot_dif - 360
      endwhile
      while rot_dif < -180
        rot_dif = rot_dif + 360
      endwhile
      if rot_dif < 0
        last_rotation = last_rotation - max_rotation
      endif
      if rot_dif > 0
        last_rotation = last_rotation + max_rotation
      endif
    endif
      

    p = 1
    camera_position[1] = player_x[p, player_pos[p]] - arena_size_x/2
    camera_position[2] = 1
    camera_position[3] = player_y[p, player_pos[p]] - arena_size_y/2
    call cameraSetRotation(0, 0, last_rotation)
  else
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
    mylen = sqrt(lvx*lvx+lvy*lvy*lvz*lvz)

    ' this returns in radians - convert to degrees first
    z_angle = atan2(-lvx, -lvz) * 57.2958
    'y_angle = atan2(-lvy, -lvz) * 57.2958
    y_angle = asin(lvy/mylen) * 57.2958
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
    if alive[1] = false
      game_is_playing = false
    endif

    call cameraSetRotation(y_angle, 0, -z_angle)
  endif


endwhile

print "hit game over"
call ReturnToOriginSprite()
call IntensitySprite(127)
call TextSprite("GAME OVER PRESS 2+3")
done_waiting = false
while done_waiting = false
  ' this is a hack for now until sprite management gets better
  on error call game_over_overflow
  controls = WaitForFrame(JoystickDigital, Controller1, JoystickX + JoystickY)
  on error call 0
  if controls[1, 4] = 1 and controls[1,5] = 1
    done_waiting = true
  endif
endwhile
print "restart!"

endwhile

sub game_over_overflow
  call ClearScreen
  call ReturnToOriginSprite()
  call IntensitySprite(127)
  call TextSprite("GAME OVER PRESS 2+3")
endsub

function collision(x, y)
    if x = 0 or y = 0 or x = arena_size_x or y = arena_size_y
      'print "colliusion at ",x," ",y," due to arena"
      return true
    endif
    ' got line too long when tryhing to do both of these!
    if arena[y*arena_size_x + x] != 0 
      'print "colliusion at ",x," ",y," due to trail ",arena[y,x]
      return true
    endif
    return false
endfunction

sub sprite_overflow
  'if overflowed
  '  print "Sprite Overflow - drew ",GetCompiledSpriteCount()," of ",total_objects," objects - time to reduce! - last frame overflow was ",overflowed
  'endif
  new_overflowed = true
endsub


' append to our sprite list
function aps(sprite)
  total_objects = total_objects + 1
  all_sprites[total_objects] = sprite
  all_origins[total_objects] = false
  return all_sprites[total_objects]
endfunction

' special one for return to origin, so we can seek it
function aps_rto()
  total_objects = total_objects + 1
  all_sprites[total_objects] = ReturnToOriginSprite()
  all_origins[total_objects] = true
  return all_sprites[total_objects]
endfunction

sub drawscreen
  dim p
  ' draw!
  '
  ' Every object that is a sprite gets shoved into the total_objects array - we do this with the aps function
  ' to defuce typing...
  '
  call ClearScreen
  call SetFrameRate(vx_frame_rate)
  total_objects = 0
  call cameraTranslate(camera_position)

  call aps(IntensitySprite(127))
  call aps(ScaleSprite(vx_scale_factor, (162 / 0.097) * local_scale))
  
  ' status display
  call aps_rto()
  call aps(TextListSprite(status_display))

  call aps_rto()
  ' draw an outline for the map
  map_box = aps(LinesSprite({ _
      {MoveTo, map_x, map_y}, _
      {DrawTo, map_x + arena_size_x / map_scale, map_y }, _
      {DrawTo, map_x + arena_size_x / map_scale, map_y + arena_size_y / map_scale }, _
      {DrawTo, map_x , map_y + arena_size_y / map_scale }, _
      {DrawTo, map_x, map_y } }))

  for p = 1 to player_count
    if alive[p]
    ' draw the 2D representation
    call aps_rto()
    call aps(IntensitySprite(player_intensity[p]))
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
    call aps(LinesSprite(player_trail[p]))

    ' and the 3D representation
    call aps_rto()
    'dim foome3d[player_pos[p]*4-2, 4]
    dim foome3d[(player_pos[p]-1)*4, 4]

    for seg = 1 to (player_pos[p] - 1)
      ' bottom right
      foome3d[(seg-1)*4+1, 1] = DrawTo
      foome3d[(seg-1)*4+1, 2] = player_x[p, seg + 1]  - arena_size_x/2
      foome3d[(seg-1)*4+1, 3] = 0 
      foome3d[(seg-1)*4+1, 4] = player_y[p, seg + 1] - arena_size_y/2
      
			' bottom left
      foome3d[(seg-1)*4+2, 1] = DrawTo
      foome3d[(seg-1)*4+2, 2] = player_x[p, seg] - arena_size_x/2
      foome3d[(seg-1)*4+2, 3] = 0
      foome3d[(seg-1)*4+2, 4] = player_y[p, seg] - arena_size_y/2

       ' to up left
      foome3d[(seg-1)*4+3, 1] = DrawTo
      foome3d[(seg-1)*4+3, 2] = player_x[p, seg] - arena_size_x/2
      foome3d[(seg-1)*4+3, 3] = 2 
      foome3d[(seg-1)*4+3, 4] = player_y[p, seg] - arena_size_y/2
      
      ' to up right 
      foome3d[(seg-1)*4+4, 1] = DrawTo
      foome3d[(seg-1)*4+4, 2] = player_x[p, seg + 1] - arena_size_x/2
      foome3d[(seg-1)*4+4, 3] = 2
      foome3d[(seg-1)*4+4, 4] = player_y[p, seg + 1] - arena_size_y/2

    next
    ' make the start of the trail a move :)
    foome3d[1, 1] = MoveTo

    player_trail3d[p] = foome3d
    ptr = aps(Lines3dSprite(player_trail3d[p]))
    call SpriteClip(ptr, clippingRect)
    endif
  next
  
  ' put these in a secod loop so they appear at the end of the display list...
  call aps(ScaleSprite(cycle_vx_scale_factor, (162 / 0.097) * cycle_local_scale))
  for p = 1 to player_count
    if alive[p]
    if first_person = false or p != 1
      ' return to origin before doing 3d things
      ' we only ever display one cycle, for now!  maybe later we'll simplify it enough to display more...   
      call aps_rto()
      call aps(IntensitySprite(player_intensity[p]))
      cycle_sprite[p] = aps(Lines3dSprite(lc_object))
      call SpriteClip(cycle_sprite[p], cycle_clippingRect)
    endif
    endif
  next
  call aps(ScaleSprite(vx_scale_factor, (162 / 0.097) * local_scale))
  call aps(IntensitySprite(127))
  
  ' why is this after the other things?  so it gets destroyed earlier ;)
  ' draw horizontal gridlines
  ' zig-zag these so we don't do long pen moves
  call aps(IntensitySprite(floor_intensity))
  call aps_rto()
  sprb = aps(Lines3dSprite(floor_b))
  call SpriteClip(sprb, clippingRect)

  ' and the vertical ones
  call aps_rto()
  sprc = aps(Lines3dSprite(floor_c))
  call SpriteClip(sprc, clippingRect)

endsub


function lightcycle()
mysprite={ _
  {MoveTo,-0.284963,-0.242065,-1.085209},   {DrawTo, -0.284963,-0.550938,-1.394082} , _
  {DrawTo, -0.452639,-0.242065,-1.394082} , _
  {DrawTo, -0.284963,-0.242065,-1.702956} , _
  {DrawTo, -0.284963,0.066808,-1.394082} , _
  {DrawTo, -0.452639,-0.242065,-1.394082} , _
  {DrawTo, -0.284963,-0.242065,-1.085209} , _
  {DrawTo, -0.284963,0.066808,-1.394082} , _
  {MoveTo,-0.284963,0.319254,-1.634925},   {DrawTo, -0.284963,-0.001222,-1.955402} , _
  {DrawTo, 0.284963,-0.001222,-1.955402} , _
  {DrawTo, 0.284963,0.319254,-1.634925} , _
  {DrawTo, 0.284963,0.319254,-1.153240} , _
  {DrawTo, 0.284963,-0.001222,-0.832763} , _
  {DrawTo, 0.284963,-0.482907,-0.832763} , _
  {DrawTo, 0.284963,-0.803384,-1.153240} , _
  {DrawTo, 0.284963,-0.803384,-1.634925} , _
  {DrawTo, 0.284963,-0.482907,-1.955402} , _
  {DrawTo, 0.284963,-0.001222,-1.955402} , _
  {MoveTo,0.284963,-0.242065,-1.702956},   {DrawTo, 0.284963,-0.550938,-1.394082} , _
  {DrawTo, 0.452639,-0.242065,-1.394082} , _
  {DrawTo, 0.284963,-0.242065,-1.702956} , _
  {DrawTo, 0.284963,0.066808,-1.394082} , _
  {DrawTo, 0.452639,-0.242065,-1.394082} , _
  {DrawTo, 0.284963,-0.242065,-1.085209} , _
  {DrawTo, 0.284963,0.066808,-1.394082} , _
  {MoveTo,0.487614,0.080097,-1.087675},   {DrawTo, -0.487614,0.080097,-1.087675} , _
  {DrawTo, -0.366132,-0.625656,-0.782431} , _
  {DrawTo, -0.267016,-0.617817,-0.007839} , _
  {DrawTo, 0.267016,-0.617817,-0.007839} , _
  {DrawTo, 0.366132,-0.625656,-0.782431} , _
  {DrawTo, 0.487614,0.080097,-1.087675} , _
  {DrawTo, 0.147834,0.360783,-1.785661} , _
  {DrawTo, 0.267016,0.633494,-1.244920} , _
  {DrawTo, 0.267016,0.860819,-0.078388} , _
  {DrawTo, 0.321604,0.578623,0.798109} , _
  {DrawTo, 0.161512,-0.258833,1.702149} , _
  {DrawTo, 0.161512,-0.496347,1.471528} , _
  {DrawTo, 0.321604,-0.258690,0.690755} , _
  {DrawTo, 0.267016,-0.617817,-0.007839} , _
  {MoveTo,-0.267016,-0.617817,-0.007839},   {DrawTo, -0.321604,-0.258690,0.690755} , _
  {DrawTo, -0.161512,-0.496347,1.471528} , _
  {DrawTo, 0.161512,-0.496347,1.471528} , _
  {MoveTo,0.217050,-0.415902,1.448602},   {DrawTo, 0.217050,-0.271424,1.593080} , _
  {DrawTo, 0.344764,-0.271424,1.448602} , _
  {DrawTo, 0.217050,-0.415902,1.448602} , _
  {DrawTo, 0.217050,-0.271424,1.304125} , _
  {DrawTo, 0.344764,-0.271424,1.448602} , _
  {DrawTo, 0.217050,-0.126946,1.448602} , _
  {DrawTo, 0.217050,-0.271424,1.304125} , _
  {MoveTo,0.217050,-0.271424,1.593080},   {DrawTo, 0.217050,-0.126946,1.448602} , _
  {MoveTo,-0.217050,-0.126946,1.448602},   {DrawTo, -0.217050,-0.271424,1.593080} , _
  {DrawTo, -0.344764,-0.271424,1.448602} , _
  {DrawTo, -0.217050,-0.415902,1.448602} , _
  {DrawTo, -0.217050,-0.271424,1.304125} , _
  {DrawTo, -0.344764,-0.271424,1.448602} , _
  {DrawTo, -0.217050,-0.126946,1.448602} , _
  {DrawTo, -0.217050,-0.271424,1.304125} , _
  {MoveTo,-0.161512,-0.496347,1.471528},   {DrawTo, -0.161512,-0.258833,1.702149} , _
  {DrawTo, 0.161512,-0.258833,1.702149} , _
  {MoveTo,-0.161512,-0.258833,1.702149},   {DrawTo, -0.321604,0.578623,0.798109} , _
  {DrawTo, -0.267016,0.860819,-0.078388} , _
  {DrawTo, 0.267016,0.860819,-0.078388} , _
  {MoveTo,-0.267016,0.860819,-0.078388},   {DrawTo, -0.267016,0.633494,-1.244920} , _
  {DrawTo, -0.147834,0.360783,-1.785661} , _
  {DrawTo, 0.147834,0.360783,-1.785661} , _
  {MoveTo,-0.147834,0.360783,-1.785661},   {DrawTo, -0.487614,0.080097,-1.087675} , _
  {MoveTo,-0.284963,0.319254,-1.153240},   {DrawTo, -0.284963,0.319254,-1.634925} , _
  {DrawTo, 0.284963,0.319254,-1.634925} , _
  {MoveTo,-0.284963,-0.001222,-1.955402},   {DrawTo, -0.284963,-0.482907,-1.955402} , _
  {DrawTo, 0.284963,-0.482907,-1.955402} , _
  {MoveTo,0.284963,-0.550938,-1.394082},   {DrawTo, 0.284963,-0.242065,-1.085209} , _
  {MoveTo,-0.284963,-0.482907,-0.832763},   {DrawTo, -0.284963,-0.001222,-0.832763} , _
  {DrawTo, 0.284963,-0.001222,-0.832763} , _
  {MoveTo,-0.284963,-0.001222,-0.832763},   {DrawTo, -0.284963,0.319254,-1.153240} , _
  {DrawTo, 0.284963,0.319254,-1.153240} , _
  {MoveTo,-0.267016,0.633494,-1.244920},   {DrawTo, 0.267016,0.633494,-1.244920} , _
  {MoveTo,-0.284963,-0.482907,-0.832763},   {DrawTo, 0.284963,-0.482907,-0.832763} , _
  {MoveTo,-0.366132,-0.625656,-0.782431},   {DrawTo, 0.366132,-0.625656,-0.782431} , _
  {MoveTo,-0.284963,-0.803384,-1.153240},   {DrawTo, -0.284963,-0.482907,-0.832763} , _
  {MoveTo,-0.284963,-0.803384,-1.153240},   {DrawTo, 0.284963,-0.803384,-1.153240} , _
  {MoveTo,-0.284963,-0.550938,-1.394082},   {DrawTo, -0.284963,-0.242065,-1.702956} , _
  {MoveTo,-0.284963,-0.482907,-1.955402},   {DrawTo, -0.284963,-0.803384,-1.634925} , _
  {DrawTo, 0.284963,-0.803384,-1.634925} , _
  {MoveTo,-0.284963,-0.803384,-1.634925},   {DrawTo, -0.284963,-0.803384,-1.153240} , _
  {MoveTo,-0.321604,-0.258690,0.690755},   {DrawTo, 0.321604,-0.258690,0.690755} , _
  {MoveTo,0.150534,-0.044357,0.919390},   {DrawTo, 0.150534,0.257788,1.221536} , _
  {DrawTo, 0.150534,0.257788,1.675669} , _
  {DrawTo, 0.150534,-0.044357,1.977815} , _
  {DrawTo, 0.150534,-0.498491,1.977815} , _
  {DrawTo, 0.150534,-0.800636,1.675669} , _
  {DrawTo, 0.150534,-0.800636,1.221536} , _
  {DrawTo, 0.150534,-0.498491,0.919390} , _
  {DrawTo, 0.150534,-0.044357,0.919390} , _
  {DrawTo, -0.150534,-0.044357,0.919390} , _
  {DrawTo, -0.150534,-0.498491,0.919390} , _
  {DrawTo, 0.150534,-0.498491,0.919390} , _
  {MoveTo,-0.150534,-0.498491,0.919390},   {DrawTo, -0.150534,-0.800636,1.221536} , _
  {DrawTo, 0.150534,-0.800636,1.221536} , _
  {MoveTo,-0.150534,-0.800636,1.221536},   {DrawTo, -0.150534,-0.800636,1.675669} , _
  {DrawTo, 0.150534,-0.800636,1.675669} , _
  {MoveTo,-0.150534,-0.800636,1.675669},   {DrawTo, -0.150534,-0.498491,1.977815} , _
  {DrawTo, 0.150534,-0.498491,1.977815} , _
  {MoveTo,-0.150534,-0.498491,1.977815},   {DrawTo, -0.150534,-0.044357,1.977815} , _
  {DrawTo, 0.150534,-0.044357,1.977815} , _
  {MoveTo,-0.150534,-0.044357,1.977815},   {DrawTo, -0.150534,0.257788,1.675669} , _
  {DrawTo, 0.150534,0.257788,1.675669} , _
  {MoveTo,-0.150534,0.257788,1.675669},   {DrawTo, -0.150534,0.257788,1.221536} , _
  {DrawTo, 0.150534,0.257788,1.221536} , _
  {MoveTo,-0.150534,0.257788,1.221536},   {DrawTo, -0.150534,-0.044357,0.919390} , _
  {MoveTo,-0.321604,0.578623,0.798109},   {DrawTo, 0.321604,0.578623,0.798109} , _
  {MoveTo,-0.217050,-0.271424,1.593080},   {DrawTo, -0.217050,-0.415902,1.448602} }
  return mysprite
endfunction
