TITLE Designing Low-Level I/O Procedures      (Low_level_IO.asm)

; Author: Matt Sanders 
; Last Modified: 6/6/2021
; OSU email address: sandemat@oregonstate.edu
; Course number/section: CS271 Section 400
; Project Number: 6             Due Date: 6/6/2021
; Description: This program displays the title and introduces the programmer,
;              then it asks the user for 10 integers, which can be positive
;			   or negative. It then displays them, their sum and their rounded
;			   average.

INCLUDE Irvine32.inc

;---------------------------------------------------------------------------------
; Name: mGetString
;
; Displays a prompt for the user to enter a signed number,
; saves the users number as a string and counts how many
; bytes were read.
;
; Preconditions: no registers used as parameters; uses EDX, ECX, EAX
;
; Receives:
;		promptAddr	= input prompt address
;		inputAddr	= address of memory location to save input
;		bytesRdAddr = address of memory location to save number of bytes read
;		inputLength	= length of input string allowed
;
; Returns: inputAddr   = input string address
;		   bytesRdAddr = number of bytes read
;---------------------------------------------------------------------------------
mGetString	MACRO  promptAddr:REQ, inputAddr:REQ, bytesRdAddr:REQ, inputLength:REQ 
	PUSH	EDX
	PUSH	ECX
	PUSH	EAX
	MOV		EDX,  promptAddr
	call	WriteString
	MOV		EDX,  inputAddr
	MOV		ECX,  inputLength
	call	ReadString
	MOV		inputAddr,  EDX			; Saves the input string
	MOV		[bytesRdAddr],  EAX		; Saves the number of bytes read
	POP		EAX
	POP		ECX
	POP		EDX
ENDM

;--------------------------------------------------------
; Name: mDisplayString
;
; Displays a string stored in memory.
;
; Preconditions: EDX not used as an input parameter
;
; Receives:
;		stringAddr = memory address of string to print
;
; Returns: None
;--------------------------------------------------------
mDisplayString MACRO  stringAddr:REQ
	PUSH	EDX
	MOV		EDX,  stringAddr
	call	WriteString
	POP		EDX
ENDM

ZERO = 30h     ; Hex value for the ASCII digit '0'
NINE = 39h	   ; Hex value for the ASCII digit '9'
POSITIVE = 2Bh ; Hex value for the '+' sign
NEGATIVE = 2Dh ; Hex value for the '-' sign
MAXINPUT = 24  ; Max string characters allowed to be entered by the user
TEN = 10	   ; Used to multiply values

.data

greeting		BYTE	9,9,9,"Designing Low-Level I/O Procedures",9,"Designed And Written By: Matt Sanders",13,10,13,10,0
instructions	BYTE	13,10,9,9,9,9,"Please enter 10 positive or negative decimal integers.",13,10
				BYTE	9,9,9,32,32,"Each number needs to be between -2,147,483,647 and 2,147,483,647.",13,10
				BYTE	9,9,"When you're finished, your numbers, their sum, and their rounded average will be displayed.",13,10,13,10,0
userPrompt		BYTE	9,9,9,9,"Please enter a signed number: ",0
errorMessage	BYTE	9,9,"ERROR: You either did not enter a number or the number was outside the accepted range.",13,10 
				BYTE	9,9,9,9,9,9,"Try Again,",13,10,13,10,0 
arrayLabel		BYTE	9,9,32,32,32,32,"The valid numbers you entered were:",13,10,13,10,9,9,9,9,0
spaceChar		BYTE	32,0			; Tab to align the array output
comma			BYTE	44,0			; Comma for the array output
newLine			BYTE	13,10,0			; Carriage return and line feed to move to next line
sumLabel		BYTE	13,10,13,10,9,9,9,32,32,32,32,"The sum of your numbers is: ",0
averageLabel	BYTE	13,10,9,9,"The rounded average of your numbers is: ",0
tagline			BYTE	13,10,13,10,9,9,9,9,9,"Have a good day!",13,10,0
storedNumb		SDWORD	?				; Holds the converted number before adding to the number array
userNumbs		SDWORD	10 DUP(?)		; Array of valid user numbers
userInput		BYTE	24 DUP(?)		; Array of string digits input by the user
numbOutput		BYTE	12 DUP(?)		; Array used to hold the strning digits from the converted number
bytesRead		SDWORD	?				; Number of bytes read by mGetString macro
sumNumbs		SDWORD  ?				; Holds the sum of the user entered numbers
numbAverage		SDWORD	?				; Holds the rounded average of the user entered numbers

.code
main PROC

	;-----------------------------------------------------------------
	; Displays the program title and the author.
	;-----------------------------------------------------------------
	PUSH	OFFSET  greeting
	call	displayMessage

	;-----------------------------------------------------------------
	; Displays the instructions to the user; which include what they
	; need to do and the range they need to stay within.
	;-----------------------------------------------------------------
	PUSH	OFFSET  instructions
	call	displayMessage
	
	;----------------------------------------------------------------
	; Displays an input prompt for the user to enter a number within
	; the specified range, then it records their numbes as a string.
	; It validates the entered data and stores the valid numbers in
	; a memory location.
	;----------------------------------------------------------------
	MOV		ECX,  LENGTHOF  userNumbs	; Sets the loop counter for getting user input
	MOV		EDI,  OFFSET  userNumbs

_InputLoop:
	PUSH	MAXINPUT
	PUSH	OFFSET  errorMessage
	PUSH	OFFSET  userPrompt
	PUSH	OFFSET  userInput
	PUSH	OFFSET  bytesRead
	PUSH	OFFSET  storedNumb		; Output to store the number after string conversion
	PUSH	ZERO
	PUSH	POSITIVE
	PUSH	NEGATIVE
	PUSH	NINE
	PUSH	TEN
	call	readVal
	MOV		EBX,	storedNumb
	MOV		[EDI],  EBX				; Copy the converted number to the array of valid numbers
	ADD		EDI,	TYPE SDWORD		; Move to next element in the array
	LOOP	_InputLoop
	
	PUSH	OFFSET  newLine
	call	displayMessage	


	;--------------------------------------------------
	; Displays the numbers entered by the user after
	; being converted; It also displays a title for
	; the print out of the numbers. It lines up
	; the output of the numbers with a 'space' and 
	; ',' sepatator.
	;--------------------------------------------------
	PUSH	OFFSET  arrayLabel			; Number array title
	call	displayMessage
	MOV		ESI,	OFFSET userNumbs
	MOV		ECX,	LENGTHOF userNumbs

_OutputLoop:
	PUSH	[ESI]						; Number from the array
	PUSH	OFFSET numbOutput
	PUSH	LENGTHOF numbOutput
	PUSH	TEN
	PUSH	ZERO
	PUSH	NEGATIVE
	call	writeVal
	ADD		ESI,  TYPE SDWORD			; Move to next element of arrray
	CMP		ECX,  TYPE BYTE
	JE		_Continue

_Lineup:	
	PUSH	OFFSET  comma				; Adds ',' to output
	call	displayMessage
	PUSH	OFFSET	spaceChar			; Adds 'space' to output
	call	displayMessage

_Continue:
	LOOP	_OutputLoop

	;--------------------------------------------------
	; Calculates the sum of the entered numbers.
	;--------------------------------------------------
	PUSH	OFFSET   userNumbs
	PUSH	OFFSET	 sumNumbs
	PUSH	LENGTHOF userNumbs
	call	integerSum

	;-------------------------------------------------
	; Displayes a label for the sum of the entered 
	; values and then displays the sum of those values
	; to the user.
	;-------------------------------------------------
	PUSH	OFFSET  sumLabel			; Label for the sum of the numbers
	call	displayMessage
	MOV		ESI,	 OFFSET sumNumbs
	PUSH	[ESI]						; The sum of the valid numbers
	PUSH	OFFSET   numbOutput
	PUSH	LENGTHOF numbOutput
	PUSH	TEN
	PUSH	ZERO
	PUSH	NEGATIVE
	call	writeVal

	;------------------------------------------------
	; Calculates the average of the set of entered
	; numbers starting from the sum of those numbers.
	;------------------------------------------------
	PUSH	sumNumbs
	PUSH	OFFSET   numbAverage
	PUSH	LENGTHOF userNumbs
	call	integerAve

	;-----------------------------------------------
	; Displays a label for the average of the
	; entered numbers and then displays the numbers
	; to the user; rounded down to the nearest 
	; integer.
	;------------------------------------------------
	PUSH	OFFSET  averageLabel		; Label for the average of the numbers
	call	displayMessage
	MOV		ESI,	 OFFSET numbAverage
	PUSH	[ESI]						; Average of the valid numbers
	PUSH	OFFSET   numbOutput
	PUSH	LENGTHOF numbOutput
	PUSH	TEN
	PUSH	ZERO
	PUSH	NEGATIVE
	call	writeVal

	;----------------------------------------------
	; Displays a farewell message to the user.
	;----------------------------------------------
	PUSH	OFFSET  tagline
	call	displayMessage

	Invoke ExitProcess,0	; exit to operating system
main ENDP

;---------------------------------------------------------------------------
; Name: readVal
;
; Uses mGetString macro to read a user input string of digits,
; then it converts the ASCII characters to an equivalent number,
; validates that the input was a number within the accepted range,
; and stores the number in an array.
;
; Preconditions: The output array is type SDWORD, macro parameters
;				 must be passed to procedure.
;
; Postconditions: None
;
; Receives:
;		[EBP + 48] = max string input
;		[EBP + 44] = error message offset
;		[EBP + 40] = user prompt offset
;		[EBP + 36] = BYTE array to store the string
;		[EBP + 32] = the number of BYTEs read from user input
;		[EBP + 28] = output to store the converted number
;		[EBP + 24] = hex number for ASCII char. '0'
;		[EBP + 20] = hex number for ASCII char. '+'
;		[EBP + 16] = hex number for ASCII char.'-'
;		[EBP + 12] = hex number for ASCII char. '9'
;		[EBP + 8]  = decimal number 10
;
; Returns: storedNumb = the converted user input number
;---------------------------------------------------------------------------
readVal  PROC
	PUSH	EBP
	MOV		EBP,	ESP
	PUSH	ESI
	PUSH	ECX
	PUSH	EDX
	PUSH	EAX
	PUSH	EBX
	PUSH	EDI
	MOV		EDI,	[EBP + 28]		; Copies offset of output variable from stack

_Input:
	mGetString  [EBP + 40], [EBP + 36], [EBP + 32], [EBP + 48]
	JZ		_Error
	MOV		ESI,	[EBP + 36]		; Copies offset of saved user input from stack
	MOV		ECX,	[EBP + 32]		; Copies number of bytes read from stack
	CLD								; Clear direction flag
	LODSB
	CMP		AL,		[EBP + 20]		; Compares first character to the '+' string
	JE		_PosSign
	CMP		AL,		[EBP + 16]		; Compares first character to the '-' string
	JE		_NegSign
	CMP		ECX,	[EBP + 8]		; Compared ECX to 10
	JG		_Error

_StartAlg:
	CMP		AL,		[EBP + 24]		; Checks if the value is less than the value for '0' character
	JL		_Error
	CMP		AL,		[EBP + 12]		; Checks if the value is greater than the value for '9' character
	JG		_Error
	SUB		AL,		[EBP + 24]		; Subtract 30h from value
	CMP		ECX,	TYPE BYTE		; Compares counter to 1
	JE		_OneCharacter
	DEC		ECX
	MOV		BL,		[EBP + 8]		; Sets BL to 10
	MUL		BL						
	MOVSX	EDX,	AX				; Sign extends AX

_Convert:
	LODSB
	SUB		AL,		[EBP + 24]		; Subtract 30h from value
	MOVSX   EBX,	AL				; Sign extend AL
	ADD		EDX,	EBX
	JO		_Error					; Check overflow flag
	MOV		[EDI],	EDX				; Store value in output variable
	MOV		EBX,	[EBP + 8]		; Copy 10 from stack
	MOV		EAX,	EDX
	MUL		EBX
	MOV		EDX,	EAX
	LOOP	_Convert
	JMP		_ExitProc

_PosSign:
	DEC		ECX
	CMP		ECX,	[EBP + 8]		; Compared ECX to 10
	JG		_Error
	LODSB
	JMP		_StartAlg

_NegSign:
	DEC		ECX
	CMP		ECX,	[EBP + 8]		; Compared ECX to 10
	JG		_Error
	LODSB
	CMP		AL,		[EBP + 24]		; Checks if the value is less than the value for '0' character
	JL		_Error
	CMP		AL,		[EBP + 12]		; Checks if the value is greater than the value for '9' character
	JG		_Error
	SUB		AL,		[EBP + 24]		; Subtract 30h from value
	CMP		ECX,	TYPE BYTE		; Compare counter to 1
	JE		_OneNegCharacter
	DEC		ECX
	MOV		BL,		[EBP + 8]		; Sets BL to 10
	MUL		BL						
	MOVZX	EDX,	AX				; Sign extends AX

_NegConvert:
	LODSB
	SUB		AL,		[EBP + 24]		; Subtract 30h from value
	MOVZX   EBX,	AL				; Sign extend AL
	ADD		EDX,	EBX
	JO		_Error					; Check overflow flag
	NEG		EDX
	MOV		[EDI],  EDX				; Store value in output variable
	NEG		EDX
	MOV		EBX,	[EBP + 8]		; Copy 10 from stack
	MOV		EAX,	EDX
	MUL		EBX
	MOV		EDX,	EAX
	LOOP	_NegConvert
	JMP		_ExitProc
	
_Error:
	mDisplayString  [EBP + 44]
	JMP		_Input

_OneNegCharacter:
	MOVSX	EDX,	AL				; Sign extends AL
	NEG		EDX
	MOV		[EDI],	EDX				; Store the value in output variable
	JMP		_ExitProc

_OneCharacter:
	MOVSX	EDX,	AL				; Sign extends AL
	MOV		[EDI],	EDX				; Store the value in output variable

_ExitProc:
	POP		EDI
	POP		EBX
	POP		EAX
	POP		EDX
	POP		ECX
	POP		ESI
	POP		EBP
	RET		44
readVal  ENDP

;---------------------------------------------------------------------------
; Name: writeVal
;
; Converts a numeric value to a string of ASCII characters that represent
; the value and then Uses mDisplayString macro to display the converted 
; string.
;
; Preconditions: Input value must be type SDWORD, macro parameter
;				 must be passed to procedure.
;
; Receives:
;		[EBP +  8]  = negative sign character
;		[EBP +  12] = hex value for '0'
;		[EBP +  16] = constant for value of 10
;		[EBP +  20] = length of the output array
;		[EBP +  24] = offset of the output array
;		[EBP +  28] = number to convert
;---------------------------------------------------------------------------
writeVal PROC
	PUSH	EBP
	MOV		EBP,  ESP
	PUSH	EDI
	PUSH	EDX
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	MOV		EDI,  [EBP + 24]	; Copy offset of userinput array
	MOV		EDX,  TYPE BYTE
	DEC		EDX					; Clears the register
	STD							; Set direction flag
	ADD		EDI,  [EBP + 20]	; Move to end of array
	MOV		AL,	  DL			
	STOSB						; Store null terminator
	CMP		EDX,  [EBP + 28]	; Compare the number to 0
	JG		_NegNumb
	MOV		EAX,  [EBP + 28]	; Copy number from stack
	MOV		EBX,  [EBP + 16]	; Copy 10 from stack

_ConvertLoop:
	DIV		EBX
	ADD		EDX,  [EBP + 12]	; Add 30h to the remainder
	MOV		ECX,  EAX
	MOV		AL,   DL
	STOSB						; Store string value in output array
	MOV		EAX,  ECX
	CMP		EAX,  TYPE BYTE		; Compare the quotient to 1
	JL		_Finished
	MOV		EDX,  TYPE BYTE
	DEC		EDX					; Clear EDX
	JMP		_ConvertLoop

_NegNumb:
	MOV		EAX,  [EBP + 28]	; Copy number from stack
	NEG		EAX
	MOV		EBX,  [EBP + 16]	; Copy 10 from stack

_NegConvert:
	DIV		EBX
	ADD		EDX,  [EBP + 12]	; Add 30h to the remainder
	MOV		ECX,  EAX
	MOV		AL,   DL
	STOSB						; Store string value in output array
	MOV		EAX,  ECX
	CMP		EAX,  TYPE BYTE		; Compare the quotient to 1
	JL		_AddNegSign
	MOV		EDX,  TYPE BYTE
	DEC		EDX					; Clear EDX
	JMP		_NegConvert

_AddNegSign:
	MOV		AL,   [EBP + 8]		; Adds the minus sign for a negative value
	STOSB

_Finished:
	ADD		EDI,	TYPE BYTE
	mDisplayString  EDI
	POP		ECX
	POP		EBX
	POP		EAX
	POP		EDX
	POP		EDI
	POP		EBP
	RET		24
writeVal ENDP

;---------------------------------------------------------------------------
; Name: integerSum
;
; Adds the integer values from an array and saves the value. 
;
; Preconditions: Input array must be type SDWORD.
;
; Receives:
;		[EBP + 16] = offset of the input array
;		[EBP + 12] = offset of the output address
;		[EBP + 8]  = the value 10
;
; Returns: sumNumbs = the sum of the integers
;---------------------------------------------------------------------------
integerSum PROC
	PUSH	EBP
	MOV		EBP,  ESP
	PUSH	ESI
	PUSH	EDI
	PUSH	EAX
	PUSH	ECX
	MOV		ESI,    [EBP + 16]		; Copies offset of the array of input numbers from stack
	MOV		EDI,    [EBP + 12]		; Copies offset of the output variable from stack
	MOV		ECX,    [EBP + 8]		; Copies 10 from stack
	MOV		EAX,    [ESI]			
	DEC		ECX

_SumLoop:
	ADD		ESI,    TYPE SDWORD		; Increments to next array element
	ADD		EAX,    [ESI]
	LOOP	_SumLoop
	
	MOV		[EDI],  EAX
	POP		ECX
	POP     EAX
	POP		EDI
	POP		ESI
	POP		EBP
	RET		12
integerSum ENDP 

;---------------------------------------------------------------------------
; Name: integerAve
;
; Averages the values from an array, rounds the value and saves it.
;
; Preconditions: Input array must be type SDWORD.
;
; Receives:
;		[EBP + 16] = sum of the array of numbers	
;		[EBP + 12] = offset of the output variable
;		[EBP + 8]  = length of the number array
;
; Returns: numbAverage = rounded average of the array values
;---------------------------------------------------------------------------
integerAve PROC
	PUSH	EBP
	MOV		EBP,  ESP
	PUSH	EDI
	PUSH	EAX
	PUSH	EDX
	PUSH	EBX
	MOV		EDI,    [EBP + 12]	; Copy the offset of the output variable from stack
	MOV		EAX,    [EBP + 16]	; Copy the sum of the values from stack
	CDQ							; Sign extends EAX into EDX
	MOV		EBX,    [EBP + 8]	; Copy length of the number array from stack
	IDIV	EBX
	MOV		[EDI],  EAX	
	POP		EBX
	POP		EDX
	POP		EAX
	POP		EDI
	POP		EBP
	RET		12
integerAve ENDP

;---------------------------------------------------------------------------
; Name: displayMessage
;
; Displays a given message or title. 
;
; Preconditions: Macro parameter must be passed to procedure.
;
; Receives:
;		[EBP + 8] = the offset of the message to print
;---------------------------------------------------------------------------
displayMessage PROC
	PUSH	EBP
	MOV		EBP,	ESP
	mDisplayString  [EBP +8]	; Calls a macro to display the input string 
	POP		EBP
	RET		4
displayMessage ENDP

END main
