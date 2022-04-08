;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Author: Harel Zeevi			;
;	Game: 	Missile Command  	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IDEAL
MODEL small
STACK 100h
jumps 
p186
DATASEG
	 msg db 'hello world', 10, 13, '$'
	
	; Enemy 
	enemy_x_cors dw  10 dup (-1)  		; An array of the enemy's missile's x coordinates
	
	enemy_y_cors dw  10 dup (-1)		; An array of the enemy's missile's y coordinates
	
	enemy_x_slopes dw 10 dup (-1) 		; An array of the enemy's missile's slopes 

	enemy_y_slopes dw 10 dup (-1)		; An array of the enemy's missile's slopes 
	
	; generated values for enemy
	enemy_slope_x db ?			; randomly gererated x slope
					
	enemy_slope_y db ?			; randomly gererated y slope
	
	enemy_init_x_cor dw ?		; randomly gererated x coordinate
	
	
	; Defender
	defender_x_cors dw  10 dup (-1) 		; An array of the defender's missile's x coordinates
	
	defender_y_cors dw 	10 dup (-1)		; An array of the defender's missile's y coordinates
	
	defender_x_slopes dw  10 dup (-1)	; An array of the defender's missile's y slopes 

	defender_y_slopes dw  10 dup (-1)	; An array of the defender's missile's x slopes 
	
	remainders dw 10 dup (-1) 			; An array of remainders of slope
	
	defender_stop_y_cors dw  10 dup (-1)	; An array of the defender's missile's ending y coordinates
	
	defender_stop_x_cors dw  10 dup (-1)	; An array of the defender's missile's ending y coordinates
	
	defender_arr_pointer dw 18
	
	; Game objects
	launchers db 2 dup(1) 				; An array of the 2 lauchers, the array contains 2 launchers x cors (or -1). 
	
	houses db 6 dup(1) 					; An array of the 6 houses, the array contains 6 house x cors (or -1). 

	
	; Score
	score dw 0 							; A global variable that stores the score of the player.

	st_score db '			   ', 10, 13			; A string that stores the word "SCORE: "
			 db '		SCORE: ', 10, 13, '$'			

	slopes_offset dw 0					; offset of the slope array


	; Graphics
	x dw ? 								; x cor of pixel
	
	y dw ? 								; y cor of pixel
	
	rect_width dw ?						; width of rectangle
	
	rect_height dw ? 					; height of rectangle
	
	radius dw ?							; radius of explosion
	
	color db ?							; the current color
	
	x_cor dw ? 							; x coordinate of a mouse click
	
	y_cor dw ?							; y coordinate of a mouse click
	
	surface_y dw 180 					; A constant which containts the surface's Y coordinate 

	
	; calc slope returned values
	x_start dw ?						; the returned starting x coordinate
	
	x_slope dw ?						; the returned slope of x axis 
			
	y_slope dw ?						; the returned slope of y axis
	
	
	; mouse click 
	is_clicked db ? 					; stores 0 or 1 id mouse was clicked
	
	last_time dw ? 						; stores the last time that was measured	
	
	; collision
	arr_rocket_rem dw ?					; stores the offset of rocket's array from which a rocket will be removed

	has_exploded db ?					; stores weather or not an explosion had happened in the current iteration of main
	
	
	; Bitmap variables 
	filename db 'pic2.bmp',0

	filehandle dw ?
	
	Header db 54 dup (0)
	
	Palette db 256*4 dup (0)
	
	ScrLine db 320 dup (0)
	
	ErrorMsg db 'Error', 13, 10,'$'



	game_status db 0 					; stores wheather the game is over or not, 1 = game over. 0 = keep playing 
	
	
	; game status pics constants
	pic_win  db 'pic3.bmp', 0
	
	pic_loose db 'pic4.bmp', 0
	
	pic_opening db 'pic2.bmp', 0
	
	pic_rules db 'pic1.bmp', 0
	
	; devisors table for print_number proc
	divisorTable db 10, 1, 0
	
	; cursor vars (for printing score)
	row db ?
	column db ?
	
	
	; enemy rockets genrating rate
	generating_rate db 2 ; generate enemy every 2 sec = normal rate
	
CODESEG

	;;;;;;;;;;;;;;;;
	;;; Logics   ;;;
	;;;;;;;;;;;;;;;;
	
	; This procedure iterates over the Enemy_slopes array and updates the matching x, y
	; coordinates of the matching rockets in the arrays: Enemey_x_cors Enemy_y_cors 
	proc update_coordinates
		push bp
		mov bp, sp
		
		; loop counter cx	
		; 10 woold've update the first in the next array
		mov cx, 18
		
		; popping to si the type of arr to update 
		;1 => enemy_x_cors, 2 => enemy_y_cors
		;3 => defender_x_cors, 4 => defender_y_cors
		mov si, ARRAY_NUM
		
		cmp si, 2
		je enemy_y_cors_update
		
		cmp si, 3
		je defender_x_cors_update
		
		cmp si, 4 
		je defender_y_cors_update
		
		; gotten 1: normally when nothing was not gotten and therfore enemy_x_cors will be updated
		lea di, [enemy_x_cors]
		lea ax, [enemy_x_slopes]
		jmp update_cors
		
		; gotten 2: when the user wants to update the enemy_y_cors arr
		enemy_y_cors_update:
			lea di, [enemy_y_cors]
			lea ax, [enemy_y_slopes]
			mov [slopes_offset], ax
			jmp update_cors
			
		; gotten 3: when the user wants to update the defender_x_cors arr
		defender_x_cors_update:
			lea di, [defender_x_cors]
			lea ax, [defender_x_slopes]
			mov [slopes_offset], ax
			jmp update_cors
			
		; gotten 4: when the user wants to update the defender_y_cors arr
		defender_y_cors_update:
			lea di, [defender_y_cors]
			lea ax, [defender_y_slopes]
			mov [slopes_offset], ax
			jmp update_cors
			

		update_cors:
			; using bx for a pointer since cx is not allowed to be used as a pointer
			mov bx, cx 

			; otherwise dx will be the slope which will be added to the y value
			; slopes_offset - the location of the slopes array
			; bx - the offset inside the array
			
			; load offset of enemy_x_slopes
			cmp si, 2
			je load_enemy_y_slopes 
			
			; load offset of enemy_x_slopes
			cmp si, 3
			je load_defender_x_slopes
			
			; load offset of enemy_x_slopes
			cmp si, 4
			je load_defender_y_slopes
			
			
			; load_enemy_x_slopes
			mov dx, [offset enemy_x_slopes + bx] 
			jmp update
			
			load_enemy_y_slopes:
				mov dx, [offset enemy_y_slopes + bx] 
				jmp update
			
			load_defender_x_slopes:
				mov dx, [offset defender_x_slopes + bx] 
				jmp update
			
			load_defender_y_slopes:
				mov dx, [offset defender_y_slopes + bx] 
		
			
			update:
				;The offset of the array is located in di register
				mov ax, [word ptr di + bx]
				cmp ax, 0	
			
				; if value is -1
				jl return_value_to_arr
				
				; changing the x / y coordinate
				add ax, dx
			
				; returning the increased / not increased value
				return_value_to_arr:
					mov [word ptr di + bx], ax
			
			; the loop counter
			sub cx, 2
			cmp cx, 0 ; loop until index 0
			jge update_cors
		pop bp
		ret 2 ; return gotten parameter
	endp update_coordinates



	; This function updates all of the arrays that contains coordinates
	; it uses the function "update_coordinates"
	proc update_enemy_defender_cors
		pusha 
		
		; update enemy coordinates
		push 1
		ARRAY_NUM equ [bp + 4]
		call update_coordinates
		
		push 2
		ARRAY_NUM equ [bp + 4]
		call update_coordinates
	
		; update defender coordinates
		push 3
		ARRAY_NUM equ [bp + 4]
		call update_coordinates
		
		push 4
		ARRAY_NUM equ [bp + 4]
		call update_coordinates
		
		popa
		ret 
	endp update_enemy_defender_cors
	
	

	; This procedure loop through the x coordinates of the missiles arrays and checks for collision
	; Between defender and enemy missiles. Deleting a missile also happens when one 
	; has reached the original click spot 
	proc check_explosion
		mov cx, 18
		loop_x_coordinates:
			mov bx, cx
			
			; dx - holds defender x cors
			mov dx, [offset defender_x_cors + bx]
			
			; there's no need to check explosion when the rocket value is -1
			cmp dx, 0
			jl update_loop_counter
			
			
			; check if the the rocket reached the final coordinates of the mouse click
			mov si, [offset defender_y_cors + bx]
			
			cmp si, [offset defender_stop_y_cors + bx]
			jbe explode
			
			ja update_loop_counter
				
			explode:			
				add [defender_arr_pointer], 2
				
				; remove the rocket
				mov [word ptr offset defender_x_cors + bx], -1
				
				push [offset defender_stop_x_cors + bx]		; X
				push [offset defender_stop_y_cors + bx]		; Y
				EXPLOSION_X equ [bp + 8]
				EXPLOSION_Y equ [bp + 6]
				call draw_explosion

				
			; decrease loop counter by 1 each iteration
			update_loop_counter:
				sub cx, 2
				cmp cx, 0 ; loop until index 0
				jne loop_x_coordinates
		ret 
	endp check_explosion



	; This procedure delays by a few milliseconds
	proc time_delay
		pusha			
		mov cx, 0
		mov dx, 20000		
		mov ah, 86h			; delay
		int 15h				; delay
		popa
		ret
	endp time_delay
	


	; This procedure waits for a keyboard click to continue
	proc wait_char
		mov ah, 0h
		int 16h
		ret
	endp wait_char
	
	

	; This procedure gets x and y coordinate, matches the
	; point to the closest launcher and calculates the slope 
	; between the launching point and the clicked point
	proc calc_slope
		push bp
		push di
		mov bp, sp
		
		mov bx, X1
		mov ax, Y1
		
		; y2 - y1 - both launchers have the same y cord of launching spot
		sub ax, 124	
		
		; 320 / 2 = 160 --> the line in the middle of the screen
		cmp bx, 160 
		
		; in the half of the 2nd launcher
		jae launcher1
		
		; in the half of the 1st launcher		
		jb launcher2 
		
		; Here we specify the accurate launching spot
		launcher1:
			cmp bx, 233
			jae launcher1_right
			jb launcher1_middle

			
		launcher2:
			cmp bx, 82
			jae launcher2_middle
			jb launcher2_left
		
		; calculate the slope with the 1st launcher to the left side
		launcher1_right:
			; x2 - x1
			sub bx, 254 ;left corner of launching box
			mov di, 254
			mov cx, 1
		
			mov si, bx
			neg si
			
			cmp si, ax 
			jae div_deltas ; if the delta x is bigger
			neg bx
			mov cx, -1			
			jmp div_deltas

		; calculate the slope with the 1st launcher to the middle
		launcher1_middle:
			; x2 - x1
			mov dx, bx
			mov bx, 230	; right corner of launching box
			mov di, 236
			sub bx, dx
			mov cx, -1 
			
			mov si, bx
			neg si
			jmp div_deltas

		
		; calculate the slope with the 2nd launcher to the middle
		launcher2_middle:
			; x2 - x1
			sub bx, 84 ;left corner of launching box
			mov di, 84
			mov cx, 1 ; in case of y divided by x
			mov si, bx
			neg si
			
			cmp si, ax 
			jae div_deltas ; if the delta x is bigger
			neg bx
			mov cx, -1
			jmp div_deltas
			
	
		; calculate the slope with the 1st launcher to the middle
		launcher2_left:
			; x2 - x1
			sub bx, 64	; right corner of launching box
			neg bx
			mov di, 64
			mov cx, -1 
			
			mov si, bx
			neg si ; make si negative so it would be compareable with ax
			
			
		div_deltas:
			cmp si, ax
			jbe x_div_y
			ja	y_div_x
			

		
		y_div_x:
			; first, check that delta x is greater than zero
			cmp bx, 0
			je accurate_spot
			
			xor dx, dx ; only ax is needed for the upper part of the devision
			cwd
			idiv bx ; finding the slope (slope => ax)
		
			shl cx, 2
			shl ax, 2
			mov [x_slope], cx ; move the x_slope
			mov [y_slope], ax ; move the y_slope
			
			cmp dx, 0F000h
			jb slope_x_normal
		
			; otherwise, slope x needs to be increased
			inc ax
	
			jmp check_zero_slope
		
		x_div_y:
			xor dx, dx ; only ax is needed for the upper part of the devision
			mov si, ax ; si - tmp register
			mov ax, bx ; swap ax and bx
			mov bx, si
			cwd
			idiv bx
			
			mov [y_slope], cx ; move the y_slope
			
			; no need to change it
			slope_x_normal:
				mov [x_slope], ax ; move the x_slope
			

		
		check_zero_slope:
			cmp [x_slope], 0
			je accurate_spot  
			jne set_starting_x
			
		; if there's no x slope than we will go to the axact y and x cor of the click
		; the program will move the click x coordinate to the starting x coordinate
		accurate_spot:
			mov ax, X1
			mov [x_start], ax
			jmp end_func
		
		set_starting_x:
			mov [x_start], di ; move the starting x coordinate

		cmp [y_slope], 0
		jg make_slope_neg
		jle end_func 
		
		make_slope_neg:
			neg [y_slope]

		end_func:

		pop di
		pop bp
		ret 4 ; popping the parameters
	endp calc_slope



	; This function generates a random number using the last_time that 
	; was measured of the last click and the current time of click.
	; the function will generate the enemy rocket's: 
	; slope (1 - 4), starting_x_cor (0 - 320), x_slope (-1 / 1) 
	proc generate_random	
		pusha
		
		mov cx, 18
		check_empty_place:
			mov di, cx 
			cmp [enemy_x_cors + di], -1 
			je generate_enemy
			
			; loop counter 
			sub cx, 2
			cmp cx, 0 
			jge check_empty_place
		
		cmp di, 0 
		jl full_array
		
		generate_enemy:
		mov ah, 2ch
		int 21h 	   	  ; interrupt for getting sys time
		
		mov si, dx		  ; in order to update last_time later on

		xor dx, [last_time] ; dl = 1/ 100 sec, dh = sec
		
		mov bl, 1
		and bl, dl
		
		xor bh, bh
	
		cmp bl, 0
		je negative_x_slope
		jne positive_x_slope
		
		negative_x_slope:
			mov [enemy_x_slopes + di], -1
			jmp random_y_slope 
			
		positive_x_slope:
			mov [enemy_x_slopes + di], 1
			
		random_y_slope:
			mov bl, 1b ; 0 - 1
			and bl, dh
			
			inc bl 		; 1- 2
	
			mov [enemy_y_slopes + di], bx
		
		; set initial random x coordinte for the enemy 
		init_enemy_x_cor:
			mov ax, dx ; divide by 319
			mov bx, 319
			cwd
			xor dx, dx
			div bx	; dx => conatians a number in the range 0 - 319
			mov [enemy_x_cors + di], dx 
			mov [enemy_y_cors + di], 17
		
		mov [last_time], si ; insert current time to last_time for the next enemy rocket

		full_array:
		popa 
		ret 
	endp generate_random
	

	; check 5 sec 
	proc randomize_enemy_rocket
		pusha 
		
		mov ah, 2ch
		int 21h ; get sys time 
		sub dx, [last_time] ; check if 5 sec have passed
		
		cmp dh, [generating_rate]
		jb no_generate
			
		call generate_random
		
		no_generate:
		popa 
		ret 
	endp randomize_enemy_rocket
	
	

	; This function gets an array type and an index of the array 
	; than, it ensures that the rocket is inside the bounds, 
	; if it doesn't, the rocket will be removed
	proc check_bounds
		push bp 
		mov bp, sp

		mov si, ARRAY_INDEX ; index in the arrays (0 - 9)
		
		mov ax, [offset enemy_x_cors + si]
		mov bx, [offset enemy_y_cors + si]
		jmp cmp_with_bounds

		cmp_with_bounds:
			; x coordinate comparison 
			cmp ax, 310 ; right bound of screen
			jae remove_enemy
			
			cmp ax, 0  ; right bound of screen 
			jle remove_enemy 
			
			; y coordinate comparison 
			cmp bx, 166 ; bottom bound of screen
			jae remove_enemy
			
			cmp bx, 10  ; top bound of screen 
			jle remove_enemy 
			jg finish_proc

		remove_enemy:
			mov [word ptr offset enemy_x_cors + si], -1 ;remove the rocket
			mov [has_exploded], 1
			
			; draw explosion
			push ax		; X
			push bx		; Y
			EXPLOSION_X equ [bp + 8]
			EXPLOSION_Y equ [bp + 6]
			call draw_explosion
		
			
		; continue and finish the proc
		finish_proc:
			pop bp
			ret 2
	endp check_bounds
	


	; this proc checks wheatehr the user have reached the winning 
	proc check_win
		pusha
		
		cmp [score], 100
		je win
		jne not_win
		
		win:
			; Graphic mode - clear screen
			mov ax, 13h
			int 10h

			mov [game_status], 1
			call time_delay
			call display_screen
			jmp end_game
			
		not_win:
		popa 
		ret 
	endp check_win
	
	
	
	; this procedure checks if the player had lost and if so it stops the game
	; the function will also display a "you lost" screen
	proc check_loose
		pusha
		 
		check_launchers:
			mov cx, 1
			launchers_loop:
				mov di, cx 
				cmp [launchers + di], 1 ; there is at least one launcher
				je keep_game 
							
				; loop counter
				dec cx
				cmp cx, 0 
				jge launchers_loop
		
		
		; else, meaning that all houses are destroyed 
		; Graphic mode - clear screen
		mov ax, 13h
		int 10h
		
		mov [game_status], 2
		call time_delay
		call display_screen
		
		jmp end_game
		
		keep_game:
			popa
			ret 
	endp check_loose
	
	
	
	; this procedure gets the keyboard buffer 
	; the proc checks if space was clicked, and if the user has more than 30 pts 
	; if so, all of the enemy rockets will be vanished immediately
	proc get_buffer
		pusha
		
		; check for clicked space - destroy all 
		cmp [score], 20
		ja destroy_all_valid
		jb not_destroy_all
		
		destroy_all_valid:
			xor ax, ax ; clear ax 
			
			; get keyboard status 
			mov ah, 6h
			int 21h 

			cmp al, '1' ; clicked 1
			je destroy_all
			jne not_destroy_all
			
			destroy_all:
				mov al, 0
				sub [score], 20
				call rem_enemies
				
				; clear buffer
				mov ah, 0ch
				int 21h 
				

		; in this case the player has less than 20 pts so he can't use "destroy" all 
		; another option is that the player didn't clicked space to activate this function
		not_destroy_all: 
		popa 
		ret 
	endp get_buffer
	
	
	
	; this proc removes all the enemies from the array of enemies 
	proc rem_enemies
		pusha
		
		mov bx, 18
		
		remove_enemies_loop:
			mov [enemy_x_cors + bx], -1
			
			; loop counter 
			sub bx, 2
			cmp bx, 0 
			jge remove_enemies_loop
		
		popa 
		ret 
	endp rem_enemies
	
	
	
	; this procedure sets the genrating pace of enemy rockets 
	; according to the user's score. above 50 = faster
	proc set_generating_rate
		cmp [score], 50 
		jb normal_generating_rate
		jae fast_generating_rate
		
		; back to normal genrating rate 
		normal_generating_rate:
			mov [generating_rate], 2
			jmp end_proc
			
		; higher pace 
		fast_generating_rate:
			mov [generating_rate], 1
	
		end_proc:
		ret 
	endp set_generating_rate
	
	
	
	;;;;;;;;;;;;;;;;
	;;; Graphics ;;;
	;;;;;;;;;;;;;;;;
	
	; this procedure initialize the basic graphics ofthe game
	proc game_graphics_init
		; Graphic mode
		mov ax, 13h
		int 10h
		
		mov [game_status], 0 ; opening image
		call display_screen
		
		call wait_char
		
		mov [game_status], 3 ; rules image
		call display_screen

		call wait_char
		
		; Graphic mode - clear screen
		mov ax, 13h
		int 10h

		call draw_background
		
		call mouse_config

		call init_score 
		
		ret 
	endp game_graphics_init
	
	
	
	; This procedure uses the interrupt INT 10h to draw one pixel 
	; It uses the global variables x and y coordinate and color 
	proc draw_pixel
		pusha
			
		mov bh,0h
		mov cx, [x]
		mov dx, [y]
		mov al,[color]
		mov ah,0ch
		int 10h
		
		popa
		ret
	endp draw_pixel
	
	
	
	; This procedure gets x, y coordinate and rectangle's width and height and color 
	; It uses the draw_pixel proc to draw a rectangle
	proc draw_rectangle
		pusha
		
		mov ax, [y]
		mov cx, [rect_width]
		draw_horizental:
			call draw_pixel
			
			mov dx, [rect_height]
			draw_vertical:
				call draw_pixel
				inc [y]
				
				dec dx
				cmp dx, 0
				jne draw_vertical

			mov [y], ax
			inc [x]
			dec cx
			cmp cx, 0
			jne draw_horizental
			
		popa
		ret
	endp draw_rectangle
	
	

	; This procedure draws a surface (large rectangle on the bottom)
	proc draw_surface
		; procedure parameters
		; x, y --> initial x and y coordinates
		; width - rectangle's width 
		; height - rectangle's height
		pusha
		mov [color], 1
		mov [rect_width], 319
		mov [rect_height], 20

		mov [x], 0
		mov bx, [surface_y]
		mov [y], bx
		
		call draw_rectangle
		
		popa
		ret 
	endp draw_surface
	
	

	; This procedure draw a launcher at a given x coordinate from the stack
	proc draw_launcher
		push bp
		mov bp, sp

		mov ax, LAUNCHER_X_COR
		
		mov bx, ERASE
		cmp bx, 1 ; erase / destroy a rocketequ [bp + 6] 
		je black1
		jne normal1
		
		black1:
			mov [color], 0
			jmp draw_lower_block 
			
		normal1:
			mov [color], 9
		
		; draw lower part of launcher 
		draw_lower_block:
			mov [rect_width],  31
			mov [rect_height], 10

			mov ax, LAUNCHER_X_COR
			mov [x], ax
			add [x], 10
			
			mov bx, [surface_y]
			mov [y], bx
			sub [y], 10
			
			call draw_rectangle
			
		; draw middle block
		mov [rect_width],  25
		mov [rect_height], 12

		mov ax, LAUNCHER_X_COR
		mov [x], ax
		add [x], 13
		
		mov bx, [surface_y]
		mov [y], bx
		sub [y], 20
		
		call draw_rectangle
		
		; draw upper block
		mov [rect_width],  15
		mov [rect_height], 30

		mov ax, LAUNCHER_X_COR
		mov [x], ax
		add [x], 18
		
		mov bx, [surface_y]
		mov [y], bx
		sub [y], 30
		
		call draw_rectangle
		
		; draw top stick
		mov [rect_width],  5
		mov [rect_height], 15

		mov ax, LAUNCHER_X_COR
		mov [x], ax
		add [x], 23
	
		mov bx, [surface_y]
		mov [y], bx
		sub [y], 45
		
		call draw_rectangle

		; draw electric ring 
		mov bx, ERASE
		cmp bx, 1 ; erase / destroy a rocketequ [bp + 6] 
		je black2
		jne normal2
		
		black2:
			mov [color], 0
			jmp draw_ring 
			
		normal2:
			mov [color], 7
			
		draw_ring:
			mov [rect_width],  9
			mov [rect_height], 8

			mov ax, LAUNCHER_X_COR
			mov [x], ax
			add [x], 21
			
			mov bx, [surface_y]
			mov [y], bx
			sub [y], 49
			
			call draw_rectangle
		
		
		; draw top launching box
		mov bx, ERASE
		cmp bx, 1 ; erase / destroy a rocketequ [bp + 6] 
		je black3
		jne normal3
		
		black3:
			mov [color], 0
			jmp draw_launching_box 
			
		normal3:
			mov [color], 13
			
		
		draw_launching_box:
			mov [rect_width],  7
			mov [rect_height], 6

			mov ax, LAUNCHER_X_COR
			mov [x], ax
			add [x], 22
					
			mov bx, [surface_y]
			mov [y], bx
			sub [y], 48
			
			call draw_rectangle

		pop bp
		ret 4 ;pop the pushed params
	endp draw_launcher
	
	
	
	; This procedure draws house at a given x coordinate
	proc draw_house
		push bp
		mov bp, sp
		
		mov ax, HOUSE_X_COR
		
		; draw base block
		mov [color], 6
		mov [rect_width],  30
		mov [rect_height], 20

		mov [x], ax
		add [x], 18
		
		mov bx, [surface_y]
		mov [y], bx
		sub [y], 20
		
		call draw_rectangle
		
		; draw window 1
		mov [color], 13
		mov [rect_width],  7
		mov [rect_height], 7

		mov [x], ax
		add [x], 22
		
		mov bx, [surface_y]
		mov [y], bx
		sub [y], 17
		
		call draw_rectangle
			
		; draw window 2
		mov [color], 13
		mov [rect_width],  7
		mov [rect_height], 7

		mov [x], ax
		add [x], 37
		
		mov bx, [surface_y]
		mov [y], bx
		sub [y], 17
		
		call draw_rectangle
		
		; draw door
		mov [color], 0
		mov [rect_width],  7
		mov [rect_height], 8

		mov [x], ax
		add [x], 29
		
		mov bx, [surface_y]
		mov [y], bx
		sub [y], 8
		
		call draw_rectangle
		
		; draw roof
		;;; draw lower block
		mov [color], 5
		mov [rect_width],  27
		mov [rect_height], 4

		mov [x], ax
		add [x], 19
		
		mov bx, [surface_y]
		mov [y], bx
		sub [y], 24
		
		call draw_rectangle
		
		;;; draw middle block
		mov [color], 5
		mov [rect_width],  19
		mov [rect_height], 4

		mov [x], ax
		add [x], 23
				
		mov bx, [surface_y]
		mov [y], bx
		sub [y], 28
		
		call draw_rectangle
		
		;;; draw upper block
		mov [color], 5
		mov [rect_width],  11
		mov [rect_height], 4

		mov [x], ax
		add [x], 27
				
		mov bx, [surface_y]
		mov [y], bx
		sub [y], 32
		
		call draw_rectangle	

		pop bp
		ret 2
	endp draw_house
	
	

	; This procedure combines all the screen graphic procs to draw
	; the screen's background
	proc draw_background
		call draw_surface
		
		; draw first launcher
		push 49 ; the launcher X coordinate
		push 0  ; draw = 0, erase = 1
		LAUNCHER_X_COR equ [bp + 6]
		ERASE equ [bp + 4]
		call draw_launcher
		
		; draw second launcher
		push 223 ; The launcher X coordinate
		push 0  ; draw = 0, erase = 1
		LAUNCHER_X_COR equ [bp + 6]
		ERASE equ [bp + 4]
		call draw_launcher
		
		; draw 1st house
		push 2 ; The house's X ccordinate
		HOUSE_X_COR equ [bp + 4]
		call draw_house
		
		; draw 2nd house
		push 78; The house's X ccordinate
		HOUSE_X_COR equ [bp + 4]
		call draw_house
		
		; draw 3rd house
		push 112 ; The house's X ccordinate
		HOUSE_X_COR equ [bp + 4]
		call draw_house
		
		; draw 4th house
		push 146 ; The house's X ccordinate
		HOUSE_X_COR equ [bp + 4]
		call draw_house
		
		; draw 5th house
		push 180 ; The house's X ccordinate
		HOUSE_X_COR equ [bp + 4]
		call draw_house
		
		; draw 6th house
		push 258 ; The house's X ccordinate
		HOUSE_X_COR equ [bp + 4]
		call draw_house
		ret
	endp draw_background
	
	
	
	; this proc draws a rocket on screen
	proc rocket_graphics
		push bp
		mov bp, sp

		mov ax, ROCKET_X
		mov dx, ROCKET_Y
		mov bx, ROCKET_TYPE
		
		; 2 --> erase rocket from a given spot
		; 1 --> draw enemy styled rocket
		; 0 --> draw defender styled rocket

		cmp bx, 2
		je erase_rocket
		
		cmp bx, 0
		je enemy_rocket
			
		
		defender_rocket:
			mov bl, 4	; outer color
			mov bh, 1	; inner color
			
			jmp draw_bullet
			
		enemy_rocket:
			mov bl,  8	; outer color
			mov bh, 14	; inner color
			jmp draw_bullet
		
		erase_rocket:
			xor bx, bx ; black color inner + outer

					
			
		draw_bullet:
			; draw ring 
			mov [color], bl
			mov [rect_width],  5
			mov [rect_height], 5

			mov [x], ax
			mov [y], dx
			sub [y], 1
				
			call draw_rectangle
			
			; draw middle rect
			mov [color], bh
			mov [rect_width],  3
			mov [rect_height], 3

			mov [x], ax
			add [x], 1
			mov [y], dx
				
			call draw_rectangle
	
		pop bp
		ret 6 ; pop back 3 parameters of double byte
	endp rocket_graphics
	
	
	
	; This function gets an index of rocket and it's array number
	; the function will check the area around it before drawing it there
	; if there's already a color of another rocket or house / launcher it will explode it
	proc check_collision
		push bp 
		push di
		
		mov bp, sp
		
		mov ax, ARRAY_TYPE ; 1 = defender, 0 = enemy
		mov bx, ROCKET_IND
		
		; initialize the check of collision
		mov cx, [offset enemy_x_cors + bx]
		mov dx, [offset enemy_y_cors + bx]
		mov [x], cx ; initial x cor
		mov [y], dx
		dec [y]
		

		; first, check if enemy hit a house 
		; the size of a rocket is 5 * 5 
		get_pixel_color:
			mov bx, 3 
			get_x_loop:
				mov si, 3
				get_y_loop:
					mov cx, [x]
					mov dx, [y]
					mov bh,0h
					mov ah,0Dh
					int 10h ; AL = COLOR
					
					; check the color value
					mov di, ARRAY_TYPE
					cmp di, 0	; enemy color checking
					je check_enemy_collision
					
					check_defender_collision:
						cmp al, 14 ; collision with enemy rocket 
						je defender_collision
						jne y_color_loop
					

					check_enemy_collision:

						; house collision
						cmp al, 6
						je house_collision
						
						cmp al, 5 
						je house_collision
						
						; launcher collision
						cmp al, 9 
						je launcher_collison
						
						cmp al, 13
						je launcher_collison
						
						cmp al, 7
						je launcher_collison
						
						; collision with defender
						cmp al, 4
						je defender_collision

						; collision with explosion
						cmp al, 8
						je defender_collision		
						
						cmp al, 9
						je defender_collision
						
						cmp al, 10
						je defender_collision
						
						cmp al, 11
						je defender_collision
					
						cmp al, 12
						je defender_collision
					
						cmp al, 13
						je defender_collision
						jne y_color_loop
					
				
					launcher_collison:
						push [x] ; explosion_x 
						EXP_X_COR equ [bp + 4]
						call destroy_launcher	
					
					house_collision:
						; remove rocket from array 
						mov di, ROCKET_IND
						mov [word ptr offset enemy_x_cors + di], -1
					
						; substract 5 from score 
						cmp [score], 5
						jae sub_score_5
						jb no_score
						
						sub_score_5:
							sub [score], 5
						
						no_score:
						jmp explosion_animation
					
					defender_collision:
						add [score], 5

						; remove rocket from array 
						mov di, ROCKET_IND
						mov [word ptr offset enemy_x_cors + di], -1
						jmp explosion_animation
						
			
					explosion_animation:	
						mov [has_exploded], 1
											
						push [x]	; X
						push [y]	; Y
						EXPLOSION_X equ [bp + 8]
						EXPLOSION_Y equ [bp + 6]
						call draw_explosion
						jmp finish_check
							
					
					; dec outer loop counter 
					y_color_loop:
						inc [y]
						dec si
						cmp si, 0
						jge get_y_loop
						
				; dec outer loop counter 
				x_color_loop:
					inc [x]
					dec bx
					cmp bx, 0
					jge get_x_loop	; inner loop
		
		finish_check:
			pop di
			pop bp
			ret 4 
	endp check_collision

	
	
	; This proc sets the mouse configuration and displays it
	proc mouse_config
		pusha 
		
		;; Configuration 
		; enable mouse driver
		mov ax, 0
		int 33h	; intialize cursor 
		
		
		; set mouse sensitivity
		mov cx, 8 * 2  ;X speed (lower multiplication = faster) 
		mov dx, 16 * 2 ;Y speed (lower multiplication = faster)
		mov ax, 0Fh ; set speed
		int 33h
		
		popa 
		ret 
	endp mouse_config

	
	
	; This procedure handles mouse clicks 
	; it assigns the global variables x_cor and y_cor the click values
	proc event_click
		pusha
		
		; display cursor
		mov ax, 1
		int 33h	
		
		; get cursor click
		get_cursor:
				
			mov ax, 3
			int 33h     ;Check the mouse
			and bx, 3h	
			cmp bx, 1

			je check_release 
			
			
			cmp bx, 0 
			je last_click
			
			jne noClick
 
			last_click:
				cmp [is_clicked], 1
				je left
				jne noClick
				
			check_release:
				mov [is_clicked], 1
				mov ax, 3
				int 33h     ;Check the release
				and bx, 3h
				
				cmp bx, 0
				je left 
				jne noClick

		  	left:
				mov [is_clicked], 0
				cmp [defender_arr_pointer], 0 ; full array 
				
				je noClick
				
				shr cx, 1 ; the x coordinate needs to be divided by 2
				
				; check if click is in the valid range (not on on the launchers and houses area)
				cmp dx, 140 
				jae noClick
				
				; insert the x, y coordinates to the arrays
				mov di, [defender_arr_pointer]
				mov [offset defender_stop_y_cors + di], dx
				mov [offset defender_stop_x_cors + di], cx
				
				
				; 320 / 2 = 160 --> the line in the middle of the screen
				cmp cx, 160 
		
				; in the half of the 2nd launcher
				jae launcher1_check
		
				; in the half of the 1st launcher		
				jb launcher2_check
				
				launcher1_check:
					; first, check if launcher is active 
					cmp [launchers + 1], 1
					jne noClick			; cannot shoot since launcher is destroyed
					je valid_shoot
					
				launcher2_check:
					; first, check if launcher is active 
					cmp [launchers + 0], 1
					jne noClick			; cannot shoot since launcher is destroyed
					
				valid_shoot:
					;parameters of slope calculation
					push cx ; X1
					push dx; Y1

					X1 equ [bp + 8]
					Y1 equ [bp + 6]
					call calc_slope
								
					; insert the returned values to the arrays
					mov bx, [x_slope]
					mov si, [y_slope]
					mov ax, [x_start]
					
					mov [offset defender_x_slopes + di], bx
					mov [offset defender_y_slopes + di], si
					
					mov [offset defender_x_cors + di], ax
					mov [word ptr offset defender_y_cors + di], 124 ; The constant height of the two launchers 

					sub [defender_arr_pointer], 2
		noClick:
		popa
		ret
	endp event_click
	

	
	; this proc draws the circle of the explosion
	proc draw_explosion
		push cx 
		push bp
		mov bp, sp
		
		; times to repeat
		mov bx, 2
		repeat_explosion:
			mov ax, EXPLOSION_X; x cor
			mov dx, EXPLOSION_Y; y_cor
			
			mov [rect_width],  6
			mov [rect_height], 6
			mov [color], 13
			
			mov cx, 6
			; amount of levels
			draw_explosion_levels:
				
				cmp [color], 8
				jne set_color
				
				; if color is 8
				mov [color], 12
				set_color:
					dec [color]
				
				add [rect_height], 2
				add [rect_width], 2
				
				sub ax, 1
				sub dx, 1
				
				mov [x], ax
				mov [y], dx

				call draw_rectangle
				
				; update_enemy_defender_cors
				
				call time_delay
				
				loop draw_explosion_levels
		
		dec bx
		cmp bx, 0 
		jne repeat_explosion
		
		mov [x], ax
		mov [y], dx
		
		call check_explosion_zone
		
		; remove the last rectangle
		mov [color], 0
		call draw_rectangle
		
		
				
		pop bp		
		pop cx 

		ret 4
	endp draw_explosion



	; this function checks if a rocket have entered the explosion zone	
	proc check_explosion_zone
		pusha
		
		mov cx, 18
		
		loop_cors:
			mov bx, cx
			
			; ax - holds enemy x cors, bx - enemy y cors
			mov ax, [offset enemy_x_cors + bx]
			mov bx, [offset	enemy_y_cors + bx]
			
			cmp ax, -1 
			je update_loop
				
			cmp ax, [x]
			jb update_loop
			
			sub ax, [x]
			cmp ax, [rect_width]
			ja update_loop
				
			cmp bx, [y]
			jb update_loop
			
			sub bx, [y]
			cmp bx, [rect_height]
			ja update_loop
			
			push [offset enemy_x_cors + bx]		; X
		    push [offset enemy_y_cors + bx]		; Y
			EXPLOSION_X equ [bp + 8]
			EXPLOSION_Y equ [bp + 6]
			call draw_explosion
			
			; decrease loop counter by 2 each iteration
			update_loop:
				sub cx, 2
				cmp cx, 0 ; loop until index 0
				jge loop_cors
		popa
		ret 
	endp check_explosion_zone



	; this procedure loops through the enemy and defender rockets arrays 
	; and displays all of the rockets on screen 
	proc show_rockets
		mov di, 18
		display_rockets:
		
			; here the loop displays the defender rockets
			mov cx, [offset defender_x_cors + di]
			mov dx, [offset defender_y_cors + di]
			
			cmp cx, -1 
			je enemy_display
			
			; first check the area for collision
			push 1
			push di
			
			ARRAY_TYPE equ [bp + 8]
			ROCKET_IND equ [bp + 6]
			call check_collision
			
			mov cx, [offset defender_x_cors + di]
			mov dx, [offset defender_y_cors + di]
			
			push 1	; ROCKET_TYPE
			push cx ; ROCKET_X
			push dx ; ROCKET_Y
			
			; parameters of "rocket_graphics"
			ROCKET_TYPE equ [bp + 8] ; 0 => enemy, 1 => defender, 2 => erase
			ROCKET_X	equ [bp + 6]
			ROCKET_Y equ [bp + 4]
			call rocket_graphics

			; display enemy rockets 
			enemy_display:
				mov [has_exploded], 0 
				
				mov cx, [offset enemy_x_cors + di]
				mov dx, [offset enemy_y_cors + di]
				
				cmp cx, -1 
				je loop_check

				; params of check bounds
				push di ; index of rcoket 
				ARRAY_INDEX equ [bp + 4]; index in the arrays (0 - 9)
				call check_bounds
				

				; params of check collision
				push 0
				push di
				
				ARRAY_TYPE equ [bp + 8]
				ROCKET_IND equ [bp + 6]
				call check_collision
				
				cmp [has_exploded], 0 
				jne loop_check
				
				mov cx, [offset enemy_x_cors + di]
				mov dx, [offset enemy_y_cors + di]
					
				push 0	; ROCKET_TYPE
				push cx ; ROCKET_X
				push dx ; rocket y
				
				; parameters of "rocket_graphics"
				ROCKET_TYPE equ [bp + 8] ; 0 => enemy, 1 => defender, 2 => erase
				ROCKET_X	equ [bp + 6]
				ROCKET_Y equ [bp + 4]
				call rocket_graphics

			loop_check:
				sub di, 2
				cmp di, -2
				jne display_rockets
		
		ret 
	endp show_rockets

	
	
	; this procedure 'hides' the rockets on the screen so that in the next 
	; iteration of the main loop the would be displayed on a different spot 
	; depending on their slope x and y 
	proc hide_rockets
		; loop counter 
		mov di, 18
		
		; removing rockets from the screen 
		remove_rockets:
			mov cx, [offset defender_x_cors + di]
			mov dx, [offset defender_y_cors + di]
				
			cmp cx, -1 
			je enemy_rockets_remove
				push 2	; ROCKET_TYPE
			push cx ; ROCKET_X
			push dx ; rocket y
			
			; parameters of "rocket_graphics"
			ROCKET_TYPE equ [bp + 8] ; 1 => enemy, 0 => defender, 2 => erase
			ROCKET_X	equ [bp + 6]
			ROCKET_Y equ [bp + 4]
			call rocket_graphics
		
			enemy_rockets_remove:
				mov cx, [offset enemy_x_cors + di]
				mov dx, [offset enemy_y_cors + di]
				
				cmp cx, -1 
				je loop_counter
				
				push 2	; ROCKET_TYPE
				push cx ; ROCKET_X
				push dx ; rocket y
			
				; parameters of "rocket_graphics"
				ROCKET_TYPE equ [bp + 8] ; 1 => enemy, 0 => defender, 2 => erase
				ROCKET_X	equ [bp + 6]
				ROCKET_Y equ [bp + 4]
				call rocket_graphics
				
			loop_counter:
				sub di, 2
				cmp di, -2
				jne remove_rockets
		ret 
	endp hide_rockets



	; this procedure gets an x and y cor of hit point of launcher
	; the procedure will than specify the launcher that was hit and remove its sign from the array
	; the launcher will than be deactivated
	proc destroy_launcher 
		push bp
		mov bp, sp 
		
		mov ax, EXP_X_COR
		
		cmp ax, 160 ; half of screen
		jae launcher_2
		jb launcher_1

		launcher_1:
			mov [launchers + 0], 0
			push 49 ; the launcher X coordinate
			jmp delete_launcher 
			
		launcher_2: 
			mov [launchers + 1], 0
			push 223 ; The launcher X coordinate
			
		delete_launcher:
			push 1  ; draw = 0, erase = 1
			LAUNCHER_X_COR equ [bp + 6]
			ERASE equ [bp + 4]
			call draw_launcher
		
		pop bp
		ret 2	
	endp destroy_launcher 
	
	
	
	; This procedure prints a given number 
	; the number is located in dx: ax
	proc print_number
		push ax
		push bx
		push dx
		

		mov bx, offset divisorTable

		next_digit:
			xor ah,ah ; dx:ax = number
			div [byte ptr bx] ; al = quotient, ah = remainder
			add al,'0'
			call print_character ; Display the quotient
			mov al,ah ; ah = remainder
			add bx,1 ; bx = address of next divisor
			cmp [byte ptr bx],0 ; Have all divisors been done?
			jne next_digit
			mov ah,2
			mov dl,13
			int 21h
			mov dl,10
			int 21h

			pop dx
			pop bx
			pop ax
			ret
	endp print_number



	; this procedure prints a given character 
	proc print_character
		push ax
		push dx
		mov ah,2
		mov dl, al
		int 21h
		pop dx
		pop ax
		ret
	endp print_character


	
	; set cursor location 
	proc set_cursor_position
		pusha
		
		mov dh, [row] 	  ;  row 
		mov dl, [column]  ; column
		mov bh, 0   ; page number
		mov ah, 2
		int 10h
		
		popa
		ret
	endp set_cursor_position


	
	; This procedure print a string on the screen assuming the string offset is in dx
	proc print_string
		pusha    
		
		mov ah, 9h 
		int 21h    ;interrupt that displays a string
		popa

		ret
	endp print_string    



	; this procedure updates the score that is displayed on screen
	proc print_updated_score
		push ax 

		; print the score number
		mov [row], 1
		mov [column], 23
		call set_cursor_position
		
		mov ax, [score]
		call print_number
		
		pop ax
		ret 
	endp print_updated_score
	
	
	
	; initialize the score display on screen
	proc init_score
		push dx 
		
		; print the word "score" 
		lea dx, [st_score]
		call print_string
		
		pop dx
		ret
	endp init_score
	
	
	
	;;;;;;;;;;;;;;;;
	;;; BMP Image ;;
	;;;;;;;;;;;;;;;;
	proc open_file
		; Open file
		mov ah, 3Dh
		xor al, al
		int 21h
		jc openerror
		mov [filehandle], ax
		ret
		openerror:
			mov dx, offset ErrorMsg
			mov ah, 9h
			int 21h
			ret
	endp open_file
	
	
	
	; Read BMP file header, 54 bytes
	proc read_header
		mov ah,3fh
		mov bx, [filehandle]
		mov cx,54
		mov dx,offset Header
		int 21h
		ret
	endp read_header



	; Read BMP file color palette, 256 colors * 4 bytes (400h)
	proc read_pallette
		mov ah,3fh
		mov cx,400h
		mov dx,offset Palette
		int 21h
		ret
	endp read_pallette

	
	
	; Copy the colors palette to the video memory
	; The number of the first color should be sent to port 3C8h
	; The palette is sent to port 3C9h
	proc copy_pal
		mov si,offset Palette
		mov cx,256
		mov dx,3C8h
		mov al,0
		; Copy starting color to port 3C8h
		out dx,al
		; Copy palette itself to port 3C9h
		inc dx
		PalLoop:
			; Note: Colors in a BMP file are saved as BGR values rather than RGB.
			mov al,[si+2] ; Get red value.
			shr al,2 ; Max. is 255, but video palette maximal
			; value is 63. Therefore dividing by 4.
			out dx,al ; Send it.
			mov al,[si+1] ; Get green value.
			shr al,2
			out dx,al ; Send it.
			mov al,[si] ; Get blue value.
			shr al,2
			out dx,al ; Send it.
			add si,4 ; Point to next color.
			; (There is a null chr. after every color.)
			loop PalLoop
		ret
	endp copy_pal

	
	
	; BMP graphics are saved upside-down.
	; Read the graphic line by line (200 lines in VGA format),
	; displaying the lines from bottom to top.
	proc copy_bitmap

		mov ax, 0A000h
		mov es, ax
		mov cx,200
		
		PrintBMPLoop:
			push cx
			; di = cx*320, point to the correct screen line
			mov di,cx
			shl cx,6
			shl di,8
			add di,cx
			; Read one line
			mov ah,3fh
			mov cx,320
			mov dx,offset ScrLine
			int 21h
			
			; Copy one line into video memory
			cld ; Clear direction flag, for movsb
			mov cx,320
			mov si,offset ScrLine
			rep movsb ; Copy line to the screen
			;rep movsb is same as the following code:
			;mov es:di, ds:si
			;inc si
			;inc di
			;dec cx
			; loop until cx=0
			pop cx
			loop PrintBMPLoop
		ret
	endp copy_bitmap



	; This procedure uses the global var 'game status' and displays an image on screen accordingly
	proc display_screen
		pusha
		
		cmp [game_status], 0 ; opening screen 
		je load_opening
		
		cmp [game_status], 1 ; win screen
		je load_winning 	
		
		cmp [game_status], 2 ; loose screen
		je load_losing 
		
		cmp [game_status], 3 ; rules screen
		je load_rules 
	
	
		; load the image according to the given game status
		load_opening:
			lea dx, [pic_opening]
			jmp load_file
			
		load_winning:
			lea dx, [pic_win]
			jmp load_file
	
		load_losing:
			lea dx, [pic_loose]
			jmp load_file
	
		load_rules:
			lea dx, [pic_rules]
			jmp load_file
			
		load_file:
			; Process BMP file
			call open_file
			call read_header
			call read_pallette
			call copy_pal
			call copy_bitmap
		

		popa
		ret 
	endp display_screen


start:
	mov ax, @data
	mov ds, ax
	xor ax, ax
	
	game:
	; initialize the graphics
	call game_graphics_init
	
	; main loop 
	main:	
		; generate a new enemy if 2 sec have passed
		call randomize_enemy_rocket
		
		; show all of the rockets on the screen
		call show_rockets 
		
		; this time delay that creates the animation of rcokets moving
		call time_delay

		; hiding all of the rockets until the next iteration 
		call hide_rockets
		
		; update coordinates
		call update_enemy_defender_cors
		
		; check if there's an explosion after coordinates have been updated
		call check_explosion
		
		; check if there is an event click
		call event_click
		
		; check winning or loosing
		call check_win 
		call check_loose
		
		; printing the score on screen
		call print_updated_score
		
		; check if "destroy all" function was called 
		call get_buffer
		
		; check if there is a higher pace that needed
		call set_generating_rate
		
		; keep the main loop of the game 
		jmp main
	

	; in case there's a need to finish the game because the player won / lost 
	end_game:
		; hide crusor 
		mov ax, 02h 
		;mov cx, 2607h
		int 33h

exit:
	mov ax, 04ch
	int 21h
	


END start