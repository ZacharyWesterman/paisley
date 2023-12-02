while 1 do
    if {${door_state} = "open"} then
        gosub close_door_anim
        sleep 1
    end

    gosub idle_pose
    sleep {frandom(0.3, 2)}
end

subroutine idle_pose:
    eye pos {frandom(-1, 1)} {frandom(-.8, .8)}
    ears {irandom(40, 50)} {irandom(40, 50)}
    neck {irandom(-2, 2), irandom(-2, 2), irandom(-2, 2)}
    arm left {frandom(-2, 2), frandom(0,2), frandom(0,2), frandom(0,2), frandom(0,2), frandom(0,2)}
    arm right {frandom(-2, 2), frandom(0,2), frandom(0,2), frandom(0,2), frandom(0,2), frandom(0,2)}
end

subroutine close_door_anim:
    eye pos .5 0
    sleep .2
    ears 30 45
    eye pos 1 -.8
    sleep .4
    eye pos -.1 .3
    sleep .1
    eye pos 1 -.8
    neck 20 -45
    ears 30 30
    eye pos 0 -.8
    sleep .5

    arm right 40 0 60 90 -30 40
    sleep .3
    arm right 40 0 60 90 -30 90
    door close
    sleep .5
    arm right 0 0 10 10 10 0

    neck 0 0
    eye pos 0 0
    ears 45 45
end
