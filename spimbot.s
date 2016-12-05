# syscall constants
PRINT_STRING = 4
PRINT_CHAR   = 11
PRINT_INT    = 1

# debug constants
PRINT_INT_ADDR   = 0xffff0080
PRINT_FLOAT_ADDR = 0xffff0084
PRINT_HEX_ADDR   = 0xffff0088

# spimbot constants
VELOCITY       = 0xffff0010
ANGLE          = 0xffff0014
ANGLE_CONTROL  = 0xffff0018
BOT_X          = 0xffff0020
BOT_Y          = 0xffff0024
OTHER_BOT_X    = 0xffff00a0
OTHER_BOT_Y    = 0xffff00a4
TIMER          = 0xffff001c
SCORES_REQUEST = 0xffff1018

TILE_SCAN       = 0xffff0024
SEED_TILE       = 0xffff0054
WATER_TILE      = 0xffff002c
MAX_GROWTH_TILE = 0xffff0030
HARVEST_TILE    = 0xffff0020
BURN_TILE       = 0xffff0058
GET_FIRE_LOC    = 0xffff0028
PUT_OUT_FIRE    = 0xffff0040

GET_NUM_WATER_DROPS   = 0xffff0044
GET_NUM_SEEDS         = 0xffff0048
GET_NUM_FIRE_STARTERS = 0xffff004c
SET_RESOURCE_TYPE     = 0xffff00dc
REQUEST_PUZZLE        = 0xffff00d0
SUBMIT_SOLUTION       = 0xffff00d4

# interrupt constants
BONK_MASK               = 0x1000
BONK_ACK                = 0xffff0060
TIMER_MASK              = 0x8000
TIMER_ACK               = 0xffff006c
ON_FIRE_MASK            = 0x400
ON_FIRE_ACK             = 0xffff0050
MAX_GROWTH_ACK          = 0xffff005c
MAX_GROWTH_INT_MASK     = 0x2000
REQUEST_PUZZLE_ACK      = 0xffff00d8
REQUEST_PUZZLE_INT_MASK = 0x800

.data
# data things go here

.align 2
	tile_data: .space 1600
	puzzle: .space 4096
	solution: .space 328
  fire_loc_queue: .space 400
  harvest_loc_queue: .space 400
  fire_loc_front: .space 4
  harvest_loc_front: .space 4
  fire_loc_back: .space 4
  harvest_loc_back: .space 4
  dest_x: .space 4
  dest_y: .space 4
  three: .float	3.0
  five:	.float	5.0
  PI:	.float	3.141592
  F180:	.float  180.0
  action: .space 4 #0 harvest and 1 for fire
  dest: .space 4

.text
main:
	# go wild
	# the world is your oyster :)

	#la $t0, tile_data
	sw $0, SEED_TILE
  sw $0, dest
  li $t1, 10
  sw $t1, VELOCITY
	li $t4, ON_FIRE_MASK
	or $t4, $t4, BONK_MASK
	#or $t4, $t4, TIMER_MASK
	or $t4, $t4, MAX_GROWTH_INT_MASK
	or $t4, $t4, REQUEST_PUZZLE_INT_MASK
	or $t4, $t4, 1
	mtc0 $t4, $12

        li $t0, 2
	sw $t0 SET_RESOURCE_TYPE

	la $t0, puzzle
	sw $t0, REQUEST_PUZZLE
loop:
  # and $a0, $s0, 0xffff0000  #x-index
  # srl $a0, $a0, 16 #upper 16 bits
  # and $a1, $s0, 0xffff #y-index
  # mul $a0, $a0, 30
  # add $a0, $a0, 15  #x
  # mul $a1, $a1, 30
  # add $a1, $a1, 15  #y
  lw $t0, dest
#  beq $t0, 0, check_harvest
already_moving:
  lw $t0, BOT_X
  lw $t1, BOT_Y
  lw $t2, dest_x
  lw $t3, dest_y
  sub $t2, $t2, $t0
  sub $t3, $t3, $t1
  abs $t2, $t2
  abs $t3, $t3
  bgt $t2, 14, not_arrived
  bgt $t3, 14, not_arrived
arrived:
  lw $t0, action
  sw $0, dest
  sw $0, dest_x
  sw $0, dest_y
  beq $t0, 0, harvest
  sw $0, PUT_OUT_FIRE
  j check_harvest
harvest:
  sw $0, HARVEST_TILE
check_harvest:
	lw $t0, harvest_loc_front
	lw $t1, harvest_loc_back
	beq $t0, $t1, check_fire

	mul $t2, $t0, 4
	la $s0, harvest_loc_queue
	sw $0, action
	add $s0, $s0, $t2 #our tile address
	lw $s1, 0($s0) #tile
	add $t0, $t0, 1
	blt $t0, 100, no_change_harvest
	li $t0, 0

no_change_harvest:
	sw $t0, harvest_loc_front #changes harvest index
	j find_coord

check_fire:
	lw $t0, fire_loc_front
	lw $t1, fire_loc_back
	beq $t0, $t1, loop

	mul $t2, $t0, 4
	la $s0, fire_loc_queue
	li $t3, 1
	sw $t3, action
	add $s0, $s0, $t2 #our tile address
	lw $s1, 0($s0) #tile
	add $t0, $t0, 1
	blt $t0, 100, no_change_fire
	li $t0, 0

no_change_fire:
	sw $t0, fire_loc_front #changes harvest index
	j find_coord


find_coord:

	sw $s1, dest
   	and $a0, $s1, 0xffff0000  #x-index
  	srl $a0, $a0, 16 #upper 16 bits
 	and $a1, $s1, 0xffff #y-index
  	mul $a0, $a0, 30
  	add $a0, $a0, 15  #x
	sw $a0, dest_x
  	mul $a1, $a1, 30
   	add $a1, $a1, 15  #y
	sw $a1, dest_y
	la $s0, go_to_tile
	jalr $s0
	j	loop
not_arrived:
  la $t0, tile_data
  sw $t0, TILE_SCAN
  lw $t1, BOT_X
  lw $t2, BOT_Y
  mul $t2, $t2, 10
  add $t2, $t2, $t1 #index of the current tile
  mul $t2, $t2, 16
  add $t0, $t0, $t2 #address of current tile in the array
  lw $t1, 0($t0) #load tile state to t1
  lw $t2, 4($t0) #load owning_bot to t2
  lw $t3, 8($t0) #load growth to t3
  lw $t4, 12($t0) #load water to t4 
  bne $t1, $0, check_waterable
  lw $t5, GET_NUM_SEEDS
  ble $t5, $0, loop
  sw $0, SEED_TILE
  lw $t7, dest
  beq $t7, 0, check_harvest
  j loop
check_waterable:
  bne $t2, $0, check_set_fire
  bge $t3, 200, harvest_now
  lw $t5, GET_NUM_WATER_DROPS
  ble $t5, 230, loop
  sub $t6, $t5, 230
  sw $t6, WATER_TILE
  lw $t7, dest
  beq $t7, 0, check_harvest
  j loop
harvest_now:
  sw $0, HARVEST_TILE
  lw $t7, dest
  beq $t7, 0, check_harvest
  j loop
check_set_fire:
  lw $t5, GET_NUM_FIRE_STARTERS
  ble $t5, $0, loop
  sw $0, BURN_TILE
  lw $t7, dest
  beq $t7, 0, check_harvest
  j loop

.kdata				# interrupt handler data (separated just for readability)
chunkIH:	.space 76	# space for two registers
non_intrpt_str:	.asciiz "Non-interrupt exception\n"
unhandled_str:	.asciiz "Unhandled interrupt type\n"


.ktext 0x80000180
interrupt_handler:

.set noat
	move $k1, $at #save $at
.set at
	la $k0 chunkIH
  sw    $ra, 0($k0)
  sw    $a0, 4($k0)     
  sw    $a1, 8($k0)    
  sw    $s0, 12($k0)    
  sw    $s1, 16($k0)     
  sw    $s2, 20($k0) 
  sw    $s3, 24($k0) 
  sw    $s4, 28($k0) 
  sw    $s5, 32($k0) 
  sw    $s6, 36($k0) 
  sw    $s7, 40($k0) 
  sw    $t0, 44($k0)    
  sw    $t1, 48($k0)     
  sw    $t2, 52($k0) 
  sw    $t3, 56($k0) 
  sw    $t4, 60($k0) 
  sw    $t5, 64($k0) 
  sw    $t6, 68($k0) 
  sw    $t7, 72($k0)


	mfc0 $k0, $13 #Get cause register
	srl $a0, $k0, 2
	and $a0, $a0, 0xf #ExcCode field
	bne $a0, 0, done

interrupt_dispatch:
	mfc0 $k0, $13 #Get cause register again
	beq $k0, $zero, done

	and $a0, $k0, MAX_GROWTH_INT_MASK #is there a plant at max growth
	bne $a0, 0, max_plant

	and $a0, $k0, ON_FIRE_MASK #is there a a plant on fire
	bne $a0, 0, fire_interrupt

#	and $a0, $k0, BONK_MASK #are we bumping into walls
#	bne $a0, 0, bonk_interrupt

	and $a0, $k0, REQUEST_PUZZLE_INT_MASK #Is there a puzzle timer
	bne $a0, 0, request_puzzle

	
	#add dispatch for other interrupt types
	#syscall
	j done

max_plant:
	sw $0, MAX_GROWTH_ACK
	lw $s0, MAX_GROWTH_TILE
  la $s1, harvest_loc_queue
  la $a0, harvest_loc_back
  lw $a0, 0($a0)
  mul $a0, $a0, 4
  add $s1, $s1, $a0
  la $a0, harvest_loc_back
  lw $a1, 0($a0)
  add $a1, $a1, 1
  blt $a1, 100, store_harvest_back
  li $a1, 0

store_harvest_back:
  sw $a1, 0($a0)
  sw $s0, 0($s1)
  j interrupt_dispatch
#	lw $s2, BOT_X
	#only called for our tile

fire_interrupt:
  sw $0, ON_FIRE_ACK
  lw $s0, GET_FIRE_LOC
  lw $s1, dest
  beq $s0, $s1, change_action
  la $s1, fire_loc_queue
  la $a0, fire_loc_back
  lw $a0, 0($a0)
  mul $a0, $a0, 4
  add $s1, $s1, $a0
  la $a0, fire_loc_back
  lw $a1, 0($a0)
  add $a1, $a1, 1
  blt $a1, 100, store_fire_back
  li $a1, 0

store_fire_back:
  sw $a1, 0($a0)
  sw $s0, 0($s1)
  j interrupt_dispatch
#	lw $s2, BOT_X
	#only called for our tile

change_action:
  li $s0, 1
  sw $s0, action
  j interrupt_dispatch
bonk_interrupt:
  sw $0, BONK_ACK
  li $a0, 75 #set angle 135 relative to actual angle
  sw $a0, ANGLE
  li $a1, 0
  sw $a1, ANGLE_CONTROL
  li $a0, 10 # Not sure what velocity we want this to be 10 is highest but it's a little fast
  sw $a0, VELOCITY
  j interrupt_dispatch
  
  

request_puzzle:
	sw $0, REQUEST_PUZZLE_ACK
	la $a0, solution
	la $a1, puzzle
        jal recursive_backtracking
        sw $a0, SUBMIT_SOLUTION
        j clear_solution

clear_solution:
        move $s1, $0
	la $s0 solution
  	j for_loop

for_loop:
  	bge $s1, 328, exit_loop
   	sw $0, 0($s0)
  	add $s1, $s1, 4
  	add $s0, $s0, 4
  	j for_loop

exit_loop:
	lw $s0, GET_NUM_SEEDS
	blt $s0, 25, get_seeds
	lw $s0, GET_NUM_WATER_DROPS
	blt $s0, 250, get_water

get_fire_starter:

	lw $s0, GET_NUM_FIRE_STARTERS
	beq $s0, 10, get_water

        li $a0, 2
	sw $a0, SET_RESOURCE_TYPE

	la $a0, puzzle
	sw $a0, REQUEST_PUZZLE
        j interrupt_dispatch

get_seeds:

        li $a0, 1
	sw $a0, SET_RESOURCE_TYPE

	la $a0, puzzle
	sw $a0, REQUEST_PUZZLE
        j interrupt_dispatch

get_water:

        li $a0, 0
	sw $a0, SET_RESOURCE_TYPE

	la $a0, puzzle
	sw $a0, REQUEST_PUZZLE
        j interrupt_dispatch

done:
	la $k0, chunkIH
  lw    $ra, 0($k0)
  lw    $a0, 4($k0)     
  lw    $a1, 8($k0)    
  lw    $s0, 12($k0)    
  lw    $s1, 16($k0)     
  lw    $s2, 20($k0) 
  lw    $s3, 24($k0) 
  lw    $s4, 28($k0) 
  lw    $s5, 32($k0) 
  lw    $s6, 36($k0) 
  lw    $s7, 40($k0) 
  lw    $t0, 44($k0)    
  lw    $t1, 48($k0)     
  lw    $t2, 52($k0) 
  lw    $t3, 56($k0) 
  lw    $t4, 60($k0) 
  lw    $t5, 64($k0) 
  lw    $t6, 68($k0) 
  lw    $t7, 72($k0)



.set noat 
	move $at, $k1 #restores #at

.set at

	eret

.globl go_to_tile
  go_to_tile:
  sub $sp, $sp,76 
  sw    $ra, 0($sp)
  sw    $a0, 4($sp)     
  sw    $a1, 8($sp)    
  sw    $s0, 12($sp)    
  sw    $s1, 16($sp)     
  sw    $s2, 20($sp) 
  sw    $s3, 24($sp) 
  sw    $s4, 28($sp) 
  sw    $s5, 32($sp) 
  sw    $s6, 36($sp) 
  sw    $s7, 40($sp) 
  sw    $t0, 44($sp)    
  sw    $t1, 48($sp)     
  sw    $t2, 52($sp) 
  sw    $t3, 56($sp) 
  sw    $t4, 60($sp) 
  sw    $t5, 64($sp) 
  sw    $t6, 68($sp) 
  sw    $t7, 72($sp)
  #a0 is x, a1 is y
    
  lw $t0, BOT_X
  lw $t1, BOT_Y

  sub $a0, $a0, $t0
  sub $a1, $a1, $t1
  jal sb_arctan
  sw $v0, ANGLE
  li $t0, 1
  sw $t0, ANGLE_CONTROL
  li $t0, 10
  sw $t0, VELOCITY

  lw    $ra, 0($sp)
  lw    $a0, 4($sp)     
  lw    $a1, 8($sp)    
  lw    $s0, 12($sp)    
  lw    $s1, 16($sp)     
  lw    $s2, 20($sp) 
  lw    $s3, 24($sp) 
  lw    $s4, 28($sp) 
  lw    $s5, 32($sp) 
  lw    $s6, 36($sp) 
  lw    $s7, 40($sp) 
  lw    $t0, 44($sp)    
  lw    $t1, 48($sp)     
  lw    $t2, 52($sp) 
  lw    $t3, 56($sp) 
  lw    $t4, 60($sp) 
  lw    $t5, 64($sp) 
  lw    $t6, 68($sp) 
  lw    $t7, 72($sp) 
  add $sp, $sp, 76
  jr $ra

.globl sb_arctan
#start arctan
  sb_arctan:
  sub $sp, $sp,80 
  sw    $ra, 0($sp)
  sw    $a0, 4($sp)     
  sw    $a1, 8($sp)    
  s.s    $f0, 12($sp)    
  s.s    $f1, 16($sp)     
  s.s    $f2, 20($sp) 
  s.s    $f3, 24($sp) 
  s.s    $f4, 28($sp) 
  s.s    $f5, 32($sp) 
  s.s    $f6, 36($sp) 
  s.s    $f7, 40($sp) 
  s.s    $f8, 44($sp) 
  sw    $t0, 48($sp)    
  sw    $t1, 52($sp)     
  sw    $t2, 56($sp) 
  sw    $t3, 60($sp) 
  sw    $t4, 64($sp) 
  sw    $t5, 68($sp) 
  sw    $t6, 72($sp) 
  sw    $t7, 76($sp) 


    li  $v0, 0    # angle = 0;

    abs $t0, $a0  # get absolute values
    abs $t1, $a1
    ble $t1, $t0, no_TURN_90    

    ## if (abs(y) > abs(x)) { rotate 90 degrees }
    move  $t0, $a1  # int temp = y;
    neg $a1, $a0  # y = -x;      
    move  $a0, $t0  # x = temp;    
    li  $v0, 90   # angle = 90;  

  no_TURN_90:
    bgez  $a0, pos_x  # skip if (x >= 0)

    ## if (x < 0) 
    add $v0, $v0, 180 # angle += 180;

  pos_x:
    mtc1  $a0, $f0
    mtc1  $a1, $f1
    cvt.s.w $f0, $f0  # convert from ints to floats
    cvt.s.w $f1, $f1
    
    div.s $f0, $f1, $f0 # float v = (float) y / (float) x;

    mul.s $f1, $f0, $f0 # v^^2
    mul.s $f2, $f1, $f0 # v^^3
    l.s $f3, three  # load 5.0
    div.s   $f3, $f2, $f3 # v^^3/3
    sub.s $f6, $f0, $f3 # v - v^^3/3

    mul.s $f4, $f1, $f2 # v^^5
    l.s $f5, five # load 3.0
    div.s   $f5, $f4, $f5 # v^^5/5
    add.s $f6, $f6, $f5 # value = v - v^^3/3 + v^^5/5

    l.s $f8, PI   # load PI
    div.s $f6, $f6, $f8 # value / PI
    l.s $f7, F180 # load 180.0
    mul.s $f6, $f6, $f7 # 180.0 * value / PI

    cvt.w.s $f6, $f6  # convert "delta" back to integer
    mfc1  $t0, $f6
    add $v0, $v0, $t0 # angle += delta


  lw    $ra, 0($sp)
  lw    $a0, 4($sp)     
  lw    $a1, 8($sp)    
  l.s    $f0, 12($sp)    
  l.s    $f1, 16($sp)     
  l.s    $f2, 20($sp) 
  l.s    $f3, 24($sp) 
  l.s    $f4, 28($sp) 
  l.s    $f5, 32($sp) 
  l.s    $f6, 36($sp) 
  l.s    $f7, 40($sp) 
  l.s    $f8, 44($sp) 
  lw    $t0, 48($sp)    
  lw    $t1, 52($sp)     
  lw    $t2, 56($sp) 
  lw    $t3, 60($sp) 
  lw    $t4, 64($sp) 
  lw    $t5, 68($sp) 
  lw    $t6, 72($sp) 
  lw    $t7, 76($sp) 
  add $sp, $sp, 80
  jr $ra
#end arctan








#code puzzle solver.................
.globl recursive_backtracking
recursive_backtracking:
  sub   $sp, $sp, 680
  sw    $ra, 0($sp)
  sw    $a0, 4($sp)     # solution
  sw    $a1, 8($sp)     # puzzle
  sw    $s0, 12($sp)    # position
  sw    $s1, 16($sp)    # val
  sw    $s2, 20($sp)    # 0x1 << (val - 1)
                        # sizeof(Puzzle) = 8
                        # sizeof(Cell [81]) = 648

  jal   is_complete
  bne   $v0, $0, recursive_backtracking_return_one
  lw    $a0, 4($sp)     # solution
  lw    $a1, 8($sp)     # puzzle
  jal   get_unassigned_position
  move  $s0, $v0        # position
  li    $s1, 1          # val = 1
recursive_backtracking_for_loop:
  lw    $a0, 4($sp)     # solution
  lw    $a1, 8($sp)     # puzzle
  lw    $t0, 0($a1)     # puzzle->size
  add   $t1, $t0, 1     # puzzle->size + 1
  bge   $s1, $t1, recursive_backtracking_return_zero  # val < puzzle->size + 1
  lw    $t1, 4($a1)     # puzzle->grid
  mul   $t4, $s0, 8     # sizeof(Cell) = 8
  add   $t1, $t1, $t4   # &puzzle->grid[position]
  lw    $t1, 0($t1)     # puzzle->grid[position].domain
  sub   $t4, $s1, 1     # val - 1
  li    $t5, 1
  sll   $s2, $t5, $t4   # 0x1 << (val - 1)
  and   $t1, $t1, $s2   # puzzle->grid[position].domain & (0x1 << (val - 1))
  beq   $t1, $0, recursive_backtracking_for_loop_continue # if (domain & (0x1 << (val - 1)))
  mul   $t0, $s0, 4     # position * 4
  add   $t0, $t0, $a0
  add   $t0, $t0, 4     # &solution->assignment[position]
  sw    $s1, 0($t0)     # solution->assignment[position] = val
  lw    $t0, 0($a0)     # solution->size
  add   $t0, $t0, 1
  sw    $t0, 0($a0)     # solution->size++
  add   $t0, $sp, 32    # &grid_copy
  sw    $t0, 28($sp)    # puzzle_copy.grid = grid_copy !!!
  move  $a0, $a1        # &puzzle
  add   $a1, $sp, 24    # &puzzle_copy
  jal   clone           # clone(puzzle, &puzzle_copy)
  mul   $t0, $s0, 8     # !!! grid size 8
  lw    $t1, 28($sp)
  
  add   $t1, $t1, $t0   # &puzzle_copy.grid[position]
  sw    $s2, 0($t1)     # puzzle_copy.grid[position].domain = 0x1 << (val - 1);
  move  $a0, $s0
  add   $a1, $sp, 24
  jal   forward_checking  # forward_checking(position, &puzzle_copy)
  beq   $v0, $0, recursive_backtracking_skip

  lw    $a0, 4($sp)     # solution
  add   $a1, $sp, 24    # &puzzle_copy
  jal   recursive_backtracking
  beq   $v0, $0, recursive_backtracking_skip
  j     recursive_backtracking_return_one # if (recursive_backtracking(solution, &puzzle_copy))
recursive_backtracking_skip:
  lw    $a0, 4($sp)     # solution
  mul   $t0, $s0, 4
  add   $t1, $a0, 4
  add   $t1, $t1, $t0
  sw    $0, 0($t1)      # solution->assignment[position] = 0
  lw    $t0, 0($a0)
  sub   $t0, $t0, 1
  sw    $t0, 0($a0)     # solution->size -= 1
recursive_backtracking_for_loop_continue:
  add   $s1, $s1, 1     # val++
  j     recursive_backtracking_for_loop
recursive_backtracking_return_zero:
  li    $v0, 0
  j     recursive_backtracking_return
recursive_backtracking_return_one:
  li    $v0, 1
recursive_backtracking_return:
  lw    $ra, 0($sp)
  lw    $a0, 4($sp)
  lw    $a1, 8($sp)
  lw    $s0, 12($sp)
  lw    $s1, 16($sp)
  lw    $s2, 20($sp)
  add   $sp, $sp, 680
  jr    $ra


#clone....
.globl clone
clone:

    lw  $t0, 0($a0)
    sw  $t0, 0($a1)

    mul $t0, $t0, $t0
    mul $t0, $t0, 2 # two words in one grid

    lw  $t1, 4($a0) # &puzzle(ori).grid
    lw  $t2, 4($a1) # &puzzle(clone).grid

    li  $t3, 0 # i = 0;
clone_for_loop:
    bge  $t3, $t0, clone_for_loop_end
    sll $t4, $t3, 2 # i * 4
    add $t5, $t1, $t4 # puzzle(ori).grid ith word
    lw   $t6, 0($t5)

    add $t5, $t2, $t4 # puzzle(clone).grid ith word
    sw   $t6, 0($t5)
    
    addi $t3, $t3, 1 # i++
    
    j    clone_for_loop
clone_for_loop_end:

    jr  $ra


#forward checking .....
.globl forward_checking
forward_checking:
  sub   $sp, $sp, 24
  sw    $ra, 0($sp)
  sw    $a0, 4($sp)
  sw    $a1, 8($sp)
  sw    $s0, 12($sp)
  sw    $s1, 16($sp)
  sw    $s2, 20($sp)
  lw    $t0, 0($a1)     # size
  li    $t1, 0          # col = 0
fc_for_col:
  bge   $t1, $t0, fc_end_for_col  # col < size
  div   $a0, $t0
  mfhi  $t2             # position % size
  mflo  $t3             # position / size
  beq   $t1, $t2, fc_for_col_continue    # if (col != position % size)
  mul   $t4, $t3, $t0
  add   $t4, $t4, $t1   # position / size * size + col
  mul   $t4, $t4, 8
  lw    $t5, 4($a1) # puzzle->grid
  add   $t4, $t4, $t5   # &puzzle->grid[position / size * size + col].domain
  mul   $t2, $a0, 8   # position * 8
  add   $t2, $t5, $t2 # puzzle->grid[position]
  lw    $t2, 0($t2) # puzzle -> grid[position].domain
  not   $t2, $t2        # ~puzzle->grid[position].domain
  lw    $t3, 0($t4) #
  and   $t3, $t3, $t2
  sw    $t3, 0($t4)
  beq   $t3, $0, fc_return_zero # if (!puzzle->grid[position / size * size + col].domain)
fc_for_col_continue:
  add   $t1, $t1, 1     # col++
  j     fc_for_col
fc_end_for_col:
  li    $t1, 0          # row = 0
fc_for_row:
  bge   $t1, $t0, fc_end_for_row  # row < size
  div   $a0, $t0
  mflo  $t2             # position / size
  mfhi  $t3             # position % size
  beq   $t1, $t2, fc_for_row_continue
  lw    $t2, 4($a1)     # puzzle->grid
  mul   $t4, $t1, $t0
  add   $t4, $t4, $t3
  mul   $t4, $t4, 8
  add   $t4, $t2, $t4   # &puzzle->grid[row * size + position % size]
  lw    $t6, 0($t4)
  mul   $t5, $a0, 8
  add   $t5, $t2, $t5
  lw    $t5, 0($t5)     # puzzle->grid[position].domain
  not   $t5, $t5
  and   $t5, $t6, $t5
  sw    $t5, 0($t4)
  beq   $t5, $0, fc_return_zero
fc_for_row_continue:
  add   $t1, $t1, 1     # row++
  j     fc_for_row
fc_end_for_row:

  li    $s0, 0          # i = 0
fc_for_i:
  lw    $t2, 4($a1)
  mul   $t3, $a0, 8
  add   $t2, $t2, $t3
  lw    $t2, 4($t2)     # &puzzle->grid[position].cage
  lw    $t3, 8($t2)     # puzzle->grid[position].cage->num_cell
  bge   $s0, $t3, fc_return_one
  lw    $t3, 12($t2)    # puzzle->grid[position].cage->positions
  mul   $s1, $s0, 4
  add   $t3, $t3, $s1
  lw    $t3, 0($t3)     # pos
  lw    $s1, 4($a1)
  mul   $s2, $t3, 8
  add   $s2, $s1, $s2   # &puzzle->grid[pos].domain
  lw    $s1, 0($s2)
  move  $a0, $t3
  jal get_domain_for_cell
  lw    $a0, 4($sp)
  lw    $a1, 8($sp)
  and   $s1, $s1, $v0
  sw    $s1, 0($s2)     # puzzle->grid[pos].domain &= get_domain_for_cell(pos, puzzle)
  beq   $s1, $0, fc_return_zero
fc_for_i_continue:
  add   $s0, $s0, 1     # i++
  j     fc_for_i
fc_return_one:
  li    $v0, 1
  j     fc_return
fc_return_zero:
  li    $v0, 0
fc_return:
  lw    $ra, 0($sp)
  lw    $a0, 4($sp)
  lw    $a1, 8($sp)
  lw    $s0, 12($sp)
  lw    $s1, 16($sp)
  lw    $s2, 20($sp)
  add   $sp, $sp, 24
  jr    $ra


#get_domain_for_cell
.globl get_domain_for_cell
get_domain_for_cell:
    # save registers    
    sub $sp, $sp, 36
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    sw $s4, 20($sp)
    sw $s5, 24($sp)
    sw $s6, 28($sp)
    sw $s7, 32($sp)

    li $t0, 0 # valid_domain
    lw $t1, 4($a1) # puzzle->grid (t1 free)
    sll $t2, $a0, 3 # position*8 (actual offset) (t2 free)
    add $t3, $t1, $t2 # &puzzle->grid[position]
    lw  $t4, 4($t3) # &puzzle->grid[position].cage
    lw  $t5, 0($t4) # puzzle->grid[posiition].cage->operation

    lw $t2, 4($t4) # puzzle->grid[position].cage->target

    move $s0, $t2   # remain_target = $s0  *!*!
    lw $s1, 8($t4) # remain_cell = $s1 = puzzle->grid[position].cage->num_cell
    lw $s2, 0($t3) # domain_union = $s2 = puzzle->grid[position].domain
    move $s3, $t4 # puzzle->grid[position].cage
    li $s4, 0   # i = 0
    move $s5, $t1 # $s5 = puzzle->grid
    move $s6, $a0 # $s6 = position
    # move $s7, $s2 # $s7 = puzzle->grid[position].domain

    bne $t5, 0, gdfc_check_else_if

    li $t1, 1
    sub $t2, $t2, $t1 # (puzzle->grid[position].cage->target-1)
    sll $v0, $t1, $t2 # valid_domain = 0x1 << (prev line comment)
    j gdfc_end # somewhere!!!!!!!!

gdfc_check_else_if:
    bne $t5, '+', gdfc_check_else

gdfc_else_if_loop:
    lw $t5, 8($s3) # puzzle->grid[position].cage->num_cell
    bge $s4, $t5, gdfc_for_end # branch if i >= puzzle->grid[position].cage->num_cell
    sll $t1, $s4, 2 # i*4
    lw $t6, 12($s3) # puzzle->grid[position].cage->positions
    add $t1, $t6, $t1 # &puzzle->grid[position].cage->positions[i]
    lw $t1, 0($t1) # pos = puzzle->grid[position].cage->positions[i]
    add $s4, $s4, 1 # i++

    sll $t2, $t1, 3 # pos * 8
    add $s7, $s5, $t2 # &puzzle->grid[pos]
    lw  $s7, 0($s7) # puzzle->grid[pos].domain

    beq $t1, $s6 gdfc_else_if_else # branch if pos == position

    

    move $a0, $s7 # $a0 = puzzle->grid[pos].domain
    jal is_single_value_domain
    bne $v0, 1 gdfc_else_if_else # branch if !is_single_value_domain()
    move $a0, $s7
    jal convert_highest_bit_to_int
    sub $s0, $s0, $v0 # remain_target -= convert_highest_bit_to_int
    addi $s1, $s1, -1 # remain_cell -= 1
    j gdfc_else_if_loop
gdfc_else_if_else:
    or $s2, $s2, $s7 # domain_union |= puzzle->grid[pos].domain
    j gdfc_else_if_loop

gdfc_for_end:
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal get_domain_for_addition # $v0 = valid_domain = get_domain_for_addition()
    j gdfc_end

gdfc_check_else:
    lw $t3, 12($s3) # puzzle->grid[position].cage->positions
    lw $t0, 0($t3) # puzzle->grid[position].cage->positions[0]
    lw $t1, 4($t3) # puzzle->grid[position].cage->positions[1]
    xor $t0, $t0, $t1
    xor $t0, $t0, $s6 # other_pos = $t0 = $t0 ^ position
    lw $a0, 4($s3) # puzzle->grid[position].cage->target

    sll $t2, $s6, 3 # position * 8
    add $a1, $s5, $t2 # &puzzle->grid[position]
    lw  $a1, 0($a1) # puzzle->grid[position].domain
    # move $a1, $s7 

    sll $t1, $t0, 3 # other_pos*8 (actual offset)
    add $t3, $s5, $t1 # &puzzle->grid[other_pos]
    lw $a2, 0($t3)  # puzzle->grid[other_pos].domian

    jal get_domain_for_subtraction # $v0 = valid_domain = get_domain_for_subtraction()
    # j gdfc_end
gdfc_end:
# restore registers
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $s4, 20($sp)
    lw $s5, 24($sp)
    lw $s6, 28($sp)
    lw $s7, 32($sp)
    add $sp, $sp, 36    
    jr $ra	

.globl convert_highest_bit_to_int
convert_highest_bit_to_int:
    move  $v0, $0             # result = 0

chbti_loop:
    beq   $a0, $0, chbti_end
    add   $v0, $v0, 1         # result ++
    sra   $a0, $a0, 1         # domain >>= 1
    j     chbti_loop

chbti_end:
    jr    $ra

.globl is_single_value_domain
is_single_value_domain:
    beq    $a0, $0, isvd_zero     # return 0 if domain == 0
    sub    $t0, $a0, 1	          # (domain - 1)
    and    $t0, $t0, $a0          # (domain & (domain - 1))
    bne    $t0, $0, isvd_zero     # return 0 if (domain & (domain - 1)) != 0
    li     $v0, 1
    jr	   $ra

isvd_zero:	   
    li	   $v0, 0
    jr	   $ra
    
.globl get_domain_for_addition
get_domain_for_addition:
    sub    $sp, $sp, 20
    sw     $ra, 0($sp)
    sw     $s0, 4($sp)
    sw     $s1, 8($sp)
    sw     $s2, 12($sp)
    sw     $s3, 16($sp)
    move   $s0, $a0                     # s0 = target
    move   $s1, $a1                     # s1 = num_cell
    move   $s2, $a2                     # s2 = domain

    move   $a0, $a2
    jal    convert_highest_bit_to_int
    move   $s3, $v0                     # s3 = upper_bound

    sub    $a0, $0, $s2                 # -domain
    and    $a0, $a0, $s2                # domain & (-domain)
    jal    convert_highest_bit_to_int   # v0 = lower_bound
     
    sub    $t0, $s1, 1                  # num_cell - 1
    mul    $t0, $t0, $v0                # (num_cell - 1) * lower_bound
    sub    $t0, $s0, $t0                # t0 = high_bits
    bge    $t0, 0, gdfa_skip0

    li     $t0, 0

gdfa_skip0:
    bge    $t0, $s3, gdfa_skip1

    li     $t1, 1          
    sll    $t0, $t1, $t0                # 1 << high_bits
    sub    $t0, $t0, 1                  # (1 << high_bits) - 1
    and    $s2, $s2, $t0                # domain & ((1 << high_bits) - 1)

gdfa_skip1:    
    sub    $t0, $s1, 1                  # num_cell - 1
    mul    $t0, $t0, $s3                # (num_cell - 1) * upper_bound
    sub    $t0, $s0, $t0                # t0 = low_bits
    ble    $t0, $0, gdfa_skip2

    sub    $t0, $t0, 1                  # low_bits - 1
    sra    $s2, $s2, $t0                # domain >> (low_bits - 1)
    sll    $s2, $s2, $t0                # domain >> (low_bits - 1) << (low_bits - 1)

gdfa_skip2:    
    move   $v0, $s2                     # return domain
    lw     $ra, 0($sp)
    lw     $s0, 4($sp)
    lw     $s1, 8($sp)
    lw     $s2, 12($sp)
    lw     $s3, 16($sp)
    add    $sp, $sp, 20
    jr     $ra


.globl get_domain_for_subtraction
get_domain_for_subtraction:
    li     $t0, 1              
    li     $t1, 2
    mul    $t1, $t1, $a0            # target * 2
    sll    $t1, $t0, $t1            # 1 << (target * 2)
    or     $t0, $t0, $t1            # t0 = base_mask
    li     $t1, 0                   # t1 = mask

gdfs_loop:
    beq    $a2, $0, gdfs_loop_end	
    and    $t2, $a2, 1              # other_domain & 1
    beq    $t2, $0, gdfs_if_end
	   
    sra    $t2, $t0, $a0            # base_mask >> target
    or     $t1, $t1, $t2            # mask |= (base_mask >> target)

gdfs_if_end:
    sll    $t0, $t0, 1              # base_mask <<= 1
    sra    $a2, $a2, 1              # other_domain >>= 1
    j      gdfs_loop

gdfs_loop_end:
    and    $v0, $a1, $t1            # domain & mask
    jr	   $ra    
    # We highly recommend that you copy in our 
    # solution when it is released on Tuesday night 
    # after the late deadline for Lab7.2
    #
    # If you reach this part before Tuesday night,
    # you can paste your Lab7.2 solution here for now

#is_complete
.globl is_complete
is_complete:
  lw    $t0, 0($a0)       # solution->size
  lw    $t1, 0($a1)       # puzzle->size
  mul   $t1, $t1, $t1     # puzzle->size * puzzle->size
  move	$v0, $0
  seq   $v0, $t0, $t1
  jr $ra 

#get_unassigned_position

.globl get_unassigned_position
get_unassigned_position:
  li    $v0, 0            # unassigned_pos = 0
  lw    $t0, 0($a1)       # puzzle->size
  mul  $t0, $t0, $t0     # puzzle->size * puzzle->size
  add   $t1, $a0, 4       # &solution->assignment[0]
get_unassigned_position_for_begin:
  bge   $v0, $t0, get_unassigned_position_return  # if (unassigned_pos < puzzle->size * puzzle->size)
  mul  $t2, $v0, 4
  add   $t2, $t1, $t2     # &solution->assignment[unassigned_pos]
  lw    $t2, 0($t2)       # solution->assignment[unassigned_pos]
  beq   $t2, 0, get_unassigned_position_return  # if (solution->assignment[unassigned_pos] == 0)
  add   $v0, $v0, 1       # unassigned_pos++
  j   get_unassigned_position_for_begin
get_unassigned_position_return:
  jr    $ra
