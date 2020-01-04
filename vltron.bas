' title screen globals
control_options = { _
  "ONE PLAYER", _
  "TWO PLAYERS - ONE CONTROLLER", _
  "TWO PLAYERS - TWO CONTROLLERS", _
  "COMPUTER ONLY" _
}

view_options = { _
  "THIRD PERSON", _
  "FIRST PERSON" _
}

arena_options = { _
  "LARGE ARENA", _
  "MEDIUM ARENA", _
  "SMALL ARENA" _
}

driver_options = { _
  "NO DRIVERS", _
  "HUMANS", _
  "DUCKS" _
}

start_text={"START GAME"}
credits_text={"CREDITS"}

menu_data = { _
  start_text, _
  control_options, _
  view_options, _
  arena_options, _
  driver_options, _
  credits_text _
}

menu_status = { 1, 1, 1, 1, 1, 1 }

options_sprite = { _
  { -100, 0,    "-> START" }, _
  { -100, -20,  "   ONE PLAYER - CONTROLLER 1" }, _
  { -100, -40,  "   THIRD PERSON" }, _
  { -100, -60,  "   LARGE ARENA" }, _
  { -100, -80,  "   NO DRIVERS" }, _
  { -100, -100, "   CREDITS" } _
}
credits_sprite = { _
  { -100, 120, "VLTRON BETA 1" }, _
  { -100, 105, "g 2020 JAYMZ JULIAN" }, _
  { -100, 90,  "CODE BY JAYMZ JULIAN" }, _
  { -100, 75,  "3D MODELS BY ILKKE" }, _
  { -100, 60,  "MUSIC BY JAYMZ JULIAN" }, _
  { -100, 45,  "THANKS TO:" }, _
  { -100, 30,  " BOB ALEXANDER, FOR THE VEXTREX32 PLATFORM," }, _
  { -100, 15,  "    MASSIVE HELP AND SUPPORT IN GETTING TO"},_
  { -100, 1,  "    GRIPS WITH IT, AND FOR ADDING SEVERAL"},_
  { -100, -15,   "    FEATURES AT MY REQUEST WHICH MADE THIS"},_
  { -100, -30,  "    GAME POSSIBLE" } _
}
menu_cursor = 1
in_menu = true


' Allow for up to 1024 co-ords for each of the 4 players
dim player_x[4,1024]
dim player_y[4,1024]
dim player_direction[4]
dim x_move[4]
dim y_move[4]
lc_object = lightcycle()

release_mode = true
'release_mode = false

vx_scale_factor = 128.0
cycle_vx_scale_factor = 32.0
local_scale = 64.0 / vx_scale_factor
cycle_local_scale = 64.0 /cycle_vx_scale_factor
vx_frame_rate = 120
target_game_rate = 20
debug_status = false

' we're going to use a bitmap for the arena as well, to simplify collisions
' if you update one of these, you need to update all of them!
arena_size_x = 128
arena_size_y = 128
' map_scale is based on a 128x128 arena
map_scale = ((arena_size_x/192.0) / local_scale)
arena = ByteArray((arena_size_y+1)*(arena_size_x+1))

' define where our horizins are
' we're going to make these dynamic, eventually...
trail_view_distance_sq = 64 * 64
cycle_view_distance_sq = 64 * 64
clip_trails = false
split_screen = false

half_screen = 255 * local_scale
half_screen_scaled = 255 * cycle_local_scale
viewport_translate = {{MoveTo, 0, half_screen }}
viewport_translate_scaled = {{MoveTo, 0, half_screen_scaled }}

first_person = false
computer_only = { true, true, true, true }


x_move = { 0, 1, 0, -1 }
y_move = { 1, 0, -1, 0 }
while true

' first things first, show the menu...
call do_menu()


status_enabled = true
player_direction = { 0, 2, 1, 3 }
player_intensity = {127, 96, 64, 80 }
alive = { true, true, true, true }
floor_intensity = 48
wall_intensity = 48

if debug_status
dim status_display[5, 3]
else
dim status_display[1, 3]
endif

status_display[1,1] = -255 * local_scale
status_display[1,2] = 255 * local_scale
status_display[1,3] = "FPS: "

if debug_status
  status_display[2,1] = -255 * local_scale
  status_display[2,2] = 235 * local_scale
  status_display[2,3] = "VXTIME: "

  status_display[3,1] = -255 * local_scale
  status_display[3,2] = 215 * local_scale
  status_display[3,3] = "LAST REDRAW: "

  status_display[4,1] = -255 * local_scale
  status_display[4,2] = 195 * local_scale
  status_display[4,3] = "AI: "
  
  status_display[5,1] = -255 * local_scale
  status_display[5,2] = 175 * local_scale
  status_display[5,3] = "CLIP: "
endif

' This is where in the static array the players are
dim player_trail[4]
dim player_trail3d[4]
dim player_pos[4]

dim sprrot[4]

sprrot = {0, 270, 180, 90}
camera_position = { 0.5, 4.5, -80.5 }
split_camera = { _
  { 0.5, 4.5, -80.5 }, _
  { 0.5, 4.5, -80.5 } _
}
camera_rotation = { 0, 0, 0 }
camera_length = 20
camera_angle = -100
clippingRect = {{-255*local_scale,-255*local_scale},{255*local_scale,255*local_scale}}
cycle_clippingRect = {{-255*cycle_local_scale,-255*cycle_local_scale},{255*cycle_local_scale,255*cycle_local_scale}}

'if split_screen
'  clippingRect = {{-255*local_scale,-255*local_scale},{255*local_scale,0}}
'  cycle_clippingRect = {{-255*cycle_local_scale,-255*cycle_local_scale},{255*cycle_local_scale,0}}
'endif

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
last_controls = controls

' set up the screen and the radar box
dim cycle_sprite[4]
for p = 1 to player_count
  cycle_sprite[p] = Lines3dSprite(lc_object)
next


call drawscreen
call aps_rto()
call aps(MoveSprite(-32.0 * local_scale, -32.0 * local_scale))
call aps(IntensitySprite(127))
text = aps(TextSprite("PRESS BUTTONS 1+2 TO START"))

print "--------------------------------------------"
print "local_scale ",local_scale
print "vx_scale_factor ",vx_scale_factor
print "map_scale ",map_scale
print "map_x ", map_x
print "map_y ", map_y
print "cliprect ",clippingRect
print "--------------------------------------------"

' some state
game_started = false
overflowed = false
last_begin = 0
last_rotation = 0
max_rotation = 15
last_frame_time = 0
wait_for_frame_time = 100
rdt = 0
game_start_time = GetTickCount()
frames_played = 0
ai_time = 0
clip_time = 0
split_player = 1
while game_is_playing do
  ' 1 eor 3 = 2
  ' 2 eor 3 = 1 :)
  if split_screen
    split_player = split_player ^ 3
    if split_player = 1
      viewport_translate[1,3] = half_screen 
      viewport_translate_scaled[1,3] = half_screen_scaled
      clippingRect[1,2] = -255*local_scale
      clippingRect[2,2] = 0
      cycle_clippingRect[1,2] = -255*cycle_local_scale
      cycle_clippingRect[2,2] = 0
    else
      viewport_translate[1,3] = 0 
      viewport_translate_scaled[1,3] = 0
      clippingRect[1,2] = -255*local_scale
      clippingRect[2,2] = 0
      cycle_clippingRect[1,2] = -255*cycle_local_scale
      cycle_clippingRect[2,2] = 0
    endif
  endif

  ' show FPS before we get too far 
  ' this is at 960 hz - so we divide by 960 to get GPS
  if status_enabled
    ctick = GetTickCount()
    fps_val = 960.0 / (ctick - last_frame_time) 
    status_display[1,3] = "FPS: "+Int(fps_val) + " ("+ (ctick - last_frame_time) +"T)"
    if debug_status
      vx_pc = (wait_for_frame_time*100.0) / (ctick - last_frame_time)
      status_display[2,3] = "WAITTIME: "+Int(vx_pc)+"%"+" ("+wait_for_frame_time+"T)"
      status_display[3,3] = "LAST REDRAW: "+rdt+"T"
      status_display[4,3] = "AI: "+ai_time+"T"
      status_display[5,3] = "CLIP: "+clip_time+"T"
    endif
    last_frame_time = ctick
  endif

  require_redraw = false

  lft = GetTickCount() - last_begin


  ' draw until everything is drawn!
  overflowed = true
  broken = false
  while overflowed = true 
    overflowed = false
    f = GetTickCount()
    ' if we have an error, lets let the error happen this loop
    if broken = false or release_mode = true
      on error call sprite_overflow
    endif
    broken = false
    controls = WaitForFrame(JoystickDigital, Controller1, JoystickX + JoystickY)
    on error call 0
    wait_for_frame_time = GetTickCount()-f
    if wait_for_frame_time > 100
      print "Drawscreen took ",wait_for_frame_time," lastov: ",overflowed
    endif
    last_begin = GetTickCount()

    ' if we are in release mode, and we got a broken draw list item, lets
    ' just try disabling that item!
    if release_mode and broken
      end_sprite = GetCompiledSpriteCount()
      print "Disabling broken sprite ",end_sprite+1
      call SpriteEnable(all_sprites[end_sprite+1], false)
    endif
  
    if overflowed = true ' and broken = false
      ' if we _did_ overflow, disable all of the sprites we draw, and call
      ' draw again to put them on the screen next frame!
      end_sprite = GetCompiledSpriteCount()

      'print "Disabling ",end_sprite," most recently drawn sprites so remaining can draw next remianing frame, hopefully"
    
      ' this should never happen, but just in case!
      if end_sprite > total_objects
        end_sprite = total_objects
      endif

      ' we have to align to return_to_origins here - otherwise
      ' we'll get pen drift.  To do this, we'll move _BOTH_ start sprite and
      ' end sprite back, on the grounds that if we half drew something, we should give it a 
      ' second chance to draw here!
      '
      ' for end sprite, we want to stop one shy of the return to origin - we want
      ' the RTO to be executed!
      while all_origins[end_sprite+1] = false  and end_sprite > 1
        end_sprite = end_sprite - 1
      endwhile

      'print all_origins[end_sprite]
      'print all_origins[end_sprite+1]
      'print "starting at sprite",end_sprite

      ' skip sprites 1 and 2, since they are our scale and the first RTO
      for sp = 3 to end_sprite
        call SpriteEnable(all_sprites[sp], false)
      next
    endif
  endwhile

  ' re-enable _after_ the loop, so clipping works!
  for sp = 1 to total_objects
    call SpriteEnable(all_sprites[sp], true)
  next


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
  run_count = 0
  while target_frames > frames_played
  ' process!
  frames_played = frames_played + 1
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

      if first_person = false or p != split_player
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
    if first_person = false or p != split_player
      call SpriteTranslate(cycle_sprite[p], {player_x[p, player_pos[p]] - arena_size_x/2, 1, player_y[p, player_pos[p]] - arena_size_y/2})
      call SpriteSetRotation(cycle_sprite[p], 0, 0, sprrot[player_direction[p]+1])
    else
      call SpriteEnable(cycle_sprite[p], false)
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
  
  if run_count > 0
    last_controls = controls
  endif

  ' if we're not playing yet, wait until we are!
  if game_started = false
    if controls[1, 4] = 1 and controls[1,3] = 1
      game_started = true
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
      

    p = split_player
    camera_position[1] = player_x[p, player_pos[p]] - arena_size_x/2
    camera_position[2] = 1
    camera_position[3] = player_y[p, player_pos[p]] - arena_size_y/2
    call cameraSetRotation(0, 0, last_rotation)
  else
    ' look at the player
    target_x = player_x[split_player, player_pos[split_player]] - arena_size_x/2
    target_y = 1
    target_z = player_y[split_player, player_pos[split_player]] - arena_size_y/2
    ' degrees to radians
    angle = ((sprrot[player_direction[split_player]+1]+camera_angle)mod 360)  / 57.2958
    sa = sin(angle)
    ca = cos(angle)

    wanted_x = (target_x - (ca*camera_length - sa*camera_length )) + 0.5
    wanted_z = (target_z + (sa*camera_length + ca*camera_length )) + 0.5
    if abs(split_camera[split_player,1] - wanted_x) < camera_step
      split_camera[split_player,1] = wanted_x
    else
      if split_camera[split_player,1] > wanted_x
        split_camera[split_player,1] = split_camera[split_player,1] - camera_step
      else
        split_camera[split_player,1] = split_camera[split_player,1] + camera_step
      endif
    endif
    if abs(split_camera[split_player,3] - wanted_z) < camera_step
      split_camera[split_player,3] = wanted_z
    else
      if split_camera[split_player,3] > wanted_z
        split_camera[split_player,3] = split_camera[split_player,3] - camera_step
      else
        split_camera[split_player,3] = split_camera[split_player,3] + camera_step
      endif
    endif

    camera_position[1] = split_camera[split_player,1]
    camera_position[2] = split_camera[split_player,2]
    camera_position[3] = split_camera[split_player,3]
    
    ' do this _after_ having moved the camear
    lvx = split_camera[split_player,1] - target_x
    lvy = split_camera[split_player,2] - target_y
    lvz = split_camera[split_player,3] - target_z
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
  
  ' finally, clip things that are more than
  ' n units away from the camera.  this might be terrible to do, but my inclination is that it makes sense!
  ctick = GetTickCount()
  for p = 1 to player_count
    ' this should be really just taken from the thing - need to switch to live data....
    player_loc = {player_x[p, player_pos[p]] - arena_size_x/2, 1, player_y[p, player_pos[p]] - arena_size_y/2}
    ' do a matrix sub 
    dist_v = player_loc - camera_position
    ' get dist^2
    dist = dist_v[1] * dist_v[1] + dist_v[3] * dist_v[3]
    ' just do the thing with sq co-orders
    ' this might be terrible to do, since 
    if dist > cycle_view_distance_sq
      call SpriteEnable(cycle_sprite[p], false)
    else
      call SpriteEnable(cycle_sprite[p], true)
    endif

    ' FIXME: disable the drivers if further - do this once i add the drivers...

    if clip_trails
      ' now do the trails - we don't spritedisable those, since it would not make sense.... what we do instead,
      ' is turn DrawTo into MoveTo, and disable the lines that way.  What this _can_ mean, is we disable longer lines
      ' so we'll need to consider _both_ ends of the line we're drawing.

      ' preload the first cached entry
      dist_v_a = {player_trail3d[p][1, 2], 0, player_trail3d[p][1, 4]} - camera_position
      dist_a =  dist_v_a[1] * dist_v_a[1] + dist_v_a[3] * dist_v_a[3]

      for ele = 2 to Ubound(player_trail3d[p])
        ' this is from the last round, as a perf hack
        dist_b = dist_a
        ' and now our new round
        dist_v_a = {player_trail3d[p][ele, 2], 0, player_trail3d[p][ele, 4]} - camera_position
        dist_a = dist_v_a[1] * dist_v_a[1] + dist_v_a[3] * dist_v_a[3]
        ' FIXME: also check sign, so a long line going through our viewport does not
        ' get clipped - another obvious answer is tesselate those large lines, however
        ' if we do this, we start overflowing DP ram - but maybe a tesselation of, say, 
        ' 32 might be okay..... i'll have to experiment and see!
        if (dist_a > trail_view_distance_sq) and (dist_b > trail_view_distance_sq)
          player_trail3d[p][ele, 1] = MoveTo
        else
          player_trail3d[p][ele, 1] = DrawTo
        endif
      next
    endif
  next
  clip_time = GetTickCount() - ctick
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
  overflowed = true
  e = GetLastError()
  if e[1] != 521
    if release_mode = false
      print "FATAL: ",e
      broken = true
    else
      print "WARNING: ",e," continuing since release_mode is on"
      broken = true
    endif
  endif
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
    if split_screen
      call aps(LinesSprite(viewport_translate))
    endif
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
      if split_screen
        call aps(LinesSprite(viewport_translate_scaled))
      endif
      call aps(IntensitySprite(player_intensity[p]))
      cycle_sprite[p] = aps(Lines3dSprite(lc_object))
      call SpriteClip(cycle_sprite[p], cycle_clippingRect)
    endif
    endif
  next
  ' why is this here?  because without it, we get the x or y co-ordinate is too large issue
  ' we used to have this lower, but it caused other problems.... and with the new sprite code, this
  ' SHOULD be fine!
  call aps_rto()
  call aps(ScaleSprite(vx_scale_factor, (162 / 0.097) * local_scale))
  call aps(IntensitySprite(127))
  
  if split_screen
    call aps(LinesSprite(viewport_translate))
  endif
  call aps(IntensitySprite(floor_intensity))
  sprb = aps(Lines3dSprite(floor_b))
  call SpriteClip(sprb, clippingRect)

  ' and the vertical ones
  call aps_rto()
  if split_screen
    call aps(LinesSprite(viewport_translate))
  endif
  sprc = aps(Lines3dSprite(floor_c))
  call SpriteClip(sprc, clippingRect)

endsub


'--------------------------------------------------------------
' The 3d model of the lightcycle
'-------------------------------------------------------------
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


' -------------------------------------------------------------------------
' Main Menu Functions
' -------------------------------------------------------------------------
sub title_picture()
  call clearscreen()
  call ReturnToOriginSprite()
  ' display a SVG title screen first
  call ScaleSprite(32)
  call IntensitySprite(64)
  call MoveSprite(0, 128)
  call LinesSprite(logo())
endsub

sub do_credits()
  call title_picture()
  call ReturnToOriginSprite()
  call IntensitySprite(127)
  call TextListSprite(credits_sprite)
  controls = WaitForFrame(JoystickDigital, Controller1, JoystickY)
  last_controls = controls
  while controls[1,3] = 0 or last_controls[1,3] = controls[1,3]
    last_controls = controls
    controls = WaitForFrame(JoystickDigital, Controller1, JoystickY)
  endwhile
endsub

sub do_menu()
  in_menu = true
  controls = WaitForFrame(JoystickDigital, Controller1, JoystickY)
  while in_menu
    call title_picture()
    call ReturnToOriginSprite()
    call IntensitySprite(127)
    call TextListSprite(options_sprite)
    last_controls = controls
    controls = WaitForFrame(JoystickDigital, Controller1, JoystickY)
    if controls[1,2] != last_controls[1, 2]
      ' dear gce, i hate the way everything on this console is upside down
      ' love as always, jaymz
      if controls[1,2] < 0
        menu_cursor = menu_cursor + 1
      endif
      if controls[1,2] > 0
        menu_cursor = menu_cursor - 1
      endif
      if menu_cursor < 1
        menu_cursor = Ubound(menu_data)
      endif
      if menu_cursor > Ubound(menu_data)
        menu_cursor = 1
      endif
    endif
    ' activate an option
    if controls[1, 3] != last_controls[1,3] and controls[1,3] = 1
      menu_status[menu_cursor] = menu_status[menu_cursor] + 1
      if menu_status[menu_cursor] > Ubound(menu_data[menu_cursor])
        menu_status[menu_cursor] = 1
      endif

      call menu_activate(menu_cursor, false)
      ' debounce!
      controls = WaitForFrame(JoystickDigital, Controller1, JoystickY)
      last_controls = controls
    endif
    call update_menu()
  endwhile
  ' activate evertything just in case
  for j = 1 to Ubound(menu_data)
    call menu_activate(j, true)
  next
endsub

' actually activate the menu options....
' this code is terrible.  i really need to make some "generic" support for this
' sometime before my next game....
sub menu_activate(j, on_exit)
  if menu_data[j][menu_status[j]] = "START GAME" and on_exit = false
    in_menu = false
  endif
  if menu_data[j][menu_status[j]] = "CREDITS" and on_exit = false
    call do_credits()
  endif
  if menu_data[j][menu_status[j]] = "ONE PLAYER"
    computer_only = { false, true, true, true }
  endif
  if menu_data[j][menu_status[j]] = "COMPUTER ONLY"
    computer_only = { true, true, true, true }
  endif
endsub

sub update_menu()
  for j = 1 to Ubound(menu_data)
    cursor_text = "   "
    if menu_cursor = j
      cursor_text = "-> "
    endif
    options_sprite[j, 3] = cursor_text + menu_data[j][menu_status[j]]
  next
endsub

'--------------------------------
'a logo
'-------------------------------
' final acceptable error: 3.8
' final angle tollerance: 0.2562890625
' final command count: 256
function  logo()
  mysprite = { _
    { MoveTo , -4.30233320906 , 221.272938517 }, _
    { DrawTo , -0.298090497796 , 225.679912148 }, _
    { DrawTo , -0.298090497796 , 294.797570021 }, _
    { DrawTo , -4.50337783355 , 298.63268167 }, _
    { DrawTo , -33.4285332247 , 298.63268167 }, _
    { DrawTo , -37.2023186367 , 294.796179898 }, _
    { DrawTo , -37.2023186367 , 225.012204274 }, _
    { DrawTo , -33.0186702116 , 221.272938517 }, _
    { DrawTo , -4.30233320906 , 221.272938517 }, _
    { MoveTo , -6.50317866257 , 227.061801067 }, _
    { DrawTo , -30.6940826764 , 226.965426099 }, _
    { DrawTo , -30.6940826764 , 293.190255489 }, _
    { DrawTo , -6.45215608365 , 293.168729325 }, _
    { DrawTo , -6.50317866257 , 227.061801067 }, _
    { MoveTo , 7.27726863231 , 271.174566365 }, _
    { DrawTo , 6.64628843949 , 294.797251019 }, _
    { DrawTo , 10.7325037534 , 298.584385259 }, _
    { DrawTo , 100.520814053 , 298.584385259 }, _
    { DrawTo , 95.9073831233 , 284.898202452 }, _
    { DrawTo , 80.5430331684 , 270.273205745 }, _
    { DrawTo , 60.0469430297 , 265.147642603 }, _
    { DrawTo , 99.5788542873 , 227.292260691 }, _
    { DrawTo , 99.5788542873 , 221.307421874 }, _
    { DrawTo , 58.8745549713 , 221.307421874 }, _
    { DrawTo , 7.27726863231 , 271.174566365 }, _
    { MoveTo , 12.7663293039 , 274.138929143 }, _
    { DrawTo , 12.7663293039 , 293.25172695 }, _
    { DrawTo , 92.9964194886 , 293.273253113 }, _
    { DrawTo , 82.833077806 , 278.79076801 }, _
    { DrawTo , 66.5392109708 , 271.365121893 }, _
    { DrawTo , 59.1143233837 , 270.704336403 }, _
    { DrawTo , 44.8156734894 , 270.704336403 }, _
    { DrawTo , 90.9966186596 , 227.061588398 }, _
    { DrawTo , 61.898259162 , 227.061801067 }, _
    { DrawTo , 12.7663293039 , 274.138929143 }, _
    { MoveTo , 59.007057041 , 336.785749674 }, _
    { DrawTo , 75.6824186004 , 333.051777607 }, _
    { DrawTo , 89.1439171429 , 321.820776617 }, _
    { DrawTo , 92.9154331098 , 314.656653979 }, _
    { DrawTo , -80.2621555116 , 314.621340697 }, _
    { DrawTo , -84.884919898 , 313.575427286 }, _
    { DrawTo , -89.0925735365 , 309.997886228 }, _
    { DrawTo , -90.7282236508 , 304.814565281 }, _
    { DrawTo , -90.7728937881 , 227.06587029 }, _
    { DrawTo , -114.963774597 , 226.969495322 }, _
    { DrawTo , -114.97537723 , 306.602331307 }, _
    { DrawTo , -110.770296124 , 321.651569024 }, _
    { DrawTo , -98.375896026 , 333.040701821 }, _
    { DrawTo , -82.1032033136 , 336.79638308 }, _
    { DrawTo , 59.007057041 , 336.785749674 }, _
    { MoveTo , 59.0694502003 , 342.391515346 }, _
    { DrawTo , 72.469202759 , 340.309895754 }, _
    { DrawTo , 91.0292980008 , 328.460399898 }, _
    { DrawTo , 100.418536842 , 309.04610068 }, _
    { DrawTo , -79.6560629667 , 309.067626844 }, _
    { DrawTo , -84.5670224456 , 225.683960623 }, _
    { DrawTo , -88.3469862597 , 221.487419503 }, _
    { DrawTo , -117.064895419 , 221.487419503 }, _
    { DrawTo , -121.472793735 , 225.016252749 }, _
    { DrawTo , -121.481495709 , 306.235629223 }, _
    { DrawTo , -117.361361284 , 322.776714067 }, _
    { DrawTo , -103.337012326 , 337.048792307 }, _
    { DrawTo , -82.0253206392 , 342.39995464 }, _
    { DrawTo , 59.0648091471 , 342.392692801 }, _
    { MoveTo , 101.235333204 , 282.04089326 }, _
    { DrawTo , 109.861582626 , 312.096185087 }, _
    { DrawTo , 135.518806218 , 335.477932201 }, _
    { DrawTo , 168.498465705 , 343.339047783 }, _
    { DrawTo , 198.511270456 , 336.914360649 }, _
    { DrawTo , 225.41807203 , 314.718462611 }, _
    { DrawTo , 235.762004298 , 282.04089326 }, _
    { DrawTo , 226.824401317 , 251.489823149 }, _
    { DrawTo , 201.217954686 , 228.470774764 }, _
    { DrawTo , 168.499422922 , 220.742414548 }, _
    { DrawTo , 138.729579945 , 227.058067101 }, _
    { DrawTo , 111.901514465 , 248.906187342 }, _
    { DrawTo , 101.244035179 , 281.139193397 }, _
    { MoveTo , 107.437346671 , 282.04089326 }, _
    { DrawTo , 115.268315652 , 309.290045417 }, _
    { DrawTo , 138.559924191 , 330.489449237 }, _
    { DrawTo , 168.498465705 , 337.617009706 }, _
    { DrawTo , 195.743467889 , 331.791830074 }, _
    { DrawTo , 220.169552105 , 311.667540766 }, _
    { DrawTo , 229.559526725 , 282.04089326 }, _
    { DrawTo , 221.728897069 , 254.792153867 }, _
    { DrawTo , 198.43767573 , 233.593488987 }, _
    { DrawTo , 168.498465705 , 226.466273272 }, _
    { DrawTo , 141.254126058 , 232.291166362 }, _
    { DrawTo , 116.827712669 , 252.414723262 }, _
    { DrawTo , 107.437346671 , 282.04089326 }, _
    { MoveTo , 132.614857382 , 282.05042183 }, _
    { DrawTo , 137.216333775 , 298.084703311 }, _
    { DrawTo , 150.903431294 , 310.559776916 }, _
    { DrawTo , 168.498320672 , 314.754237524 }, _
    { DrawTo , 184.509222617 , 311.326200621 }, _
    { DrawTo , 198.863600631 , 299.483743736 }, _
    { DrawTo , 204.381783961 , 282.05042183 }, _
    { DrawTo , 199.779976326 , 266.017542511 }, _
    { DrawTo , 186.092514441 , 253.543649705 }, _
    { DrawTo , 168.498320672 , 249.349606831 }, _
    { DrawTo , 152.486731636 , 252.7773013 }, _
    { DrawTo , 138.132658995 , 264.618630609 }, _
    { DrawTo , 132.614857382 , 282.05042183 }, _
    { MoveTo , 138.860554763 , 282.050637091 }, _
    { DrawTo , 142.661696299 , 295.279694638 }, _
    { DrawTo , 153.967209047 , 305.570988473 }, _
    { DrawTo , 168.498697757 , 309.030915658 }, _
    { DrawTo , 181.723138797 , 306.203210407 }, _
    { DrawTo , 193.579149739 , 296.433885018 }, _
    { DrawTo , 198.136840752 , 282.050637091 }, _
    { DrawTo , 194.010468572 , 268.313148228 }, _
    { DrawTo , 182.759690029 , 258.398320872 }, _
    { DrawTo , 168.498320672 , 255.076035726 }, _
    { DrawTo , 154.242835037 , 258.396933121 }, _
    { DrawTo , 142.993183246 , 268.30602882 }, _
    { DrawTo , 138.880859371 , 281.106102756 }, _
    { MoveTo , 141.784331276 , 238.761823303 }, _
    { DrawTo , 210.905074338 , 256.870972818 }, _
    { DrawTo , 217.82475878 , 256.468885915 }, _
    { DrawTo , 224.017050554 , 252.828787469 }, _
    { DrawTo , 227.198476503 , 246.811090468 }, _
    { DrawTo , 226.137156063 , 239.474935821 }, _
    { DrawTo , 190.942222026 , 185.862643483 }, _
    { DrawTo , 179.768779052 , 172.850814092 }, _
    { DrawTo , 209.145506027 , 164.126561068 }, _
    { DrawTo , 236.633180716 , 166.541408628 }, _
    { DrawTo , 274.695770814 , 166.194136097 }, _
    { DrawTo , 278.559118767 , 165.164592873 }, _
    { DrawTo , 283.127329939 , 155.802850918 }, _
    { DrawTo , 278.992283852 , 145.601793208 }, _
    { DrawTo , 228.901164319 , 96.117811832 }, _
    { DrawTo , 216.93556362 , 87.4853295592 }, _
    { DrawTo , 238.299297104 , 99.1910995898 }, _
    { DrawTo , 291.385143252 , 151.829182609 }, _
    { DrawTo , 294.706624366 , 158.603650632 }, _
    { DrawTo , 295.175693506 , 162.301069873 }, _
    { DrawTo , 294.206524641 , 167.52107291 }, _
    { DrawTo , 290.276396107 , 172.093917712 }, _
    { DrawTo , 284.256833574 , 173.733506256 }, _
    { DrawTo , 216.012495401 , 171.067400143 }, _
    { DrawTo , 198.844840972 , 170.346004371 }, _
    { DrawTo , 225.729642583 , 220.457768643 }, _
    { DrawTo , 235.584177798 , 238.392905201 }, _
    { DrawTo , 237.31002902 , 243.1308197 }, _
    { DrawTo , 237.923864904 , 256.697484908 }, _
    { DrawTo , 213.276449491 , 263.791777 }, _
    { DrawTo , 121.657127667 , 233.769068301 }, _
    { DrawTo , 110.441616451 , 225.28678216 }, _
    { DrawTo , 141.784331276 , 238.761823303 }, _
    { MoveTo , 240.573152126 , 225.225206958 }, _
    { DrawTo , 244.497017596 , 221.31320541 }, _
    { DrawTo , 272.695157801 , 221.31320541 }, _
    { DrawTo , 276.863403731 , 225.685371494 }, _
    { DrawTo , 276.863403731 , 271.482237485 }, _
    { DrawTo , 303.346413708 , 271.482237485 }, _
    { DrawTo , 306.778356543 , 292.194639308 }, _
    { DrawTo , 259.732899183 , 342.227239597 }, _
    { DrawTo , 244.530984305 , 342.227239597 }, _
    { DrawTo , 240.573152126 , 338.681058338 }, _
    { DrawTo , 240.573152126 , 225.225206958 }, _
    { MoveTo , 246.759734091 , 227.296648916 }, _
    { DrawTo , 246.826449231 , 336.955085368 }, _
    { DrawTo , 257.374460966 , 336.955085368 }, _
    { DrawTo , 301.266438685 , 290.354082311 }, _
    { DrawTo , 301.261507566 , 276.545349326 }, _
    { DrawTo , 270.978461219 , 276.545349326 }, _
    { DrawTo , 270.978461219 , 227.296648916 }, _
    { DrawTo , 246.759734091 , 227.296648916 }, _
    { MoveTo , 264.384510807 , 261.398848276 }, _
    { DrawTo , 275.464503268 , 269.985759352 }, _
    { DrawTo , 304.13884454 , 281.931981248 }, _
    { DrawTo , 311.56455871 , 284.232811708 }, _
    { DrawTo , 335.639210142 , 282.090903984 }, _
    { DrawTo , 339.867069165 , 275.77550336 }, _
    { DrawTo , 341.434406287 , 270.153891656 }, _
    { DrawTo , 341.56348558 , 260.921117872 }, _
    { DrawTo , 336.439356725 , 238.530723081 }, _
    { DrawTo , 323.366525014 , 204.325815393 }, _
    { DrawTo , 313.967376999 , 178.304859377 }, _
    { DrawTo , 312.677570294 , 167.002689917 }, _
    { DrawTo , 314.193947416 , 162.99397365 }, _
    { DrawTo , 317.164366515 , 160.010239919 }, _
    { DrawTo , 323.447206406 , 157.935722138 }, _
    { DrawTo , 327.855238019 , 157.619086248 }, _
    { DrawTo , 352.900563384 , 161.02191773 }, _
    { DrawTo , 384.0 , 169.968969301 }, _
    { DrawTo , 373.159833964 , 161.916550268 }, _
    { DrawTo , 342.685170132 , 153.559652732 }, _
    { DrawTo , 317.404221947 , 150.233860484 }, _
    { DrawTo , 305.50627286 , 153.198116927 }, _
    { DrawTo , 302.276534913 , 156.654129496 }, _
    { DrawTo , 300.673660161 , 161.131675228 }, _
    { DrawTo , 302.249703824 , 172.973373336 }, _
    { DrawTo , 312.303240345 , 199.400862619 }, _
    { DrawTo , 325.46779087 , 233.501129811 }, _
    { DrawTo , 330.230613731 , 255.336157366 }, _
    { DrawTo , 329.935558772 , 264.108333498 }, _
    { DrawTo , 324.336099047 , 275.039342624 }, _
    { DrawTo , 318.883944506 , 277.83689289 }, _
    { DrawTo , 311.168688704 , 278.316543074 }, _
    { DrawTo , 301.260985447 , 276.546742042 }, _
    { DrawTo , 293.94694662 , 274.246017916 }, _
    { DrawTo , 264.384510807 , 261.398848276 }, _
    { MoveTo , 310.222772209 , 271.245675323 }, _
    { DrawTo , 357.302283297 , 221.307421874 }, _
    { DrawTo , 372.504111156 , 221.307421874 }, _
    { DrawTo , 376.42794762 , 224.759256293 }, _
    { DrawTo , 376.42794762 , 338.215107673 }, _
    { DrawTo , 372.504111156 , 342.45941094 }, _
    { DrawTo , 344.305854925 , 342.45941094 }, _
    { DrawTo , 340.137696016 , 337.754943137 }, _
    { DrawTo , 340.137696016 , 291.958077146 }, _
    { DrawTo , 313.654686038 , 291.958077146 }, _
    { DrawTo , 310.222772209 , 271.245675323 }, _
    { MoveTo , 315.617358441 , 273.087731371 }, _
    { DrawTo , 315.617358441 , 286.894965306 }, _
    { DrawTo , 346.022638527 , 286.894965306 }, _
    { DrawTo , 346.123001303 , 337.052323976 }, _
    { DrawTo , 370.197884788 , 337.052323976 }, _
    { DrawTo , 370.179465608 , 226.945287465 }, _
    { DrawTo , 359.631482879 , 226.945287465 }, _
    { DrawTo , 315.617358441 , 273.087731371 }, _
    { MoveTo , -128.55129911 , 312.6014941 }, _
    { DrawTo , -128.55129911 , 338.993867208 }, _
    { DrawTo , -132.456571361 , 342.335381336 }, _
    { DrawTo , -176.266518464 , 342.335381336 }, _
    { DrawTo , -179.944408114 , 338.990957286 }, _
    { DrawTo , -179.944408114 , 312.295218291 }, _
    { DrawTo , -176.12421217 , 309.397895248 }, _
    { DrawTo , -132.396237669 , 309.397895248 }, _
    { DrawTo , -128.55129911 , 312.6014941 }, _
    { MoveTo , -135.399811292 , 314.749828551 }, _
    { DrawTo , -173.570733691 , 314.749828551 }, _
    { DrawTo , -173.570733691 , 336.84264099 }, _
    { DrawTo , -135.399811292 , 336.84264099 }, _
    { DrawTo , -135.399811292 , 314.749828551 }, _
    { MoveTo , -164.474182346 , 299.93596897 }, _
    { DrawTo , -191.288853589 , 299.93596897 }, _
    { DrawTo , -216.838924849 , 274.180479825 }, _
    { DrawTo , -202.012210117 , 299.937040091 }, _
    { DrawTo , -262.929337574 , 299.937040091 }, _
    { DrawTo , -230.11401946 , 261.736718268 }, _
    { DrawTo , -262.929337574 , 223.534466871 }, _
    { DrawTo , -236.11470984 , 223.534466871 }, _
    { DrawTo , -210.564597971 , 249.288884895 }, _
    { DrawTo , -225.391312703 , 223.530397649 }, _
    { DrawTo , -164.474182346 , 223.530397649 }, _
    { DrawTo , -197.28950336 , 261.73468236 }, _
    { DrawTo , -164.474182346 , 299.93596897 }, _
    { MoveTo , -243.591771462 , 338.994723068 }, _
    { DrawTo , -272.887538449 , 338.994723068 }, _
    { DrawTo , -317.761528223 , 271.250922001 }, _
    { DrawTo , -282.810580156 , 338.993545613 }, _
    { DrawTo , -384.0 , 338.993545613 }, _
    { DrawTo , -313.796270359 , 220.497286011 }, _
    { DrawTo , -243.591771462 , 338.994723068 } _
  }
  return mysprite
endfunction

