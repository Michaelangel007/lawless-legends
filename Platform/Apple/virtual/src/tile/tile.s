;@com.wudsn.ide.asm.hardware=APPLE2
; Tile routines
; ------------------
;     
 * = $6000
; Global definitions
!source "../include/global.i"
!source "../include/mem.i"
!source "../include/plasma.i"

HEADER_LENGTH=6
SECTION_WIDTH=22
SECTION_HEIGHT=23
VIEWPORT_WIDTH=9
VIEWPORT_HEIGHT=9
VIEWPORT_VERT_PAD=0 ; This is the distance between the center of the viewport and the top/bottom
VIEWPORT_HORIZ_PAD=4 ; This is the distance between the center of the viewport and the left/right
MAX_MAP_ID=254	; This means that the total map area can be as big as 5588x5842 tiles!

REL_X=$50	; Will always be in the range 0-43
REL_Y=$51	; Will always be in the range 0-45
; Map quadrant data pointers
NW_MAP_LOC=$52
NE_MAP_LOC=$54
SW_MAP_LOC=$56
SE_MAP_LOC=$58
; Map section IDs (255 = not loaded)
NOT_LOADED=$FF
NW_MAP_ID=$5A
NE_MAP_ID=$5B	
SW_MAP_ID=$5C
SE_MAP_ID=$5D

NORTH	=0
EAST	=1
SOUTH	=2
WEST 	=3

; >> INIT (reset map drawing vars)
INIT
		LDA #NOT_LOADED
		STA NW_MAP_ID
		STA NE_MAP_ID
		STA SW_MAP_ID
		STA SE_MAP_ID
		LDX VIEWPORT_HORIZ_PAD
		LDY VIEWPORT_VERT_PAD
		JSR SET_XY
		RTS

;----------------------------------------------------------------------
; >> START LOADING MAP SECTIONS
START_LOAD
		LDX #0
		LDA #START_LOAD
		JMP mainLoader
!macro startLoad {
		JSR START_LOAD
}

;----------------------------------------------------------------------
; >> LOAD MAP SECTION
;	Section number is in A
;	Returns location of loaded data (Y = hi, X = lo)
;	First 6 bytes are header information
;	0 Resource ID of next map section (north), FF = none
;	1 Resource ID of next map section (east), FF = none
;	2 Resource ID of next map section (south), FF = none
;	3 Resource ID of next map section (west), FF = none
;	4 Tileset resouce id
;	5 Resource ID of script library (if any)
LOAD_SECTION
		CMP #$FF
		BNE .doLoad
		LDX #00		; This is a bogus map section, don't load
		LDY #00
		RTS
.doLoad		TAY		; resource # in Y
		LDX #RES_TYPE_2D_MAP
		LDA #QUEUE_LOAD
		JMP mainLoader
!macro loadSection ptr {
		JSR LOAD_SECTION
		STX ptr 
		STY ptr+1
}

;----------------------------------------------------------------------
; >> FINISH LOADING MAP SECTIONS
FINISH_LOAD
		LDX #0		; 1 to keep open for next load, 0 for close so you can flip to HGR page 2
		LDA #FINISH_LOAD
		JMP mainLoader
!macro finishLoad {
		JSR FINISH_LOAD
}

;----------------------------------------------------------------------
; >> RELEASE MAP SECTION
!macro releaseMapSection ptr {
	; --> free up unused resource
		LDX ptr
		LDY ptr+1
		LDA #FREE_MEMORY
		JSR mainLoader
}
;----------------------------------------------------------------------
; >> LOAD TILES
;	Load tile resource (A = Resource ID)
;----------------------------------------------------------------------
; >> MOVE NORTH
;	Check for boundary
;	If none, check for map boundary
;		If so, move to bottom of next map
;	If not at boundary
;		Move up one row
;		Check to see if viewport is crossing section boundary;			
;	Does new location have a script assigned?
;		execute script
;----------------------------------------------------------------------
; >> MOVE EAST
;	(same as move north, might be able to overlap functionality)
;----------------------------------------------------------------------
; >> MOVE SOUTH
;	(same as move north, might be able to overlap functionality)
;----------------------------------------------------------------------
; >> MOVE WEST
;	(same as move north, might be able to overlap functionality)
;----------------------------------------------------------------------
; >> GET TILE IN CARDINAL DIRECTION AND FLAGS 
;	(Returns Tile # in Y, Flags in A)
;	Each tile in memory can be 0-64, the flags are the upper 3 bits
;	0 0 0
;	| | `- Boundary (Can not cross)
;	| `--- Requires special (rope, raft, etc)
;	`----- Script assigned, triggers script lookup 
;----------------------------------------------------------------------
; >> SET X,Y COORDINATES FOR VIEWPORT CENTER
SET_XY
		STX REL_X
		STY REL_Y
		RTS
;----------------------------------------------------------------------
; >> TRIGGER SCRIPT AT TILE (X,Y = Coordinates in section)
;----------------------------------------------------------------------
!macro move_word from, to {
		!move_byte from, to
		!move_byte from+1, to+1
}

!macro move_byte from, to {
		LDX from
		STX to
}

; >> CROSS NORTH BOUNDARY (Load next section to the north)
!zone
CROSS_NORTH
		!releaseMapSection SW_MAP_LOC
		!releaseMapSection SE_MAP_LOC
		LDA REL_Y
		CLC
		ADC #SECTION_HEIGHT
		STA REL_Y
		!move_byte NW_MAP_ID, SW_MAP_ID
		!move_word NW_MAP_LOC, SW_MAP_LOC
		!move_byte NE_MAP_ID, SE_MAP_ID
		!move_word NE_MAP_LOC, SE_MAP_LOC
 		; Get new NW section
		!startLoad
		LDA (SW_MAP_LOC)
		STA NW_MAP_ID
		!loadSection NW_MAP_LOC
 		; Get the new NE section
		LDA (SE_MAP_LOC)
		STA NE_MAP_ID
		!loadSection NE_MAP_LOC
		!finishLoad
		RTS
;----------------------------------------------------------------------
; >> CROSS EAST BOUNDARY (Load next section to the east)
!zone
CROSS_EAST
		!releaseMapSection NW_MAP_LOC
		!releaseMapSection SW_MAP_LOC
		LDA REL_X
		SEC
		SBC #SECTION_WIDTH
		STA REL_X
		!move_byte NE_MAP_ID, NW_MAP_ID
		!move_word NE_MAP_LOC, NW_MAP_LOC
		!move_byte SE_MAP_ID, SW_MAP_ID
		!move_word SE_MAP_LOC, SW_MAP_LOC
 		; Get new NE section
		!startLoad
		LDY #EAST
		LDA (NW_MAP_LOC),Y
		STA NE_MAP_ID
		!loadSection NE_MAP_LOC
 		; Get the new SE section
		LDY #EAST
		LDA (SW_MAP_LOC),Y
		STA SE_MAP_ID
		!loadSection SE_MAP_LOC
		!finishLoad
		RTS
;----------------------------------------------------------------------
; >> CROSS SOUTH BOUNDARY (Load next section to the south)
!zone
CROSS_SOUTH
		!releaseMapSection NW_MAP_LOC
		!releaseMapSection NE_MAP_LOC
		LDA REL_Y
		SEC
		SBC #SECTION_HEIGHT
		STA REL_Y
		!move_byte SW_MAP_ID, NW_MAP_ID
		!move_word SW_MAP_LOC, NW_MAP_LOC
		!move_byte SE_MAP_ID, NE_MAP_ID
		!move_word SE_MAP_LOC, NE_MAP_LOC
	 	; Get new SW section
		!startLoad
	 	LDY #SOUTH
		LDA (NW_MAP_LOC),Y
		STA SW_MAP_ID
		!loadSection SW_MAP_LOC
 		; Get the new SE section
		LDY #SOUTH
		LDA (NE_MAP_LOC),Y
		STA SE_MAP_ID
		!loadSection SE_MAP_LOC
		!finishLoad
		RTS
;----------------------------------------------------------------------
; >> CROSS WEST BOUNDARY (load next section to the west)
!zone
CROSS_WEST
		!releaseMapSection NE_MAP_LOC
		!releaseMapSection SE_MAP_LOC
		LDA REL_X
		CLC
		ADC #SECTION_WIDTH
		STA REL_X
		!move_byte NW_MAP_ID, NE_MAP_ID
		!move_word NW_MAP_LOC, NE_MAP_LOC
		!move_byte SW_MAP_ID, SE_MAP_ID
		!move_word SW_MAP_LOC, SE_MAP_LOC
 		; Get new NW section
		!startLoad
		LDY #WEST
		LDA (NE_MAP_LOC),Y
		STA NW_MAP_ID
		!loadSection NW_MAP_LOC
 		; Get the new SE section
		LDY #WEST
		LDA (SE_MAP_LOC),Y
		STA SW_MAP_ID
		!loadSection SW_MAP_LOC
		!finishLoad
		RTS
;----------------------------------------------------------------------
; >> SET PLAYER TILE (A = tile)
;----------------------------------------------------------------------
; >> SET NPC TILE (A = tile, X,Y = coordinates in section)
;----------------------------------------------------------------------
; >> DRAW
!zone draw
!macro drawMapSection ptr, deltaX, deltaY {
	; Determine X1 and X2 bounds for what is being drawn
		LDA REL_X
		SEC
		SBC #(deltaX+VIEWPORT_HORIZ_PAD)
		TAX
		BPL .10
		;This section isn't at the edge, note that
		EOR #$FF
		ADC #$00 ; Carry is still set, so this is really +1
		BPL .11	; Should be always true
.10		LDA #0
.11 	STA X1
		TXA
		CLC
		ADC VIEWPORT_WIDTH
		CMP SECTION_WIDTH
		BLT .12
		LDA #SECTION_WIDTH-1
.12		STA X2		

		}

	; Determine Y1 and Y2 bounds for what is being drawn
}

DRAW
; For each quadrant, display relevant parts of screen
.checkNorthQuads
		LDA REL_Y
		CMP SECTION_HEIGHT+VIEWPORT_VERT_PAD
		BGE .checkSouthQuads
;	Check for NW quadrant area
		LDA REL_X
		CMP SECTION_WIDTH+VIEWPORT_HORIZ_PAD
		BGE .checkNEQuad
		!drawMapSection NW_MAP_LOC, 0, 0
		LDA NW_MAP_LOC+1
		BNE .drawNW

.drawNW
;	Check for NE quadrant area
.checkNEQuad

.checkSouthQuads
;	Check for SW quadrant area
		LDA REL_X
		CMP SECTION_WIDTH+VIEWPORT_HORIZ_PAD
		BGE .checkSEQuad
;	Check for SE quadrand area
.checkSEQuad
	RTS
.mainDraw
; Identify start of map data (upper left)
; Display row of tiles
; Get tile
;   Is there a NPC there?
;     No, use map tile
;     Yes, use NPC tile
; Compare tile to last-drawn tile
; Skip if no change
; Is this the first time we're drawing this row?
;   -- It is, update the draw pointers
; If tile is different then redraw
; 	-- unrolled loop for 16 rows at a time
; Increment row
; Draw player