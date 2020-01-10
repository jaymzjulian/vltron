' title screen globals
control_options = { _
  "ONE PLAYER", _
  "TWO PLAYERS - ONE CONTROLLER", _
  "TWO PLAYERS - TWO CONTROLLERS", _
  "COMPUTER ONLY" _
}

view_options = { _
  "THIRD PERSON", _
  "FIRST PERSON", _
  "THIRD PERSON SPLIT", _
  "FIRST PERSON SPLIT" _
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

status_text = { _
  "NO STATUS", _
  "FPS ONLY", _
  "DEBUG" _
}

start_text={"START GAME"}
credits_text={"CREDITS"}

menu_data = { _
  start_text, _
  control_options, _
  view_options, _
  arena_options, _
  driver_options, _
  credits_text, _
  status_text _
}

menu_status = { 1, 1, 1, 1, 1, 1, 1 }

options_sprite = { _
  { -100, 0,    "-> START" }, _
  { -100, -20,  "   ONE PLAYER - CONTROLLER 1" }, _
  { -100, -40,  "   THIRD PERSON" }, _
  { -100, -60,  "   LARGE ARENA" }, _
  { -100, -80,  "   NO DRIVERS" }, _
  { -100, -100, "   CREDITS" }, _
  { -100, -120, "   NO STATUS" } _
}
credits_sprite = { _
  { -100, 90, "VLTRON BETA 1" }, _
  { -100, 75, "g 2020 JAYMZ JULIAN" }, _
  { -100, 60,  "CODE BY JAYMZ JULIAN" }, _
  { -100, 45,  "3D MODELS BY ILKKE" }, _
  { -100, 30,  "MUSIC BY JAYMZ JULIAN" }, _
  { -100, 15,  "THANKS TO:" }, _
  { -100, 1,  " BOB ALEXANDER, FOR THE VEXTREX32 PLATFORM," }, _
  { -100, -15,  "    MASSIVE HELP AND SUPPORT IN GETTING TO"},_
  { -100, -30,  "    GRIPS WITH IT, AND FOR ADDING SEVERAL"},_
  { -100, -45,   "    FEATURES AT MY REQUEST WHICH MADE THIS"},_
  { -100, -60,  "    GAME POSSIBLE" } _
}
menu_cursor = 1
tfc = 0
menu_zoom = 1
in_menu = true
demo_mode = false
max_demo_frames = 300


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
clipping = true

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

' FIXME: we're going to change this to a countdown... but still we'll init this countdown here
if demo_mode = false
  call aps_rto()
  call aps(MoveSprite(-32.0 * local_scale, -32.0 * local_scale))
  call aps(IntensitySprite(127))
  text = aps(TextSprite("PRESS BUTTONS 1+2 TO START"))
else
  game_is_playing = true
endif
demo_frames = 0

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

  ' quit demo mode on button press
  if demo_mode = true
    if controls[1, 4] = 1 or controls[1,3] = 1 or demo_frames > max_demo_frames
      game_is_playing = false
    endif
    demo_frames = demo_frames + 1
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
  if clipping
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
  endif
  clip_time = GetTickCount() - ctick
endwhile

if demo_mode = false
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
endif

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
  ' zoom this in, too, so it looks cool!
  call ScaleSprite(menu_zoom)
  menu_zoom = menu_zoom + 2
  if menu_zoom > 32
    menu_zoom = 32
  endif
  call IntensitySprite(64)
  call logo()
  call IntensitySprite(48)
  call ReturnToOriginSprite()
  call ScaleSprite(64)
  call bg(tfc)
  call ScaleSprite(32)
  tfc=tfc+1
  tfc = tfc mod 3
endsub

sub do_credits()
  controls = WaitForFrame(JoystickDigital, Controller1, JoystickY)
  last_controls = controls
  while controls[1,3] = 0 or last_controls[1,3] = controls[1,3]
  call title_picture()
  call ReturnToOriginSprite()
  call IntensitySprite(127)
  call TextListSprite(credits_sprite)
    last_controls = controls
    controls = WaitForFrame(JoystickDigital, Controller1, JoystickY)
  endwhile
endsub

sub do_menu()
  menu_zoom = 1
  in_menu = true
  controls = WaitForFrame(JoystickDigital, Controller1, JoystickY)
  no_input_frames = 0
  demo_mode = false
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
      no_input_frames = 0
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
      no_input_frames = 0
    endif
    no_input_frames += 1
    call update_menu()
    ' after 60s with no input, demo mode
    if no_input_frames > 60*20
      demo_mode = true
      computer_only = { true, true, true, true }
      return
    endif
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
  if menu_data[j][menu_status[j]] = "THIRD PERSON" or menu_data[j][menu_status[j]] = "THIRD PERSON SPLIT"
    first_person = false
  endif
  if menu_data[j][menu_status[j]] = "FIRST PERSON" or menu_data[j][menu_status[j]] = "FIRST PERSON SPLIT"
    first_person = true
  endif
  if menu_data[j][menu_status[j]] = "FIRST PERSON SPLIT" or menu_data[j][menu_status[j]] = "THIRD PERSON SPLIT"
    split_screen = true
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
' final acceptable error: 4.9
' final angle tollerance: 0.2562890625
' final command count: 256
sub  logo()
  call LinesSprite({ _
    { MoveTo , -4.30233320906 , 413.272938517 }, _
    { DrawTo , -0.298090497796 , 417.679912148 }, _
    { DrawTo , -0.298090497796 , 486.797570021 }, _
    { DrawTo , -4.50337783355 , 490.63268167 }, _
    { DrawTo , -33.4285332247 , 490.63268167 }, _
    { DrawTo , -37.2023186367 , 486.796179898 }, _
    { DrawTo , -37.2023186367 , 417.012204274 }, _
    { DrawTo , -33.0186702116 , 413.272938517 }, _
    { DrawTo , -4.30233320906 , 413.272938517 }, _
    { MoveTo , -6.50317866257 , 419.061801067 }, _
    { DrawTo , -30.6940826764 , 418.965426099 }, _
    { DrawTo , -30.6940826764 , 485.190255489 }, _
    { DrawTo , -6.45215608365 , 485.168729325 }, _
    { DrawTo , -6.50317866257 , 419.061801067 }, _
    { MoveTo , 6.64628850127 , 465.318509773 }, _
    { DrawTo , 6.64628843949 , 486.797251019 }, _
    { DrawTo , 10.7325037534 , 490.584385259 }, _
    { DrawTo , 100.520814053 , 490.584385259 }, _
    { DrawTo , 93.9870929603 , 473.916599889 }, _
    { DrawTo , 78.8919309362 , 461.445857106 }, _
    { DrawTo , 59.0663174894 , 457.127296488 }, _
    { DrawTo , 99.5788542873 , 419.292260691 }, _
    { DrawTo , 99.5788542873 , 413.307421874 }, _
    { DrawTo , 58.8745549713 , 413.307421874 }, _
    { DrawTo , 7.27726863231 , 463.174566365 }, _
    { MoveTo , 12.7663293039 , 466.138929143 }, _
    { DrawTo , 12.7663293039 , 485.25172695 }, _
    { DrawTo , 92.9964194886 , 485.273253113 }, _
    { DrawTo , 81.7687908414 , 469.949986265 }, _
    { DrawTo , 65.0961793614 , 463.129052406 }, _
    { DrawTo , 59.1143233837 , 462.704336403 }, _
    { DrawTo , 44.8156734894 , 462.704336403 }, _
    { DrawTo , 90.9966186596 , 419.061801067 }, _
    { DrawTo , 61.898259162 , 419.061801067 }, _
    { DrawTo , 12.7663293039 , 466.138929143 }, _
    { MoveTo , 59.007057041 , 528.785749674 }, _
    { DrawTo , 76.9243868276 , 524.429341829 }, _
    { DrawTo , 89.8959611743 , 512.702927859 }, _
    { DrawTo , 92.9154331098 , 506.656653979 }, _
    { DrawTo , -80.2621555116 , 506.621340697 }, _
    { DrawTo , -85.3461319244 , 505.342397527 }, _
    { DrawTo , -89.3633118977 , 501.578260228 }, _
    { DrawTo , -90.7282236508 , 496.814565281 }, _
    { DrawTo , -90.7728937881 , 419.06587029 }, _
    { DrawTo , -114.963774597 , 418.969495322 }, _
    { DrawTo , -114.97537723 , 498.602331307 }, _
    { DrawTo , -109.945078909 , 514.942687354 }, _
    { DrawTo , -96.9289955408 , 525.730608417 }, _
    { DrawTo , -82.1032033136 , 528.79638308 }, _
    { DrawTo , 59.007057041 , 528.785749674 }, _
    { MoveTo , 59.0694502003 , 534.391515346 }, _
    { DrawTo , 74.2641601862 , 531.69342092 }, _
    { DrawTo , 92.2196585186 , 519.08509918 }, _
    { DrawTo , 100.418536842 , 501.04610068 }, _
    { DrawTo , -83.3288333368 , 498.588789167 }, _
    { DrawTo , -84.5670224456 , 417.683960623 }, _
    { DrawTo , -88.3469862597 , 413.487419503 }, _
    { DrawTo , -117.064895419 , 413.487419503 }, _
    { DrawTo , -121.472793735 , 417.016252749 }, _
    { DrawTo , -121.481495709 , 498.235629223 }, _
    { DrawTo , -115.47874704 , 517.920121087 }, _
    { DrawTo , -101.65912438 , 529.941990456 }, _
    { DrawTo , -82.0253206392 , 534.39995464 }, _
    { DrawTo , 59.0648091471 , 534.392692801 } _
  })

  call ReturnToOriginSprite()
  call LinesSprite({ _
    {MoveTo, 274.695770814 , 358.194136097 }, _
    { DrawTo , 282.025821315 , 353.978313202 }, _
    { DrawTo , 283.027915764 , 346.961975891 }, _
    { DrawTo , 278.992283852 , 337.601793208 }, _
    { DrawTo , 228.901164319 , 288.117811832 }, _
    { DrawTo , 219.433285454 , 280.07459574 }, _
    { DrawTo , 238.299297104 , 291.19109959 }, _
    { DrawTo , 291.961053515 , 344.57986038 }, _
    { DrawTo , 295.175464468 , 354.299264493 }, _
    { DrawTo , 293.404829746 , 361.04719906 }, _
    { DrawTo , 289.449848517 , 364.53977501 }, _
    { DrawTo , 284.256833574 , 365.733506256 }, _
    { DrawTo , 216.012495401 , 363.067400143 }, _
    { DrawTo , 195.362235244 , 362.827252845 }, _
    { DrawTo , 190.705208072 , 367.177340814 }, _
    { DrawTo , 225.729642583 , 412.457768643 }, _
    { DrawTo , 235.584177798 , 430.392905201 }, _
    { DrawTo , 237.31002902 , 435.1308197 }, _
    { DrawTo , 237.049055835 , 450.287297413 }, _
    { DrawTo , 213.276449491 , 455.791777 }, _
    { DrawTo , 121.657127667 , 425.769283563 }, _
    { DrawTo , 110.441616451 , 417.28678216 }, _
    { DrawTo , 141.784331276 , 430.761823303 }, _
    { MoveTo , 240.573152126 , 417.225206958 }, _
    { DrawTo , 244.497017596 , 413.31320541 }, _
    { DrawTo , 272.695157801 , 413.31320541 }, _
    { DrawTo , 276.863403731 , 417.685371494 }, _
    { DrawTo , 276.863403731 , 463.482237485 }, _
    { DrawTo , 306.349363676 , 466.099946239 }, _
    { DrawTo , 306.778356543 , 484.194639308 }, _
    { DrawTo , 259.732899183 , 534.227239597 }, _
    { DrawTo , 244.530984305 , 534.227239597 }, _
    { DrawTo , 240.573152126 , 530.681058338 }, _
    { DrawTo , 240.573152126 , 417.225206958 }, _
    { MoveTo , 246.759734091 , 419.296648916 }, _
    { DrawTo , 246.826449231 , 528.955085368 }, _
    { DrawTo , 257.374460966 , 528.955085368 }, _
    { DrawTo , 301.266438685 , 482.354082311 }, _
    { DrawTo , 301.261507566 , 468.545349326 }, _
    { DrawTo , 270.978461219 , 468.545349326 }, _
    { DrawTo , 270.978461219 , 419.296648916 }, _
    { DrawTo , 246.759734091 , 419.296648916 }, _
    { MoveTo , 264.384510807 , 453.398848276 }, _
    { DrawTo , 275.46517042 , 461.985759352 }, _
    { DrawTo , 304.13884454 , 473.931981248 }, _
    { DrawTo , 311.56455871 , 476.232811708 }, _
    { DrawTo , 335.639210142 , 474.090903984 }, _
    { DrawTo , 340.822815101 , 464.394736199 }, _
    { DrawTo , 341.56348558 , 452.921117872 }, _
    { DrawTo , 336.439356725 , 430.530723081 }, _
    { DrawTo , 323.366525014 , 396.325815393 }, _
    { DrawTo , 313.967376999 , 370.304859377 }, _
    { DrawTo , 312.677570294 , 359.002689917 }, _
    { DrawTo , 316.978715321 , 352.196723277 }, _
    { DrawTo , 325.828088676 , 349.774259013 }, _
    { DrawTo , 352.900563384 , 353.02191773 }, _
    { DrawTo , 384.0 , 361.968969301 }, _
    { DrawTo , 373.159833964 , 353.916550268 }, _
    { DrawTo , 342.685170132 , 345.559652732 }, _
    { DrawTo , 317.404221947 , 342.233860484 }, _
    { DrawTo , 305.50627286 , 345.198116927 }, _
    { DrawTo , 301.875816225 , 349.773515929 }, _
    { DrawTo , 302.249703824 , 364.973373336 }, _
    { DrawTo , 312.303240345 , 391.400862619 }, _
    { DrawTo , 325.46779087 , 425.501129811 } _
  })

  call ReturnToOriginSprite()
  call LinesSprite({ _
    {MoveTo, 59.0648091471 , 534.392692801 }, _
    { MoveTo , 101.235333204 , 474.04089326 }, _
    { DrawTo , 111.579337781 , 506.718442605 }, _
    { DrawTo , 138.486617428 , 528.914338731 }, _
    { DrawTo , 168.498465705 , 535.339047783 }, _
    { DrawTo , 201.479007705 , 527.477954119 }, _
    { DrawTo , 227.13580759 , 504.096205094 }, _
    { DrawTo , 235.753302323 , 473.139193397 }, _
    { DrawTo , 225.096913807 , 440.906207054 }, _
    { DrawTo , 198.269263573 , 419.058088658 }, _
    { DrawTo , 168.499422922 , 412.742414548 }, _
    { DrawTo , 135.780873253 , 420.470753208 }, _
    { DrawTo , 110.173963052 , 443.489803437 }, _
    { DrawTo , 101.235333204 , 474.04089326 }, _
    { MoveTo , 107.437346671 , 474.04089326 }, _
    { DrawTo , 116.827711182 , 503.667538499 }, _
    { DrawTo , 141.254120919 , 523.79182759 }, _
    { DrawTo , 168.498465705 , 529.617009706 }, _
    { DrawTo , 198.437670591 , 522.489451721 }, _
    { DrawTo , 221.728895581 , 501.290047684 }, _
    { DrawTo , 229.559526725 , 474.04089326 }, _
    { DrawTo , 220.169553592 , 444.41472553 }, _
    { DrawTo , 195.743473028 , 424.291168846 }, _
    { DrawTo , 168.498465705 , 418.466273272 }, _
    { DrawTo , 138.55992933 , 425.593486503 }, _
    { DrawTo , 115.268317139 , 446.7921516 }, _
    { DrawTo , 107.437346671 , 474.04089326 }, _
    { MoveTo , 132.614857382 , 474.05042183 }, _
    { DrawTo , 138.132658995 , 491.483743736 }, _
    { DrawTo , 152.486731635 , 503.326200621 }, _
    { DrawTo , 168.498320672 , 506.754237524 }, _
    { DrawTo , 186.09251444 , 502.559776916 }, _
    { DrawTo , 199.779976326 , 490.084703311 }, _
    { DrawTo , 204.381783961 , 474.05042183 }, _
    { DrawTo , 198.863600631 , 456.61863061 }, _
    { DrawTo , 184.509222617 , 444.7773013 }, _
    { DrawTo , 168.498320672 , 441.349606831 }, _
    { DrawTo , 150.903431294 , 445.543649704 }, _
    { DrawTo , 137.216333776 , 458.017542511 }, _
    { DrawTo , 132.614857382 , 474.05042183 }, _
    { MoveTo , 138.860554763 , 474.050637091 }, _
    { DrawTo , 143.418620424 , 488.433885018 }, _
    { DrawTo , 155.274931085 , 498.203210407 }, _
    { DrawTo , 168.498697757 , 501.030915658 }, _
    { DrawTo , 183.030869195 , 497.570988473 }, _
    { DrawTo , 194.336024324 , 487.279694638 }, _
    { DrawTo , 198.119436802 , 473.120024738 }, _
    { DrawTo , 193.24381111 , 459.199095096 }, _
    { DrawTo , 181.471812412 , 449.790699839 }, _
    { DrawTo , 168.500467159 , 447.076676324 }, _
    { DrawTo , 152.99298969 , 451.05894265 }, _
    { DrawTo , 142.285322641 , 461.45498809 }, _
    { DrawTo , 138.860554763 , 474.050637091 }, _
    { MoveTo , 141.784331276 , 430.761823303 }, _
    { DrawTo , 210.905074338 , 448.870972818 }, _
    { DrawTo , 218.721346684 , 448.180099636 }, _
    { DrawTo , 224.604648698 , 444.184879602 }, _
    { DrawTo , 227.323099817 , 437.944453626 }, _
    { DrawTo , 226.137156063 , 431.474935821 }, _
    { DrawTo , 190.942222026 , 377.862643483 }, _
    { DrawTo , 178.702588893 , 359.1715079 }, _
    { DrawTo , 182.40229516 , 355.976349631 }, _
    { DrawTo , 209.145506027 , 356.126561068 }, _
    { DrawTo , 236.633180716 , 358.541408628 }, _
    { DrawTo , 274.695770814 , 358.194136097 } _
  })

  call ReturnToOriginSprite()
  call LinesSprite({ _
    {MoveTo, 325.46779087 , 425.501129811 }, _
    { DrawTo , 330.230613731 , 447.336157366 }, _
    { DrawTo , 329.935558772 , 456.108333498 }, _
    { DrawTo , 324.336099047 , 467.039342624 }, _
    { DrawTo , 317.392982488 , 470.155822627 }, _
    { DrawTo , 311.168688704 , 470.316543074 }, _
    { DrawTo , 301.260985447 , 468.546742042 }, _
    { DrawTo , 293.94694662 , 466.246017916 }, _
    { DrawTo , 264.384510807 , 453.398848276 }, _
    { MoveTo , 310.222772209 , 463.245675323 }, _
    { DrawTo , 357.302283297 , 413.307421874 }, _
    { DrawTo , 372.504111156 , 413.307421874 }, _
    { DrawTo , 376.42794762 , 416.759256293 }, _
    { DrawTo , 376.42794762 , 530.215107673 }, _
    { DrawTo , 372.504111156 , 534.45941094 }, _
    { DrawTo , 344.305854925 , 534.45941094 }, _
    { DrawTo , 340.137696016 , 529.754943137 }, _
    { DrawTo , 340.137696016 , 483.958077146 }, _
    { DrawTo , 311.295245293 , 481.901304223 }, _
    { DrawTo , 310.222772209 , 463.245675323 }, _
    { MoveTo , 315.617358441 , 465.087731371 }, _
    { DrawTo , 315.617358441 , 478.894965306 }, _
    { DrawTo , 346.022638527 , 478.894965306 }, _
    { DrawTo , 346.123001303 , 529.052323976 }, _
    { DrawTo , 370.197884788 , 529.052323976 }, _
    { DrawTo , 370.179465608 , 418.945287465 }, _
    { DrawTo , 359.631482879 , 418.945287465 }, _
    { DrawTo , 315.617358441 , 465.087731371 }, _
    { MoveTo , -128.55129911 , 504.6014941 }, _
    { DrawTo , -128.55129911 , 530.993867208 }, _
    { DrawTo , -132.456571361 , 534.335381336 }, _
    { DrawTo , -176.266518464 , 534.335381336 }, _
    { DrawTo , -179.944408114 , 530.990957286 }, _
    { DrawTo , -178.989359128 , 503.57088753 }, _
    { DrawTo , -132.396237669 , 501.397895248 }, _
    { DrawTo , -128.55129911 , 504.6014941 }, _
    { MoveTo , -135.399811292 , 506.749828551 }, _
    { DrawTo , -173.570733691 , 506.749828551 }, _
    { DrawTo , -173.570733691 , 528.84264099 }, _
    { DrawTo , -135.399811292 , 528.84264099 }, _
    { DrawTo , -135.399811292 , 506.749828551 }, _
    { MoveTo , -164.474182346 , 491.93596897 }, _
    { DrawTo , -191.288853589 , 491.93596897 }, _
    { DrawTo , -216.838924849 , 466.180479825 }, _
    { DrawTo , -222.475763586 , 470.701833115 }, _
    { DrawTo , -202.012210117 , 491.937040091 }, _
    { DrawTo , -262.929337574 , 491.937040091 }, _
    { DrawTo , -230.11401946 , 453.736718268 }, _
    { DrawTo , -262.929337574 , 415.534466871 }, _
    { DrawTo , -236.11470984 , 415.534466871 }, _
    { DrawTo , -210.564597971 , 441.288884895 }, _
    { DrawTo , -204.927971502 , 436.765973254 }, _
    { DrawTo , -225.391312703 , 415.530397649 }, _
    { DrawTo , -164.474182346 , 415.530397649 }, _
    { DrawTo , -197.28950336 , 453.73468236 }, _
    { DrawTo , -164.474182346 , 491.93596897 }, _
    { MoveTo , -243.591771462 , 530.994723068 }, _
    { DrawTo , -272.887538449 , 530.994723068 }, _
    { DrawTo , -317.761528223 , 463.250922001 }, _
    { DrawTo , -322.722880936 , 463.250801635 }, _
    { DrawTo , -322.723986092 , 470.744903272 }, _
    { DrawTo , -282.810580156 , 530.993545613 }, _
    { DrawTo , -384.0 , 530.993545613 }, _
    { DrawTo , -313.796270359 , 412.497286011 }, _
    { DrawTo , -243.591771462 , 530.994723068 } _
  })

endsub


' final acceptable error: 6.1
' final angle tollerance: 1.0
' final command count: 380
sub  bg(tfc)
  if tfc==0
  call LinesSprite({ _
    { MoveTo , 1.67557386755 , -1.70876125367 }, _
    { DrawTo , -5.2328108013 , -9.96075924761 }, _
    { DrawTo , -17.3454111224 , -0.413190955188 }, _
    { DrawTo , -56.0203156997 , -4.68448260524 }, _
    { DrawTo , -58.3173968093 , -15.5773728135 }, _
    { DrawTo , -57.8044768183 , -26.9641100323 }, _
    { DrawTo , -57.8940008413 , -42.1464263238 }, _
    { DrawTo , -64.621467869 , -35.3607744036 }, _
    { DrawTo , -74.2926954198 , -12.2035247487 }, _
    { DrawTo , -75.2174259169 , -2.92712949448 }, _
    { DrawTo , -62.1068960445 , 4.42743755581 }, _
    { DrawTo , -39.4625843273 , 8.82820062535 }, _
    { DrawTo , -21.0312099995 , 7.85913395225 }, _
    { DrawTo , -60.527058275 , -2.92544084677 }, _
    { DrawTo , -61.2769556895 , -26.1206480161 }, _
    { DrawTo , -54.7343727905 , -35.8204380574 }, _
    { DrawTo , -48.4149867911 , -41.3029641569 }, _
    { DrawTo , -41.0524482825 , -49.7255379541 }, _
    { DrawTo , -32.0900178129 , -54.7983565548 }, _
    { DrawTo , -47.3027823005 , -40.0398799385 }, _
    { DrawTo , -49.9948231378 , -32.4466132727 }, _
    { DrawTo , -44.2020914175 , -20.6381449215 }, _
    { DrawTo , -43.2315456985 , -10.9383317244 }, _
    { DrawTo , -25.2440630165 , 0.0266744862625 }, _
    { DrawTo , -10.2077463376 , -12.5565663188 }, _
    { DrawTo , -14.3568885876 , -18.7660809658 }, _
    { DrawTo , -23.663970288 , -28.2270353916 }, _
    { DrawTo , -33.1432415225 , -32.8683441457 }, _
    { DrawTo , -28.9303141775 , -21.9036210796 }, _
    { DrawTo , -38.7244217017 , -27.8267396675 }, _
    { DrawTo , -33.6698840039 , -20.638153192 }, _
    { DrawTo , -21.5577797137 , -17.2642968459 }, _
    { MoveTo , -23.6642273153 , -28.2293030566 }, _
    { DrawTo , -8.91909410414 , -22.3250689432 }, _
    { DrawTo , -3.1263631997 , -27.3858410404 }, _
    { DrawTo , 7.93248670871 , -22.7467999512 }, _
    { DrawTo , -3.1263631997 , -27.3858410404 }, _
    { MoveTo , 3.19297951094 , -31.181420063 }, _
    { DrawTo , 26.3639032227 , -41.0773382184 }, _
    { DrawTo , 35.8429174299 , -39.2934160541 }, _
    { DrawTo , 56.3807815455 , -35.3451703563 }, _
    { DrawTo , 77.971869462 , -30.7596891052 }, _
    { MoveTo , 83.7646003664 , -36.6639232186 }, _
    { DrawTo , 60.0670648483 , -41.9022440702 }, _
    { DrawTo , 47.4283792387 , -44.7126595082 }, _
    { DrawTo , 27.9437389239 , -41.7246953158 }, _
    { MoveTo , 30.5767984259 , -34.6855830596 }, _
    { DrawTo , 43.2154840355 , -32.4466131376 }, _
    { DrawTo , 44.8282329765 , -25.0926787065 }, _
    { DrawTo , 33.1403672708 , -16.5398070421 }, _
    { DrawTo , 20.8047273476 , 0.382802669188 }, _
    { DrawTo , 27.779172705 , -4.24335197077 }, _
    { DrawTo , 33.7364698283 , -12.2035247487 }, _
    { MoveTo , 45.4606955964 , -5.62949024115 }, _
    { DrawTo , 32.1566341271 , -4.61236660286 }, _
    { MoveTo , 21.6001264073 , -10.0491992336 }, _
    { DrawTo , 12.1453825711 , -6.29929090018 }, _
    { DrawTo , 5.2994272067 , -2.08198055425 }, _
    { DrawTo , 5.8260391071 , -11.7817937406 }, _
    { DrawTo , 16.8848890155 , -12.2035247487 }, _
    { MoveTo , 27.4171270235 , -24.4337239836 }, _
    { DrawTo , 34.7896735405 , -26.1204871384 }, _
    { DrawTo , 30.5822263791 , -34.6843091162 }, _
    { DrawTo , 10.5014235412 , -21.4005248028 } _
  })

  call ReturnToOriginSprite()
  call LinesSprite({ _
    {MoveTo, 48.4816030337 , -13.4687177722 }, _
    { DrawTo , 43.2154840355 , -32.4466131376 }, _
    { MoveTo , 45.3219316373 , -17.2642968462 }, _
    { DrawTo , 47.4283792387 , -7.14275265147 }, _
    { MoveTo , 12.1453819119 , 8.8830256564 }, _
    { DrawTo , -3.6529751001 , 9.99808244182 }, _
    { DrawTo , -11.9566755461 , 9.74012677985 }, _
    { DrawTo , -48.4149866341 , 14.3655287617 }, _
    { DrawTo , -31.0367939209 , 12.1856011808 }, _
    { DrawTo , -5.2328108013 , 9.72648767261 }, _
    { DrawTo , -21.0311678133 , 7.85906276873 }, _
    { MoveTo , -32.0015858535 , 1.13489081804 }, _
    { DrawTo , -51.0480461361 , -17.686027854 }, _
    { DrawTo , -43.8071325056 , -12.4143902527 }, _
    { DrawTo , -51.5766100255 , -31.6056514611 }, _
    { DrawTo , -44.7287033313 , -21.4816069269 }, _
    { MoveTo , -39.4004441231 , -39.6160402753 }, _
    { DrawTo , -33.6698534229 , -33.2900751538 }, _
    { MoveTo , -33.6872316156 , -39.6160402753 }, _
    { DrawTo , -19.985843191 , -32.2011656909 }, _
    { DrawTo , -14.1831066605 , -36.5437298813 }, _
    { DrawTo , 1.6131439039 , -47.0789921947 }, _
    { DrawTo , 13.1986057127 , -44.9425029076 }, _
    { DrawTo , 33.7364698283 , -50.1593154779 }, _
    { MoveTo , 17.9381128163 , -54.3766255589 }, _
    { DrawTo , 6.92657569583 , -49.7660018912 }, _
    { DrawTo , 17.9381128163 , -54.3766255589 }, _
    { MoveTo , 11.0921581111 , -52.2679705184 }, _
    { DrawTo , -7.33925840291 , -46.7854674116 }, _
    { DrawTo , 1.6131439039 , -53.1114325346 }, _
    { MoveTo , -11.5402502456 , -49.7822386643 }, _
    { DrawTo , -28.8122694685 , -37.4219162762 }, _
    { DrawTo , -23.1376154149 , -34.5552681781 }, _
    { DrawTo , -11.0255417057 , -41.7246953158 }, _
    { DrawTo , -25.6773935849 , -41.6865295358 }, _
    { DrawTo , -16.8182726101 , -57.7504735986 }, _
    { DrawTo , -8.39248220404 , -55.220087575 }, _
    { DrawTo , -7.9833047571 , -62.9386084854 }, _
    { DrawTo , 3.1929796051 , -62.6358056215 }, _
    { DrawTo , 21.0951511592 , -71.3403336288 }, _
    { DrawTo , 37.1870791478 , -90.8660277172 }, _
    { DrawTo , 43.789491007 , -115.527621734 }, _
    { DrawTo , 42.1622602347 , -131.97513105 }, _
    { DrawTo , 39.002589003 , -139.566288877 }, _
    { DrawTo , 8.98571050951 , -95.7062643529 }, _
    { DrawTo , 10.3106660509 , -113.418966693 }, _
    { DrawTo , 36.3695293303 , -142.518406252 }, _
    { DrawTo , 40.582424408 , -136.614172315 }, _
    { DrawTo , 18.4647247167 , -93.5976093123 }, _
    { MoveTo , 24.7840675215 , -94.8628023367 }, _
    { DrawTo , 45.5852375873 , -128.891223053 }, _
    { DrawTo , 42.2744285695 , -142.049863102 }, _
    { DrawTo , 27.409227845 , -153.492690545 }, _
    { DrawTo , -17.6482129651 , -124.383972904 }, _
    { DrawTo , -24.1908392157 , -111.310311653 }, _
    { DrawTo , -26.8238987177 , -99.0801124177 }, _
    { DrawTo , -37.8827486261 , -88.9585682232 }, _
    { DrawTo , -48.6598611678 , -77.7818530465 }, _
    { DrawTo , -61.5802841441 , -58.1722046318 }, _
    { DrawTo , -52.8511652831 , -68.2937488262 }, _
    { DrawTo , -30.6335927159 , -85.4069026017 }, _
    { DrawTo , -28.4158111378 , -75.5994995655 }, _
    { DrawTo , -46.4091219055 , -66.1850937857 }, _
    { DrawTo , -41.9739964803 , -58.1722046318 }, _
    { DrawTo , -51.0480461361 , -49.3158534617 } _
  })

  call ReturnToOriginSprite()
  endif
  if tfc=1
  call LinesSprite({ _
    {MoveTo, 90.0839431712 , -133.662055082 }, _
    { DrawTo , 93.2436193639 , -119.744929897 }, _
    { DrawTo , 97.8905531791 , -99.6649347141 }, _
    { DrawTo , 109.041971586 , -95.7062643529 }, _
    { MoveTo , 114.30809059 , -77.9935620126 }, _
    { DrawTo , 69.5460790556 , -88.115106207 }, _
    { DrawTo , 53.8946467638 , -90.2701516584 }, _
    { DrawTo , 51.7197396151 , -80.3404950727 }, _
    { DrawTo , 87.9774955696 , -70.4024038667 }, _
    { MoveTo , 53.2211101431 , -90.6454922556 }, _
    { DrawTo , 55.3275577447 , -107.51473258 }, _
    { DrawTo , 66.9130195536 , -106.914187624 }, _
    { MoveTo , 60.0670648483 , -118.058007782 }, _
    { DrawTo , 59.8579999239 , -126.865016424 }, _
    { DrawTo , 69.5460790556 , -126.070896936 }, _
    { DrawTo , 64.806571952 , -140.409751212 }, _
    { DrawTo , 51.6412744419 , -141.664400961 }, _
    { DrawTo , 42.2744285695 , -142.049863102 }, _
    { MoveTo , 49.0082149399 , -142.096675244 }, _
    { DrawTo , 42.1622602347 , -153.061681455 }, _
    { MoveTo , 51.1146625415 , -152.639528716 }, _
    { DrawTo , 29.5235746251 , -153.061681455 }, _
    { MoveTo , 50.0614387407 , -141.253213228 }, _
    { DrawTo , 53.2211101431 , -128.601282985 }, _
    { MoveTo , -24.1908392157 , -111.310311653 }, _
    { DrawTo , -39.1466171871 , -97.3931883853 }, _
    { DrawTo , -57.8940008413 , -77.9935620126 }, _
    { DrawTo , -48.4149866341 , -77.9935620126 }, _
    { MoveTo , -39.4625843273 , -78.8370240288 }, _
    { DrawTo , -32.6166296221 , -84.7412581422 }, _
    { MoveTo , -39.3425158669 , -75.4509473793 }, _
    { DrawTo , -33.1429635815 , -66.6067293758 }, _
    { DrawTo , -38.2777075514 , -77.4663982525 }, _
    { MoveTo , -16.460827922 , -75.5643500104 }, _
    { DrawTo , -13.5104916107 , -65.8819746237 }, _
    { DrawTo , -24.4910079989 , -73.7825778967 }, _
    { DrawTo , -26.8238987177 , -99.0801124177 }, _
    { MoveTo , -24.7174511161 , -48.8941224536 }, _
    { DrawTo , -30.5266386424 , -40.0509503774 }, _
    { MoveTo , -66.8464031482 , 3.82225355918 }, _
    { DrawTo , -79.383452661 , -4.61236660286 }, _
    { DrawTo , -75.1984678885 , -19.3729518864 }, _
    { DrawTo , -68.9396854522 , -36.6639232186 }, _
    { DrawTo , -64.9116310261 , -46.3637364049 }, _
    { DrawTo , -70.5326477803 , -65.341649466 }, _
    { DrawTo , -63.1601198453 , -72.9327899154 }, _
    { DrawTo , -68.4262227784 , -63.233005687 }, _
    { DrawTo , -77.3791473901 , -49.315505966 }, _
    { DrawTo , -74.7455816542 , -38.350847251 }, _
    { DrawTo , -72.6391340526 , -44.2550813644 }, _
    { DrawTo , -66.8464031482 , -60.7025906804 }, _
    { MoveTo , -76.2925041106 , -58.923412991 }, _
    { DrawTo , -84.6377456872 , -56.4902357009 }, _
    { DrawTo , -88.5744101587 , -61.3157875662 }, _
    { DrawTo , -96.5906544901 , -57.6243760523 }, _
    { DrawTo , -109.501967081 , -29.916227089 }, _
    { DrawTo , -119.825350809 , -12.6252557568 }, _
    { DrawTo , -128.0 , 47.2605473937 }, _
    { DrawTo , -110.112678962 , 74.2513318242 }, _
    { DrawTo , -79.4850887578 , 87.8871605971 }, _
    { DrawTo , -24.1434441447 , 99.4949692103 }, _
    { DrawTo , 3.1929796051 , 101.421099071 }, _
    { DrawTo , 30.0501865255 , 102.507309455 }, _
    { MoveTo , -37.3561367257 , 28.2826520291 }, _
    { DrawTo , -43.6754795305 , 23.2218799319 } _
  })

  call ReturnToOriginSprite()
  call LinesSprite({ _
    {MoveTo, 10.5014235412 , -21.4005248028 }, _
    { DrawTo , 2.66636770499 , -9.67313870144 }, _
    { DrawTo , -9.44568413101 , -12.2035258152 }, _
    { MoveTo , -11.0255417057 , -23.5902619674 }, _
    { DrawTo , 10.5655462107 , -37.6115527938 }, _
    { DrawTo , 33.8814174073 , -44.9112836579 }, _
    { DrawTo , 79.0250932628 , -44.1235012899 }, _
    { DrawTo , 91.6623469347 , -31.6770516114 }, _
    { DrawTo , 83.237988466 , -21.0598759188 }, _
    { DrawTo , 86.3976598684 , -37.9291162429 }, _
    { DrawTo , 50.0614387407 , -44.6768123725 }, _
    { MoveTo , 57.6738500517 , -58.6874541697 }, _
    { DrawTo , 63.2493622786 , -61.2061231634 }, _
    { DrawTo , 55.3502020565 , -57.3666984063 }, _
    { MoveTo , 47.4283953097 , -61.1243232973 }, _
    { DrawTo , 32.6832460277 , -59.015666648 }, _
    { DrawTo , 47.4283792387 , -61.1243216885 }, _
    { MoveTo , 32.1566341271 , -58.5939356399 }, _
    { DrawTo , 20.0445604179 , -55.2200875751 }, _
    { DrawTo , 32.1566341271 , -58.5939356399 }, _
    { MoveTo , 34.7896936291 , -50.581046486 }, _
    { DrawTo , 80.604928964 , -50.1470852786 }, _
    { DrawTo , 102.193598207 , -36.2405319535 }, _
    { DrawTo , 101.14279308 , -45.9420053968 }, _
    { DrawTo , 96.3893090059 , -50.9016453444 }, _
    { DrawTo , 102.196016878 , -43.4116193537 }, _
    { DrawTo , 98.5097337034 , -33.7118063376 }, _
    { DrawTo , 94.8234502748 , -28.2293030566 }, _
    { MoveTo , 89.0307193704 , -23.1685309593 }, _
    { DrawTo , 113.324906172 , -45.5202743887 }, _
    { DrawTo , 119.214007054 , -57.7504736237 }, _
    { DrawTo , 126.356970871 , -77.1500999964 }, _
    { DrawTo , 127.308558575 , -85.928852661 }, _
    { DrawTo , 114.83470249 , -92.7541472954 }, _
    { DrawTo , 108.655240971 , -113.880234983 }, _
    { DrawTo , 109.568583486 , -99.9235744339 }, _
    { DrawTo , 117.467312006 , -90.6458526215 }, _
    { DrawTo , 113.451293028 , -72.5110589073 }, _
    { DrawTo , 110.475409178 , -66.8674545568 }, _
    { DrawTo , 103.775852582 , -67.3672058014 }, _
    { DrawTo , 88.50410747 , -69.9806728586 }, _
    { DrawTo , 85.7725715426 , -56.9968403122 }, _
    { DrawTo , 89.0044138378 , -50.8362349916 }, _
    { DrawTo , 84.8178241672 , -57.3287426156 }, _
    { DrawTo , 73.234468806 , -55.1176069401 }, _
    { DrawTo , 68.6245082299 , -60.8080234324 }, _
    { DrawTo , 81.1315408644 , -57.7504736237 }, _
    { MoveTo , 86.3976598684 , -37.9291162429 }, _
    { DrawTo , 71.1259147568 , -25.0983720524 }, _
    { DrawTo , 64.806571952 , -21.4196124687 }, _
    { DrawTo , 50.5880506411 , -22.3250689432 }, _
    { DrawTo , 55.3275577447 , -15.1556418054 }, _
    { DrawTo , 63.2267362507 , -10.9383317244 }, _
    { DrawTo , 81.656095687 , -19.7934473545 }, _
    { MoveTo , 51.6412753208 , -16.4208345954 }, _
    { DrawTo , 46.3751554379 , -2.50371156235 }, _
    { DrawTo , 42.6888721513 , 2.97879152677 }, _
    { DrawTo , 12.1453819119 , 8.8830256564 }, _
    { DrawTo , 5.2994272067 , -0.395056521844 }, _
    { MoveTo , 15.3050533448 , -28.2293029711 }, _
    { DrawTo , 3.1929796051 , -31.1814201133 }, _
    { MoveTo , 19.517948507 , -29.0727650491 }, _
    { DrawTo , 25.8372913223 , -26.5423790242 }, _
    { MoveTo , 34.7896936291 , -14.7339107973 }, _
    { DrawTo , 48.4816030337 , -13.4687177722 } _
  })

  call ReturnToOriginSprite()
  endif
  if tfc=2
  call LinesSprite({ _
    {MoveTo, -51.0480461361 , -49.3158534617 }, _
    { DrawTo , -58.5942802816 , -42.9873224422 }, _
    { DrawTo , -56.3141651401 , -61.9677837047 }, _
    { DrawTo , -49.9948223353 , -50.581046486 }, _
    { DrawTo , -56.3141651401 , -61.9677837047 }, _
    { DrawTo , -47.8883747337 , -70.4024038667 }, _
    { DrawTo , -40.5158081281 , -58.1722046318 }, _
    { DrawTo , -32.5977098251 , -63.4782463646 }, _
    { DrawTo , -21.5577797164 , -67.8720178052 }, _
    { DrawTo , -15.7650489816 , -66.185093703 }, _
    { DrawTo , -20.5630097876 , -60.9720767512 }, _
    { DrawTo , -30.5101820205 , -56.9070116075 }, _
    { DrawTo , -38.9489073317 , -40.5649350435 }, _
    { MoveTo , -30.7074146338 , -44.1101113304 }, _
    { DrawTo , -21.0311678133 , -55.6418185832 }, _
    { MoveTo , -14.4941193163 , -57.1543402549 }, _
    { DrawTo , -6.52418492682 , -67.1855644841 }, _
    { DrawTo , -20.5045559129 , -77.9935620126 }, _
    { DrawTo , -22.6926283591 , -99.0801124177 }, _
    { DrawTo , 9.51232240991 , -147.387712472 }, _
    { DrawTo , 28.4703508243 , -148.929139306 }, _
    { DrawTo , 32.4883821223 , -144.321547745 }, _
    { DrawTo , 0.329527396676 , -103.824586259 }, _
    { DrawTo , 15.4161684253 , -134.505517098 }, _
    { DrawTo , 27.9437389239 , -145.470523309 }, _
    { DrawTo , 0.210249801235 , -133.240324074 }, _
    { DrawTo , -16.2916607097 , -93.1758783042 }, _
    { DrawTo , -14.4411464917 , -79.734889345 }, _
    { DrawTo , -9.44570600435 , -73.3545209235 }, _
    { DrawTo , 5.29225292206 , -66.6254650398 }, _
    { DrawTo , 16.8026059061 , -74.8108108108 }, _
    { DrawTo , 23.7308437207 , -75.0414449559 }, _
    { MoveTo , 13.7252176131 , -61.2757231204 }, _
    { DrawTo , -6.2860346021 , -57.3287426156 }, _
    { MoveTo , 13.7252176131 , -61.2757231204 }, _
    { DrawTo , 39.8741315275 , -90.6454922556 }, _
    { DrawTo , 45.0238693015 , -104.435252759 }, _
    { DrawTo , 53.7477220435 , -107.936463588 }, _
    { DrawTo , 46.3751554379 , -109.201656612 }, _
    { DrawTo , 47.0692299227 , -126.851942763 }, _
    { DrawTo , 58.8317788417 , -126.94650163 }, _
    { DrawTo , 53.2211101431 , -142.096675244 }, _
    { DrawTo , 51.1146464706 , -152.639528717 }, _
    { DrawTo , 57.7610313365 , -151.136901134 }, _
    { DrawTo , 65.8597957528 , -139.566289195 }, _
    { DrawTo , 88.3776068079 , -131.62008665 }, _
    { DrawTo , 92.1903907728 , -120.588393831 }, _
    { DrawTo , 70.072690956 , -125.649165928 }, _
    { DrawTo , 71.1259147568 , -118.901469798 }, _
    { MoveTo , 66.9130195536 , -106.914187624 }, _
    { DrawTo , 97.9831216772 , -99.5018434258 }, _
    { DrawTo , 96.403285976 , -118.47973879 }, _
    { DrawTo , 105.355688283 , -115.527621734 }, _
    { DrawTo , 100.667262534 , -130.329114925 }, _
    { DrawTo , 109.441305309 , -125.542078344 }, _
    { DrawTo , 114.83470247 , -110.888580661 }, _
    { DrawTo , 128.0 , -102.032229474 }, _
    { MoveTo , 128.0 , -86.8499131827 }, _
    { DrawTo , 105.882300183 , -135.279815229 }, _
    { DrawTo , 93.770226474 , -140.83148222 }, _
    { DrawTo , 98.5097335776 , -131.553400041 }, _
    { DrawTo , 90.0839431712 , -133.662055082 }, _
    { DrawTo , 82.7113765656 , -145.048792301 }, _
    { DrawTo , 93.2436145736 , -141.253213228 }, _
    { MoveTo , 90.0839431712 , -133.662055082 } _
  })

  call ReturnToOriginSprite()
  call LinesSprite({ _
    {MoveTo, -43.6754795305 , 23.2218799319 }, _
    { DrawTo , -40.5158044503 , 30.4811316487 }, _
    { DrawTo , -65.266567447 , 23.6423457469 }, _
    { DrawTo , -72.1125221573 , 21.9566869086 }, _
    { DrawTo , -88.287143367 , 29.269080857 }, _
    { DrawTo , -103.452407552 , 47.6447443421 }, _
    { DrawTo , -110.549503473 , 59.9124776367 }, _
    { DrawTo , -110.112678901 , 74.2513319122 }, _
    { MoveTo , -103.182624276 , 49.3692024342 }, _
    { DrawTo , -69.4794626502 , 78.5766051313 }, _
    { MoveTo , -78.9584768574 , 23.64361094 }, _
    { DrawTo , -110.55517481 , 24.4870729562 }, _
    { DrawTo , -100.549564774 , 21.3316815536 }, _
    { DrawTo , -76.8817910564 , 14.1015045583 }, _
    { DrawTo , -86.8576553634 , 11.0827745947 }, _
    { DrawTo , -104.762459977 , -1.66024954614 }, _
    { DrawTo , -108.975355178 , -11.0305853769 }, _
    { DrawTo , -109.501967081 , -29.916227089 }, _
    { MoveTo , -100.022985015 , -23.5905451125 }, _
    { DrawTo , -103.178526438 , -15.9965094539 }, _
    { DrawTo , -95.9872099135 , -49.7375844698 }, _
    { DrawTo , -89.4907148654 , -57.3287426156 }, _
    { DrawTo , -93.9063556502 , -47.6289294292 }, _
    { DrawTo , -79.6541082164 , -29.3529086198 }, _
    { DrawTo , -90.5439386662 , -9.25140769198 }, _
    { DrawTo , -90.0173267658 , -15.9991038202 }, _
    { DrawTo , -86.8576553787 , -21.9033379145 }, _
    { DrawTo , -81.5915502406 , -31.603137654 }, _
    { DrawTo , -88.3363289185 , -16.4208348297 }, _
    { DrawTo , -92.1237777676 , -5.0341167047 }, _
    { DrawTo , -86.331043463 , -8.40794567577 }, _
    { DrawTo , -92.6503862678 , -7.98621466767 }, _
    { DrawTo , -98.4431171722 , -4.19063559476 }, _
    { DrawTo , -104.719804413 , -12.2035247487 }, _
    { DrawTo , -98.9698077695 , -34.5554527459 }, _
    { DrawTo , -89.9226578164 , -27.2636464945 }, _
    { DrawTo , -84.2245958663 , -34.1335371668 }, _
    { DrawTo , -88.964102965 , -20.2164139026 }, _
    { MoveTo , -96.3366673196 , -21.4816052145 }, _
    { DrawTo , -92.1237743674 , -12.6252557568 }, _
    { MoveTo , -89.5112856427 , -42.5319148235 }, _
    { DrawTo , -82.0291378391 , -56.9576938126 }, _
    { DrawTo , -74.9986487637 , -47.2000572634 }, _
    { DrawTo , -71.0592983514 , -56.0635495913 }, _
    { MoveTo , -80.0117006582 , -29.4944960809 }, _
    { DrawTo , -84.7512077627 , -12.2035247495 }, _
    { MoveTo , -94.2208472753 , -2.00589632212 }, _
    { DrawTo , -87.9087727166 , 3.74887236377 }, _
    { DrawTo , -70.2693794912 , 13.1003356027 }, _
    { DrawTo , -60.3295808807 , 14.4621315208 }, _
    { DrawTo , -70.0060745506 , 21.1132248914 }, _
    { DrawTo , -55.9654246405 , 13.535879367 }, _
    { DrawTo , -75.2721935546 , 15.630721786 }, _
    { DrawTo , -110.555190881 , 24.4870729562 }, _
    { MoveTo , 59.0138410475 , -151.79648843 }, _
    { DrawTo , 79.0250983163 , -145.892253161 }, _
    { DrawTo , 84.2912122668 , -136.614172139 }, _
    { MoveTo , 104.829076382 , -134.927248106 }, _
    { DrawTo , 109.568583368 , -126.070897078 }, _
    { DrawTo , 123.260492896 , -119.323200807 }, _
    { MoveTo , 105.882300183 , -115.527621734 } _
  })
  endif

endsub
