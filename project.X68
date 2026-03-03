*-------------------------------------------------------
* assembly project - option 1
* name: Ihor Maslovskyi   id: c00325691   date created: 20/02/2026
* description: quantum janitor game - alternative physics theme.
*              player picks a mission and tool, game checks if
*              you have enough energy, then resolves the mission.
*              gravity can invert which flips how collisions work.
* known bugs: none so far
*-------------------------------------------------------

    ORG     $1000

*-------------------------------------------------------
* constants
*-------------------------------------------------------
EXIT        EQU 0
MIN_TOOL    EQU 1
MAX_TOOL    EQU 2
MIN_MISSION EQU 1
MAX_MISSION EQU 3
COST_M1     EQU 10
COST_M2     EQU 15
COST_M3     EQU 20

*-------------------------------------------------------
* start
*-------------------------------------------------------
START:
    MOVE.B  #50,ENERGY
    MOVE.B  #0,ENTROPY
    MOVE.B  #0,GRAVITY_INV

    BSR     WELCOME
    BSR     GAME

    ORG     $3000

*-------------------------------------------------------
* game - main loop controls replay
*-------------------------------------------------------
GAME:
NEXT_ROUND:
    BSR     GAMELOOP        ; run one full round
    BSR     REPLAY          ; ask to continue, result in D1
    CMP.B   #EXIT,D1        ; did player press 0?
    BNE     NEXT_ROUND      ; no - do another round
    RTS                     ; yes - exit

END:
    SIMHALT

*-------------------------------------------------------
* welcome
*-------------------------------------------------------
WELCOME:
    BSR     ENDL
    LEA     WELCOME_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    BSR     ENDL
    BSR     CONTINUE
    RTS

*-------------------------------------------------------
* gameloop - one round, clear screen at start
*-------------------------------------------------------
GAMELOOP:
    BSR     CLEAR_SCREEN    ; clear at start of each round
    BSR     INPUT
    BSR     MISSION_SELECT
    BSR     MISSION_PREP
    BSR     UPDATE
    BSR     DRAW
    BSR     GAMEPLAY
    BSR     HUD
    BSR     CHECK_DEATH     ; check game over after hud
    RTS                     ; replay prompt visible after this

*-------------------------------------------------------
* input - choose tool
*-------------------------------------------------------
INPUT:
    BSR     ENDL
    LEA     TOOL_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  #MIN_TOOL,D2
    MOVE.B  #MAX_TOOL,D3
    BSR     VALIDATE_INPUT
    MOVE.B  D1,TOOL_CHOICE  ; save before CONTINUE overwrites D1
    BSR     CONTINUE
    RTS

*-------------------------------------------------------
* mission select
*-------------------------------------------------------
MISSION_SELECT:
    BSR     ENDL
    LEA     MISSION_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  #MIN_MISSION,D2
    MOVE.B  #MAX_MISSION,D3
    BSR     VALIDATE_INPUT
    MOVE.B  D1,MISSION
    BSR     ENDL
    RTS

*-------------------------------------------------------
* mission prep - check energy before mission starts
*-------------------------------------------------------
MISSION_PREP:
    BSR     ENDL
    MOVE.B  MISSION,D4
    CMP.B   #1,D4
    BEQ     PREP_COST1
    CMP.B   #2,D4
    BEQ     PREP_COST2
    BRA     PREP_COST3
PREP_COST1:
    MOVE.B  #COST_M1,D4
    BRA     PREP_COST_DONE
PREP_COST2:
    MOVE.B  #COST_M2,D4
    BRA     PREP_COST_DONE
PREP_COST3:
    MOVE.B  #COST_M3,D4
PREP_COST_DONE:
    LEA     COST_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVEQ   #0,D1
    MOVE.B  D4,D1
    MOVE.B  #3,D0
    TRAP    #15
    BSR     ENDL

    MOVEQ   #0,D1
    MOVE.B  ENERGY,D1
    CMP.B   D4,D1
    BGE     PREP_OK

    * not enough energy
    LEA     LOW_ENG_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  #1,D2
    MOVE.B  #2,D3
    BSR     VALIDATE_INPUT
    CMP.B   #1,D1
    BEQ     DO_REST
    LEA     RISK_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    BRA     PREP_OK

DO_REST:
    ADD.B   #15,ENERGY
    ADD.B   #5,ENTROPY
    LEA     REST_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15

PREP_OK:
    RTS

*-------------------------------------------------------
* validate input - D2=min D3=max returns valid D1
*-------------------------------------------------------
VALIDATE_INPUT:
    MOVE.B  #4,D0
    TRAP    #15
    CMP.B   D2,D1
    BLT     VAL_ERROR
    CMP.B   D3,D1
    BGT     VAL_ERROR
    RTS
VAL_ERROR:
    LEA     ERROR_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    BRA     VALIDATE_INPUT

*-------------------------------------------------------
* update - random physics change each round
*-------------------------------------------------------
UPDATE:
    BSR     ENDL
    LEA     UPDATE_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  #8,D0
    TRAP    #15
    AND.L   #1,D1
    MOVE.B  D1,GRAVITY_INV
    RTS

*-------------------------------------------------------
* draw - show world state
*-------------------------------------------------------
DRAW:
    BSR     DECORATE
    MOVE.B  GRAVITY_INV,D1
    CMP.B   #1,D1
    BEQ     DRAW_INV
    LEA     NORMAL_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    BRA     DRAW_END
DRAW_INV:
    LEA     INVERT_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
DRAW_END:
    BSR     DECORATE
    RTS

*-------------------------------------------------------
* gameplay - pay energy cost then resolve collision
*-------------------------------------------------------
GAMEPLAY:
    BSR     ENDL
    LEA     GAMEPLAY_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  MISSION,D4
    CMP.B   #1,D4
    BEQ     GP_C1
    CMP.B   #2,D4
    BEQ     GP_C2
    BRA     GP_C3
GP_C1:
    SUB.B   #COST_M1,ENERGY
    BRA     GP_DONE
GP_C2:
    SUB.B   #COST_M2,ENERGY
    BRA     GP_DONE
GP_C3:
    SUB.B   #COST_M3,ENERGY
GP_DONE:
    BSR     COLLISION
    RTS

*-------------------------------------------------------
* collision - tool + mission combo affects outcome
*-------------------------------------------------------
COLLISION:
    MOVE.B  #8,D0
    TRAP    #15
    LSR.L   #2,D1
    AND.L   #1,D1

    * tachyon broom + mission 1 = always dodge
    MOVE.B  TOOL_CHOICE,D5
    MOVE.B  MISSION,D6
    CMP.B   #1,D5
    BNE     SKIP_B
    CMP.B   #1,D6
    BNE     SKIP_B
    MOVEQ   #0,D1
SKIP_B:
    * gravity boots + mission 3 = always dodge
    CMP.B   #2,D5
    BNE     RESOLVE
    CMP.B   #3,D6
    BNE     RESOLVE
    MOVEQ   #0,D1
RESOLVE:
    CMP.B   #1,D1
    BEQ     HIT_EV
    BRA     MISS_EV

HIT_EV:
    MOVE.B  GRAVITY_INV,D2
    CMP.B   #1,D2
    BEQ     HIT_INV
    * normal physics: hit = bad
    LEA     HIT_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    ADD.B   #8,ENTROPY
    CMP.B   #8,ENERGY       ; prevent underflow
    BLT     ENG_Z
    SUB.B   #8,ENERGY
    BRA     HIT_DONE
ENG_Z:
    MOVE.B  #0,ENERGY
HIT_DONE:
    RTS

HIT_INV:
    * inverted physics: hit charges us
    LEA     HIT_ALT_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    ADD.B   #12,ENERGY
    RTS

MISS_EV:
    MOVE.B  GRAVITY_INV,D2
    CMP.B   #1,D2
    BEQ     MISS_INV
    * normal physics: miss = good
    LEA     MISS_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    CMP.B   #8,ENTROPY      ; prevent underflow
    BLT     ENT_Z
    SUB.B   #8,ENTROPY
    BRA     MISS_DONE
ENT_Z:
    MOVE.B  #0,ENTROPY
MISS_DONE:
    RTS

MISS_INV:
    * inverted physics: miss tears space
    LEA     MISS_ALT_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    ADD.B   #8,ENTROPY
    RTS

*-------------------------------------------------------
* hud - show current stats
*-------------------------------------------------------
HUD:
    BSR     ENDL
    BSR     DECORATE
    LEA     HUD_ENG,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVEQ   #0,D1
    MOVE.B  ENERGY,D1
    MOVE.B  #3,D0
    TRAP    #15
    BSR     ENDL
    LEA     HUD_ENT,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVEQ   #0,D1
    MOVE.B  ENTROPY,D1
    MOVE.B  #3,D0
    TRAP    #15
    BSR     ENDL
    BSR     DECORATE
    RTS

*-------------------------------------------------------
* check death
*-------------------------------------------------------
CHECK_DEATH:
    CMP.B   #0,ENERGY
    BLE     DO_GAMEOVER
    CMP.B   #120,ENTROPY
    BGE     DO_GAMEOVER
    RTS
DO_GAMEOVER:
    BSR     ENDL
    LEA     GAMEOVER_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    BRA     END

*-------------------------------------------------------
* replay - fixed: task 5 reads one char, no Enter needed
* '0' = quit, any other key = continue
*-------------------------------------------------------
REPLAY:
    BSR     ENDL
    LEA     REPLAY_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  #5,D0           ; task 5: read single character into D1
    TRAP    #15
    CMP.B   #'0',D1         ; did they press '0'?
    BEQ     REPLAY_QUIT
    MOVEQ   #1,D1           ; any other key = 1 = continue
    RTS
REPLAY_QUIT:
    MOVEQ   #0,D1           ; '0' pressed = 0 = quit
    RTS

*-------------------------------------------------------
* continue / endl / decorate / clear
*-------------------------------------------------------
CONTINUE:
    BSR     ENDL
    LEA     CONTINUE_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  #4,D0
    TRAP    #15
    RTS

ENDL:
    MOVEM.L D0/A1,-(A7)
    MOVE.B  #14,D0
    LEA     CRLF,A1
    TRAP    #15
    MOVEM.L (A7)+,D0/A1
    RTS

DECORATE:
    MOVE.B  #40,D3
    BSR     ENDL
OUT_DEC:
    LEA     LOOP_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    SUB     #1,D3
    BNE     OUT_DEC
    BSR     ENDL
    RTS

CLEAR_SCREEN:
    MOVE.B  #11,D0
    MOVE.W  #$FF00,D1
    TRAP    #15
    RTS

*-------------------------------------------------------
* data
*-------------------------------------------------------
CRLF:           DC.B    $0D,$0A,0

WELCOME_MSG:    DC.B    '=== QUANTUM JANITOR: SECTOR 7 ===', $0D,$0A
                DC.B    'keep entropy below 120.', $0D,$0A
                DC.B    'physics can invert each round!',0

TOOL_MSG:       DC.B    'tool: 1=tachyon  2=grav boots: ',0

MISSION_MSG:    DC.B    'mission:', $0D,$0A
                DC.B    '1=patrol      (cost: 10)', $0D,$0A
                DC.B    '2=scout       (cost: 15)', $0D,$0A
                DC.B    '3=cleanup     (cost: 20)', $0D,$0A
                DC.B    'choice: ',0

COST_MSG:       DC.B    'energy cost: ',0
LOW_ENG_MSG:    DC.B    'low energy! 1=rest  2=risk: ',0
RISK_MSG:       DC.B    'going in anyway...',0
REST_MSG:       DC.B    'rested. +15 energy.',0

UPDATE_MSG:     DC.B    'scanning physics...',0
NORMAL_MSG:     DC.B    '[world] gravity normal.',0
INVERT_MSG:     DC.B    '[world] gravity inverted!',0

GAMEPLAY_MSG:   DC.B    'resolving mission...',0

HIT_MSG:        DC.B    'hit! -8 energy  +8 entropy',0
MISS_MSG:       DC.B    'miss! -8 entropy',0
HIT_ALT_MSG:    DC.B    'alt physics! hit healed +12e',0
MISS_ALT_MSG:   DC.B    'alt physics! miss +8 entropy',0

HUD_ENG:        DC.B    'energy:  ',0
HUD_ENT:        DC.B    'entropy: ',0

GAMEOVER_MSG:   DC.B    'sector collapsed. game over.',0
REPLAY_MSG:     DC.B    'press 0 to quit, any key to continue: ',0
CONTINUE_MSG:   DC.B    'any number + enter: ',0
ERROR_MSG:      DC.B    'invalid, try again: ',0
LOOP_MSG:       DC.B    '-',0

* variables
ENERGY:         DS.B    1
ENTROPY:        DS.B    1
GRAVITY_INV:    DS.B    1
TOOL_CHOICE:    DS.B    1
MISSION:        DS.B    1

    END START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
