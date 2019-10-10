.org 0x200 ; create 7SEG CODE TABLE at address 0x100 (word address, which will be byte address of 200)
data:.DB     0b01000000,0b01111001,0b0100100,0b00110000,0b00011001,0b00010010,0b00000010,0b01111000,0b00000000,0b00011000,0b00000001,0b00000010,0b00000100,0b00001000,0b00010000,0b00100000
//            0   ,   1      ,   2     ,     3    ,    4     ,    5     ,    6     ,    7     ,    8     ,     9    , A digit 1, B digit 2, C digit 3, D digit 4, E digit 5, F digit 6
// test change in the atmel studio :)
// 0b0GFEDCBA
//	   G   F  E  D  C   B    A
//   (15)(11)(5)(3)(13)(16)(14) THIS FOR THE LED
//   https://www.microchip.com/webdoc/avrassembler/avrassembler.wb_instruction_list.html
	.org 0x00
	jmp start
	.org 0x02
	jmp pause

; Replace with your application code
start:
    LDI R16, 0xFF ; load 1's into R16
	OUT DDRB, R16 ; output 1's to configure DDRB as "output" port
	OUT DDRC, R16 ; output 1's to configure DDRC as "output" port
	CBI DDRD,6

	ldi r23,0x08 ;seconds one's place, load r16 with BCD(hex) value of the digit to be converted (digit 7 is used as an example)
	ldi r24,0x05 ;seconds ten's place, load r16 with BCD(hex) value of the digit to be converted (digit 7 is used as an example)
	ldi r25,0x08 ;minutes one's place, load r16 with BCD(hex) value of the digit to be converted (digit 7 is used as an example)
	ldi r26,0x05 ;minutes ten's place, load r16 with BCD(hex) value of the digit to be converted (digit 7 is used as an example)
	ldi r27,0x03 ;hours ones's place, load r16 with BCD(hex) value of the digit to be converted (digit 7 is used as an example)
	ldi r28,0x02 ;hours ten's place, load r16 with BCD(hex) value of the digit to be converted (digit 7 is used as an example)
	ldi r31,0x0a	; Preload binary 00001010 into r31
	ldi r17,0x00
	sts eicra,r31	; Set eicra to 00001010 (both interrupts trigger on active low)
	ldi r31,0x03	; Preload binary 00000011 into r31
	out eimsk,r31	; Set eimsk to 00000011 (enable both interrupts)
	ldi r31,0x00	; Preload binary 00000000 into r31
	out DDRD,r31	; Set ddrd to 00000000 (all pins of portd are input pins, note you only need pins 2 and 3 for the interrupts)
	ldi r31,0x0c	; Preload binary 00001100 into r31
	out PORTD,r31	; Set portd to 00001100 (portd pins 2 and 3 are internally hooked to pull up resistors)
	sei		; Set enable interrupts


tog:
	sei
	ldi r16, 0x01;
	cp r17,r16;
	breq IncrementSecondsjmp

	LDI R22, 1;
	
	LOP_1:LDI R21, 1;
		LOP_2:LDI R20, 1;
			LOP_3:
				call DisplayAll

				DEC R20;
			BRNE LOP_3;
			DEC R21;
		BRNE LOP_2;
		DEC R22;
	BRNE LOP_1;

	ldi r21, 0x00
	ldi r30,0x09; load 9 in so we can compare it
	cp r23,r30; compare
	brsh resetSeconds1sPlace; branch if same or higher,  https://www.microchip.com/webdoc/avrassembler/avrassembler.wb_instruction_list.html
	

	
	inc r23; increase seconds one's place, this should be happening at 1Hz
	JMP tog; go to tog

IncrementSecondsjmp:
	ldi r20, 0x01
	jmp IncrementSeconds

TurnOnDigit:
	; first digit code
   ldi ZL, low(2*data)
   ldi ZH, high(2*data)
	add zl,r29 ; add the BCD  value to be converted to low byte of 7SEG CODE TABLE to create an offset numerically equivalent to BCD value 
	lpm r18,z ; load z into r17 from program memory from7SEG CODE TABLE using modified z register as pointer
	out PORTC, r18 // put on line adjacent to out portb
	ret
	
LoopDelay:
	ldi r31,60;
	LOOP1:
		dec r31;
	BRNE LOOP1;
	ret

resetAllSeconds:
	ldi r23,0x00;
	ldi r24,0x00;
	ret

resetSeconds1sPlace:
	ldi r23,0x00;
	inc r24;

	ldi r30,0x06; load 6 in so we can compare it
	cp r24,r30; compare
	brsh resetSecondsTensPlace; branch if same or higher, 
	jmp tog;

	
resetSecondsTensPlace:
	ldi r23,0x00;
	ldi r24,0x00;

	ldi r16,0x01
	cp r21,r16
	breq freezejmp

	inc r25;



	
	ldi r30,0x09; load 9 in so we can compare it
	cp r25,r30; compare
	brsh resetMinutes1sPlace; branch if same or higher, 
	jmp tog;

	
resetMinutes1sPlace:
	ldi r25,0x00;
	inc r26;

	ldi r16,0x01
	cp r21,r16
	breq minutesResetCheck


	call resetAllSeconds
	
	ldi r30,0x06; load 9 in so we can compare it
	cp r26,r30; compare
	brsh resetMinutesTensPlace; branch if same or higher, 

	jmp tog;

minutesResetCheck:
	ldi r30,0x06; load 6 in so we can compare it
	cp r26,r30; compare
	brsh resetMinutesTensPlace; branch if same or higher,
	jmp freezejmp
	
resetMinutesTensPlace:
	ldi r25,0x00;
	ldi r26,0x00;

	ldi r16,0x01
	cp r21,r16
	breq freezejmp

	call resetAllSeconds
	inc r27;

	ldi r30,0x0A; load 9 in so we can compare it
	cp r27,r30; compare
	brsh resetHoursOnesPlace; branch if same or higher, 

	ldi r30,0x04
	cp r27,r30;
	brsh CheckIfNeedToReset; branch if same or higher, 

	jmp tog;

freezejmp:
	jmp freeze

resetHoursOnesPlace:

	ldi r27,0x00;
	inc r28;

	ldi r16,0x01
	cp r21,r16
	breq hoursResetCheck

	call resetAllMin

	
	ldi r30,0x02; load 9 in so we can compare it
	cp r28,r30; compare
	brsh resetHoursTensPlace; branch if same or higher, 

	jmp tog;

hoursResetCheck:
	ldi r30,0x02; load 9 in so we can compare it
	cp r28,r30; compare
	brsh resetHoursTensPlace; branch if same or higher,
	jmp freezejmp

resetAllMin:
	ldi r23,0x00;
	ldi r24,0x00;
	ldi r25,0x00;
	ldi r26,0x00;
	ret

resetHoursTensPlace:
	call resetAllmin
	ldi r27,0x00

	jmp tog;

CheckIfNeedToReset: 

	ldi r30,0x02; load 9 in so we can compare it
	cp r28,r30; compare
	brsh ResetToZero; branch if same or higher, 

	
	jmp tog;

ResetToZero:
	ldi r23,0x00 ;seconds one's place, load r16 with BCD(hex) value of the digit to be converted (digit 7 is used as an example)
	ldi r24,0x00 ;seconds ten's place, load r16 with BCD(hex) value of the digit to be converted (digit 7 is used as an example)
	ldi r25,0x00 ;minutes one's place, load r16 with BCD(hex) value of the digit to be converted (digit 7 is used as an example)
	ldi r26,0x00 ;minutes ten's place, load r16 with BCD(hex) value of the digit to be converted (digit 7 is used as an example)
	ldi r27,0x00 ;hours ones's place, load r16 with BCD(hex) value of the digit to be converted (digit 7 is used as an example)
	ldi r28,0x00 ;hours ten's place, load r16 with BCD(hex) value of the digit to be converted (digit 7 is used as an example)
	jmp tog;

pause:
	ldi r16, 0x00
	cp r17,r16 // check if not frozen
	breq freeze /// if not froze, loop freeze
	ldi r16, 0x01
	cp r17,r16  // check if frozen
	breq togjump  // if frozen, unfreeze and jump to main

freeze:
	ldi r17, 0x01
	call DisplayAll

	sei

	ldi r20, 0x00
	ldi r21, 0x00
	SBIC PIND,5;
	jmp IncrementSeconds
	SBIC PIND,6;
	jmp IncrementMinutes
	SBIC PIND,7;
	jmp IncrementHours

	jmp freeze

togjump:
	ldi r17,0x00
	jmp tog

IncrementSeconds:
	SBIC PIND,5
	jmp IncrementSeconds

	ldi r30,0x09; load 9 in so we can compare it
	cp r23,r30; compare
	brsh resetSeconds1sPlacejmp; branch if same or higher,  https://www.microchip.com/webdoc/avrassembler/avrassembler.wb_instruction_list.html
	ldi r16, 0x00
	cp r20, r16
	breq incSec

	jmp freeze

incSec:
		inc r23
		jmp freeze


resetSeconds1sPlacejmp:
	ldi r21, 0x01
	jmp resetSeconds1sPlace
	
IncrementMinutes:
	SBIC PIND,6
	jmp IncrementMinutes

	ldi r30,0x09; load 9 in so we can compare it
	cp r25,r30; compare
	brsh resetMinutes1sPlacejmp; branch if same or higher,  https://www.microchip.com/webdoc/avrassembler/avrassembler.wb_instruction_list.html
	ldi r16, 0x00
	cp r20, r16
	breq incMin

	jmp freeze

incMin:
		inc r25
		jmp freeze


resetMinutes1sPlacejmp:
	ldi r21, 0x01
	jmp resetMinutes1sPlace
	

	
IncrementHours:
	SBIC PIND,7
	jmp IncrementHours
	
	ldi r30,0x03
	cp r27,r30
	breq checkifneedtoresetjmp
	ldi r30,0x09; load 9 in so we can compare it
	cp r27,r30; compare
	brsh resetHours1sPlacejmp; branch if same or higher,  https://www.microchip.com/webdoc/avrassembler/avrassembler.wb_instruction_list.html
	ldi r16, 0x00
	cp r20, r16
	breq incHr

	jmp freeze

incHr:
		inc r27
		jmp freeze

checkifneedtoresetjmp:
	ldi r20,0x01
	inc r27
	jmp checkifneedtoreset

resetHours1sPlacejmp:
	ldi r21, 0x01
	jmp resetHoursOnesPlace


LoadZRegister:
   ldi ZL, low(2*data)
   ldi ZH, high(2*data)
	add zl,r19 ; add the BCD  value to be converted to low byte of 7SEG CODE TABLE to create an offset numerically equivalent to BCD value 
	lpm r19,z ; load z into r17 from program memory from7SEG CODE TABLE using modified z register as pointer
	ret

DisplayAll:
	mov r19,r23
	call LoadZRegister
	
	ldi r29, 0x0A ; set to 10 so we can load 10's item in the database
	call TurnOnDigit
	out PORTB, r19
				
	call LoopDelay

	mov r19,r24
	call LoadZRegister

	inc r29
	call TurnOnDigit
	out PORTB, r19
				
	call LoopDelay
			
	mov r19,r25
	call LoadZRegister	
	
	inc r29
	call TurnOnDigit
	out PORTB, r19
	call LoopDelay
	
	mov r19,r26
	call LoadZRegister
	
	inc r29
	call TurnOnDigit
	out PORTB, r19
	call LoopDelay

				
	mov r19,r27
	call LoadZRegister
	
	inc r29
	call TurnOnDigit
	out PORTB, r19
	call LoopDelay
				
				
	mov r19,r28
	call LoadZRegister
	
	inc r29
	call TurnOnDigit
	out PORTB, r19
	call LoopDelay
	ret
