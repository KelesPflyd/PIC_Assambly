; PIC 16F628A - Keypad 4x4 Binary Display
; RA0-RA3: LED Output, RB0-RB3: Column Input, RB4-RB7: Row Output

    LIST P=16F628A
    INCLUDE "P16F628A.INC"
    __CONFIG _INTOSC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _LVP_OFF

    ORG 0x00
    GOTO START

START:
    MOVLW 0x07          ; Karşılaştırıcıları kapat (PortA'yı digital yap)
    MOVWF CMCON
    BANKSEL TRISA
    CLRF TRISA          ; PORTA çıkış (LEDler)
    MOVLW B'00001111'   ; RB0-RB3 Giriş (Sütunlar), RB4-RB7 Çıkış (Satırlar)
    MOVWF TRISB
    BANKSEL PORTA

MAIN_LOOP:
    ; --- SATIR 1 (RB4) TARAMA ---
    MOVLW B'11101111'   ; RB4=0, diğerleri 1
    MOVWF PORTB
    BTFSS PORTB, 0      ; Tuş 0?
    MOVLW D'0'
    BTFSS PORTB, 1      ; Tuş 1?
    MOVLW D'1'
    BTFSS PORTB, 2      ; Tuş 2?
    MOVLW D'2'
    BTFSS PORTB, 3      ; Tuş 3?
    MOVLW D'3'
    MOVWF PORTA         ; Sonucu LED'e gönder

    ; --- SATIR 2 (RB5) TARAMA ---
    MOVLW B'11011111'   ; RB5=0
    MOVWF PORTB
    BTFSS PORTB, 0      ; Tuş 4?
    MOVLW D'4'
    ; ... (Diğer satırlar için benzer mantık devam eder)
    
    GOTO MAIN_LOOP
    END