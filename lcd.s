; lcd.s
; Desenvolvido para a placa EK-TM4C1294XL
; Template by Prof. Guilherme Peron - 24/08/2020

; -------------------------------------------------------------------------------
        THUMB                        ; Instruções do tipo Thumb-2
; -------------------------------------------------------------------------------
		
; Declarações EQU - Defines
;<NOME>         EQU <VALOR>
; ========================
; -------------------------------------------------------------------------------
; Área de Dados - Declarações de variáveis
		AREA  DATA, ALIGN=2
		; Se alguma variável for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a variável <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma variável de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posição da RAM		

; -------------------------------------------------------------------------------
; Área de Código - Tudo abaixo da diretiva a seguir será armazenado na memória de 
;                  código
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma função do arquivo for chamada em outro arquivo
		; EXPORT <func>				; Permite chamar a função a partir de outro arquivo
		EXPORT LCD_Init
		EXPORT LCD_Line2
		EXPORT LCD_PrintString
		EXPORT LCD_Reset
		EXPORT print_tabuada
		EXPORT print_numero
									
		; Se chamar alguma função externa	
        ;IMPORT <func>              ; Permite chamar dentro deste arquivo uma função de outro
		IMPORT PortM_Output			; Permite chamar PortM_Output de outro arquivo
		IMPORT PortK_Output			; Permite chamar PortK_Output de outro arquivo
		IMPORT SysTick_Wait1ms		; Permite chamar SysTick_Wait1ms de outro arquivo
; -------------------------------------------------------------------------------
; Função LCD_Init
; Inicializa o LCD
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
LCD_Init
	PUSH {LR}
	
	MOV R3, #0x38		; Inicializar no modo 2 linhas/caracter matriz 5x7
	BL LCD_Instruction
	
	MOV R3, #0x06		; Cursor com autoincremento para direita
	BL LCD_Instruction
	
	MOV R3, #0x0E		; Configurar o cursor (habilitar o display + cursor + não-pisca)
	BL LCD_Instruction
	
	MOV R3, #0x01		; Resetar: Limpar o display e levar o cursor para o home
	BL LCD_Instruction
	
	POP {LR}
	BX LR

; Função LCD_Instruction
; Recebe uma instrução e a executa
; Parâmetro de entrada: R3
; Parâmetro de saída: Não tem
LCD_Instruction
	PUSH {LR}
	
	MOV R0, #2_00000100	; Ativa o modo de instrução (EN=1, RW=0, RS=0)
	BL PortM_Output
	
	MOV R0, R3			; Escreve no barramento de dados
	BL PortK_Output
	
	MOV R0, #10			; Delay de 10ms para executar (bem mais do que os 40us ou 1,64ms necessários)
	BL SysTick_Wait1ms
	
	MOV R0, #2_00000000	; Desativa o modo de instrução (EN=0, RW=0, RS=0)
	BL PortM_Output
	
	POP {LR}
	BX LR

; Função LCD_Data
; Recebe um dado e o escreve
; Parâmetro de entrada: R3
; Parâmetro de saída: Não tem
LCD_Data
	PUSH {LR, R0}
	
	MOV R0, #2_00000101	; Ativa o modo de dados (EN=1, RW=0, RS=1)
	BL PortM_Output
	
	MOV R0, R3			; Escreve no barramento de dados
	BL PortK_Output
	
	MOV R0, #10			; Delay de 10ms para executar (bem mais do que os 40us ou 1,64ms necessários)
	BL SysTick_Wait1ms
	
	MOV R0, #2_00000000	; Desativa o modo de dados (EN=0, RW=0, RS=0)
	BL PortM_Output
	
	POP {LR, R0}
	BX LR

; Função LCD_Line2
; Prepara a escrita na segunda linha do LCD
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
LCD_Line2
	PUSH {LR, R0, R3}
	
	MOV R3, #0xC0		; Endereço da primeira posição - Segunda Linha
	BL LCD_Instruction
	
	MOV R0, #10			; Delay de 10ms para executar (bem mais do que os 40us ou 1,64ms necessários)
	BL SysTick_Wait1ms
	
	POP {LR, R0, R3}
	BX LR

; Funções LCD_PrintString, LCD_PrintChar e LCD_EndOfString
; Imprimem uma string no LCD através de um loop
; Parâmetro de entrada: R4 -> A string a ser escrita
; Parâmetro de saída: Não tem
LCD_PrintString
	PUSH {LR, R0, R3, R4}
LCD_PrintChar
	LDRB R3, [R4], #1	; Lê um caractere da string e desloca para o próximo
	
	CMP R3, #0			; Verifica se chegou no final da string
	BEQ LCD_EndOfString
	
	BL LCD_Data			; Escreve o caractere
	
	B LCD_PrintChar		; Continua iterando sobre a string até chegar no fim
LCD_EndOfString
	MOV R0, #10			; Delay de 10ms para executar (bem mais do que os 40us ou 1,64ms necessários)
	BL SysTick_Wait1ms
	
	POP {LR, R0, R3, R4}			; A string foi escrita. Retorna
	BX LR

; Função LCD_Reset
; Limpa o display e leva o cursor para o home
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
LCD_Reset
	PUSH {LR, R0, R3}
	
	MOV R3, #0x01		; Resetar: Limpar o display e levar o cursor para o home
	BL LCD_Instruction
	
	MOV R0, #10			; Delay de 10ms para executar (bem mais do que os 40us ou 1,64ms necessários)
	BL SysTick_Wait1ms
	
	POP {LR, R0, R3}
	BX LR
	

;Input: R0 = N, R1 = M
;Output: -
print_tabuada
	PUSH {LR, R2}
	BL LCD_Reset
	MUL R2, R0, R1
	;ADD R2, R2, #0
	LDR R4, =TABUADA
	BL LCD_PrintString
	
	BL print_numero
	BL LCD_Line2
	
	BL print_numero
	
	LDR R4,=X
	BL LCD_PrintString
	
	MOV R0, R1
	BL print_numero
	
	LDR R4,=EQUAL
	BL LCD_PrintString
	
	MOV R0, R2
	BL print_numero
	
	POP{LR, R2}
	BX LR

;Input: R0
;Output: -
print_numero
    PUSH {LR, R0, R1, R2, R3, R4, R5, R6} ; Salva registradores críticos
    MOV R1, R0                 ; R1 recebe o número original
    MOV R5, SP                 ; R5 será usado como pilha auxiliar para armazenar os dígitos
    MOV R6, #10                ; Divisor base 10

    CMP R1, #0                 ; Verifica se o número é zero
    BEQ handle_zero            ; Tratamento especial para zero

store_digits
    SDIV R0, R1, R6            ; R0 = R1 / 10 (parte inteira)
    MUL R2, R0, R6             ; R2 = R0 * 10 (recalcula a parte inteira)
    SUB R3, R1, R2             ; R3 = R1 % 10 (resto da divisão, o dígito atual)

    PUSH {R3}                  ; Empilha o dígito atual
    MOV R1, R0                 ; Atualiza R1 com a parte inteira
    CMP R1, #0                 ; Verifica se o número foi reduzido a 0
    BNE store_digits           ; Continua o laço se ainda há dígitos

    B print_digits             ; Vai para a impressão dos dígitos

handle_zero
    MOV R3, #0                 ; Coloca 0 em R3
    PUSH {R3}                  ; Empilha o dígito 0
    B print_digits             ; Vai para a impressão dos dígitos

print_digits
    CMP SP, R5                 ; Verifica se todos os dígitos foram desempilhados
    BEQ print_done             ; Sai se a pilha está vazia

    POP {R3}                   ; Desempilha o próximo dígito
    LDR R4, =DIGIT_9_STR       ; Inicializa com "9" como padrão
    CMP R3, #0
    LDREQ R4, =DIGIT_0_STR
    CMP R3, #1
    LDREQ R4, =DIGIT_1_STR
    CMP R3, #2
    LDREQ R4, =DIGIT_2_STR
    CMP R3, #3
    LDREQ R4, =DIGIT_3_STR
    CMP R3, #4
    LDREQ R4, =DIGIT_4_STR
    CMP R3, #5
    LDREQ R4, =DIGIT_5_STR
    CMP R3, #6
    LDREQ R4, =DIGIT_6_STR
    CMP R3, #7
    LDREQ R4, =DIGIT_7_STR
    CMP R3, #8
    LDREQ R4, =DIGIT_8_STR
    CMP R3, #9
    LDREQ R4, =DIGIT_9_STR

    BL LCD_PrintString         ; Imprime o dígito correspondente
    B print_digits             ; Continua o desempilhamento

print_done
    POP {LR, R0, R1, R2, R3, R4, R5, R6} ; Restaura registradores
    BX LR                      ; Retorna

; Definição dos textos do LCD
DIGIT_0_STR	DCB "0", 0
DIGIT_1_STR	DCB "1", 0
DIGIT_2_STR	DCB "2", 0
DIGIT_3_STR	DCB "3", 0
DIGIT_4_STR	DCB "4", 0
DIGIT_5_STR	DCB "5", 0
DIGIT_6_STR	DCB "6", 0
DIGIT_7_STR	DCB "7", 0
DIGIT_8_STR	DCB "8", 0
DIGIT_9_STR	DCB "9", 0
TABUADA	DCB "Tabuada do ",  0
X DCB "x",0
EQUAL DCB "=",0
; -------------------------------------------------------------------------------------------------------------------------
; Fim do Arquivo
; -------------------------------------------------------------------------------------------------------------------------	
    ALIGN                        ;Garante que o fim da seção está alinhada 
    END                          ;Fim do arquivo
